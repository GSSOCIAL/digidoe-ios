//
//  OCRScanView.swift
//  DigiDoe Business Banking
//
//  Created by Михайло Картмазов on 22.04.2025.
//

import SwiftUI
import Combine
import Foundation
import Vision
import AVFoundation
import CoreImage
import UIKit
import Photos

struct OCRShutterButton: View{
    @Binding var autoCaptureEnabled: Bool
    @Binding var loading: Bool
    @Binding var result: OCRScanView.OCRDecodeResult?
    
    //Shutter button
    @State private var shutterProcessing : Bool = false
    @State private var shutterTrimFrom: CGFloat = 0
    @State private var shutterTrimTo: CGFloat = 0.5
    
    var hideShutterButton: Binding<Bool>{
        Binding(
            get:{
                if (self.loading){
                    return true
                }
                if (self.result != nil){
                    if case .failed(let type) = self.result{
                        return true
                    }
                    if case .success(let type) = self.result{
                        return true
                    }
                }
                return false
            },
            set:{ value in
                
            }
        )
    }
    var hideLoader: Binding<Bool>{
        Binding(
            get:{
                if (self.result != nil){
                    if case .failed(let type) = self.result{
                        return true
                    }
                    if case .success(let type) = self.result{
                        return true
                    }
                }
                return false
            },
            set:{ value in
                
            }
        )
    }
    
    var loaderColor: Color{
        if (self.result != nil){
            if case .submit = self.result{
                return Color.get(.Active)
            }
            if case .processing = self.result{
                return Color.get(.Pending)
            }
            if case .failed(let type) = self.result{
                return Color.get(.Danger)
            }
            if case .success(let type) = self.result{
                return Color.get(.Active)
            }
        }
        return Color.get(.Pending)
    }
    
    var outlineColor: Color{
        if (self.result != nil){
            if case .failed(let type) = self.result{
                return Color.get(.Danger)
            }
            if case .success(let type) = self.result{
                return Color.get(.Active)
            }
        }
        return Color.white
    }
    
    var body: some View{
        ZStack{
            ZStack{
                //MARK: Shutter button contents
                VStack{
                    HStack{
                        Spacer()
                    }
                    Spacer()
                }
                    .background(self.autoCaptureEnabled || self.hideShutterButton.wrappedValue ? Color.black : Color.white)
                    .clipShape(Circle())
                    .padding(6)
                    .overlay(
                        ZStack{
                            if case .failed(let error) = self.result{
                                Image("warn")
                                    .transition(.asymmetric(insertion: .scale, removal: .opacity))
                            }else if case .submit = self.result{
                                Image("refresh-2")
                                    .foregroundColor(Color.white)
                                    .transition(.asymmetric(insertion: .scale, removal: .opacity))
                            }
                        }
                    )
            }
                .background(Color.black)
                .clipShape(Circle())
                .padding(6)
        }
            .frame(width: 78, height: 78)
            .background(self.outlineColor)
            .clipShape(Circle())
            .overlay(
                ZStack{
                    Circle()
                        .trim(
                            from: self.shutterTrimFrom,
                            to: self.shutterTrimTo
                        )
                        .stroke(
                            self.loaderColor,
                            style: StrokeStyle(
                                lineWidth: 6,
                                lineCap: .round
                            )
                        )
                        .frame(width: 72, height: 72)
                        .rotationEffect(.degrees(-90))
                        .onChange(of: self.shutterProcessing){ _ in
                            self.shutterTrimFrom = 0
                            self.shutterTrimTo = 0
                            self.shutterProcessing = false
                            withAnimation(
                                Animation
                                    .timingCurve(0.15, 0.15, 0.25, 1, duration: 1)
                            ){
                                self.shutterTrimFrom = 0
                                self.shutterTrimTo = 1
                            }
                            withAnimation(
                                Animation
                                    .timingCurve(0.15, 0.15, 0.25, 1, duration: 1)
                                    .delay(1)
                            ){
                                self.shutterTrimFrom = 1
                                self.shutterTrimTo = 1
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                self.shutterProcessing = true
                            }
                        }
                        .onAppear{
                            self.shutterProcessing = true
                        }
                }
                    .opacity((self.autoCaptureEnabled || self.loading) ? 1 : 0)
            )
    }
}

//MARK: Swift UI
struct OCRScanView: View {
    @EnvironmentObject var Store: ApplicationStore
    @EnvironmentObject var Router: RoutingController
    @EnvironmentObject var Error: ErrorHandlingService
    @StateObject var model: CameraViewController = CameraViewController()
    
