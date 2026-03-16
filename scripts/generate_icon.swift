#!/usr/bin/env swift

import AppKit
import Foundation

let size = 1024
let rect = CGRect(x: 0, y: 0, width: size, height: size)

guard let context = CGContext(
    data: nil, width: size, height: size,
    bitsPerComponent: 8, bytesPerRow: 0,
    space: CGColorSpaceCreateDeviceRGB(),
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
) else {
    fputs("Failed to create context\n", stderr)
    exit(1)
}

// White background
context.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
context.fill(rect)

// Draw emoji
let nsContext = NSGraphicsContext(cgContext: context, flipped: false)
NSGraphicsContext.current = nsContext

let emoji = "🎯" as NSString
let fontSize: CGFloat = 680
let font = NSFont.systemFont(ofSize: fontSize)
let attrs: [NSAttributedString.Key: Any] = [.font: font]
let emojiSize = emoji.size(withAttributes: attrs)
let x = (CGFloat(size) - emojiSize.width) / 2
let y = (CGFloat(size) - emojiSize.height) / 2
emoji.draw(at: NSPoint(x: x, y: y), withAttributes: attrs)

NSGraphicsContext.current = nil

guard let image = context.makeImage() else {
    fputs("Failed to create image\n", stderr)
    exit(1)
}

let outputPath = URL(fileURLWithPath: #filePath)
    .deletingLastPathComponent()
    .deletingLastPathComponent()
    .appendingPathComponent("Assets.xcassets/AppIcon.appiconset/icon_1024.png")

let dest = CGImageDestinationCreateWithURL(outputPath as CFURL, "public.png" as CFString, 1, nil)!
CGImageDestinationAddImage(dest, image, nil)
CGImageDestinationFinalize(dest)

print("Icon generated at \(outputPath.path)")
