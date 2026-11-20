var checks = 0
for tea in Tea.allCases {
    for large in [false, true] {
        for pearls in [false, true] {
            for milk in [false, true] {
                for ownCup in [false, true] {
                    for quantity in 1...12 {
                        var order = TeaOrder()
                        order.tea = tea; order.large = large; order.pearls = pearls; order.milk = milk; order.ownCup = ownCup; order.quantity = quantity
                        let expected = tea.price + (large ? 10 : 0) + (pearls ? 10 : 0) + (milk ? 15 : 0) - (ownCup ? 5 : 0)
                        precondition(order.total == expected * quantity)
                        checks += 1
                    }
                }
            }
        }
    }
}
var order = TeaOrder()
precondition(order.validation() != nil)
order.name = "  \n "
precondition(order.validation() != nil)
order.name = "小茶"
precondition(order.validation() == nil)
order.pickup = Date().addingTimeInterval(-60)
precondition(order.validation() != nil)
order.pickup = Date().addingTimeInterval(1800)
let receipt = Receipt(order: order, days: [Calendar.current.dateComponents([.year, .month, .day], from: Date())])
let data = try JSONEncoder().encode([receipt])
let loaded = try JSONDecoder().decode([Receipt].self, from: data)
precondition(loaded.first?.total == order.total && loaded.first?.reminderDays.count == 1 && loaded.first?.id == receipt.id)
print("PASS: \(checks) pricing combinations, required name, expired pickup, receipt persistence encoding")
