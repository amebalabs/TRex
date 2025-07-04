import Foundation

// Global registry for Tesseract implementation
public class TesseractBridge {
    public static let shared = TesseractBridge()
    
    private var wrapperFactory: (() -> TesseractWrapperProtocol)?
    
    private init() {}
    
    // Called by the main app to register the TesseractWrapper factory
    public func registerWrapperFactory(_ factory: @escaping () -> TesseractWrapperProtocol) {
        self.wrapperFactory = factory
    }
    
    // Called by TesseractOCREngine to get a wrapper instance
    public func createWrapper() -> TesseractWrapperProtocol? {
        return wrapperFactory?()
    }
    
    public var isAvailable: Bool {
        return wrapperFactory != nil
    }
}