    @State private var boxes: Array<DetectedObject> = []
    
    @State private var autoCaptureEnabled: Bool = true
    @State private var holdingProgress: CGFloat = 0
    @State private var globalFrame: CGRect = .zero
    @State private var maskFrame: CGRect = .zero
    @State private var capturing: Bool = false //If document found & capturing in progress
    @State private var fileSelection: Bool = false
    
    @State private var loading: Bool = false
    @State private var captured: Bool = false
    
    @State private var result: OCRScanView.OCRDecodeResult? = nil
    @State private var ocrResult: KycpService.OCRDecodeResponse.OCRDecodeResultExtended? = nil
    
    //Declare timers
    @State private var captureTimer: Publishers.Autoconnect<Timer.TimerPublisher>?
    @State private var lostTask: Task<Bool, any Error>?
    @State private var cameraError: CameraViewService.CameraViewServiceError? = .init(code: .notPermitted, message: "")
    @State private var submitTask: Task<Bool, any Error>?
    
    var body: some View{
        ZStack{
            GeometryReader{ geometry in
                ZStack{
                    VStack(spacing:0){
                        CameraView(
                            boxes: self.$boxes,
                            frame: self.$globalFrame,
                            mask: self.$maskFrame,
                            isCapturing: self.$capturing,
                            detectObjectsEnabled: self.$autoCaptureEnabled
                        )
                            .zIndex(1)
                            .edgesIgnoringSafeArea(.all)
                            .ignoresSafeArea()
                            .background(
                                Color.black
                            )
                            .environmentObject(self.model)
                            .onAppear {
                                Task{
                                    do{
                                        try await self.model.setup()
                                        self.cameraError = nil
                                    }catch let error{
                                        if let error = error as? CameraViewService.CameraViewServiceError{
                                            self.cameraError = error
                                        }
                                    }
                                }
                                let frame = geometry.frame(in: .global)
                                self.globalFrame = CGRect(
                                    x: 0,
                                    y: 0,
                                    width: frame.width + geometry.safeAreaInsets.leading + geometry.safeAreaInsets.trailing,
                                    height: frame.height + geometry.safeAreaInsets.top + geometry.safeAreaInsets.bottom
                                )
                            }.onChange(of: geometry.size) { newSize in
                                let frame = geometry.frame(in: .global)
                                self.globalFrame = CGRect(
                                    x: 0,
                                    y: 0,
                                    width: frame.width + geometry.safeAreaInsets.leading + geometry.safeAreaInsets.trailing,
                                    height: frame.height + geometry.safeAreaInsets.top + geometry.safeAreaInsets.bottom
                                )
                            }
                    }
                    .overlay(
                        ZStack{
                            if (self.model.photo != nil){
                                Image(uiImage: UIImage(data: self.model.photo!) ?? UIImage())
                                    .resizable()
                                    .scaledToFill()
                                    .onAppear{
                                        Task{
                                            do{
                                                try await self.submit()
                                            }catch let error{
                                                self.loading = false
                                            }
                                        }
                                    }
                            }
                        }
                    )
                    .overlay(
                        VStack(spacing:0){
                            self.header
                                .background(Color.black)
                            GeometryReader{ shape in
                                ZStack{
                                    VStack{
                                        GeometryReader{ area in
                                            HStack{
                                                Spacer()
                                            }
                                            Spacer()
                                            .onAppear {
                                                self.maskFrame = area.frame(in: .global)
                                            }.onChange(of: area.size) { newSize in
                                                self.maskFrame = area.frame(in: .global)
                                            }
                                        }
                                    }
                                    .background(Color.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                    .padding(.horizontal, 24)
                                    .overlay(
                                        ZStack{
                                            VStack{
                                                HStack{
                                                    Spacer()
                                                }
                                                Spacer()
                                            }
                                            .background(self.outlineColor)
                                            .clipShape(RoundedRectangle(cornerRadius: 16))
                                            .padding(.horizontal, 24)
                                        }
                                    )
                                }
                                    .edgesIgnoringSafeArea(.all)
                                    .ignoresSafeArea()
                                    .background(Color.black)
                                    .mask(
                                        CameraViewMask(in: CGRect(
                                            x: 0,
                                            y: 0,
                                            width: shape.size.width,
                                            height: shape.size.height
                                        ))
                                        .fill(
                                            style: FillStyle(eoFill: true)
                                        )
                                    )
                            }
                            .coordinateSpace(name: "mask")
                            .overlay(
                                ZStack{
                                    self.toast
                                }
                                , alignment: .bottom
                            )
                            self.footer
                                .background(Color.black)
                        }
                    )
                }
                .overlay(
                    ZStack{
                        #if DEBUG
                        ForEach(self.boxes, id: \.id){ box in
                            Rectangle()
                                .stroke(box.color, style: .init(lineWidth: 2))
                                .frame(width: box.boundingBox.width, height: box.boundingBox.height)
                                .offset(
                                    x: box.boundingBox.minX,
                                    y: box.boundingBox.minY - geometry.safeAreaInsets.top
                                )
                        }
                        #endif
                    },
                    alignment: .topLeading
                )
                .overlay(
                    ZStack{
                        if (self.cameraError != nil){
                            self.issuePage
                        }
                    }
                )
            }
            .coordinateSpace(name: "global")
            .onChange(of: self.capturing){ _ in
                //Act as PWM, if capturing HIGH - calculate capture time, otherwise reset
                if (self.lostTask?.isCancelled == false){
                    self.lostTask?.cancel()
                }
                //Reset timer
                self.captureTimer?.upstream.connect().cancel()
                self.captureTimer = nil
                
                Task{
                    if (!self.capturing){
                        //Check if after x seconds capturing still false
                        self.lostTask = Task.detached(priority: .background){
                            try await Task.sleep(nanoseconds: 500_000_000)
                            return await self.capturing
                        }
                        
                        do{
                            let result = try await self.lostTask?.value
                            if (result == nil || !result!){
                                self.holdingProgress = 0
                            }
                        }
                    }else{
                        //Increase holding time
                        self.captureTimer = Timer.publish(every: 0.2, on: .main, in: .common).autoconnect()
                    }
                }
            }
            .onChange(of: self.autoCaptureEnabled){ _ in
                if (!self.autoCaptureEnabled){
                    self.boxes = []
                    self.holdingProgress = 0
                    
                    if (self.lostTask?.isCancelled == false){
                        self.lostTask?.cancel()
                    }
                    
                    //Reset timer
                    self.captureTimer?.upstream.connect().cancel()
                    self.captureTimer = nil
                }
            }
            if (self.captureTimer != nil){
                EmptyView()
                    .onReceive(self.captureTimer!, perform: { _ in
                        self.holdingProgress += 0.2
                        if (self.holdingProgress >= 1){
                            self.holdingProgress = 1
                            
                            self.captureTimer?.upstream.connect().cancel()
                            self.captureTimer = nil
                            
                            if (self.lostTask?.isCancelled == false){
                                self.lostTask?.cancel()
                            }
                            
                            self.capture()
                        }
                    })
            }
            //MARK: File Uploader
            MediaUploaderContainer(
                isPresented: self.$fileSelection,
                onImport: { url in
                    do{
                        url.startAccessingSecurityScopedResource()
                        let data = try Data(contentsOf: url)
                        self.model.photo = data
                    }catch let error{
                        DispatchQueue.main.async {
                            self.fileSelection = false
                        }
                        self.Error.handle(error)
                    }
                },
                onError: { error in
                    DispatchQueue.main.async {
                        self.fileSelection = false
                    }
                    self.Error.handle(error)
                }
            )
        }
        .navigationBarBackButtonHidden(true)
        .navigationTitle("")
        .background(Color.black)
    }
}

extension OCRScanView{
    var header: some View{
        HStack{
            Button{
                self.Router.stack.removeLast()
                self.Router.goTo(CreatePersonView(), routingType: .backward)
            } label:{
                ZStack{
                    Image("arrow-left")
                        .foregroundColor(Color.white)
                }
                .frame(width: 24, height: 24)
            }
            Spacer()
            ZStack{
                
            }
            .disabled(self.loading)
        }
        .padding(.horizontal,24)
        .padding(.vertical, 16)
        .padding(.bottom, 4)
        .overlay(
            VStack{
                Button{
                    self.autoCaptureEnabled.toggle()
                } label:{
                    HStack(spacing:5){
                        ZStack{
                            
                        }
                            .frame(width: 11, height: 11)
                            .background(self.autoCaptureEnabled ? Color.get(.Active) : Color.get(.Ocean))
                            .clipShape(Circle())
                        Text("Auto-capture \(self.autoCaptureEnabled ? "on" : "off")")
                            .font(.subheadline)
                            .foregroundColor(Color.white)
                    }
                        .padding(.vertical, 5)
                        .padding(.horizontal, 12)
                        .background(Color("ToolTip"))
                        .clipShape(RoundedRectangle(cornerRadius: 70))
                }
                .disabled(self.loading)
            }
        )
    }
    
