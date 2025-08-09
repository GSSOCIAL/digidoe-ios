//
//  CameraModel.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 19.11.2023.
//

import Foundation
import SwiftUI
import Combine
import AVFoundation
import UIKit
import Photos

class PhotoCaptureProcessor: NSObject {
    lazy var context = CIContext()
    private(set) var requestedPhotoSettings: AVCapturePhotoSettings
    private let willCapturePhotoAnimation: () -> Void
    private let completionHandler: (PhotoCaptureProcessor) -> Void
    private let photoProcessingHandler: (Bool) -> Void
    
    var photoData: Data?
    private var maxPhotoProcessingTime: CMTime?
    
    init(with requestedPhotoSettings: AVCapturePhotoSettings, willCapturePhotoAnimation: @escaping () -> Void, completionHandler: @escaping (PhotoCaptureProcessor) -> Void, photoProcessingHandler: @escaping (Bool) -> Void) {
        
        self.requestedPhotoSettings = requestedPhotoSettings
        self.willCapturePhotoAnimation = willCapturePhotoAnimation
        self.completionHandler = completionHandler
        self.photoProcessingHandler = photoProcessingHandler
    }
}

extension PhotoCaptureProcessor: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, willBeginCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
        maxPhotoProcessingTime = resolvedSettings.photoProcessingTimeRange.start + resolvedSettings.photoProcessingTimeRange.duration
    }
    func photoOutput(_ output: AVCapturePhotoOutput, willCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
        DispatchQueue.main.async {
            self.willCapturePhotoAnimation()
        }
        
        guard let maxPhotoProcessingTime = maxPhotoProcessingTime else {
            return
        }
        
        let oneSecond = CMTime(seconds: 2, preferredTimescale: 1)
        if maxPhotoProcessingTime > oneSecond {
            DispatchQueue.main.async {
                self.photoProcessingHandler(true)
            }
        }
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        
        DispatchQueue.main.async {
            self.photoProcessingHandler(false)
        }
        
        if let error = error {
            print("Error capturing photo: \(error)")
        } else {
            photoData = photo.fileDataRepresentation()
        }
    }
    
    func saveToPhotoLibrary(_ photoData: Data) {
        
        PHPhotoLibrary.requestAuthorization { status in
            if status == .authorized {
                PHPhotoLibrary.shared().performChanges({
                    let options = PHAssetResourceCreationOptions()
                    let creationRequest = PHAssetCreationRequest.forAsset()
                    options.uniformTypeIdentifier = self.requestedPhotoSettings.processedFileType.map { $0.rawValue }
                    creationRequest.addResource(with: .photo, data: photoData, options: options)
                    
                    
                }, completionHandler: { _, error in
                    if let error = error {
                        print("Error occurred while saving photo to photo library: \(error)")
                    }
                    
                    DispatchQueue.main.async {
                        self.completionHandler(self)
                    }
                }
                )
            } else {
                DispatchQueue.main.async {
                    self.completionHandler(self)
                }
            }
        }
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings, error: Error?) {
        if let error = error {
            print("Error capturing photo: \(error)")
            DispatchQueue.main.async {
                self.completionHandler(self)
            }
            return
        } else {
            guard let data  = photoData else {
                DispatchQueue.main.async {
                    self.completionHandler(self)
                }
                return
            }
            
            self.saveToPhotoLibrary(data)
        }
    }
}

class CameraPreviewView: UIView {
    override class var layerClass: AnyClass {
         AVCaptureVideoPreviewLayer.self
    }
    
    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        return layer as! AVCaptureVideoPreviewLayer
    }
}

struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> CameraPreviewView {
        let view = CameraPreviewView()
        view.backgroundColor = .black
        view.videoPreviewLayer.cornerRadius = 0
        view.videoPreviewLayer.session = self.session
        return view
    }
        
    func updateUIView(_ uiView: CameraPreviewView, context: Context) {
            
    }
}

public struct Photo: Identifiable, Equatable {
    public var id: String
    public var originalData: Data
    
