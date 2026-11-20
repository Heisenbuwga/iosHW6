import SwiftUI

struct CupShape: Shape {
    func path(in r: CGRect) -> Path {
        Path { p in
            p.move(to: CGPoint(x: r.width * 0.08, y: 0))
            p.addLine(to: CGPoint(x: r.width * 0.92, y: 0))
            p.addLine(to: CGPoint(x: r.width * 0.79, y: r.height * 0.94))
            p.addQuadCurve(to: CGPoint(x: r.width * 0.21, y: r.height * 0.94), control: CGPoint(x: r.width * 0.5, y: r.height * 1.05))
            p.closeSubpath()
        }
    }
}
struct TeaCupView: View {
    let order: TeaOrder
    let labelColor: Color
    let photo: UIImage?
    var body: some View {
        ZStack {
            Ellipse().fill(.black.opacity(0.10)).frame(width: 155, height: 20).offset(y: 111)
            RoundedRectangle(cornerRadius: 4).fill(Color(red: 0.36, green: 0.27, blue: 0.18)).frame(width: 12, height: 100).rotationEffect(.degrees(12)).offset(x: 29, y: -91)
            CupShape().fill(LinearGradient(colors: liquidColors, startPoint: .topLeading, endPoint: .bottomTrailing)).frame(width: 182, height: 206)
                .overlay {
                    ZStack {
                        if order.ice != "去冰" {
                            HStack(spacing: 8) { ForEach(0..<3) { n in RoundedRectangle(cornerRadius: 5).fill(.white.opacity(0.32)).frame(width: 27, height: 25).rotationEffect(.degrees(Double(n * 17 - 15))) } }.offset(y: -62)
                        }
                        if order.pearls {
                            ForEach(0..<15) { n in
                                Circle().fill(Color(red: 0.22, green: 0.15, blue: 0.12)).frame(width: 12, height: 12)
                                    .offset(x: CGFloat(n % 5 - 2) * 23 + CGFloat(n / 5 % 2) * 5, y: 62 + CGFloat(n / 5) * 13)
                            }
                        }
                        RoundedRectangle(cornerRadius: 2).fill(labelColor).frame(width: 155, height: 76)
                        if let photo { Image(uiImage: photo).resizable().scaledToFill().frame(width: 58, height: 58).clipShape(Circle()) }
                        else { VStack(spacing: 1) { Text("茶 序").font(.system(size: 26, weight: .medium, design: .serif)); Text("TEA ATELIER").font(.system(size: 8, weight: .semibold)).tracking(2) }.foregroundStyle(.white).shadow(color: .black.opacity(0.5), radius: 2) }
                    }
                }
            Capsule().fill(Color(red: 0.95, green: 0.91, blue: 0.81)).frame(width: 170, height: 12).offset(y: -103)
        }.frame(height: 268)
        .accessibilityElement(children: .ignore).accessibilityLabel("\(order.tea.rawValue)杯身預覽，\(order.recipe)")
    }
    var liquidColors: [Color] {
        if order.milk { return [Color(red: 0.85, green: 0.72, blue: 0.51), Color(red: 0.63, green: 0.43, blue: 0.26)] }
        if order.tea == .jasmine { return [Color(red: 0.77, green: 0.81, blue: 0.40), Color(red: 0.45, green: 0.53, blue: 0.20)] }
        return [Color(red: 0.87, green: 0.60, blue: 0.27), Color(red: 0.49, green: 0.26, blue: 0.12)]
    }
}