    var captureDisabled: Bool{
        if case .submit = self.result{
            return false
        }
        if (self.loading){
            return true
        }
        if (self.autoCaptureEnabled){
           return true
        }
        return false
    }
    
    var footer: some View{
        HStack{
            Spacer()
            Button{
                self.selectFromPhotos()
            } label:{
                ZStack{
                    Image("gallery")
                        .foregroundColor(Color.white)
                }
                    .frame(width: 24, height: 24)
                    .padding(20)
                    .clipShape(Circle())
            }
                .disabled(self.loading)
            Spacer()
            Button{
                self.capture()
            } label:{
                OCRShutterButton(
                    autoCaptureEnabled: self.$autoCaptureEnabled,
                    loading: self.$loading,
                    result: self.$result
                )
            }
                .disabled(self.captureDisabled)
            Spacer()
            Button{
                self.model.toggleFlashlight()
            } label:{
                ZStack{
                    Image("flash")
                        .foregroundColor(Color.white)
                }
                    .frame(width: 24, height: 24)
                    .padding(20)
                    .clipShape(Circle())
            }
                .disabled(self.loading)
            Spacer()
        }
        .padding(.horizontal,24)
        .padding(.vertical, 12)
        .padding(.top, 12)
    }
    
    var toastMessage: String?{
        withAnimation{
            if case .failed(let error) = self.result{
                return error.message
            }
            if case .submit = self.result{
                return "If unclear, retake the photo."
            }
            if case .processing = self.result{
                return "Your ID verification is in progress, please wait..."
            }
            if case .success(let type) = self.result{
                if (self.documentSecondSideRequired){
                    return "Thank you. Now please turn your ID document over to scan the reverse side."
                }
                return nil
            }
            if (self.autoCaptureEnabled){
                if (self.holdingProgress > 0){
                    return "Scanning your ID document, hold your phone steady."
                }
                return "Looking for your ID document."
            }
            return "Ensure good lighting and clear visibility of all text before capturing your ID document."
        }
    }
    
