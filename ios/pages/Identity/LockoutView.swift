//
//  LockoutView.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 20.05.2024.
//

import Foundation
import SwiftUI
import UIKit
import Combine
import LocalAuthentication

extension LockoutView{
    enum LockoutResult{
        case success
        case reject
    }
}

struct LockoutView: View {
    @EnvironmentObject var Store: ApplicationStore
    @EnvironmentObject var Error: ErrorHandlingService
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    ///Called when lock passed
    public var onVerify: ()->Void = { }
    
    ///Called when lock failed or rejected
    public var onCancel: ()->Void = { }
    public var onClose: ()->Void = { }
    
    @State private var loading: Bool = false
    @State private var scrollOffset : Double = 0
    
    let service: pin = pin()
    @State private var retry: Int = 0
    @State private var code: String = ""
    
    /// Code validated
    func process() async throws{
        self.onVerify()
    }
    
    ///Manually reject
    func reject() async throws{
        self.onCancel()
    }
    
    func vibrate(){
        let tapticFeedback = UINotificationFeedbackGenerator()
        tapticFeedback.notificationOccurred(.error)
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
                                                try await self.reject()
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
                            
                            //Content
                            VStack(spacing:12){
                                VStack(spacing:8){
                                    Text("Enter PIN")
                                        .font(.title2.bold())
                                        .foregroundColor(Color.get(.Text))
                                    Text("Please enter your PIN to confirm person")
                                        .font(.body)
                                        .foregroundColor(Color.get(.Text))
                                }
                                .padding(.bottom, 24)
                            }
                            .padding(.top, 24)
                            
                            PassCode(passcode:self.$code, onEnter:{ code in
                                Task{
                                    do{
                                        if self.service.verify(code){
                                            try await self.process()
                                        }else{
                                            self.vibrate()
                                            self.retry += 1
                                            self.code = ""
                                            
                                            if self.retry >= 3{
                                                self.code = ""
                                                try await self.reject()
                                                return;
                                            }
                                            
                                            throw ApplicationError(title: "", message: "Wrong pin! You have \(3 - self.retry) attempts")
                                        }
                                    }catch(let error){
                                        self.loading = false
                                        self.Error.handle(error)
                                    }
                                }
                            })
                            Spacer()
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
                            if Biometrics.isEnabled() {
                                let context = LAContext()
                                var error: NSError?
                                
                                if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
                                    let reason = "Login to \(Whitelabel.BrandName())"
                                    context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authenticationError in
                                        if success {
                                            Task{
                                                do{
                                                    try await self.process()
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .coordinateSpace(name: "scroll")
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationTitle("")
        .background(Color.get(.Background))
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to:nil, from:nil, for:nil)
        }
    }
}

struct LockoutViewParent: View{
    @EnvironmentObject var Store: ApplicationStore
    @EnvironmentObject var Error: ErrorHandlingService
    
    @State private var lockout: Bool = false
    
    var body: some View{
        ZStack{
            VStack{
                Button("Lock"){
                    self.lockout = true
                }
            }
            if (self.lockout){
                LockoutView()
            }
        }
    }
}

struct LockoutView_Previews: PreviewProvider {
    static var store: ApplicationStore {
        var store = ApplicationStore()
        return store
    }
    
    static var error: ErrorHandlingService {
        var error = ErrorHandlingService()
        return error
    }
    
    static var previews: some View {
        LockoutViewParent()
            .environmentObject(self.store)
            .environmentObject(self.error)
    }
}
