import UIKit
import CoreImage
import Foundation
import AVFoundation

// MARK: ScreenCaptureOutputPixelBufferDelegate
public protocol ScreenCaptureOutputPixelBufferDelegate: class {
    func didSet(size:CGSize)
    func output(pixelBuffer:CVPixelBuffer, withPresentationTime:CMTime)
}

// MARK: -
public final class ScreenCaptureSession: NSObject {
    static let defaultFrameInterval:Int = 2
    static let defaultAttributes:[NSString:NSObject] = [
        kCVPixelBufferPixelFormatTypeKey: NSNumber(value: kCVPixelFormatType_32BGRA),
        kCVPixelBufferCGBitmapContextCompatibilityKey: true as NSObject
    ]

    public var enabledScale:Bool = false
    public var frameInterval:Int = ScreenCaptureSession.defaultFrameInterval
    public var attributes:[NSString:NSObject] {
        get {
            var attributes:[NSString:NSObject] = ScreenCaptureSession.defaultAttributes
            attributes[kCVPixelBufferWidthKey] = NSNumber(value: Float(size.width * scale))
            attributes[kCVPixelBufferHeightKey] = NSNumber(value: Float(size.height * scale))
            attributes[kCVPixelBufferBytesPerRowAlignmentKey] = NSNumber(value: Float(size.width * scale * 4))
            return attributes
        }
    }
    public weak var delegate:ScreenCaptureOutputPixelBufferDelegate?

    internal(set) var running:Bool = false
    fileprivate var shared:UIApplication
    fileprivate var context:CIContext = CIContext(options: [kCIContextUseSoftwareRenderer: NSNumber(value: false)])
    fileprivate let semaphore:DispatchSemaphore = DispatchSemaphore(value: 1)
    fileprivate let lockQueue:DispatchQueue = DispatchQueue(
        label: "com.github.shogo4405.lf.ScreenCaptureSession.lock", qos: DispatchQoS.userInteractive, attributes: []
    )
    fileprivate var colorSpace:CGColorSpace!
    fileprivate var displayLink:CADisplayLink!

    fileprivate var size:CGSize = CGSize() {
        didSet {
            guard size != oldValue else {
                return
            }
            delegate?.didSet(size: CGSize(width: size.width * scale, height: size.height * scale))
            pixelBufferPool = nil
        }
    }
    fileprivate var scale:CGFloat {
        return enabledScale ? UIScreen.main.scale : 1.0
    }

    fileprivate var _pixelBufferPool:CVPixelBufferPool?
    fileprivate var pixelBufferPool:CVPixelBufferPool! {
        get {
            if (_pixelBufferPool == nil) {
                var pixelBufferPool:CVPixelBufferPool?
                CVPixelBufferPoolCreate(nil, nil, attributes as CFDictionary?, &pixelBufferPool)
                _pixelBufferPool = pixelBufferPool
            }
            return _pixelBufferPool!
        }
        set {
            _pixelBufferPool = newValue
        }
    }

    public init(shared:UIApplication) {
        self.shared = shared
        size = shared.delegate!.window!!.bounds.size
        super.init()
    }

    public func onScreen(_ displayLink:CADisplayLink) {
        guard semaphore.wait(timeout: DispatchTime.now()) == .success else {
            return
        }
        lockQueue.async {
            autoreleasepool {
                self.onScreenProcess(displayLink)
            }
            self.semaphore.signal()
        }
    }

    fileprivate func onScreenProcess(_ displayLink:CADisplayLink) {
        var pixelBuffer:CVPixelBuffer?

        size = shared.delegate!.window!!.bounds.size
        CVPixelBufferPoolCreatePixelBuffer(nil, pixelBufferPool, &pixelBuffer)
        CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: CVOptionFlags(0)))
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        let cgctx:CGContext = UIGraphicsGetCurrentContext()!
        DispatchQueue.main.sync {
            UIGraphicsPushContext(cgctx)
            for window:UIWindow in shared.windows {
                window.drawHierarchy(
                    in: CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height),
                    afterScreenUpdates: false
                )
            }
            UIGraphicsPopContext()
        }
        let image:UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        context.render(CIImage(cgImage: image.cgImage!), to: pixelBuffer!)
        delegate?.output(pixelBuffer: pixelBuffer!, withPresentationTime: CMTimeMakeWithSeconds(displayLink.timestamp, 1000))
        CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: CVOptionFlags(0)))
    }
}

// MARK: Runnable
extension ScreenCaptureSession: Runnable {
    public func startRunning() {
        lockQueue.sync {
            guard !self.running else {
                return
            }
            self.running = true
            self.pixelBufferPool = nil
            self.colorSpace = CGColorSpaceCreateDeviceRGB()
            self.displayLink = CADisplayLink(target: self, selector: #selector(ScreenCaptureSession.onScreen(_:)))
            self.displayLink.frameInterval = self.frameInterval
            self.displayLink.add(to: .main, forMode: .commonModes)
        }
    }

    public func stopRunning() {
        lockQueue.sync {
            guard self.running else {
                return
            }
            self.displayLink.remove(from: .main, forMode: .commonModes)
            self.displayLink.invalidate()
            self.colorSpace = nil
            self.displayLink = nil
            self.running = false
        }
    }
}
