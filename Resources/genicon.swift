#!/usr/bin/env swift

import Foundation
import AppKit

// ──────────────────────────────────────────────
//  Macopy App Icon Generator v2 (1024×1024)
//  Modern, vibrant, glass-effect clipboard
// ──────────────────────────────────────────────

func drawIcon() -> NSImage? {
    let w: CGFloat = 1024
    let h: CGFloat = 1024

    let img = NSImage(size: NSSize(width: w, height: h), flipped: false) { rect in
        guard let ctx = NSGraphicsContext.current?.cgContext else { return false }
        ctx.setShouldAntialias(true)
        ctx.setAllowsAntialiasing(true)
        ctx.interpolationQuality = .high

        // ── Rounded background mask ──
        let bgRect = CGRect(x: 40, y: 40, width: 944, height: 944)
        let bgRadius: CGFloat = 220
        let bgClip = CGPath(roundedRect: bgRect, cornerWidth: bgRadius, cornerHeight: bgRadius, transform: nil)
        ctx.addPath(bgClip)
        ctx.clip()

        // ── Deep gradient background ──
        let gradient = CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceRGB(),
            colors: [
                CGColor(red: 0.28, green: 0.08, blue: 0.58, alpha: 1),   // deep indigo
                CGColor(red: 0.30, green: 0.12, blue: 0.78, alpha: 1),   // rich purple
                CGColor(red: 0.15, green: 0.38, blue: 0.92, alpha: 1),   // vivid blue
                CGColor(red: 0.00, green: 0.65, blue: 0.88, alpha: 1),   // bright teal
                CGColor(red: 0.08, green: 0.82, blue: 0.72, alpha: 1),   // emerald accent
            ] as CFArray,
            locations: [0, 0.25, 0.55, 0.82, 1]
        )
        ctx.drawLinearGradient(
            gradient!,
            start: CGPoint(x: bgRect.minX + 100, y: bgRect.maxY - 100),
            end: CGPoint(x: bgRect.maxX - 100, y: bgRect.minY + 100),
            options: []
        )

        // ── Ambient glow (top-left) ──
        let glowColor = CGColor(red: 0.6, green: 0.4, blue: 1.0, alpha: 0.18)
        ctx.setFillColor(glowColor)
        let glowRect = CGRect(x: -200, y: h - 400, width: 700, height: 700)
        ctx.fillEllipse(in: glowRect)

        // ── Secondary glow (bottom-right) ──
        let glow2 = CGColor(red: 0.0, green: 0.9, blue: 0.8, alpha: 0.12)
        ctx.setFillColor(glow2)
        let glow2Rect = CGRect(x: w - 500, y: -150, width: 700, height: 700)
        ctx.fillEllipse(in: glow2Rect)

        // ── Clipboard body ──
        let clipW: CGFloat = 380
        let clipH: CGFloat = 470
        let clipX = (w - clipW) / 2
        let clipY = (h - clipH) / 2 - 10

        // Shadow behind clipboard
        let shadowColor = CGColor(red: 0, green: 0, blue: 0, alpha: 0.35)
        ctx.setShadow(offset: CGSize(width: 0, height: -12), blur: 40, color: shadowColor)

        let bodyRect = CGRect(x: clipX, y: clipY, width: clipW, height: clipH)
        let bodyRadius: CGFloat = 40
        let bodyPath = CGPath(roundedRect: bodyRect, cornerWidth: bodyRadius, cornerHeight: bodyRadius, transform: nil)
        ctx.addPath(bodyPath)
        ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.97))
        ctx.fillPath()

        // Reset shadow
        ctx.setShadow(offset: .zero, blur: 0, color: CGColor(red: 0, green: 0, blue: 0, alpha: 0))

        // ── Clipboard glass overlay (top half) ──
        let glassPath = CGMutablePath()
        glassPath.move(to: CGPoint(x: clipX + bodyRadius, y: clipY + clipH))
        glassPath.addLine(to: CGPoint(x: clipX, y: clipY + clipH - 20))
        glassPath.addLine(to: CGPoint(x: clipX, y: clipY + clipH * 0.5))
        glassPath.addLine(to: CGPoint(x: clipX + clipW, y: clipY + clipH * 0.5))
        glassPath.addLine(to: CGPoint(x: clipX + clipW, y: clipY + clipH - 20))
        glassPath.addLine(to: CGPoint(x: clipX + clipW - bodyRadius, y: clipY + clipH))
        glassPath.closeSubpath()
        ctx.addPath(glassPath)
        ctx.setFillColor(CGColor(red: 0.96, green: 0.97, blue: 1.0, alpha: 0.15))
        ctx.fillPath()

        // ── Clip mechanism (metallic) ──
        // Clip body
        let clipMechW: CGFloat = 110
        let clipMechH: CGFloat = 36
        let clipMechX = (w - clipMechW) / 2
        let clipMechY = clipY + clipH - 2

        let clipMechPath = CGPath(roundedRect: CGRect(x: clipMechX, y: clipMechY, width: clipMechW, height: clipMechH),
                                   cornerWidth: 14, cornerHeight: 14, transform: nil)
        ctx.addPath(clipMechPath)
        let clipMechGrad = CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceRGB(),
            colors: [
                CGColor(red: 0.82, green: 0.83, blue: 0.88, alpha: 1),
                CGColor(red: 0.92, green: 0.93, blue: 0.96, alpha: 1),
                CGColor(red: 0.78, green: 0.79, blue: 0.84, alpha: 1),
            ] as CFArray,
            locations: [0, 0.5, 1]
        )
        ctx.drawLinearGradient(
            clipMechGrad!,
            start: CGPoint(x: clipMechX, y: clipMechY),
            end: CGPoint(x: clipMechX + clipMechW, y: clipMechY),
            options: []
        )

        // Clip top circle (metallic)
        let circR: CGFloat = 32
        let circRect = CGRect(x: (w - circR * 2) / 2, y: clipMechY + clipMechH - 4, width: circR * 2, height: circR * 2)
        let circGrad = CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceRGB(),
            colors: [
                CGColor(red: 0.85, green: 0.86, blue: 0.90, alpha: 1),
                CGColor(red: 0.95, green: 0.96, blue: 0.98, alpha: 1),
                CGColor(red: 0.80, green: 0.81, blue: 0.86, alpha: 1),
            ] as CFArray,
            locations: [0, 0.4, 1]
        )
        ctx.saveGState()
        ctx.addEllipse(in: circRect)
        ctx.clip()
        ctx.drawLinearGradient(circGrad!, start: circRect.origin, end: CGPoint(x: circRect.maxX, y: circRect.maxY), options: [])
        ctx.restoreGState()

        // Clip inner circle (dark)
        let innerR: CGFloat = 12
        let innerRect = CGRect(x: (w - innerR * 2) / 2, y: circRect.midY - innerR + 4, width: innerR * 2, height: innerR * 2)
        ctx.addEllipse(in: innerRect)
        ctx.setFillColor(CGColor(red: 0.55, green: 0.56, blue: 0.62, alpha: 1))
        ctx.fillPath()

        // ── Paper sheet (on clipboard) ──
        let paperInset: CGFloat = 36
        let paperRect = CGRect(x: clipX + paperInset, y: clipY + paperInset, width: clipW - paperInset * 2, height: clipH - paperInset * 2 - 20)
        let paperPath = CGPath(roundedRect: paperRect, cornerWidth: 24, cornerHeight: 24, transform: nil)
        ctx.addPath(paperPath)
        ctx.setFillColor(CGColor(red: 0.97, green: 0.975, blue: 0.99, alpha: 0.5))
        ctx.fillPath()

        // ── Text lines on paper ──
        let lineColors: [(CGFloat, CGFloat, CGFloat)] = [
            (0.20, 0.78, 0.35),  // green
            (0.27, 0.51, 0.93),  // blue
            (0.90, 0.30, 0.36),  // red
            (0.90, 0.58, 0.14),  // orange
            (0.55, 0.30, 0.90),  // purple
            (0.20, 0.78, 0.35),  // green again
        ]

        let lineX: CGFloat = clipX + paperInset + 30
        let lineYStart: CGFloat = clipY + clipH - paperInset - 50
        let lineSpacing: CGFloat = 38

        for (i, (r, g, b)) in lineColors.enumerated() {
            let y = lineYStart - CGFloat(i) * lineSpacing
            let widths: [CGFloat] = [0.82, 0.65, 0.74, 0.52, 0.68, 0.58]
            let lineW = (clipW - paperInset * 2 - 60) * widths[i]

            ctx.setFillColor(CGColor(red: r, green: g, blue: b, alpha: 0.7))
            let lr = CGRect(x: lineX, y: y, width: lineW, height: 9)
            let lp = CGPath(roundedRect: lr, cornerWidth: 4, cornerHeight: 4, transform: nil)
            ctx.addPath(lp)
            ctx.fillPath()
        }

        // ── Small checkmark icon (bottom-right corner of paper) ──
        let checkX = clipX + clipW - paperInset - 40
        let checkY = clipY + paperInset + 20
        let checkSize: CGFloat = 24
        ctx.setStrokeColor(CGColor(red: 0.20, green: 0.78, blue: 0.35, alpha: 0.8))
        ctx.setLineWidth(3.5)
        ctx.setLineCap(.round)
        ctx.setLineJoin(.round)
        ctx.move(to: CGPoint(x: checkX - checkSize * 0.25, y: checkY))
        ctx.addLine(to: CGPoint(x: checkX, y: checkY - checkSize * 0.25))
        ctx.addLine(to: CGPoint(x: checkX + checkSize * 0.45, y: checkY + checkSize * 0.3))
        ctx.strokePath()

        // ── Subtle highlight on clipboard edge ──
        ctx.setStrokeColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.25))
        ctx.setLineWidth(2)
        let highlightPath = CGMutablePath()
        highlightPath.move(to: CGPoint(x: clipX + bodyRadius, y: clipY + clipH - 1))
        highlightPath.addLine(to: CGPoint(x: clipX + 8, y: clipY + clipH * 0.3))
        ctx.addPath(highlightPath)
        ctx.strokePath()

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
