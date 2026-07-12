import Foundation
import AppKit
import CoreImage

/// Preprocesses images for LLM API requests
public class ImagePreprocessor {
    private static let maxDimension: CGFloat = 2048
    private static let jpegQuality: CGFloat = 0.85
    private static let targetMaxSize: Int = 2_097_152 // 2MB

    /// Preprocess image for LLM request
    /// - Parameter image: The image to preprocess
    /// - Returns: JPEG data optimized for transfer
    public func preprocess(_ image: NSImage) throws -> Data {
        // Convert NSImage to CGImage
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw LLMError.imageProcessingFailed
        }

        // Resize if needed
        let resizedImage = resizeIfNeeded(cgImage)

        // Convert to JPEG with quality
        guard let data = convertToJPEG(resizedImage, quality: Self.jpegQuality) else {
            throw LLMError.imageProcessingFailed
        }

        // If still too large, reduce quality incrementally
        if data.count > Self.targetMaxSize {
            return try reduceSize(resizedImage, targetSize: Self.targetMaxSize)
        }

        return data
    }

    private func resizeIfNeeded(_ image: CGImage) -> CGImage {
        let width = image.width
        let height = image.height
        let maxDim = max(width, height)

        // No resize needed
        if CGFloat(maxDim) <= Self.maxDimension {
            return image
        }

        // Calculate new dimensions
        let scale = Self.maxDimension / CGFloat(maxDim)
        let newWidth = Int(CGFloat(width) * scale)
        let newHeight = Int(CGFloat(height) * scale)

        // Create context and resize
        guard let context = CGContext(
            data: nil,
            width: newWidth,
            height: newHeight,
            bitsPerComponent: image.bitsPerComponent,
            bytesPerRow: 0,
            space: image.colorSpace ?? CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: image.bitmapInfo.rawValue
        ) else {
            return image
        }

        context.interpolationQuality = .high
        context.draw(image, in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))

        return context.makeImage() ?? image
    }

    private func convertToJPEG(_ image: CGImage, quality: CGFloat) -> Data? {
        let nsImage = NSImage(cgImage: image, size: NSSize(width: image.width, height: image.height))
        guard let tiffData = nsImage.tiffRepresentation,
              let bitmapImage = NSBitmapImageRep(data: tiffData) else {
            return nil
        }

        return bitmapImage.representation(
            using: .jpeg,
            properties: [.compressionFactor: quality]
        )
    }

    private func reduceSize(_ image: CGImage, targetSize: Int) throws -> Data {
        var workingImage = image

        while max(workingImage.width, workingImage.height) >= 256 {
            var quality: CGFloat = 0.8
            while quality >= 0.3 {
                if let data = convertToJPEG(workingImage, quality: quality), data.count <= targetSize {
                    return data
                }
                quality -= 0.1
            }

            guard let smallerImage = resize(workingImage, scale: 0.8) else { break }
            workingImage = smallerImage
        }

        throw LLMError.imageProcessingFailed
    }

    private func resize(_ image: CGImage, scale: CGFloat) -> CGImage? {
        let width = max(1, Int(CGFloat(image.width) * scale))
        let height = max(1, Int(CGFloat(image.height) * scale))
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return nil
        }
        context.interpolationQuality = .high
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        return context.makeImage()
    }

    /// Convert image data to base64 string
    /// - Parameter data: Image data
    /// - Returns: Base64 encoded string
    public func toBase64(_ data: Data) -> String {
        return data.base64EncodedString()
    }
}
