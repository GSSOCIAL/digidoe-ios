//
//  SettingsView.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 30.09.2023.
//

import Foundation
import SwiftUI
import AudioToolbox
import LocalAuthentication

struct SettingsView: View, RouterPage {
    @EnvironmentObject var Store: ApplicationStore
    @EnvironmentObject var Error: ErrorHandlingService
    @EnvironmentObject var Router: RoutingController
    
    @State private var loading: Bool = false
    
    @State private var verificationPopup: Bool = false
    @State private var openSecuritySettings: Bool = false
    let service: pin = pin()
    @State private var retry: Int = 0
    @State private var code: String = ""
    
    func navigateToSecuritySettings(){
        //Ask to login
        self.verificationPopup = true
        
        if Biometrics.isEnabled(){
            let context = LAContext()
            var error: NSError?

            if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
                let reason = "Manage security settings "

                context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authenticationError in
                    if success {
                        DispatchQueue.main.async {
                            self.verificationPopup = false
                            self.codeVerified()
                        }
                    }
                }
            }
        }
    }
    
    func codeVerified(){
        self.Router.goTo(SecurityView())
    }
    
    var body: some View {
        ApplicationNavigatorContainerView{
            GeometryReader{ geometry in
                ZStack{
                    ScrollView{
                        VStack(spacing: 0){
                            Header(back:{
                                self.Router.back()
                            }, title: "Settings and Info")
                            Text("Settings")
                                .font(.subheadline.bold())
                                .foregroundColor(Color.get(.LightGray))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                            VStack(spacing:0){
                                Button{
                                    self.navigateToSecuritySettings();
                                } label:{
                                    HStack{
                                        Text("Security")
                                        Spacer()
                                    }
                                }
                                .buttonStyle(.next(image:"lock"))
                                .frame(maxWidth: .infinity)
                            }
                            Text("Info")
                                .font(.subheadline.bold())
                                .foregroundColor(Color.get(.LightGray))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                            VStack(spacing:0){
                                Button{
                                    self.Router.goTo(LegalInformationView())
                                } label:{
                                    HStack{
                                        Text("Legal Information")
                                        Spacer()
                                    }
                                }
                                    .buttonStyle(.next(image:"Content, Edit - Linear 1"))
                                    .frame(maxWidth: .infinity)
                                Divider()
                                    .overlay(Color("Divider"))
                                Button{
                                    self.Router.goTo(AboutAppView())
                                } label:{
                                    HStack{
                                        Text("About app")
                                        Spacer()
                                    }
                                }
                                .buttonStyle(.next(image:"device"))
                                .frame(maxWidth: .infinity)
                            }
                            Spacer()
                        }
                        .frame(
                            maxWidth: .infinity,
                            minHeight: geometry.size.height - geometry.safeAreaInsets.bottom
                        )
                    }
                    //MARK: Popup
                    PresentationSheet(isPresented: self.$verificationPopup){
                        VStack(spacing:60){
                            Text("Confirm your pincode to access devices")
                                .font(.title2.bold())
                                .foregroundColor(Color.get(.Text))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.bottom,15)
                            PassCode(passcode: self.$code, onEnter: { code in
                                Task{
                                    do{
                                        if self.service.verify(code){
                                            self.code = ""
                                            self.verificationPopup = false
                                            
                                            self.codeVerified()
                                        }else{
                                            self.retry += 1
                                            
                                            if self.retry >= 4{
                                                //Ask to logout
                                                self.code = ""
                                                
                                                self.loading = true
                                                try await self.Store.logout()
                                                self.loading = false
                                                self.Router.home()
                                                return;
                                            }
                                            self.code = ""
                                            
                                            throw ApplicationError(title: "", message: "Wrong pin! You have \(4 - self.retry) attempts")
                                        }
                                    }catch(let error){
                                        DispatchQueue.main.asyncAfter(deadline: .now()+0.2){
                                            self.Error.handle(error)
                                        }
                                    }
                                }
                            })
                        }
                        .padding(20)
                        .padding(.bottom, geometry.safeAreaInsets.bottom)
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationTitle("")
        .background(Color.get(.Background))
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        ContentViewContainerPreview{
            SettingsView()
        }
    }
}
