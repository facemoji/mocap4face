/*
 See LICENSE.md for this sample’s licensing information.
*/

import UIKit
import AVFoundation

@objc protocol VideoCaptureDelegate : AnyObject {
    @objc optional func sampleBufferAvailable(_ buffer:CMSampleBuffer, brightness:CGFloat)
//    @objc optional func pixelBufferAvailable(_ pixelBuffer:CVPixelBuffer, brightness:CGFloat)
    @objc optional func captureSessionReady(_ captureSession:AVCaptureSession, captureDevice:AVCaptureDevice, resolution:CGSize)
}

enum VideoCaptureType:String
{
    case video = "VIDEO"
    case photo = "PHOTO"
}

class VideoCapture: NSObject {
    
    weak var delegate:VideoCaptureDelegate?
    
    private var captureSession: AVCaptureSession?
    private var currentVideoCaptureType:VideoCaptureType?
    private var capturePhotoOutput: AVCapturePhotoOutput?
    private var captureVideoOutput: AVCaptureVideoDataOutput?
    private var currentCameraPosition: AVCaptureDevice.Position?
    private var currentCameraConnection: AVCaptureConnection?
    
    var videoDataOutputQueue: DispatchQueue =  DispatchQueue(label: "videoCaptureQueue", qos: .default)

    private var cameraResolution = CGSize(width: 0, height: 0)
    var currentPixelBuffer:CVPixelBuffer?
    public var currentCaptureDevice:AVCaptureDevice?
 
    var brightness:CGFloat = 0
    private var checkForBrightnessEveryNFrames = 30
    private var checkForBrightnessCount = 28
    
    var position: AVCaptureDevice.Position? { get { return currentCameraPosition} }

