import AppKit
let image = NSImage(size: NSSize(width: 1024, height: 1024))
image.lockFocus()
NSColor(red: 0.17, green: 0.23, blue: 0.18, alpha: 1).setFill()
NSBezierPath(rect: NSRect(x: 0, y: 0, width: 1024, height: 1024)).fill()
NSColor(red: 0.84, green: 0.68, blue: 0.40, alpha: 1).setFill()
let cup = NSBezierPath()
cup.move(to: NSPoint(x: 270, y: 710)); cup.line(to: NSPoint(x: 754, y: 710)); cup.line(to: NSPoint(x: 690, y: 230)); cup.curve(to: NSPoint(x: 334, y: 230), controlPoint1: NSPoint(x: 600, y: 200), controlPoint2: NSPoint(x: 400, y: 200)); cup.close(); cup.fill()
NSColor(red: 0.95, green: 0.91, blue: 0.81, alpha: 1).setFill()
NSBezierPath(roundedRect: NSRect(x: 255, y: 700, width: 514, height: 34), xRadius: 17, yRadius: 17).fill()
NSBezierPath(roundedRect: NSRect(x: 580, y: 720, width: 25, height: 145), xRadius: 10, yRadius: 10).fill()
NSColor(red: 0.22, green: 0.30, blue: 0.23, alpha: 1).setFill()
NSBezierPath(rect: NSRect(x: 310, y: 370, width: 404, height: 210)).fill()
let attrs: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: 115, weight: .medium), .foregroundColor: NSColor.white]
let text = "茶序" as NSString
text.draw(at: NSPoint(x: 397, y: 405), withAttributes: attrs)
image.unlockFocus()
let bitmap = NSBitmapImageRep(data: image.tiffRepresentation!)!
try bitmap.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
