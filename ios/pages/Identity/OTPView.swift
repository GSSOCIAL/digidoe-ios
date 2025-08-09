//
//  OTPView.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 10.03.2024.
//

import Foundation
import SwiftUI
import UIKit
import Combine

extension OTPView{
    enum OTPOperationResult{
        case confirmed(String, String, ProfileService.ConfirmationType)
        case rejected(String, String?, ProfileService.ConfirmationType?)
    }
    
    func startKeyComplexTick(){
        self.shakeTimer = Timer.publish(every: 10, on: .main, in: .common).autoconnect()
    }
}

struct OTPView: View {
    @EnvironmentObject var Store: ApplicationStore
    @EnvironmentObject var Error: ErrorHandlingService
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    ///OperationId
    @Binding public var operationId: String
    
    ///Called when OTP passed
    public var onVerify: (String,String,ProfileService.ConfirmationType)->Void = { (operationId, sessionId, type) in }
    
    ///Called when OTP failed or rejected
    public var onCancel: (String,String?,ProfileService.ConfirmationType?)->Void = { (operationId, sessionId, type) in }
    public var onClose: ()->Void = {}
    
    @State private var loading: Bool = false
    @State private var scrollOffset : Double = 0
    
    ///OTP Code length
    @State private var codeLength: Int = 6
    
    ///OTP Code
    @State private var code: String = ""
    
    ///Operation session id
    @State private var sessionId: String = ""
    
    ///Confirmation id
    @State private var sessionReplaced: Bool = false
    
    ///Flag, shows that code is failed
    @State private var isFailed: Bool = false
    
    ///Countdown
    @State private var contactName: String? = ""
    @State private var remainingCount: Int = 0
    @State private var codeType: ProfileService.ConfirmationType? = nil
    @State private var iteration: Int = 0
    @State private var countdownDelay: Int = 0
    @State private var timer: Publishers.Autoconnect<Timer.TimerPublisher>?
    @State private var pushStatusTimer: Publishers.Autoconnect<Timer.TimerPublisher>?
    @State private var sessionExpired: Bool = false
    @State private var notificationsAttempts: Int = 5
    
    //Animators
    @State private var animationDidAppear: Bool = false
    @State private var animationDidAppearB: Bool = false
    @State private var animationDidAppearC: Bool = false
    @State private var shakeEffect: Int = 0
    @State private var shakeTimer: Publishers.Autoconnect<Timer.TimerPublisher>?
    
    @State private var result: OTPOperationResult? = nil
    
    ///Masked user email
    private var userEmailMasked: String{
        if (self.contactName != nil){
            return self.contactName!
        }
        var userEmail = self.Store.user.email ?? ""
        
        //Mask before @ symbol, split string by @ char
        var emailParts = userEmail.components(separatedBy: "@")
        //Output
        var completedEmailParts: Array<String> = []
        
        //If email splitted
        if (emailParts.count > 0){
            //Take first 2 char of email & add 6 stars
            completedEmailParts.append([String(emailParts[0].prefix(2)),"********"].joined(separator: ""))
            if (emailParts.count > 1){
                //Append email domain
                completedEmailParts.append(String(emailParts[1]))
            }
        }
        
        return completedEmailParts.joined(separator: "@")
    }
    
    ///Start session
    func initiate() async throws{
        do{
            self.loading = true
            self.code = ""
            self.pushStatusTimer = nil
            self.timer = nil
            
            let response = try await services.profiles.sessionInitiate(self.operationId)
            self.contactName = response.value.contactDisplayName
            self.sessionId = response.value.id
            self.codeType = response.value.type
            self.countdownDelay = response.value.resendDelay
            self.remainingCount = self.countdownDelay
            
            //If session with push confirmation - check each N secs for operation status
            if (self.codeType == .Push){
                self.pushStatusTimer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()
            }else if(self.codeType == .OtpEmail){
                self.timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
            }
            
            self.loading = false
        }catch(let error){
            if let isExpired = error as? ProfileService.SessionOperationNotFoundError{
                self.sessionExpired = true
                return;
            }
            self.loading = false
            throw error
        }
    }
    
