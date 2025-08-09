//
//  ExtendedCameraService.swift
//  DigiDoe Business Banking
//
//  Created by Михайло Картмазов on 30.04.2025.
//
import SwiftUI
import Combine
import Foundation
import Vision
import AVFoundation
import CoreImage
import UIKit
import Photos

struct DetectedObject: Identifiable {
    let id = UUID()
    let label: String
    let color: Color
    let confidence: Float
    let boundingBox: CGRect
}

//MARK: to link between swift ui & service
class CameraViewController: ObservableObject{
    @Published var photo: Data?
    var service: CameraViewService = CameraViewService()
    @Published public var flashMode: AVCaptureDevice.FlashMode = .off
    
    var session: AVCaptureSession{
        return self.service.session
    }
    
    func setup() async throws{
        try await self.service.setup()
        self.service.model = self
    }
    
    func capture(){
        self.service.takePhoto()
    }
    
    func toggleFlashlight(){
        self.flashMode = self.flashMode == .off ? .on : .off
        guard let device = AVCaptureDevice.default(for: AVMediaType.video) else { return }
        guard device.hasTorch else { return }

        do {
            try device.lockForConfiguration()
            if (self.flashMode == .off){
                do {
                    try device.setTorchModeOn(level: 1.0)
                }catch let error{
                    
                }
            }else{
                device.torchMode = AVCaptureDevice.TorchMode.off
            }
            device.unlockForConfiguration()
        }catch let error{
            
        }
    }
    func disableFlashlight(){
        self.flashMode = .off
        guard let device = AVCaptureDevice.default(for: AVMediaType.video) else { return }
        guard device.hasTorch else { return }
        
        do {
            try device.lockForConfiguration()
            device.torchMode = AVCaptureDevice.TorchMode.off
            device.unlockForConfiguration()
        }catch let error{
            
        }
    }
}

//MARK:
class CameraViewService: NSObject{
    //Video stream
    var session = AVCaptureSession()
    var model: CameraViewController? = nil
    let sessionQueue = DispatchQueue(label: "camera session queue")
    
