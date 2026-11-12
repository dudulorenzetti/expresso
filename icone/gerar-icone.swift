// Desenha o ícone do Expresso (1024 x 1024) e salva em PNG.
// É a mesma xícara cheia da barra de menus (CupIcon em main.swift), em branco sobre fundo café.
// Uso: swift gerar-icone.swift saida.png
import AppKit

let side = 1024
let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: side, pixelsHigh: side,
                           bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                           colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
rep.size = NSSize(width: side, height: side)
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

// Fundo padrão de ícone do macOS: quadrado arredondado de 824 no meio da tela de 1024, com sombra leve.
let plate = NSBezierPath(roundedRect: NSRect(x: 100, y: 100, width: 824, height: 824), xRadius: 185, yRadius: 185)
NSGraphicsContext.saveGraphicsState()
let shadow = NSShadow()
shadow.shadowColor = NSColor.black.withAlphaComponent(0.3)
shadow.shadowOffset = NSSize(width: 0, height: -10)
shadow.shadowBlurRadius = 20
shadow.set()
NSColor(srgbRed: 0.36, green: 0.22, blue: 0.14, alpha: 1).setFill()
plate.fill()
NSGraphicsContext.restoreGraphicsState()
NSGradient(starting: NSColor(srgbRed: 0.55, green: 0.36, blue: 0.24, alpha: 1),
           ending: NSColor(srgbRed: 0.27, green: 0.16, blue: 0.10, alpha: 1))!.draw(in: plate, angle: -90)

// A xícara usa as mesmas medidas do ícone da barra (grade de 18 x 18), ampliadas e centralizadas.
let scale: CGFloat = 36
let t = NSAffineTransform()
t.translateX(by: 512 - 8.425 * scale, yBy: 512 - 9.35 * scale)
t.scale(by: scale)
t.concat()
NSColor.white.set()
let bottom: CGFloat = 3.5, top: CGFloat = 11.5

let body = NSBezierPath()
body.move(to: NSPoint(x: 2.5, y: top))
body.line(to: NSPoint(x: 2.5, y: 7.5))
body.curve(to: NSPoint(x: 6.5, y: bottom), controlPoint1: NSPoint(x: 2.5, y: 5.3), controlPoint2: NSPoint(x: 4.3, y: bottom))
body.line(to: NSPoint(x: 8.5, y: bottom))
body.curve(to: NSPoint(x: 12.5, y: 7.5), controlPoint1: NSPoint(x: 10.7, y: bottom), controlPoint2: NSPoint(x: 12.5, y: 5.3))
body.line(to: NSPoint(x: 12.5, y: top))
body.close()
body.lineWidth = 1.3
body.lineJoinStyle = .round
body.fill()      // xícara cheia
body.stroke()

let handle = NSBezierPath()
handle.move(to: NSPoint(x: 12.5, y: 10.3))
handle.curve(to: NSPoint(x: 12.5, y: 5.9), controlPoint1: NSPoint(x: 16.3, y: 10.3), controlPoint2: NSPoint(x: 16.3, y: 5.9))
handle.lineWidth = 1.3
handle.stroke()

let saucer = NSBezierPath()
saucer.move(to: NSPoint(x: 1.5, y: 1.4))
saucer.line(to: NSPoint(x: 13.5, y: 1.4))
saucer.lineWidth = 1.3
saucer.lineCapStyle = .round
saucer.stroke()

for x in [5.0, 10.0] as [CGFloat] {   // fumaça
    let w = NSBezierPath()
    w.move(to: NSPoint(x: x, y: 13.3))
    w.curve(to: NSPoint(x: x, y: 17.3), controlPoint1: NSPoint(x: x + 1.8, y: 14.6), controlPoint2: NSPoint(x: x - 1.8, y: 16.0))
    w.lineWidth = 1.2
    w.lineCapStyle = .round
    w.stroke()
}

NSGraphicsContext.current?.flushGraphics()
let out = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "Expresso-1024.png"
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: out))
print("Salvo: \(out)")
