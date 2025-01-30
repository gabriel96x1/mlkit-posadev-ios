//
//  CameraView.swift
//  mlkitposadev
//
//  Created by Gabriel Ernesto Rodriguez Zamora on 07/12/24.
//

import SwiftUI
import UIKit
import AVFoundation

public struct CameraView: View {
    
    private var delegate: CameraViewDelegate?
    private var cameraType: AVCaptureDevice.DeviceType
    private var cameraPosition: AVCaptureDevice.Position
    private var preview : PreviewHolder
    private var onFrameCaptured: ((UIImage) -> Void)?
    
    @ObservedObject private var viewModel : CameraViewModel
    
    public init(delegate: CameraViewDelegate? = nil, cameraType: AVCaptureDevice.DeviceType = .builtInWideAngleCamera, cameraPosition: AVCaptureDevice.Position = .back, onFrameCaptured: ((UIImage) -> Void)? = nil) {
        self.delegate = delegate
        self.cameraType = cameraType
        self.cameraPosition = cameraPosition
        self.onFrameCaptured = onFrameCaptured
        self.preview = PreviewHolder(delegate: delegate, cameraType: cameraType, cameraPosition: cameraPosition, onFrameCaptured: onFrameCaptured)
        
        self.viewModel = CameraViewModel(preview: self.preview)
    }
    
    public var body: some View {
        preview.onTapGesture {
            viewModel.capturePhoto()
        }
    }
    
    public func getViewModel() -> CameraViewModel {
        return self.viewModel
    }
}

extension CameraView {
    public class CameraViewModel : NSObject, ObservableObject {
        @Published var capturedPhoto: UIImage? = nil
        
        private var preview : PreviewHolder
        
        fileprivate init(preview : PreviewHolder) {
            self.preview = preview
        }
        
        public func capturePhoto() {
            preview.getView().capturePhoto()
        }
    }
}

enum PhotoParseError : Error {
    case error(Error)
    case takeRetainValueFailed
}

private class PreviewView: UIView, AVCapturePhotoCaptureDelegate, AVCaptureVideoDataOutputSampleBufferDelegate {
        
    private var delegate: CameraViewDelegate?
    
    private var captureSession: AVCaptureSession?
    private var videoDeviceInput: AVCaptureDeviceInput?
    private var photoOutput: AVCapturePhotoOutput?
    private var videoOutput: AVCaptureVideoDataOutput?
    private var onFrameCaptured: ((UIImage) -> Void)?
    
    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        return layer as! AVCaptureVideoPreviewLayer
    }
    
    init(delegate: CameraViewDelegate? = nil, cameraType: AVCaptureDevice.DeviceType = .builtInWideAngleCamera, cameraPosition: AVCaptureDevice.Position = .back, onFrameCaptured: ((UIImage) -> Void)? = nil) {
        super.init(frame: .zero)
        
        self.delegate = delegate
        self.onFrameCaptured = onFrameCaptured
        
        var accessAllowed = false
        
        let blocker = DispatchGroup()
        blocker.enter()
        
        AVCaptureDevice.requestAccess(for: .video) { (flag) in
            accessAllowed = true
            delegate?.cameraAccessGranted()
            blocker.leave()
        }
        
        blocker.wait()
        
        if !accessAllowed {
            delegate?.cameraAccessDenied()
            return
        }
        
        setupSession(cameraType: cameraType, cameraPosition: cameraPosition)
        
    }
    
    func setupSession(cameraType: AVCaptureDevice.DeviceType = .builtInWideAngleCamera, cameraPosition: AVCaptureDevice.Position = .back) {
        let session = AVCaptureSession()
        session.beginConfiguration()
        let videoDevice = AVCaptureDevice.default(cameraType,
                                                  for: .video, position: cameraPosition)
        
        guard videoDevice != nil, let deviceInput = try? AVCaptureDeviceInput(device: videoDevice!), session.canAddInput(deviceInput) else {
            delegate?.noCameraDetected()
            return
        }
        self.videoDeviceInput = deviceInput
        session.addInput(videoDeviceInput!)
        
        self.photoOutput = AVCapturePhotoOutput()
        
        videoOutput = AVCaptureVideoDataOutput()
        let queue = DispatchQueue(label: "videoOutputQueue")
        videoOutput!.setSampleBufferDelegate(self, queue: queue)
        
        guard session.canAddOutput(photoOutput!) else {
            delegate?.noCameraDetected()
            return
            
        }
        session.automaticallyConfiguresCaptureDeviceForWideColor = false
        session.addOutput(photoOutput!)
        
        guard session.canAddOutput(videoOutput!) else {
            delegate?.noCameraDetected()
            return
            
        }

        session.addOutput(videoOutput!)
        
        videoOutput!.alwaysDiscardsLateVideoFrames = true
        
        session.commitConfiguration()
        
        self.captureSession = session
        delegate?.cameraSessionStarted()
        
        DispatchQueue.global(qos: .background).async {
            self.captureSession?.startRunning()
        }
    }
    
    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        
        if nil != self.superview {
            self.videoPreviewLayer.session = self.captureSession
            self.videoPreviewLayer.videoGravity = .resizeAspectFill
        }
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        //guard let uiImage = sampleBuffer.imageWithCGImage() else { return }
        DispatchQueue.global(qos: .background).async {
            //self.onFrameCaptured?(uiImage)
        }
    }
    
    func capturePhoto() {
        let photoSettings = AVCapturePhotoSettings()
        photoSettings.previewPhotoFormat = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
        self.photoOutput?.capturePhoto(with: photoSettings, delegate: self)
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        print("taking photo")
        
        DispatchQueue.global(qos: .background).async {
            if let cgImage = photo.cgImageRepresentation() {
                let image = UIImage(cgImage: cgImage)
                self.onFrameCaptured?(image)
                
                self.setupSession()
            } else {
                print("Error: \(error?.localizedDescription ?? "No error") ")
            }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }
}