    var videoOutput = AVCaptureVideoDataOutput()
    var photoOutput = AVCapturePhotoOutput()
    @objc dynamic var videoDeviceInput: AVCaptureDeviceInput!
    private let videoDeviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera, .builtInDualCamera, .builtInTrueDepthCamera], mediaType: .video, position: .back)
    
    //States
    private var setupResult: CameraServiceSetupResult = .notAuthorized
    
    enum CameraServiceSetupResult{
        case success
        case failed
        case notAuthorized
    }
    
    struct CameraViewServiceError: Error{
        var code: CameraViewServiceErrorCode
        var message: String
        
        enum CameraViewServiceErrorCode{
            case notPermitted
        }
    }
    
    //MARK: Setup Camera service
    func setup() async throws{
        if (!self.session.isRunning && self.setupResult != .success){
            switch (self.setupResult){
                case .success:
                    break
                case .failed:
                    try self.configure()
                    break
                case .notAuthorized:
                    try await self.accessPermissions()
                    break
            }
        }
    }
    
    //MARK: Check & ask for permissions
    func accessPermissions() async throws{
        switch AVCaptureDevice.authorizationStatus(for: .video){
        case .authorized:
            try self.configure()
            break;
        case .denied:
            throw CameraViewServiceError(code: .notPermitted, message: "")
        case .restricted:
            throw CameraViewServiceError(code: .notPermitted, message: "")
        case .notDetermined:
            sessionQueue.suspend()
            let granted = try await AVCaptureDevice.requestAccess(for: .video)
            
            if (!granted){
                self.sessionQueue.resume()
                throw CameraViewServiceError(code: .notPermitted, message: "")
            }
            
            self.sessionQueue.resume()
            try self.configure()
            break;
        default:
            break;
        }
    }
    
    //MARK: Configure camera
    func configure() throws{
        if (self.setupResult == .success){
            return
        }
        
        self.session.beginConfiguration()
        
        do{
            let preferredPosition: AVCaptureDevice.Position = .back
            let preferredDeviceType: AVCaptureDevice.DeviceType = .builtInWideAngleCamera
            
            let devices = self.videoDeviceDiscoverySession.devices
            var newVideoDevice: AVCaptureDevice? = nil
            
            if let device = devices.first(where: { $0.position == preferredPosition && $0.deviceType == preferredDeviceType }) {
                newVideoDevice = device
            } else if let device = devices.first(where: { $0.position == preferredPosition }) {
                newVideoDevice = device
            }
            
            if let videoDevice = newVideoDevice {
                do {
                    let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
                    if (self.session.canAddInput(videoDeviceInput)){
                        self.session.addInput(videoDeviceInput)
                        self.videoDeviceInput = videoDeviceInput
                    }
                }
            }
            
            if let connection = self.photoOutput.connection(with: .video) {
                if connection.isVideoStabilizationSupported {
                    connection.preferredVideoStabilizationMode = .auto
                }
            }
            
            self.photoOutput.maxPhotoQualityPrioritization = .quality
            
            //Add video output
            if self.session.canAddOutput(self.videoOutput) {
                self.session.addOutput(self.videoOutput)
            }
            //Add photo output
            if (self.session.canAddOutput(self.photoOutput)){
                self.session.addOutput(self.photoOutput)
            }
            
            self.session.commitConfiguration()
            self.session.startRunning()
            self.setupResult = .success
        }catch(let error){
            throw CameraViewServiceError(code: .notPermitted, message: "")
        }
    }
    
    func takePhoto(){
        self.sessionQueue.async{
            var photoSettings = AVCapturePhotoSettings()
            if  self.photoOutput.availablePhotoCodecTypes.contains(.hevc) {
                photoSettings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
            }
            if (self.videoDeviceInput.device.isFlashAvailable){
                photoSettings.flashMode = self.model?.flashMode ?? .auto
            }
            photoSettings.isHighResolutionPhotoEnabled = self.photoOutput.isHighResolutionCaptureEnabled
            photoSettings.photoQualityPrioritization = self.photoOutput.maxPhotoQualityPrioritization
            
            if let photoOutputVideoConnection = self.photoOutput.connection(with: .video) {
                
            }
            self.photoOutput.capturePhoto(with: photoSettings, delegate: self)
        }
    }
}

extension CameraViewService: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error{
            return
        }
        
        let data = photo.fileDataRepresentation()
        self.model?.photo = data
    }
}

//MARK: Camera view controller
struct CameraView: UIViewControllerRepresentable {
    @EnvironmentObject var model: CameraViewController
    
    @Binding var boxes: Array<DetectedObject>
    @Binding var frame: CGRect
    @Binding var mask: CGRect
    @Binding var isCapturing: Bool
    @Binding var detectObjectsEnabled: Bool
    
    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()
        let previewLayer = AVCaptureVideoPreviewLayer(session: self.model.session)
        previewLayer.frame = viewController.view.bounds
        previewLayer.videoGravity = .resizeAspectFill
        viewController.view.layer.addSublayer(previewLayer)
        self.model.service.videoOutput.setSampleBufferDelegate(context.coordinator, queue: DispatchQueue(label: "videoOutputQueue"))
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
        var parent: CameraView
        private var frame = 0
        
        init(_ parent: CameraView) {
            self.parent = parent
        }
        
        func captureOutput(_ output: AVCaptureOutput,
                           didOutput sampleBuffer: CMSampleBuffer,
                           from connection: AVCaptureConnection
        ) {
            if (self.parent.detectObjectsEnabled){
                //Skip each 3 frames to optimize
                self.frame += 1
                if self.frame % 2 != 0 { return }
                
                guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
                self.detectObjects(in: pixelBuffer)
            }
        }
        