    var toast: some View{
        VStack{
            if case .success(let type) = self.result{
                if (self.documentSecondSideRequired){
                    VStack(alignment: .center){
                        Image("flip-card")
                            .foregroundColor(Color.white)
                    }
                    .padding(.bottom,10)
                    .transition(.asymmetric(insertion: .scale, removal: .opacity))
                }
            }
            HStack{
                if (self.toastMessage != nil){
                    VStack(alignment: .center){
                        Text(self.toastMessage!)
                            .foregroundColor(Color.white)
                            .font(.body)
                            .multilineTextAlignment(.center)
                    }
                    .padding(10)
                    .background(Color.black.opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .transition(.slide)
                }
            }
        }
        .padding(.vertical, 26)
        .padding(.horizontal, 40)
    }
    
    var outlineColor: Color{
        if case .processing = self.result{
            return Color.get(.Pending)
        }
        if case .submit = self.result{
            return Color.get(.Pending)
        }
        if case .failed(let error) = self.result{
            return Color.get(.Danger)
        }
        if case .success(let type) = self.result{
            return Color.get(.Active)
        }
        if (self.holdingProgress > 0){
            return Color.get(.Pending)
        }
        return Color.white.opacity(0)
    }
    
    var issuePage: some View{
        ZStack{
            VStack(alignment: .center){
                HStack{
                    Button{
                        self.Router.stack.removeLast()
                        self.Router.goTo(CreatePersonView(), routingType: .backward)
                    } label:{
                        ZStack{
                            Image("arrow-left")
                                .foregroundColor(Color.white)
                        }
                        .frame(width: 24, height: 24)
                    }
                    Spacer()
                    ZStack{
                        
                    }
                    .disabled(self.loading)
                }
                .padding(.horizontal,24)
                .padding(.vertical, 16)
                .padding(.bottom, 4)
                Spacer()
                ZStack{
                    Image("errorLarge")
                }
                    .padding(.horizontal, 30)
                    .padding(.bottom, 32)
                VStack(alignment: .center, spacing: 10){
                    Text("Camera permission required")
                        .multilineTextAlignment(.center)
                        .foregroundColor(Color.white)
                        .font(.title2)
                    VStack(alignment: .center, spacing: 26){
                        Text("\(Whitelabel.BrandName()) services needs to access your device's camera to scan a document.")
                            .multilineTextAlignment(.center)
                            .foregroundColor(Color.white)
                        Text("To enable, please grant camera permission to \(Whitelabel.BrandName()) services in Settings.")
                            .multilineTextAlignment(.center)
                            .foregroundColor(Color.white)
                    }
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 36)
                HStack(spacing: 20){
                    Button{
                        UIApplication.shared.open(
                            URL(string: UIApplication.openSettingsURLString)!,
                            options: [:],
                            completionHandler: nil
                        )
                    } label: {
                        HStack{
                            Spacer()
                            Text("Go to Settings")
                            Spacer()
                        }
                    }
                    .buttonStyle(.primary())
                }
                .padding(.horizontal, 30)
            }
        }.background(Color.black)
    }
}

//MARK: - Methods
extension OCRScanView{
    func CameraViewMask(in rect: CGRect) -> Path {
        var shape = Rectangle().path(in: rect)
        shape.addPath(RoundedRectangle(cornerRadius: 12).path(in: CGRect(
            x: rect.minX + 30,
            y: rect.minY + 6,
            width: rect.width - 60,
            height: rect.height - 12)
        ))
        return shape
    }
    
