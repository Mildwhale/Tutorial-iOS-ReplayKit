#if os(iOS)
import UIKit
#endif
import Foundation
import AVFoundation

public final class DeviceUtil {
    private init() {
    }

    #if os(iOS)
    static public func videoOrientation(by notification:Notification) -> AVCaptureVideoOrientation? {
        guard let device:UIDevice = notification.object as? UIDevice else {
            return nil
        }
        return videoOrientation(by: device.orientation)
    }

    static public func videoOrientation(by orientation:UIDeviceOrientation) -> AVCaptureVideoOrientation? {
        switch orientation {
        case .portrait:
            return .portrait
        case .portraitUpsideDown:
            return .portraitUpsideDown
        case .landscapeLeft:
            return .landscapeRight
        case .landscapeRight:
            return .landscapeLeft
        default:
            return nil
        }
    }
    #endif

    static public func device(withPosition:AVCaptureDevicePosition) -> AVCaptureDevice? {
        for device in AVCaptureDevice.devices() {
            guard let device:AVCaptureDevice = device as? AVCaptureDevice else {
                continue
            }
            if (device.hasMediaType(AVMediaTypeVideo) && device.position == withPosition) {
                return device
            }
        }
        return nil
    }

    static public func device(withLocalizedName:String, mediaType:String) -> AVCaptureDevice? {
        for device in AVCaptureDevice.devices() {
            guard let device:AVCaptureDevice = device as? AVCaptureDevice else {
                continue
            }
            if (device.hasMediaType(mediaType) && device.localizedName == withLocalizedName) {
                return device
            }
        }
        return nil
    }

    static func getActualFPS(_ fps:Float64, device:AVCaptureDevice) -> (fps:Float64, duration:CMTime)? {
        var durations:[CMTime] = []
        var frameRates:[Float64] = []

        for object:Any in device.activeFormat.videoSupportedFrameRateRanges {
            guard let range:AVFrameRateRange = object as? AVFrameRateRange else {
                continue
            }
            if (range.minFrameRate == range.maxFrameRate) {
                durations.append(range.minFrameDuration)
                frameRates.append(range.maxFrameRate)
                continue
            }
            if (range.minFrameRate <= fps && fps <= range.maxFrameRate) {
                return (fps, CMTimeMake(100, Int32(100 * fps)))
            }
            
            let actualFPS:Float64 = max(range.minFrameRate, min(range.maxFrameRate, fps))
            return (actualFPS, CMTimeMake(100, Int32(100 * actualFPS)))
        }
        
        var diff:[Float64] = []
        for frameRate in frameRates {
            diff.append(abs(frameRate - fps))
        }
        if let minElement:Float64 = diff.min() {
            for i in 0..<diff.count {
                if (diff[i] == minElement) {
                    return (frameRates[i], durations[i])
                }
            }
        }
        
        return nil
    }
}