        func detectObjects(in pixelBuffer: CVPixelBuffer) {
            let handler = VNImageRequestHandler(
                cvPixelBuffer: pixelBuffer,
                orientation: .right
            )
            
            
            do {
                let request = VNDetectRectanglesRequest()
                request.minimumAspectRatio = 0.4
                request.maximumAspectRatio = 1.0
                
                try handler.perform([request])
                
                let rects = request.results as! Array<VNRectangleObservation>
                
                self.parent.decodeDocuments(rects, buffer: pixelBuffer)
            } catch {
                print("Detection error: \(error.localizedDescription)")
            }
        }
    }
    
    //Try to detect documents
    func decodeDocuments(
        _ rects: Array<VNRectangleObservation>,
        buffer: CVPixelBuffer
    ){
        #if DEBUG
            self.boxes = []
        #endif
        //On this step - detect if paralel rectangles lines exists in offset (mask) zone + (+- error) zone
        let width = CVPixelBufferGetWidth(buffer) //Original image width (1980)
        let height = CVPixelBufferGetHeight(buffer) //Original image height (1080)
        
        let errorArea: CGFloat = 60;
        
        let (maskTop,maskRight,maskBottom,maskLeft) = (
            self.mask.minY,
            (self.mask.minX + self.mask.width),
            (self.mask.minY + self.mask.height),
            self.mask.minX
        )
        
        let mW = self.frame.width / CGFloat(height)
        let mH = self.frame.height / CGFloat(width)
        
        var fittedWidth = self.frame.width
        var fittedHeight = self.frame.height
        
        let ratio = CGFloat(width) / CGFloat(height)
        let scaleToFitWidth = self.frame.height / ratio
        
        //Apply point transformation
        let transform = CGAffineTransform.identity
            .scaledBy(
                x: scaleToFitWidth,
                y: fittedHeight
            )
        
        let colors = [
            Color.red,
            Color.green,
            Color.blue,
            Color.yellow,
            Color.pink
        ]
        var isCapturing = false
        
        rects.forEach({ rect in
            //Collect rectangle points
            var points = [
                rect.topLeft,
                rect.topRight,
                rect.bottomRight,
                rect.bottomLeft
            ]
            //Flip y coordinate
            points = points.map({
                return CGPoint(
                    x: $0.x,
                    y: 1 - $0.y
                )
            })
            //TODO: Calculate this diff, seems like output is locked aspect ratio simillar to input size, so we can calculate original aspect ratio then scale frame size with it
            points = points.map({
                return $0.applying(transform)
            }).map({
                return CGPoint(
                    x: $0.x - ((scaleToFitWidth - fittedWidth)/2),
                    y: $0.y
                )
            })
            //Draw rectangle
            var i = 0;
            points.forEach({
                #if DEBUG && false
                self.boxes.append(
                    .init(
                        label: "",
                        color: colors[i] ?? Color.purple,
                        confidence: 1,
                        boundingBox: CGRect(
                            x: $0.x,
                            y: $0.y,
                            width: 10,
                            height: 10
                        )
                    )
                )
                #endif
                i += 1;
            })
            //Detect edges
            let (sortedByX, sortedByY) = (points.sorted { $0.x < $1.x }, points.sorted { $0.y < $1.y })
            
            //Here we will get inner offset btw point position with mask edges
            let leadingEdge = sortedByX.prefix(2).map({
                return $0.x - maskLeft
            })
            let trailingEdge = sortedByX.suffix(2).map({
                return maskRight - $0.x
            })
            
            //Compare if leading edge points located in capture area (-10 < x < errorArea)
            if (
                leadingEdge.filter({
                    return $0 > -10 && $0 < errorArea
                }).count == leadingEdge.count &&
                trailingEdge.filter({
                    return $0 > -10 && $0 < errorArea
                }).count == trailingEdge.count
            ){
                isCapturing = true
            }
        })
        
        if (isCapturing){
            self.isCapturing = true
        }else{
            self.isCapturing = false
        }
    }
}