    func capture(){
        if case .submit = self.result{
            //Retake photo
            self.reset()
            return;
        }
        
        //Capture initial image
        self.model.capture()
    }
    
    /**
     Reset state to initial
     */
    func reset(){
        self.model.photo = nil
        self.loading = false
        withAnimation{
            self.result = nil
        }
        self.holdingProgress = 0
        self.captureTimer?.upstream.connect().cancel()
        self.captureTimer = nil
        
        if (self.lostTask?.isCancelled == false){
            self.lostTask?.cancel()
        }
        
        if (self.submitTask?.isCancelled == false){
            self.submitTask?.cancel()
            self.submitTask = nil
        }
    }
    
    var documentTypesRequiresBothSides: Array<String>{
        return [
            "idDocument.driverLicense",
            "idDocument.nationalIdentityCard",
            "idDocument.residencePermit"
        ]
    }
    
    var documentSecondSideRequired: Bool{
        switch(self.result){
        case .decoded(type: let type), .success(type: let type):
            return self.documentTypesRequiresBothSides.contains(where: {$0.lowercased() == type.lowercased()})
            break;
        default:
            return false;
        }
        return false;
    }
    
    func submit() async throws{
        if (self.model.photo != nil && self.Store.user.person != nil){
            self.loading = true
            withAnimation{
                self.result = .submit
            }
            //Create task
            if (self.submitTask?.isCancelled == false){
                self.submitTask?.cancel()
            }
            
            Task{
                //Check if after x seconds capturing still false
                self.submitTask = Task.detached(priority: .background){
                    try await Task.sleep(nanoseconds: 5_000_000_000)
                    return try await self.process()
                }
                do{
                    let _ = try await self.submitTask!.value
                }catch let error{
                    if let error = error as? OCRResultError{
                        withAnimation{
                            self.result = .failed(error: error)
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3){
                            self.reset()
                        }
                    }
                    self.loading = false
                    throw error
                }
            }
        }
    }
    