    ///Check push status
    func checkCodeStatus() async throws{
        Task{
            do{
                if (self.loading){
                    return
                }
                let response = try await services.profiles.sessionStatus(operationId: self.operationId, sessionId: self.sessionId)
                
                if (response.value == .Confirmed){
                    self.result = .confirmed(self.operationId, self.sessionId, self.codeType ?? .Push)
                    //self.onVerify(self.operationId, self.sessionId, self.codeType ?? .Push)
                }else if(response.value == .Rejected){
                    self.result = .rejected(self.operationId, self.sessionId, self.codeType ?? .Push)
                    //self.onCancel(self.operationId, self.sessionId, self.codeType)
                }
            }catch(let error){
                if let isExpired = error as? ProfileService.SessionOperationNotFoundError{
                    self.sessionExpired = true
                    return;
                }
                self.loading = false
                throw error
            }
        }
    }
    
    ///Manually check entered code
    func verifyCode() async throws{
        self.loading = true
        do{
            let response = try await services.profiles.sessionConfirm(operationId: self.operationId, sessionId: self.sessionId, code: self.code)
            if (response.value.state == .Confirmed){
                self.result = .confirmed(self.operationId, self.sessionId, self.codeType ?? .Push)
                //self.onVerify(self.operationId, self.sessionId, response.value.type)
            }else{
                self.code = ""
                self.isFailed = true
                
                //Id replaced, new one
                if (self.sessionId != response.value.id){
                    //Replace data
                    self.code = ""
                    self.pushStatusTimer = nil
                    self.timer = nil
                    
                    self.sessionReplaced = true
                    
                    self.contactName = response.value.contactDisplayName
                    self.sessionId = response.value.id
                    self.codeType = response.value.type
                    self.countdownDelay = response.value.resendDelay
                    self.remainingCount = self.countdownDelay
                    
                    //If session with push confirmation - check each N secs for operation status
                    if (self.codeType == .Push){
                        self.pushStatusTimer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()
                    }else if(self.codeType == .OtpEmail){
                        self.timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
                    }
                }
            }
            
            self.loading = false
        }catch(let error){
            self.code = ""
            if let isExpired = error as? ProfileService.SessionOperationNotFoundError{
                self.sessionExpired = true
                self.loading = false
                return;
            }
            DispatchQueue.main.async{
                self.isFailed = true
                self.loading = false
            }
        }
    }
    
    ///Manually reject OTP
    func rejectOTP() async throws{
        Task{
            do{
                self.loading = true
                let response = try await services.profiles.sessionReject(operationId: self.operationId, sessionId: self.sessionId, code: "")
                self.loading = false
                self.onCancel(self.operationId, self.sessionId, self.codeType)
            }catch(let error){
                self.loading = false
                self.onCancel(self.operationId, self.sessionId, self.codeType)
                throw error
            }
        }
    }
    
    ///Handled when session expired
    func handleExpiredSession() async throws{
        self.loading = true
        self.sessionExpired = false
        self.loading = false
        self.onCancel(self.operationId, self.sessionId, nil)
    }
    
