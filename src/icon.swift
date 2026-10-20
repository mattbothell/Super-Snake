import Cocoa

// Draws the 1024x1024 app icon: dark rounded tile, green block snake, red apple.
let size = 1024
let out = CommandLine.arguments[1]

let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size,
                           bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                           colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

let inset: CGFloat = 100
let tile = NSRect(x: inset, y: inset, width: CGFloat(size) - inset * 2, height: CGFloat(size) - inset * 2)
NSColor(red: 0x0b/255, green: 0x0d/255, blue: 0x10/255, alpha: 1).setFill()
NSBezierPath(roundedRect: tile, xRadius: 185, yRadius: 185).fill()

// 8x8 grid inside the tile; rows counted from the top.
let grid = 8, cell = tile.width / CGFloat(grid), gap: CGFloat = 8
func block(_ col: Int, _ row: Int, _ color: NSColor) {
    color.setFill()
    let r = NSRect(x: tile.minX + CGFloat(col) * cell + gap,
                   y: tile.maxY - CGFloat(row + 1) * cell + gap,
                   width: cell - gap * 2, height: cell - gap * 2)
    NSBezierPath(roundedRect: r, xRadius: 10, yRadius: 10).fill()
}
let green = NSColor(red: 0x6d/255, green: 0xdb/255, blue: 0x4c/255, alpha: 1)
let snake = [(1,2),(2,2),(3,2),(4,2),(5,2),(6,2),(6,3),(6,4),(5,4),(4,4),(3,4),(2,4),(1,4),(1,5),(1,6),(2,6),(3,6)]
for (c, r) in snake { block(c, r, green) }
block(5, 6, NSColor(red: 0xe8/255, green: 0x3a/255, blue: 0x3a/255, alpha: 1))

NSGraphicsContext.current = nil
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: out))
