import SwiftUI
import PhotosUI

struct ContentView: View {
    @State private var order = TeaOrder()
    @State private var step = 0
    @State private var labelColor = Color(red: 0.25, green: 0.34, blue: 0.26)
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var photo: UIImage?
    @State private var days: Set<DateComponents> = []
    @State private var alert: Notice?
    @State private var history: [Receipt] = []
    @State private var showHistory = false
    @AppStorage("tea.receipts.v1") private var savedReceipts = Data()
    private let ink = Color(red: 0.17, green: 0.23, blue: 0.18)
    private let paper = Color(red: 0.97, green: 0.95, blue: 0.90)
    enum Notice: String, Identifiable { case invalid, confirm, success, reset, photoError; var id: String { rawValue } }
    @State private var message = ""
    var body: some View {
        GeometryReader { geometry in
            let wide = geometry.size.width > 760
            VStack(spacing: 0) {
                header
                ScrollViewReader { proxy in
                ScrollView {
                    if wide {
                        HStack(alignment: .top, spacing: 32) { preview.frame(width: 320); editor.id("editor").frame(maxWidth: 560) }.padding(32).frame(maxWidth: .infinity)
                    } else { VStack(spacing: 24) { preview; editor.id("editor") }.padding(20) }
                }.scrollDismissesKeyboard(.interactively)
                    .onChange(of: step) { _, _ in if !wide { withAnimation { proxy.scrollTo("editor", anchor: .top) } } }
                }
                checkout
            }
            .background(paper).foregroundStyle(ink)
        }
        .tint(ink).preferredColorScheme(.light)
        .sheet(isPresented: $showHistory) { historySheet }
        .alert(alertTitle, isPresented: Binding(get: { alert != nil }, set: { if !$0 { alert = nil } })) {
            switch alert {
            case .confirm:
                Button("再調整", role: .cancel) { }
                Button("確認製作") { saveOrder() }
            case .reset:
                Button("取消", role: .cancel) { }
                Button("重設", role: .destructive) { order = TeaOrder(); days = []; photo = nil; selectedPhoto = nil; labelColor = ink; step = 0 }
            default: Button("知道了", role: .cancel) { }
            }
        } message: { Text(message) }
        .task(id: selectedPhoto) { await loadPhoto() }
        .task {
            history = (try? JSONDecoder().decode([Receipt].self, from: savedReceipts)) ?? []
            #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("-schedule") { step = 1 }
            if ProcessInfo.processInfo.arguments.contains("-review") { order.name = "小茶"; step = 2 }
            if ProcessInfo.processInfo.arguments.contains("-demo") { await demo() }
            #endif
        }
    }
    private var header: some View {
        HStack {
            HStack(spacing: 10) { Image(systemName: "leaf").font(.title2); Text("茶序").font(.system(size: 25, weight: .medium, design: .serif)); Text("TEA ATELIER").font(.system(size: 9, weight: .semibold)).tracking(2) }
            Spacer()
            Button { showHistory = true } label: { Image(systemName: "receipt").font(.title3).frame(width: 44, height: 44) }.accessibilityLabel("訂單紀錄")
        }.padding(.horizontal, 24).padding(.vertical, 8)
        .background(paper).overlay(alignment: .bottom) { Rectangle().fill(ink.opacity(0.12)).frame(height: 1) }
    }
    private var preview: some View {
        VStack(spacing: 0) {
            HStack { Text("YOUR DAILY RITUAL").font(.system(size: 9, weight: .semibold)).tracking(2); Spacer(); Text("手作 01").font(.caption) }.padding(20)
            TeaCupView(order: order, labelColor: labelColor, photo: photo)
                .contextMenu {
                    Button("回復經典配方", systemImage: "arrow.counterclockwise") { message = "將清除目前的飲料、取餐與杯身設定。已儲存訂單會保留。"; alert = .reset }
                    Button("移除杯身照片", systemImage: "photo.badge.minus", role: .destructive) { photo = nil; selectedPhoto = nil }.disabled(photo == nil)
                }
            Text(order.tea.rawValue).font(.system(size: 28, weight: .medium, design: .serif))
            Text(order.tea.subtitle).font(.system(size: 9, weight: .medium)).tracking(3).padding(.top, 7)
            Text(order.recipe).font(.caption).foregroundStyle(.secondary).padding(.top, 14)
            HStack(spacing: 6) { Image(systemName: "sparkle"); Text("一點茶香，調成你的日常") }.font(.caption).padding(.top, 20).padding(.bottom, 24)
        }.background(Color(red: 0.91, green: 0.89, blue: 0.81), in: RoundedRectangle(cornerRadius: 22))
    }
    private var editor: some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack { Text("調一杯，剛剛好。").font(.system(size: 26, weight: .medium, design: .serif)); Spacer() }
            Picker("製作步驟", selection: $step) { Text("01 調茶").tag(0); Text("02 取餐").tag(1); Text("03 杯身").tag(2) }.pickerStyle(.segmented)
            if step == 0 { recipeEditor }
            else if step == 1 { pickupEditor }
            else { designEditor }
        }
    }
    private var recipeEditor: some View {
        VStack(alignment: .leading, spacing: 22) {
            sectionTitle("01", "選一款茶底", detail: "清香・焙火・回甘")
            Picker("茶底", selection: $order.tea) { ForEach(Tea.allCases) { tea in Text("\(tea.rawValue)  $\(tea.price)").tag(tea) } }.pickerStyle(.menu).frame(maxWidth: .infinity, alignment: .leading).padding(10).background(.white.opacity(0.7), in: RoundedRectangle(cornerRadius: 12))
            Picker("杯型", selection: $order.large) { Text("中杯 500 ml").tag(false); Text("大杯 700 ml +$10").tag(true) }.pickerStyle(.segmented)
            HStack { Text("甜度"); Spacer(); Text("\(Int(order.sweetness))%").monospacedDigit() }
            Slider(value: $order.sweetness, in: 0...100, step: 10) { Text("甜度") }
            Picker("冰量", selection: $order.ice) { ForEach(["去冰", "微冰", "少冰", "正常冰"], id: \.self) { Text($0) } }.pickerStyle(.segmented)
            VStack(spacing: 15) {
                Toggle("手作珍珠 +$10", isOn: $order.pearls)
                Toggle("加入鮮奶 +$15", isOn: $order.milk)
                Toggle("自備環保杯 −$5", isOn: $order.ownCup)
                Divider()
                Stepper("杯數  \(order.quantity) 杯", value: $order.quantity, in: 1...12)
            }.padding(18).background(.white.opacity(0.7), in: RoundedRectangle(cornerRadius: 16))
            nextButton("下一步・安排取餐", to: 1)
        }
    }
    private var pickupEditor: some View {
        VStack(alignment: .leading, spacing: 18) {
            sectionTitle("02", "留一段喝茶時間", detail: "今天的好心情，預約好了")
            TextField("取餐姓名（必填）", text: $order.name).textContentType(.name).padding(15).background(.white, in: RoundedRectangle(cornerRadius: 12))
            DatePicker("取餐時間", selection: $order.pickup, in: Date()..., displayedComponents: [.date, .hourAndMinute])
            Text("再喝一杯的日子").font(.headline)
            Text("可選多天，記在訂單中；不會重複下單或發送通知。").font(.caption).foregroundStyle(.secondary)
            MultiDatePicker("喝茶日曆", selection: $days, in: Calendar.current.startOfDay(for: Date())...).padding(8).background(.white, in: RoundedRectangle(cornerRadius: 16))
            Text("已選 \(days.count) 天").font(.caption).foregroundStyle(.secondary)
            Text("給茶師的小紙條").font(.headline)
            TextEditor(text: $order.note).frame(height: 95).padding(8).scrollContentBackground(.hidden).background(.white, in: RoundedRectangle(cornerRadius: 12)).overlay(alignment: .topLeading) { if order.note.isEmpty { Text("例如：珍珠請分開裝").font(.body).foregroundStyle(.tertiary).padding(16).allowsHitTesting(false) } }.accessibilityLabel("訂單備註")
            nextButton("下一步・設計杯身", to: 2)
        }
    }
    private var designEditor: some View {
        VStack(alignment: .leading, spacing: 20) {
            sectionTitle("03", "把喜歡，握在手心", detail: "為這杯茶留下一點自己的樣子")
            ColorPicker("杯標顏色", selection: $labelColor, supportsOpacity: false).padding(18).background(.white, in: RoundedRectangle(cornerRadius: 14))
            PhotosPicker(selection: $selectedPhoto, matching: .images) { Label("選擇杯身照片", systemImage: "photo.on.rectangle.angled").frame(maxWidth: .infinity).padding(18).background(.white, in: RoundedRectangle(cornerRadius: 14)) }
            if photo != nil { Button("移除照片", role: .destructive) { selectedPhoto = nil; photo = nil } }
            Text("長按上方茶杯，可移除照片或重設配方。杯身設計僅預覽，本機訂單保留文字內容。").font(.caption).foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 14) {
                Text("你的專屬配方").font(.headline)
                summaryRow("茶飲", order.tea.rawValue)
                summaryRow("單杯", "NT$ \(order.unitPrice)")
                summaryRow("數量", "\(order.quantity) 杯")
                summaryRow("取餐人", order.name.isEmpty ? "尚未填寫" : order.name)
                summaryRow("取餐時間", order.pickup.formatted(date: .abbreviated, time: .shortened))
                Divider()
                Text("本 App 為課堂模擬點餐，不會付款或送出至店家。").font(.caption).foregroundStyle(.secondary)
            }.padding(20).background(.white.opacity(0.7), in: RoundedRectangle(cornerRadius: 16))
            Button("重新調整茶飲") { step = 0 }.font(.subheadline)
        }
    }
    private var checkout: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) { Text("\(order.quantity) 杯・合計").font(.caption).foregroundStyle(.secondary); Text("NT$ \(order.total)").font(.system(size: 26, weight: .semibold, design: .serif)).monospacedDigit() }
            Spacer()
            Button { requestOrder() } label: { HStack { Text("製作這杯茶"); Image(systemName: "arrow.right") }.font(.subheadline.bold()).padding(.horizontal, 23).padding(.vertical, 17).foregroundStyle(.white).background(ink, in: Capsule()) }
        }.padding(.horizontal, 24).padding(.vertical, 12).background(paper.shadow(color: .black.opacity(0.05), radius: 12, y: -5))
    }
    private var historySheet: some View {
        NavigationStack {
            List {
                if history.isEmpty { ContentUnavailableView("還沒有茶香紀錄", systemImage: "cup.and.saucer", description: Text("完成一筆模擬訂單，就會收藏在這裡。")) }
                ForEach(history) { receipt in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack { Text(receipt.tea).font(.headline); Spacer(); Text("$\(receipt.total)").bold() }
                        Text("\(receipt.name) · \(receipt.quantity) 杯 · \(receipt.recipe)").font(.subheadline)
                        if !receipt.additions.isEmpty { Text(receipt.additions).font(.caption) }
                        Text(receipt.pickup.formatted(date: .abbreviated, time: .shortened)).font(.caption).foregroundStyle(.secondary)
                        if !receipt.note.isEmpty { Text("備註：\(receipt.note)").font(.caption) }
                        if !receipt.reminderDays.isEmpty { Text("喝茶日：" + receipt.reminderDays.map { $0.formatted(date: .abbreviated, time: .omitted) }.joined(separator: "、")).font(.caption) }
                    }.padding(.vertical, 8)
                }
            }.navigationTitle("茶香紀錄").toolbar { ToolbarItem(placement: .confirmationAction) { Button("完成") { showHistory = false } } }
        }.tint(ink)
    }
    private func sectionTitle(_ number: String, _ title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 6) { Text(title).font(.headline); Text(detail).font(.caption).foregroundStyle(.secondary) }
    }
    private func summaryRow(_ name: String, _ value: String) -> some View { HStack(alignment: .top) { Text(name).foregroundStyle(.secondary); Spacer(); Text(value).multilineTextAlignment(.trailing) }.font(.subheadline) }
    private func nextButton(_ title: String, to next: Int) -> some View { Button { withAnimation { step = next } } label: { HStack { Text(title); Spacer(); Image(systemName: "arrow.right") }.font(.subheadline.bold()).padding(.vertical, 8) } }
    private var alertTitle: String {
        switch alert { case .invalid: "還差一點點"; case .confirm: "確認你的茶"; case .success: "茶香已收藏"; case .reset: "重新調一杯？"; case .photoError: "照片無法載入"; case nil: "" }
    }
    private func requestOrder() {
        if let error = order.validation() { message = error; alert = .invalid; step = 1; return }
        message = "\(order.name)的\(order.tea.rawValue)\n\(order.recipe) × \(order.quantity) 杯\n合計 NT$ \(order.total)\n此為模擬訂單，確認後儲存在此裝置。"
        alert = .confirm
    }
    private func saveOrder() {
        if let error = order.validation() { message = error; DispatchQueue.main.async { alert = .invalid }; return }
        history.insert(Receipt(order: order, days: days), at: 0)
        history = Array(history.prefix(30))
        savedReceipts = (try? JSONEncoder().encode(history)) ?? Data()
        message = "已儲存這筆模擬訂單！\n\(order.name)，\(order.pickup.formatted(date: .abbreviated, time: .shortened)) 記得享受一杯好茶。\n可在右上角查看最近 30 筆紀錄。"
        DispatchQueue.main.async { alert = .success }
    }
    private func loadPhoto() async {
        guard let item = selectedPhoto else { return }
        do {
            guard let data = try await item.loadTransferable(type: Data.self), let decoded = UIImage(data: data) else { throw CocoaError(.fileReadCorruptFile) }
            guard selectedPhoto == item else { return }
            let scale = min(1, 600 / max(decoded.size.width, decoded.size.height, 1))
            let size = CGSize(width: decoded.size.width * scale, height: decoded.size.height * scale)
            photo = UIGraphicsImageRenderer(size: size).image { _ in decoded.draw(in: CGRect(origin: .zero, size: size)) }
        } catch { guard selectedPhoto == item else { return }; message = "請選擇其他照片，或確認 iCloud 原始照片已下載。"; alert = .photoError }
    }
    #if DEBUG
    private func demo() async {
        func pause(_ seconds: Double) async { try? await Task.sleep(for: .seconds(seconds)) }
        let documents = URL.documentsDirectory
        func mark(_ value: String) { try? value.write(to: documents.appendingPathComponent("demo-phase.txt"), atomically: true, encoding: .utf8) }
        mark("ready")
        while !FileManager.default.fileExists(atPath: documents.appendingPathComponent("demo-go").path) {
            if Task.isCancelled { return }
            await pause(0.2)
        }
        await pause(4); order.tea = .jasmine; order.milk = true; order.sweetness = 50
        await pause(3); order.large = true; order.quantity = 2
        await pause(3); step = 1; order.name = "小茶"; order.note = "珍珠請分開裝"; days = [Calendar.current.dateComponents([.year, .month, .day], from: Date().addingTimeInterval(86400))]
        await pause(4); step = 2; labelColor = Color(red: 0.51, green: 0.30, blue: 0.22)
        await pause(4); requestOrder(); mark("confirmation")
        while !FileManager.default.fileExists(atPath: documents.appendingPathComponent("demo-confirm").path) {
            if Task.isCancelled { return }
            await pause(0.2)
        }
        await pause(2); alert = nil
        await pause(1); saveOrder()
        await pause(4); alert = nil; showHistory = true; mark("history")
    }
    #endif
}

#Preview { ContentView() }