    public init(id: String = UUID().uuidString, originalData: Data) {
        self.id = id
        self.originalData = originalData
    }
}

public class CameraService: ObservableObject{
    typealias PhotoCaptureSessionID = String
    
    @Published public var flashMode: AVCaptureDevice.FlashMode = .off
    @Published public var shouldShowSpinner = false
    @Published public var willCapturePhoto = false
    @Published public var isCameraButtonDisabled = true
    @Published public var isCameraUnavailable = true
    @Published public var photo: Photo?
    @Published var alert: Error?
    
    public let session = AVCaptureSession()
    private var isConfigured = false
    private var setupResult: SessionSetupResult = .success
    let sessionQueue = DispatchQueue(label: "camera session queue")
    @objc dynamic var videoDeviceInput: AVCaptureDeviceInput!
    
    private let videoDeviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera, .builtInDualCamera, .builtInTrueDepthCamera], mediaType: .video, position: .unspecified)
    let photoOutput = AVCapturePhotoOutput()
    
    private var inProgressPhotoCaptureDelegates = [Int64: PhotoCaptureProcessor]()
    
    enum SessionSetupResult{
        case success
        case failure
        case configurationFailed
        case notAuthorized
    }
    
    struct AlertError: Error{
        public var title: String = ""
        public var message: String = ""
        public var primaryButtonTitle = "Accept"
        public var secondaryButtonTitle: String?
        public var primaryAction: (() -> ())?
        public var secondaryAction: (() -> ())?
        
        public init(title: String = "", message: String = "", primaryButtonTitle: String = "Accept", secondaryButtonTitle: String? = nil, primaryAction: (() -> ())? = nil, secondaryAction: (() -> ())? = nil) {
            self.title = title
            self.message = message
            self.primaryAction = primaryAction
            self.primaryButtonTitle = primaryButtonTitle
            self.secondaryAction = secondaryAction
        }
    }
    
    private var isSessionRunning: Bool{
        return self.session.isRunning
    }
    
    public func start(){
        sessionQueue.async{
            if !self.isSessionRunning && self.isConfigured{
                switch self.setupResult{
                case .success:
                    self.session.startRunning()
                    
                    if self.session.isRunning {
                        DispatchQueue.main.async {
                            self.isCameraButtonDisabled = false
                            self.isCameraUnavailable = false
                        }
                    }
                    break
                case .failure:
                    break
                case .configurationFailed:
                    break
                case .notAuthorized:
                    break
                }
            }
        }
    }
    
    public func stop(completion: (() -> ())? = nil) {
        sessionQueue.async {
            if self.isSessionRunning {
                if self.setupResult == .success {
                    self.session.stopRunning()
                    
                    if !self.session.isRunning {
                        DispatchQueue.main.async {
                            self.isCameraButtonDisabled = true
                            self.isCameraUnavailable = true
                            completion?()
                        }
                    }
                }
            }
        }
    }
    
    public func changeCamera() {
        DispatchQueue.main.async {
            self.isCameraButtonDisabled = true
        }
        
        sessionQueue.async {
            let currentVideoDevice = self.videoDeviceInput.device
            let currentPosition = currentVideoDevice.position
            
            let preferredPosition: AVCaptureDevice.Position
            let preferredDeviceType: AVCaptureDevice.DeviceType
            
            switch currentPosition {
            case .unspecified, .front:
                preferredPosition = .back
                preferredDeviceType = .builtInWideAngleCamera
                
            case .back:
                preferredPosition = .front
                preferredDeviceType = .builtInWideAngleCamera
                
            @unknown default:
                preferredPosition = .back
                preferredDeviceType = .builtInWideAngleCamera
            }
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
                    
                    self.session.beginConfiguration()
                    self.session.removeInput(self.videoDeviceInput)
                    
                    if self.session.canAddInput(videoDeviceInput) {
                        self.session.addInput(videoDeviceInput)
                        self.videoDeviceInput = videoDeviceInput
                    } else {
                        self.session.addInput(self.videoDeviceInput)
                    }
                    
                    if let connection = self.photoOutput.connection(with: .video) {
                        if connection.isVideoStabilizationSupported {
                            connection.preferredVideoStabilizationMode = .auto
                        }
                    }
                    
                    self.photoOutput.maxPhotoQualityPrioritization = .quality
                    
                    self.session.commitConfiguration()
                } catch {
                    print("Error occurred while creating video device input: \(error)")
                }
            }
            
            DispatchQueue.main.async {
                self.isCameraButtonDisabled = false
            }
        }
    }
    
    public func checkForPermissions(){
        switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .authorized:
            break
            case .notDetermined:
                sessionQueue.suspend()
                AVCaptureDevice.requestAccess(for: .video, completionHandler: { granted in
                    if !granted {
                        self.setupResult = .notAuthorized
                        self.alert = AlertError(
                            title: "Camera Access",
                            message: "\(Whitelabel.BrandName()) doesn't have access to use your camera, please update your privacy settings.",
                            primaryButtonTitle: "Settings",
                            secondaryButtonTitle: nil,
                            primaryAction: {
                                UIApplication.shared.open(
                                    URL(string: UIApplication.openSettingsURLString)!,
                                    options: [:],
                                    completionHandler: nil
                                )
                            },
                            secondaryAction: nil
                        )
                    }
                    self.sessionQueue.resume()
                })
            break
            default:
                DispatchQueue.main.async {
                    self.alert = AlertError(
                        title: "Camera Access",
                        message: "\(Whitelabel.BrandName()) doesn't have access to use your camera, please update your privacy settings.",
                        primaryButtonTitle: "Settings",
                        secondaryButtonTitle: nil,
                        primaryAction: {
                            UIApplication.shared.open(
                                URL(string: UIApplication.openSettingsURLString)!,
                                options: [:],
                                completionHandler: nil
                            )
                        },
                        secondaryAction: nil
                    )
                    
                    self.isCameraUnavailable = true
                    self.isCameraButtonDisabled = true
                }
            break
        }
    }
    
    public func configure(){
        if self.setupResult != .success{
            return
        }
        
        self.session.beginConfiguration()
        self.session.sessionPreset = .photo
        
        do{
            var defaultVideoDevice: AVCaptureDevice?
            
            if let backCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
                defaultVideoDevice = backCameraDevice
            } else if let frontCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) {
                defaultVideoDevice = frontCameraDevice
            }
            
            guard let videoDevice = defaultVideoDevice else {
                self.alert = AlertError(
                    title: "Camera Access",
                    message: "Application unable to access device camera. Device not found"
                )
                self.setupResult = .configurationFailed
                self.session.commitConfiguration()
                return
            }
            
            let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
            
            if session.canAddInput(videoDeviceInput) {
                session.addInput(videoDeviceInput)
                self.videoDeviceInput = videoDeviceInput
            } else {
                self.alert = AlertError(
                    title: "Device Input Error",
                    message: "Application unable to add your device cameras input"
                )
                self.setupResult = .configurationFailed
                self.session.commitConfiguration()
                return
            }
        }catch let error{
            self.alert = error
            self.setupResult = .configurationFailed
            self.session.commitConfiguration()
            return
        }
        
        if self.session.canAddOutput(photoOutput) {
            self.session.addOutput(photoOutput)
            
            photoOutput.isHighResolutionCaptureEnabled = true
            photoOutput.maxPhotoQualityPrioritization = .quality
        } else {
            self.setupResult = .configurationFailed
            self.session.commitConfiguration()
            self.alert = AlertError(
                title: "Output error",
                message: "Unable to add camera as output"
            )
            return
        }
                
        self.session.commitConfiguration()
        self.isConfigured = true
                
        self.start()
    }
    
    func takePhoto(){
        if self.setupResult != .configurationFailed{
            sessionQueue.async {
                var photoSettings = AVCapturePhotoSettings()
                if  self.photoOutput.availablePhotoCodecTypes.contains(.hevc) {
                    photoSettings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
                }
                if self.videoDeviceInput.device.isFlashAvailable {
                    photoSettings.flashMode = self.flashMode
                }
                photoSettings.isHighResolutionPhotoEnabled = true
                photoSettings.photoQualityPrioritization = .quality
                
                let photoCaptureProcessor = PhotoCaptureProcessor(with: photoSettings, willCapturePhotoAnimation: {
                    DispatchQueue.main.async {
                        self.willCapturePhoto.toggle()
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        self.willCapturePhoto.toggle()
                    }
                },completionHandler: { (photoCaptureProcessor) in
                    if let data = photoCaptureProcessor.photoData {
                        self.photo = Photo(originalData: data)
                    }
                    self.isCameraButtonDisabled = false
                    self.sessionQueue.async {
                        self.inProgressPhotoCaptureDelegates[photoCaptureProcessor.requestedPhotoSettings.uniqueID] = nil
                    }
                },photoProcessingHandler: { animate in
                    if animate {
                        self.shouldShowSpinner = true
                    } else {
                        self.shouldShowSpinner = false
                    }
                })
                
                self.inProgressPhotoCaptureDelegates[photoCaptureProcessor.requestedPhotoSettings.uniqueID] = photoCaptureProcessor
                self.photoOutput.capturePhoto(with: photoSettings, delegate: photoCaptureProcessor)
            }
        }
    }
}
    
