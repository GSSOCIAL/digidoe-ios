//
//  SecurityView.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 30.09.2023.
//

import Foundation
import SwiftUI

struct SecurityView: View, RouterPage{
    @EnvironmentObject var Store: ApplicationStore
    @EnvironmentObject var Error: ErrorHandlingService
    @EnvironmentObject var Router: RoutingController
    
    @State private var useBiometrics: Bool = false
    
    var body: some View {
        ApplicationNavigatorContainerView{
            GeometryReader{ geometry in
                ZStack{
                    ScrollView{
                        VStack(spacing: 0){
                            Header(back:{
                                self.Router.back()
                            }, title: "Security")
                                .padding(.bottom, 16)
                            VStack(spacing:0){
                                Button{
                                    self.useBiometrics = !self.useBiometrics
                                } label:{
                                    HStack{
                                        Text("Biometric authentication")
                                        Spacer()
                                        Toggle(isOn: self.$useBiometrics){
                                            EmptyView()
                                        }
                                        .padding(0)
                                        .labelsHidden()
                                    }
                                    .padding(.trailing, 16)
                                }
                                .buttonStyle(.plain(image: "finger-scan"))
                                
                                Divider()
                                    .overlay(Color("Divider"))
                                
                                Button{
                                    self.Router.goTo(ChangePinCodeView())
                                } label: {
                                    HStack{
                                        Text("PIN")
                                        Spacer()
                                    }
                                }
                                .buttonStyle(.next(image:"security"))
                                .frame(maxWidth: .infinity)
                                
                                Divider()
                                    .overlay(Color("Divider"))
                                
                                Button{
                                    self.Router.goTo(DevicesListView())
                                } label: {
                                    HStack{
                                        Text("Devices")
                                        Spacer()
                                    }
                                }
                                .buttonStyle(.next(image:"devices"))
                                .frame(maxWidth: .infinity)
                            }
                            .padding(.top, 16)
                            Spacer()
                        }
                        .frame(
                            maxWidth: .infinity,
                            minHeight: geometry.size.height - geometry.safeAreaInsets.bottom
                        )
                        .onAppear{
                            if (Biometrics.isEnabled()){
                                self.useBiometrics = true
                            }
                        }
                        .onChange(of: self.useBiometrics){ val in
                            //Write data
                            if (self.useBiometrics){
                                Biometrics.enable()
                            }else{
                                Biometrics.disable()
                            }
                        }
                    }
                    //MARK: Popup
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationTitle("")
        .background(Color.get(.Background))
    }
}

struct SecurityView_Previews: PreviewProvider {
    static var previews: some View {
        ContentViewContainerPreview{
            SecurityView()
        }
    }
}