private struct PreviewHolder: UIViewRepresentable {
    private var delegate: CameraViewDelegate?
    private var cameraType: AVCaptureDevice.DeviceType
    private var cameraPosition: AVCaptureDevice.Position
    private var view: PreviewView
    private var onFrameCaptured: ((UIImage) -> Void)?
    
    
    init(delegate: CameraViewDelegate? = nil, cameraType: AVCaptureDevice.DeviceType = .builtInWideAngleCamera, cameraPosition: AVCaptureDevice.Position = .back, onFrameCaptured: ((UIImage) -> Void)? = nil) {
        self.delegate = delegate
        self.cameraType = cameraType
        self.cameraPosition = cameraPosition
        self.onFrameCaptured = onFrameCaptured
        self.view = PreviewView(delegate: delegate, cameraType: cameraType, cameraPosition: cameraPosition, onFrameCaptured: onFrameCaptured)
    }
    
    func makeUIView(context: UIViewRepresentableContext<PreviewHolder>) -> PreviewView {
        view
    }
    
    func updateUIView(_ uiView: PreviewView, context: UIViewRepresentableContext<PreviewHolder>) {
    }
    
    func getView() -> PreviewView {
        return view
    }
    
    typealias UIViewType = PreviewView
}

public struct CameraView_Previews: PreviewProvider {
    public static var previews: some View {
        CameraView()
    }
}

extension CMSampleBuffer {
    /// https://stackoverflow.com/questions/15726761/make-an-uiimage-from-a-cmsamplebuffer
    func image(orientation: UIImage.Orientation = .up, scale: CGFloat = 1.0) -> UIImage? {
        if let buffer = CMSampleBufferGetImageBuffer(self) {
            let ciImage = CIImage(cvPixelBuffer: buffer)

            return UIImage(ciImage: ciImage, scale: scale, orientation: orientation)
        }

        return nil
    }

    func imageWithCGImage(orientation: UIImage.Orientation = .up, scale: CGFloat = 1.0) -> UIImage? {
        if let buffer = CMSampleBufferGetImageBuffer(self) {
            let ciImage = CIImage(cvPixelBuffer: buffer)

            let context = CIContext(options: nil)

            guard let cg = context.createCGImage(ciImage, from: ciImage.extent) else {
                return nil
            }
            
            return UIImage(cgImage: cg, scale: scale, orientation: orientation)
        }

        return nil
    }
    
}
