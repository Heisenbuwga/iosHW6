import Foundation

enum Tea: String, CaseIterable, Identifiable, Codable {
    case oolong = "焙香烏龍", jasmine = "茉莉綠茶", black = "日月潭紅茶"
    var id: String { rawValue }
    var price: Int { self == .oolong ? 55 : self == .jasmine ? 50 : 60 }
    var subtitle: String { self == .oolong ? "ROASTED OOLONG" : self == .jasmine ? "JASMINE GREEN" : "RUBY BLACK TEA" }
}

struct TeaOrder {
    var tea: Tea = .oolong
    var large = false
    var sweetness = 30.0
    var ice = "微冰"
    var pearls = true
    var milk = false
    var ownCup = false
    var quantity = 1
    var name = ""
    var note = ""
    var pickup = Date().addingTimeInterval(1800)
    var unitPrice: Int { tea.price + (large ? 10 : 0) + (pearls ? 10 : 0) + (milk ? 15 : 0) - (ownCup ? 5 : 0) }
    var total: Int { unitPrice * quantity }
    var recipe: String { "\(large ? "大杯" : "中杯") · \(Int(sweetness))% 糖 · \(ice)" }
    func validation(now: Date = Date()) -> String? {
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return "請填寫取餐姓名，讓我們知道這杯茶屬於誰。" }
        if pickup < now { return "取餐時間已經過了，請重新選擇未來的時間。" }
        return nil
    }
}

struct Receipt: Identifiable, Codable {
    var id = UUID()
    let name: String
    let tea: String
    let recipe: String
    let additions: String
    let quantity: Int
    let total: Int
    let pickup: Date
    let note: String
    let reminderDays: [Date]
    init(order: TeaOrder, days: Set<DateComponents>) {
        name = order.name.trimmingCharacters(in: .whitespacesAndNewlines)
        tea = order.tea.rawValue
        recipe = order.recipe
        additions = [order.pearls ? "珍珠" : nil, order.milk ? "鮮奶" : nil, order.ownCup ? "自備杯折 $5／杯" : nil].compactMap { $0 }.joined(separator: " · ")
        quantity = order.quantity; total = order.total; pickup = order.pickup; note = order.note
        reminderDays = days.compactMap { Calendar.current.date(from: $0) }.sorted()
    }
}
