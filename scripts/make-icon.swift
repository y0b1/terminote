import AppKit

guard CommandLine.arguments.count == 2 else { exit(1) }

let size = NSSize(width: 1024, height: 1024)
let image = NSImage(size: size)
image.lockFocus()

let accent = NSColor(calibratedRed: 70 / 255, green: 137 / 255, blue: 204 / 255, alpha: 1)
let iconRect = NSRect(origin: .zero, size: size).insetBy(dx: 48, dy: 48)
let iconShape = NSBezierPath(roundedRect: iconRect, xRadius: 210, yRadius: 210)
NSColor.black.setFill()
iconShape.fill()
accent.setStroke()
iconShape.lineWidth = 12
iconShape.stroke()

let symbolConfiguration = NSImage.SymbolConfiguration(pointSize: 500, weight: .medium)
    .applying(NSImage.SymbolConfiguration(paletteColors: [accent]))
let symbol = NSImage(
    systemSymbolName: "square.and.pencil",
    accessibilityDescription: "Terminote"
)!.withSymbolConfiguration(symbolConfiguration)!
let symbolSize = symbol.size
let opticalYOffset: CGFloat = 34
let symbolRect = NSRect(
    x: (size.width - symbolSize.width) / 2,
    y: (size.height - symbolSize.height) / 2 + opticalYOffset,
    width: symbolSize.width,
    height: symbolSize.height
)
symbol.draw(in: symbolRect, from: .zero, operation: .sourceOver, fraction: 1)

image.unlockFocus()

guard let tiff = image.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: tiff),
      let png = bitmap.representation(using: .png, properties: [:]) else { exit(1) }
try png.write(to: URL(fileURLWithPath: CommandLine.arguments[1]), options: .atomic)