struct AVCamera: View {
    @EnvironmentObject var model: cameraModelService
    
    var body: some View {
        CameraPreview(session:self.model.session)
            .onAppear{
                self.model.configure()
            }
            .overlay(
                Color.black
                    .opacity(self.model.willCapturePhoto ? 1 : 0)
            )
            .animation(.easeInOut(duration: 0.1))
            .alert(isPresented: self.$model.showAlertError, content: {
                if self.$model.alertError.wrappedValue != nil{
                    var title = "Undefined error"
                    var message = "Something went wrong"
                    
                    var dismissButtonLabel = ""
                    var dissmissButtonAction: (()->Void)? = nil
                    
                    if let error = self.model.alertError! as? CameraService.AlertError{
                        title = error.title
                        message = error.message
                        dismissButtonLabel = error.primaryButtonTitle
                        dissmissButtonAction = error.primaryAction
                    }
                    
                    return Alert(
                        title: Text(title),
                        message: Text(message),
                        dismissButton: .default(
                            Text(dismissButtonLabel),
                            action:{
                                dissmissButtonAction?()
                            }
                        )
                    )
                }else{
                    return Alert(
                        title: Text("Undefined Error")
                    )
                }
            })
    }
}

struct AVCamera_Previews: PreviewProvider {
    static var previews: some View {
        AVCamera()
    }
}

