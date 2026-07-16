#!/usr/bin/env swift

import AppKit
import Foundation

let output = URL(fileURLWithPath: CommandLine.arguments.dropFirst().first ?? ".build/assets", isDirectory: true)
let iconset = output.appendingPathComponent("AppIcon.iconset", isDirectory: true)
try FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)

func image(size: Int, draw: (NSRect) -> Void) throws -> Data {
    guard let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size, bitsPerSample: 8,
        samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
        bytesPerRow: 0, bitsPerPixel: 0
    ) else {
        throw NSError(domain: "JsonLens", code: 1)
    }
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
    draw(NSRect(x: 0, y: 0, width: size, height: size))
    NSGraphicsContext.restoreGraphicsState()
    return bitmap.representation(using: .png, properties: [:]) ?? Data()
}

func drawIcon(in rect: NSRect) {
    let size = rect.width
    NSColor.clear.setFill()
    rect.fill()
    let tile = rect.insetBy(dx: size * 0.07, dy: size * 0.07)
    NSColor(calibratedRed: 0.04, green: 0.38, blue: 0.70, alpha: 1).setFill()
    NSBezierPath(roundedRect: tile, xRadius: size * 0.21, yRadius: size * 0.21).fill()

    let attributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.monospacedSystemFont(ofSize: size * 0.50, weight: .bold),
        .foregroundColor: NSColor.white
    ]
    let text = "{}" as NSString
    let textSize = text.size(withAttributes: attributes)
    text.draw(
        at: NSPoint(x: rect.midX - textSize.width / 2, y: rect.midY - textSize.height / 2 - size * 0.035),
        withAttributes: attributes
    )
}

for (name, size) in [
    ("icon_16x16.png", 16), ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32), ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128), ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256), ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512), ("icon_512x512@2x.png", 1024)
] {
    try image(size: size, draw: drawIcon).write(to: iconset.appendingPathComponent(name))
}

let background = try image(size: 700) { _ in }
_ = background

let backgroundSize = NSSize(width: 700, height: 440)
guard let backgroundBitmap = NSBitmapImageRep(
    bitmapDataPlanes: nil, pixelsWide: Int(backgroundSize.width), pixelsHigh: Int(backgroundSize.height),
    bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
    bytesPerRow: 0, bitsPerPixel: 0
) else { throw NSError(domain: "JsonLens", code: 2) }
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: backgroundBitmap)
let canvas = NSRect(origin: .zero, size: backgroundSize)
NSColor(calibratedRed: 0.96, green: 0.98, blue: 1.0, alpha: 1).setFill()
canvas.fill()

let titleAttrs: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 25, weight: .bold),
    .foregroundColor: NSColor(calibratedRed: 0.04, green: 0.18, blue: 0.32, alpha: 1)
]
let title = "Json Lens" as NSString
let titleSize = title.size(withAttributes: titleAttrs)
title.draw(at: NSPoint(x: (canvas.width - titleSize.width) / 2, y: 380), withAttributes: titleAttrs)

let subAttrs: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 13, weight: .regular),
    .foregroundColor: NSColor(calibratedWhite: 0.35, alpha: 1)
]
let subtitle = "Drag Json Lens to Applications" as NSString
let subSize = subtitle.size(withAttributes: subAttrs)
subtitle.draw(at: NSPoint(x: (canvas.width - subSize.width) / 2, y: 352), withAttributes: subAttrs)

let line = NSBezierPath()
line.move(to: NSPoint(x: 285, y: 220))
line.line(to: NSPoint(x: 414, y: 220))
line.lineWidth = 3
NSColor(calibratedRed: 0.20, green: 0.55, blue: 0.82, alpha: 0.8).setStroke()
line.stroke()
let arrow = NSBezierPath()
arrow.move(to: NSPoint(x: 414, y: 220))
arrow.line(to: NSPoint(x: 398, y: 232))
arrow.move(to: NSPoint(x: 414, y: 220))
arrow.line(to: NSPoint(x: 398, y: 208))
arrow.lineWidth = 3
arrow.stroke()
NSGraphicsContext.restoreGraphicsState()
try backgroundBitmap.representation(using: .png, properties: [:])!.write(to: output.appendingPathComponent("Install.png"))