    var hasResult: Binding<Bool>{
        Binding(
            get: {
                return self.result != nil
            }, set: { _ in }
        )
    }
    ///View for OTP if confirmation is email
    var emailOTPView: some View{
        VStack(spacing:24){
            VStack(spacing: 8){
                Text("Enter a One-time Password")
                    .font(.largeTitle.bold())
                    .foregroundColor(Color.get(.Text))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .multilineTextAlignment(.leading)
                Text("For your security, we have sent a one-time password to the following email:")
                    .font(.caption)
                    .foregroundColor(Color.get(.LightGray))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .multilineTextAlignment(.leading)
                HStack{
                    if (!self.userEmailMasked.isEmpty){
                        //Contact details
                        Button{
                            //No actions
                        } label:{
                            Text(self.userEmailMasked)
                        }
                        .buttonStyle(.contact(style:.primary))
                    }
                    Spacer()
                }
            }
            VStack{
                //Show code
                OTPField(value: self.$code, isFailed: self.$isFailed, length: self.codeLength)
                    .disabled(self.loading)
                    .onChange(of: self.code){ code in
                        self.isFailed = false
                    }
            }
            VStack(spacing:8){
                if (self.isFailed){
                    Text("You have entered the wrong code, please try again")
                        .font(.caption)
                        .foregroundColor(Color.get(.Danger))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .multilineTextAlignment(.leading)
                }
                if (self.timer != nil){
                        Group{
                            Text("Haven't received your code yet? You can retry in ")
                                .foregroundColor(Color.get(.Text))
                            + Text(String(self.remainingCount).toTime())
                                .foregroundColor(Color.get(.Primary))
                        }
                        .font(.caption)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .multilineTextAlignment(.leading)
                        .onReceive(self.timer!, perform: { time in
                            if (self.remainingCount > 1){
                                self.remainingCount -= 1
                            }else{
                                self.timer = nil
                            }
                        })
                }else{
                    HStack{
                        if (!self.sessionId.isEmpty){
                            Button{
                                Task{
                                    do{
                                        try await self.initiate()
                                    }catch(let error){
                                        self.Error.handle(error)
                                        self.loading = false
                                    }
                                }
                            } label:{
                                HStack(spacing:6){
                                    Spacer()
                                    ZStack{
                                        Image("refresh")
                                    }
                                    .frame(width: 18, height: 18)
                                    Text("Resend")
                                    Spacer()
                                }
                            }
                            .buttonStyle(.link())
                            .disabled(self.loading)
                        }
                    }
                }
            }
            Spacer()
            VStack(spacing:12){
                Text("Make sure you have entered the correct email address. Also check your spam folder")
                    .font(.caption)
                    .foregroundColor(Color.get(.LightGray))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .multilineTextAlignment(.leading)
                Button{
                    Task{
                        do{
                            try await self.verifyCode()
                        }catch(let error){
                            self.loading = false
                            self.Error.handle(error)
                        }
                    }
                } label: {
                    HStack{
                        Spacer()
                        Text("Continue")
                        Spacer()
                    }
                }
                .buttonStyle(.primary())
                .disabled(self.code.count < self.codeLength || self.loading)
            }
        }
        .padding(.horizontal, 16)
    }
    
