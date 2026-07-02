#!/usr/bin/env swift

import Foundation
import AppKit

// ──────────────────────────────────────────────
//  Macopy App Icon Generator (1024×1024)
// ──────────────────────────────────────────────

func clippedRect(_ r: CGRect, radius: CGFloat) -> CGPath {
    CGPath(roundedRect: r, cornerWidth: radius, cornerHeight: radius, transform: nil)
}

func drawIcon() -> NSImage? {
    let w: CGFloat = 1024
    let h: CGFloat = 1024
    let scale: CGFloat = 1

    let img = NSImage(size: NSSize(width: w, height: h), flipped: false) { rect in
        guard let ctx = NSGraphicsContext.current?.cgContext else { return false }
        ctx.setShouldAntialias(true)
        ctx.setAllowsAntialiasing(true)
        ctx.interpolationQuality = .high

        // ── Background ──
        let bgRect = CGRect(x: 80, y: 80, width: 864, height: 864)
        let bgClip = clippedRect(bgRect, radius: 192)
        ctx.addPath(bgClip)
        ctx.clip()

        // Gradient
        let gradient = CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceRGB(),
            colors: [
                CGColor(red: 0.41, green: 0.15, blue: 0.92, alpha: 1),   // purple
                CGColor(red: 0.22, green: 0.34, blue: 0.95, alpha: 1),   // blue
                CGColor(red: 0.00, green: 0.71, blue: 0.94, alpha: 1),   // cyan
            ] as CFArray,
            locations: [0, 0.55, 1]
        )
        ctx.drawLinearGradient(
            gradient!,
            start: CGPoint(x: bgRect.midX - 400, y: bgRect.midY + 400),
            end:   CGPoint(x: bgRect.midX + 400, y: bgRect.midY - 400),
            options: []
        )

        // Subtle inner shine
        ctx.setFillColor(red: 1, green: 1, blue: 1, alpha: 0.06)
        let shine = CGMutablePath()
        shine.addArc(center: CGPoint(x: bgRect.midX - 60, y: bgRect.midY + 240),
                     radius: 520, startAngle: 0, endAngle: .pi * 2, clockwise: false)
        ctx.addPath(shine)
        ctx.fillPath()

        // ── Clipboard Body ──
        let clipW: CGFloat = 340
        let clipH: CGFloat = 430
        let clipX = (w - clipW) / 2
        let clipY = (h - clipH) / 2 - 20

        let bodyRect = CGRect(x: clipX, y: clipY, width: clipW, height: clipH)
        let bodyPath = clippedRect(bodyRect, radius: 52)
        ctx.addPath(bodyPath)
        ctx.setFillColor(red: 1, green: 1, blue: 1, alpha: 0.95)
        ctx.fillPath()

        // Clipboard border
        ctx.addPath(bodyPath)
        ctx.setStrokeColor(red: 1, green: 1, blue: 1, alpha: 1)
        ctx.setLineWidth(0)
        ctx.drawPath(using: .fillStroke)

        // ── Clip Spring (top) ──
        let springW: CGFloat = 100
        let springH: CGFloat = 30
        let springX = (w - springW) / 2
        let springY = clipY + clipH + 4
        let springRect = CGRect(x: springX, y: springY, width: springW, height: springH)
        let springPath = clippedRect(springRect, radius: 12)
        ctx.addPath(springPath)
        ctx.setFillColor(red: 0.90, green: 0.91, blue: 0.94, alpha: 1)
        ctx.fillPath()

        // ── Clip Top Circle ──
        let circleR: CGFloat = 28
        let circleRect = CGRect(
            x: (w - circleR * 2) / 2,
            y: springY + springH + 2,
            width: circleR * 2,
            height: circleR * 2
        )
        ctx.addEllipse(in: circleRect)
        ctx.setFillColor(red: 0.85, green: 0.86, blue: 0.90, alpha: 1)
        ctx.fillPath()

        // ── Paper Lines (text history) ──
        let lineColors: [(CGFloat, CGFloat, CGFloat)] = [
            (0.90, 0.30, 0.36),  // red
            (0.27, 0.51, 0.93),  // blue
            (0.20, 0.78, 0.35),  // green
            (0.90, 0.58, 0.14),  // orange
            (0.55, 0.30, 0.90),  // purple
        ]

        let lineStartX: CGFloat = clipX + 44
        let lineEndXVariations: [CGFloat] = [0.72, 0.55, 0.82, 0.45, 0.65]
        let lineYStart: CGFloat = clipY + clipH - 60
        let lineSpacing: CGFloat = 44

        for (i, (r, g, b)) in lineColors.enumerated() {
            let endX = lineStartX + clipW * lineEndXVariations[i] * 0.65
            let y = lineYStart - CGFloat(i) * lineSpacing

            ctx.setFillColor(red: r, green: g, blue: b, alpha: 0.65)
            let lineRect = CGRect(x: lineStartX, y: y, width: endX - lineStartX, height: 8)
            let linePath = CGPath(roundedRect: lineRect, cornerWidth: 4, cornerHeight: 4, transform: nil)
            ctx.addPath(linePath)
            ctx.fillPath()
        }

        // ── Subtle shadow under clipboard ──
        ctx.setFillColor(red: 0, green: 0, blue: 0, alpha: 0.06)
        let shadowRect = CGRect(x: clipX + 10, y: clipY - 12, width: clipW - 20, height: 16)
        let shadowPath = CGPath(roundedRect: shadowRect, cornerWidth: 8, cornerHeight: 8, transform: nil)
        ctx.addPath(shadowPath)
        ctx.fillPath()

        return true
    }

    return img
}

// ── Save ──
guard let icon = drawIcon(),
      let cgImage = icon.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
    fputs("ERROR: Could not generate icon\n", stderr)
    exit(1)
}

let outputPath = CommandLine.arguments.count > 1
    ? CommandLine.arguments[1]
    : "icon_1024.png"

let rep = NSBitmapImageRep(cgImage: cgImage)
rep.size = NSSize(width: 1024, height: 1024)
guard let pngData = rep.representation(using: .png, properties: [.compressionFactor: 1.0]) else {
    fputs("ERROR: Could not create PNG\n", stderr)
    exit(1)
}

try pngData.write(to: URL(fileURLWithPath: outputPath))
print("✅ Icon saved: \(outputPath) (\(pngData.count) bytes)")