    func process() async throws -> Bool{
        withAnimation{
            self.result = .processing
        }
        let jpg = UIImage(data:self.model.photo!)!.jpegData(compressionQuality: 0.7)
        let attachment = FileAttachment(data: jpg!)
        attachment.fileType = .jpg
        attachment.fileName = "ocr.jpg"
        attachment.key = randomString(length: 6)
        
        //MARK: Ask KYC service to get document data
        let job = try await services.kycp.uploadOCR(
            attachment,
            entityId: self.Store.user.person!.id,
            entityType: "person"
        )
        //MARK: Wait until response
        var result: KycpService.OCRDecodeResponse.OCRDecodeResult? = nil
        
        while(result == nil){
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            do{
                var response = try await services.kycp.getOCR(job.value)
                if (response.value != nil){
                    result = response.value!
                }
            }catch let error{
                result = .init(documentType: "idDocument.nationalIdentityCard")
                throw OCRResultError(message: "The ID document you’ve provided was not recognised. Please submit a photo of a valid document, such as a passport or driver's license.")
            }
        }
        
        if (result != nil){
            //If document doesnt contain name - throw error
            if (self.ocrResult == nil || self.ocrResult?.firstName?.id == nil){
                if (result!.firstName == nil){
                    throw OCRResultError(message: "The ID document you’ve provided was not recognised. Please submit a photo of a valid document, such as a passport or driver's license.")
                }
            }
            
            //Check if this second page
            var isSecondPage = true
            if (self.documentTypesRequiresBothSides.contains(where: {$0.lowercased() == result!.documentType?.lowercased()})){
                isSecondPage = self.ocrResult?.firstName != nil
            }
            if (self.ocrResult != nil && (result!.firstName != nil || result!.lastName != nil)){
                throw OCRResultError(message: "The ID document you’ve provided was not recognised. Please submit a photo of a valid document, such as a passport or driver's license.")
            }
            
            //Just popup existing model
            if (self.ocrResult == nil){
                self.ocrResult = .init()
            }
            if (result?.dateOfBirth != nil){
                self.ocrResult!.dateOfBirth = .init(
                    value: result?.dateOfBirth ?? self.ocrResult?.dateOfBirth?.value ?? "",
                    id: result?.id ?? ""
                )
            }
            if (result?.dateOfExpiration != nil){
                self.ocrResult!.dateOfExpiration = .init(
                    value: result?.dateOfExpiration ?? self.ocrResult?.dateOfExpiration?.value ?? "",
                    id: result?.id ?? ""
                )
            }
            if (result?.dateOfIssue != nil){
                self.ocrResult!.dateOfIssue = .init(
                    value: result?.dateOfIssue ?? self.ocrResult?.dateOfIssue?.value ?? "",
                    id: result?.id ?? ""
                )
            }
            if (result?.documentType != nil){
                self.ocrResult!.documentType = .init(
                    value: result?.documentType ?? self.ocrResult?.documentType?.value ?? "",
                    id: result?.id ?? ""
                )
            }
            if (result?.firstName != nil){
                self.ocrResult!.firstName = .init(
                    value: result?.firstName ?? self.ocrResult?.firstName?.value ?? "",
                    id: result?.id ?? ""
                )
            }
            if (result?.gender != nil){
                self.ocrResult!.gender = .init(
                    value: result?.gender ?? self.ocrResult?.gender?.value ?? "",
                    id: result?.id ?? ""
                )
            }
            if (result?.lastName != nil){
                self.ocrResult!.lastName = .init(
                    value: result?.lastName ?? self.ocrResult?.lastName?.value ?? "",
                    id: result?.id ?? ""
                )
            }
            if (result?.middleName != nil){
                self.ocrResult!.middleName = .init(
                    value: result?.middleName ?? self.ocrResult?.middleName?.value ?? "",
                    id: result?.id ?? ""
                )
            }
            if (result?.nationality != nil){
                self.ocrResult!.nationality = .init(
                    value: result?.nationality ?? self.ocrResult?.nationality?.value ?? "",
                    id: result?.id ?? ""
                )
            }
            if (result?.placeOfBirth != nil){
                self.ocrResult!.placeOfBirth = .init(
                    value: result?.placeOfBirth ?? self.ocrResult?.placeOfBirth?.value ?? "",
                    id: result?.id ?? ""
                )
            }
            if (result?.id != nil){
                self.ocrResult!.id = .init(
                    value: result?.id ?? self.ocrResult?.id?.value ?? "",
                    id: result?.id ?? ""
                )
            }
            
            withAnimation{
                self.result = .success(type: result!.documentType ?? "")
            }
            DispatchQueue.main.asyncAfter(deadline: .now()+3){
                self.model.photo = nil
                if (!isSecondPage){
                    withAnimation{
                        self.result = .decoded(type: result!.documentType ?? "")
                    }
                }else{
                    withAnimation{
                        self.result = .done
                    }
                    self.model.disableFlashlight()
                    self.Router.goTo(ConfirmPersonDetailsView(ocrResult: self.ocrResult))
                }
            }
        }
        self.loading = false
        
        return false
    }
    
    func selectFromPhotos(){
        self.fileSelection = true
    }
}

extension OCRScanView{
    enum OCRDecodeResult{
        /**
         Document in process
         */
        case processing
        /** Document captured and await for submit*/
        case submit
        /** Document parsed and decoded*/
        case success(type: String)
        /** Decoded document result*/
        case decoded(type: String)
        /** Failure to decode document*/
        case failed(error: OCRScanView.OCRResultError)
        /** Document flow done*/
        case done
    }
    
    struct OCRResultError: Error, Decodable{
        var message: String
    }
}

struct OCRScanView_Previews: PreviewProvider {
    static var previews: some View {
        OCRScanView()
    }
}
