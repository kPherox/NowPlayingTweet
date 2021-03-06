/**
 *  NSImage++.swift
 *  NowPlayingTweet
 *
 *  © 2018 kPherox.
**/

import Cocoa

extension NSImage {

    convenience init?(named name: NSImage.Name, templated: Bool) {
        self.init(named: name)
        self.isTemplate = templated
    }

    convenience init?(data: Data, templated: Bool) {
        self.init(data: data)
        self.isTemplate = templated
    }

    convenience init(size: NSSize, templated: Bool) {
        self.init(size: size)
        self.isTemplate = templated
    }

}

extension NSImage {

    func toRoundCorners(width: CGFloat = 48, height: CGFloat = 48) -> NSImage {
        let xRad = width / 2
        let yRad = height / 2
        let image: NSImage = self
        let imageSize: NSSize = image.size
        let newSize = NSMakeSize(imageSize.width, imageSize.height)
        let composedImage = NSImage(size: newSize, templated: self.isTemplate)

        composedImage.lockFocus()
        let ctx = NSGraphicsContext.current
        ctx?.imageInterpolation = NSImageInterpolation.high

        let imageFrame = NSRect(x: 0, y: 0, width: width, height: height)
        let clipPath = NSBezierPath(roundedRect: imageFrame, xRadius: xRad, yRadius: yRad)
        clipPath.windingRule = .evenOdd
        clipPath.addClip()

        let rect = NSRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        image.draw(at: .zero, from: rect, operation: .sourceOver, fraction: 1)
        composedImage.unlockFocus()

        return composedImage
    }

}