    func captureDevice(position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position) {
            
            return device
        } else {
            return nil
        }
    }
    
    func setupResolutionForDevice(_ device:AVCaptureDevice, type: VideoCaptureType) {
        try? device.lockForConfiguration()
        
        var bestFormat:AVCaptureDevice.Format? = nil;
        
        var sizeW = 1024
        var sizeH = 768
        
        let backupW = 1280
        let backupH = 960
        
        if type == .video {
            sizeW = 1280
            sizeH = 720
        }
        
        var possibleFormats = [AVCaptureDevice.Format]()
        
        for format in device.formats {
            var support60fps = false
            
            for range in format.videoSupportedFrameRateRanges {
                if range.maxFrameRate == 60.0 {
                    support60fps = true
                }
            }
           
            let dimensions = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
            if dimensions.width == sizeW && dimensions.height == sizeH {
                if support60fps {
                    bestFormat = format
                    break
                } else {
                    possibleFormats.append(format)
                }
            } else if dimensions.width == backupW && dimensions.height == backupH  {
                if support60fps {
                    bestFormat = format
                    break
                }
            }
        }
        
        if bestFormat != nil {
            device.activeFormat = bestFormat!
//            device.activeVideoMinFrameDuration = CMTimeMake(value: 1, timescale: 60)
//            device.activeVideoMaxFrameDuration = CMTimeMake(value: 1, timescale: 60)
            device.activeVideoMinFrameDuration = CMTimeMake(value: 1, timescale: 30)
            device.activeVideoMaxFrameDuration = CMTimeMake(value: 1, timescale: 30)

        } else if possibleFormats.count > 0 {
            device.activeFormat = possibleFormats[0]
        }
        
        device.unlockForConfiguration()
        
    }
    
    func startCamera(position: AVCaptureDevice.Position, videoCaptureType:VideoCaptureType = .video, previewOnly: Bool = false) {
        if let captureDevice = captureDevice(position: position) {
            do {
                currentCaptureDevice = captureDevice
                currentCameraPosition = position
                currentVideoCaptureType = videoCaptureType
                
                let input = try AVCaptureDeviceInput(device: captureDevice)
                
                let session = AVCaptureSession()
                session.addInput(input)
                session.beginConfiguration()
                if previewOnly {
                    session.sessionPreset = .cif352x288
                } else {

                    
                    captureVideoOutput = AVCaptureVideoDataOutput()
                    guard let captureVideoOutput = self.captureVideoOutput else { return }
                    captureVideoOutput.videoSettings = [
                        kCVPixelBufferPixelFormatTypeKey as String : NSNumber(value: kCVPixelFormatType_32BGRA),
//                        kCVPixelBufferMetalCompatibilityKey as String: NSNumber(booleanLiteral: true)
                    ]

                    captureVideoOutput.alwaysDiscardsLateVideoFrames = true
                    
                    if session.canAddOutput(captureVideoOutput) {
                        session.addOutput(captureVideoOutput)
                    }
                
                    captureVideoOutput.setSampleBufferDelegate(self, queue: videoDataOutputQueue)
                    
                    captureVideoOutput.connection(with: .video)?.isEnabled = true
                    if let captureConnection = captureVideoOutput.connection(with: AVMediaType.video) {
                        
                        currentCameraConnection = captureConnection
                        
                        captureConnection.videoOrientation = uiOrientationToAvOrientation(UIDevice.current.orientation)
                        
                        captureConnection.isEnabled = true
                        if position == .front {
                            captureConnection.isVideoMirrored = true
                        } else {
                            captureConnection.isVideoMirrored = false
                        }
                    } else {
                        currentCameraConnection = nil
                    }
                }
                
                session.commitConfiguration()
                
                setupResolutionForDevice(captureDevice, type: videoCaptureType)
                
                session.startRunning()

                captureSession = session
                
                refreshView()
            } catch {
                print(error)
            }
            
        }
        
    }
    
    private func uiOrientationToAvOrientation(_ orientation: UIDeviceOrientation) -> AVCaptureVideoOrientation {
        return { switch UIDevice.current.orientation {
            case .landscapeLeft:
               return AVCaptureVideoOrientation.landscapeRight
            case .landscapeRight:
                return AVCaptureVideoOrientation.landscapeLeft
            case .portrait:
                return AVCaptureVideoOrientation.portrait
            case .portraitUpsideDown:
                return AVCaptureVideoOrientation.portraitUpsideDown
            default:
                return AVCaptureVideoOrientation.portrait
        } } ()
    }
    
    public func changeOrientation(_ newOrientation: UIDeviceOrientation = UIDevice.current.orientation) {
        currentCameraConnection?.videoOrientation = uiOrientationToAvOrientation(newOrientation)
        refreshView()
    }
    
    public var imageOrientation: CGImagePropertyOrientation {
        get {
            guard let videoOrientation = currentCameraConnection?.videoOrientation else { return .up }
            switch videoOrientation {
            case .landscapeLeft:
                return .left
            case .landscapeRight:
                return .right
            case .portrait:
                return .up
            case .portraitUpsideDown:
                return .down
            default:
                return .up
            }
        }
    }
    
    public var frameResolution: (Int, Int) {
        get {
            return (Int(cameraResolution.width), Int(cameraResolution.height))
        }
    }
    
    func refreshView() {
        // Get video dimensions
        guard let formatDescription = currentCaptureDevice?.activeFormat.formatDescription else { return }
        let dimensions = CMVideoFormatDescriptionGetCleanAperture(formatDescription, originIsAtTopLeft: true)
        cameraResolution = CGSize(width: CGFloat(dimensions.height), height: CGFloat(dimensions.width))
        
        guard let cs = captureSession else { return }
        guard let ccd = currentCaptureDevice else { return }
        
        delegate?.captureSessionReady?(cs, captureDevice: ccd, resolution: cameraResolution)
    }
    
    func switchSessionPreset() {
        guard let captureDevice = currentCaptureDevice else { return }
        if currentVideoCaptureType == .video {
            currentVideoCaptureType = .photo
        } else {
            currentVideoCaptureType = .video
        }
        setupResolutionForDevice(captureDevice, type: currentVideoCaptureType!)
        
        refreshView()
    }
    
    func toggleFlash() {
        guard let device = currentCaptureDevice else { return }
        
        if device.hasTorch == false {
            if UIScreen.main.brightness < 1.0 {
                UIScreen.main.brightness = CGFloat(1.0)
            } else {
                UIScreen.main.brightness = CGFloat(0.5)
            }
        } else {
            do {
                try device.lockForConfiguration()
                
                if (device.torchMode == AVCaptureDevice.TorchMode.on) {
                    device.torchMode = AVCaptureDevice.TorchMode.off
                } else {
                    do {
                        try device.setTorchModeOn(level: 1.0)
                    } catch {
                        print(error)
                    }
                }
                
                device.unlockForConfiguration()
            } catch {
                print(error)
            }
        }
    }
    
    func stopCamera() {
        captureSession?.stopRunning()
    }
    
    func switchLowLight(value:Bool) {
        guard let captureDevice = currentCaptureDevice else { return }
        guard let session = captureSession else { return }
        try? captureDevice.lockForConfiguration()
        session.beginConfiguration()
        if captureDevice.isLowLightBoostSupported {
            captureDevice.automaticallyEnablesLowLightBoostWhenAvailable = value
        }
        print("isLowLightBoostEnabled", captureDevice.isLowLightBoostEnabled)
        session.commitConfiguration()
        captureDevice.unlockForConfiguration()
    }
    
    func getSession()->AVCaptureSession? {
        return captureSession
    }
}

extension VideoCapture: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
            self.delegate?.sampleBufferAvailable?(sampleBuffer, brightness: self.brightness)
    }
    
    func getBrightnessValue(from sampleBuffer: CMSampleBuffer) -> CGFloat {
        guard
            let metadataDict = CMCopyDictionaryOfAttachments(allocator: nil, target: sampleBuffer, attachmentMode: kCMAttachmentMode_ShouldPropagate) as? [String: Any],
            let exifMetadata = metadataDict[String(kCGImagePropertyExifDictionary)] as? [String: Any],
            let brightnessValue = exifMetadata[String(kCGImagePropertyExifBrightnessValue)] as? CGFloat
            else { return 0.0 }
        return brightnessValue
    }
    
    func exifOrientation(orientation: UIDeviceOrientation) -> Int {
        switch orientation {
        case .portraitUpsideDown:
            return 8
        case .landscapeLeft:
            return 3
        case .landscapeRight:
            return 1
        default:
            return 6
        }
    }
}