    ///View for OTP if confirmation is push
    var pushOTPView: some View{
        VStack(spacing:24){
            Spacer()
            VStack(spacing: 12){
                ZStack{
                    Image("complexSecurityFill")
                        .scaleEffect(self.animationDidAppear ? 1 : 0)
                    ZStack{
                        Image("complexSecurityPrimary")
                            .scaleEffect(self.animationDidAppearB ? 1 : 0)
                    }
                    .overlay(
                        Image("complexSecuritySecondary")
                            .offset(x: 50, y: 0)
                            .scaleEffect(self.animationDidAppearC ? 1 : 0)
                            .modifier(Shake(animatableData: CGFloat(self.shakeEffect)))
                        , alignment: .bottomTrailing
                    )
                        .offset(x: -10)
                    if (self.pushStatusTimer != nil){
                        EmptyView()
                            .onReceive(self.pushStatusTimer!, perform: { _ in
                                Task{
                                    do{
                                        try await self.checkCodeStatus()
                                    }catch(let error){
                                        self.Error.handle(error)
                                    }
                                }
                            })
                    }
                    if (self.shakeTimer != nil){
                        EmptyView()
                            .onReceive(self.shakeTimer!, perform: { _ in
                                withAnimation(.interpolatingSpring(duration: 0.2)){
                                    self.shakeEffect += 1;
                                }
                            })
                    }
                }
                VStack(spacing:4){
                    Text("Please confirm the operation on your trusted device to continue.")
                        .font(.body.weight(.medium))
                        .foregroundColor(Color.get(.Text))
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                    Button{
                        Task{
                            do{
                                //Initiate session
                                try await self.initiate()
                            }catch(let error){
                                self.loading = false
                                self.Error.handle(error)
                            }
                        }
                    } label: {
                        Text("If trusted is unavailable, please click ")
                            .foregroundColor(self.loading ? Color.get(.DisabledText) : Color.get(.LightGray)) +
                        Text("here")
                            .foregroundColor(self.loading ? Color.get(.DisabledText) : Whitelabel.Color(.Primary))
                    }
                    .font(.caption)
                    .disabled(self.loading)
                }
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .onAppear{
            withAnimation(.interactiveSpring(duration:0.6)){
                self.animationDidAppear = true
            }
            withAnimation(.interactiveSpring(duration:0.4)){
                self.animationDidAppearB = true
            }
            withAnimation(.interactiveSpring(duration:0.6)){
                self.animationDidAppearC = true
            }
            self.startKeyComplexTick()
        }
    }
    
    var body: some View {
        ApplicationNavigatorContainerView{
            GeometryReader{ geometry in
                ZStack{
                    ScrollView{
                        VStack(spacing: 0){
                            VStack(spacing: 0){
                                HStack{
                                    Spacer()
                                    Button{
                                        Task{
                                            do{
                                                try await self.rejectOTP()
                                            }catch(let error){
                                                self.loading = false
                                                self.Error.handle(error)
                                            }
                                        }
                                    } label: {
                                        Text("Cancel")
                                    }
                                    .buttonStyle(.link())
                                    .disabled(self.loading)
                                }
                                .padding(.horizontal, 16)
                            }
                            .padding(.bottom, 16)
                            .offset(
                                y: self.scrollOffset < 0 ? self.scrollOffset : 0
                            )
                            
                            if (self.codeType == .OtpEmail){
                                self.emailOTPView
                            }else{
                                self.pushOTPView
                            }
                            
                        }
                        .background(GeometryReader {
                            Color.clear.preference(key: RefreshViewOffsetKey.self, value: -$0.frame(in: .named("scroll")).origin.y)
                        })
                        .onPreferenceChange(RefreshViewOffsetKey.self) { position in
                            self.scrollOffset = position
                        }
                        .frame(
                            maxWidth: .infinity,
                            minHeight: geometry.size.height - geometry.safeAreaInsets.bottom
                        )
                        .onAppear{
                            Task{
                                do{
                                    //Initiate session
                                    try await self.initiate()
                                }catch(let error){
                                    self.loading = false
                                    self.Error.handle(error)
                                }
                            }
                        }
                    }
                    .coordinateSpace(name: "scroll")
                    
                    //MARK: Popup
                    PresentationSheet(isPresented: self.$sessionExpired){
                        VStack(spacing:24){
                            ZStack{
                                Image("danger")
                            }
                            .frame(width: 80, height: 80)
                            VStack(spacing: 6){
                                Text("Operation expired")
                                    .font(.body.bold())
                                    .foregroundColor(Color.get(.Text))
                                Text("The operation time has expired. Please initiate the operation again.")
                                    .multilineTextAlignment(.center)
                                    .font(.caption)
                                    .foregroundColor(Color.get(.LightGray))
                            }
                            HStack(spacing: 16){
                                Button{
                                    Task{
                                        do{
                                            try await self.handleExpiredSession()
                                        }catch(let error){
                                            self.loading = false
                                            self.Error.handle(error)
                                        }
                                    }
                                } label:{
                                    HStack{
                                        Spacer()
                                        Text("Ok")
                                        Spacer()
                                    }
                                }
                                .buttonStyle(.secondary())
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 24)
                        .padding(.bottom, geometry.safeAreaInsets.bottom)
                    }
                    PresentationSheet(isPresented: self.$sessionReplaced){
                        VStack(spacing:24){
                            ZStack{
                                Image("danger")
                            }
                            .frame(width: 80, height: 80)
                            VStack(spacing: 6){
                                Text("Attempt limit exceeded")
                                    .font(.body.bold())
                                    .foregroundColor(Color.get(.Text))
                                Text("You've exceeded the attempt limit. Please try again using a new one-time password we have sent to your email.")
                                    .multilineTextAlignment(.center)
                                    .font(.caption)
                                    .foregroundColor(Color.get(.LightGray))
                            }
                            HStack(spacing: 16){
                                Button{
                                    Task{
                                        do{
                                            self.sessionReplaced = false
                                        }catch(let error){
                                            self.loading = false
                                            self.Error.handle(error)
                                        }
                                    }
                                } label:{
                                    HStack{
                                        Spacer()
                                        Text("Ok")
                                        Spacer()
                                    }
                                }
                                .buttonStyle(.secondary())
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 24)
                        .padding(.bottom, geometry.safeAreaInsets.bottom)
                    }
                    PresentationSheet(isPresented: self.hasResult){
                        VStack(spacing:24){
                            switch(self.result){
                            case .confirmed(let operationId,let sessionId,let type):
                                ZStack{
                                    Image("tick-square-large")
                                }
                                .frame(width: 80, height: 80)
                                VStack(spacing: 6){
                                    Text("Operation approved")
                                        .font(.body.bold())
                                        .foregroundColor(Color.get(.Text))
                                }
                                HStack(spacing: 16){
                                    Button{
                                        self.onVerify(operationId, sessionId, type)
                                    } label:{
                                        HStack{
                                            Spacer()
                                            Text("Ok")
                                            Spacer()
                                        }
                                    }
                                    .buttonStyle(.secondary())
                                }
                            case .rejected(let operationId,let sessionId,let type):
                                ZStack{
                                    Image("close-circle-large")
                                }
                                .frame(width: 80, height: 80)
                                VStack(spacing: 6){
                                    Text("Operation rejected")
                                        .font(.body.bold())
                                        .foregroundColor(Color.get(.Text))
                                }
                                HStack(spacing: 16){
                                    Button{
                                        self.onCancel(operationId, sessionId, type)
                                    } label:{
                                        HStack{
                                            Spacer()
                                            Text("Ok")
                                            Spacer()
                                        }
                                    }
                                    .buttonStyle(.secondary())
                                }
                            default:
                                ZStack{
                                    
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 24)
                        .padding(.bottom, geometry.safeAreaInsets.bottom)
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationTitle("")
        .background(Color.get(.Background))
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to:nil, from:nil, for:nil)
        }
        .onReceive(self.Store.$receivedNotification){ _ in
            if (self.Store.receivedNotification == nil){
                return;
            }
            if (self.operationId != self.Store.receivedNotification!.operationId){
                return;
            }
            if (self.sessionId != self.Store.receivedNotification!.sessionId){
                return;
            }
            if (self.Store.receivedNotification!.code == nil){
                return;
            }
            
            Task{
                do{
                    let response = try await services.profiles.sessionConfirm(operationId: self.operationId, sessionId: self.sessionId, code: self.Store.receivedNotification!.code!)
                    
                    if (response.value.state == .Confirmed){
                        self.onVerify(self.operationId, self.sessionId, response.value.type)
                    }
                }catch(let error){
                    
                }
            }
        }
    }
}

struct OTPModifider: ViewModifier{
    @Binding public var isPresented: Bool
    @Binding public var operationId: String
    
    @State public var onVerify: (String,String,ProfileService.ConfirmationType)->Void = { (operationId, sessionId, type) in }
    @State public var onReject: (String,String?,ProfileService.ConfirmationType?)->Void = { (operationId, sessionId, type) in }
    
    @Binding public var operationResult: OTPView.OTPOperationResult?
    
    init(isPresented: Binding<Bool>, operationId: Binding<String>, onVerify: @escaping (String,String,ProfileService.ConfirmationType)->Void, onReject: @escaping (String,String?,ProfileService.ConfirmationType?)->Void){
        self._isPresented = isPresented
        self._operationId = operationId
        self.onVerify = onVerify
        self.onReject = onReject
        self._operationResult = .constant(.rejected("", nil, nil))
    }
    
    init(isPresented: Binding<Bool>, operationId: Binding<String>, operationResult: Binding<OTPView.OTPOperationResult?>){
        self._isPresented = isPresented
        self._operationId = operationId
        self._operationResult = operationResult
    }
    
    //MARK: - Methods
    
    /// Called when OTP operation confirmed
    func operationConfirmed(operationId: String, sessionId: String, type: ProfileService.ConfirmationType){
        self.operationResult = .confirmed(operationId, sessionId, type)
        self.onVerify(operationId, sessionId, type)
        self.isPresented = false
    }
    
    /// Called when OTP operation rejected
    func operationRejected(operationId: String, sessionId: String?, type: ProfileService.ConfirmationType?){
        self.operationResult = .rejected(operationId, sessionId, type)
        self.onReject(operationId, sessionId, type)
        self.isPresented = false
    }
    
    func body(content: Content) -> some View{
        ZStack{
            content
            if (self.isPresented){
                OTPView(operationId: self.$operationId, onVerify: self.operationConfirmed, onCancel: self.operationRejected)
            }
        }
    }
}

extension View{
    /// Create OTP Confirmation screen
    ///
    /// - Parameter isPresented: Determite if OTP confirmation should be shown
    /// - Parameter operationId: Operation identifier
    ///
    /// - Returns: A view with OTP support
    func otp(isPresented: Binding<Bool>, operationId: Binding<String>, onVerify: @escaping (String,String,ProfileService.ConfirmationType)->Void, onReject: @escaping (String,String?,ProfileService.ConfirmationType?)->Void) -> some View{
        modifier(OTPModifider(isPresented: isPresented, operationId: operationId, onVerify: onVerify, onReject: onReject))
    }
    
    func otp(isPresented: Binding<Bool>, operationId: Binding<String>, result: Binding<OTPView.OTPOperationResult?>) -> some View{
        modifier(OTPModifider(isPresented: isPresented, operationId: operationId, operationResult: result))
    }
}

struct OTPViewParent: View{
    @EnvironmentObject var Store: ApplicationStore
    @EnvironmentObject var Error: ErrorHandlingService
    
    //OTP
    @State private var verifyOtp: Bool = false
    @State private var otpOperationId: String = ""
    
    func otpConfirmed(operationId: String, sessionId: String, type: ProfileService.ConfirmationType){
        self.verifyOtp = false
    }
    
    func otpRejected(operationId: String, sessionId: String?, type: ProfileService.ConfirmationType?){
        self.verifyOtp = false
    }
    
    var body: some View{
        /*
        ZStack{
            ScrollView{
                VStack{
                    Spacer()
                    Button{
                        self.verifyOtp = true
                    } label:{
                        Text("Verify")
                    }
                    Spacer()
                }
                .fullScreenCover(isPresented: self.$verifyOtp, content: {
                    OTPView(operationId: self.$otpOperationId, onVerify: self.otpConfirmed, onCancel: self.otpRejected)
                        .environmentObject(self.Error)
                })
            }
        }
         */
        VStack{
            Button("Action"){
                self.verifyOtp = true
            }
        }
        /*
         OTPView(operationId: self.$otpOperationId, onVerify: self.otpConfirmed, onCancel: self.otpRejected)
            .environmentObject(self.Error)
         */
    }
}


struct OTPView_Previews: PreviewProvider {
    static var store: ApplicationStore {
        var store = ApplicationStore()
        return store
    }
    
    static var error: ErrorHandlingService {
        var error = ErrorHandlingService()
        return error
    }
    
    static var previews: some View {
        OTPViewParent()
            .environmentObject(self.store)
            .environmentObject(self.error)
    }
}
