import Cocoa

extension NSImage {
    func resizedCopy(w: CGFloat, h: CGFloat) -> NSImage {
        let destSize = NSMakeSize(w, h)
        let newImage = NSImage(size: destSize)

        newImage.lockFocus()

        draw(in: NSRect(origin: .zero, size: destSize),
             from: NSRect(origin: .zero, size: size),
             operation: .copy,
             fraction: CGFloat(1))

        newImage.unlockFocus()

        guard let data = newImage.tiffRepresentation,
              let result = NSImage(data: data)
        else { return NSImage() }

        return result
    }
}