final class cameraModelService:ObservableObject{
    private let service = CameraService()
    
    @Published var showAlertError = false
    var alertError: Error?
    @Published var willCapturePhoto = false
    @Published var photo: Photo!
    @Published var isFlashOn = false
    
    var session: AVCaptureSession
    private var subscriptions = Set<AnyCancellable>()
    
    init() {
        self.session = service.session
        
        service.$photo.sink { [weak self] (photo) in
            guard let pic = photo else { return }
            self?.photo = pic
        }
        .store(in: &self.subscriptions)
        
        service.$flashMode.sink { [weak self] (mode) in
            self?.isFlashOn = mode == .on
        }
        .store(in: &self.subscriptions)
        
        service.$alert.sink { [weak self] (val) in
            self?.alertError = val
            self?.showAlertError = val != nil
        }
        .store(in: &self.subscriptions)
        
        service.$willCapturePhoto.sink{ [weak self] (val) in
            self?.willCapturePhoto = val
        }.store(in: &self.subscriptions)
    }
    
    func configure() {
        self.service.checkForPermissions()
        self.service.configure()
    }
    
    func takePhoto(){
        self.service.takePhoto()
    }
    
    func flipCamera() {
        service.changeCamera()
    }
    
    func zoom(with factor: CGFloat) {
        //service.set(zoom: factor)
    }
    
    func switchFlash() {
        service.flashMode = service.flashMode == .on ? .off : .on
    }
}
