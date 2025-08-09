//
//  ChangePinCodeView.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 30.09.2023.
//

import Foundation
import SwiftUI
import AudioToolbox

struct ChangePinCodeView: View, RouterPage {
    @EnvironmentObject var Store: ApplicationStore
    @EnvironmentObject var Error: ErrorHandlingService
    @EnvironmentObject var Router: RoutingController
    
    @State private var page: ChangePinCodeView.step = .setup
    @State private var newpin: String = ""
    @State private var currentpin: String = ""
    @State private var confirmationpin: String = ""
    @State private var updated: Bool = false
    @State private var retry: Int = 0
    @State private var pinValidated: Bool = false
    @State private var loading: Bool = false
    
    let service: pin = pin()
    
    enum step{
        case setup
        case enter
        case confirm
    }
    
    func update(){
        self.service.set(self.confirmationpin)
        self.updated = true
    }
    
    func vibrate(){
        let tapticFeedback = UINotificationFeedbackGenerator()
        tapticFeedback.notificationOccurred(.error)
    }
    
    var body: some View {
        ApplicationNavigatorContainerView{
            GeometryReader{ geometry in
                ScrollView{
                    VStack(spacing: 0){
                        if (self.page == .enter){
                            HStack(spacing:0){
                                Spacer()
                                Button{
                                    self.Router.back()
                                } label:{
                                    ZStack{
                                        Image("cross")
                                            .resizable()
                                            .scaledToFit()
                                            .foregroundColor(Color.get(.Text))
                                    }.frame(width: 24, height: 24)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 16)
                            
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
                                
                                PassCode(passcode:self.$currentpin, onEnter:{ code in
                                    Task{
                                        do{
                                            if self.service.verify(code){
                                                self.page = .setup
                                                self.pinValidated = true
                                            }else{
                                                self.vibrate()
                                                self.retry += 1
                                                
                                                if self.retry >= 4{
                                                    self.currentpin = ""
                                                    self.newpin = ""
                                                    self.confirmationpin = ""
                                                    
                                                    self.loading = true
                                                    try await self.Store.logout()
                                                    self.loading = false
                                                    self.Router.home()
                                                    return;
                                                }
                                                
                                                throw ApplicationError(title: "", message: "Wrong pin! You have \(4 - self.retry) attempts")
                                            }
                                            
                                            self.currentpin = ""
                                            self.newpin = ""
                                            self.confirmationpin = ""
                                        }catch (let error){
                                            self.currentpin = ""
                                            self.newpin = ""
                                            self.confirmationpin = ""
                                            
                                            self.loading = false
                                            self.Error.handle(error)
                                        }
                                    }
                                })
                                .padding(.vertical, 24)
                                
                                Spacer()
                            }
                        }else if (self.page == .setup){
                            HStack(spacing:0){
                                Spacer()
                                Button{
                                    self.Router.back()
                                } label:{
                                    ZStack{
                                        Image("cross")
                                            .resizable()
                                            .scaledToFit()
                                            .foregroundColor(Color.get(.Text))
                                    }.frame(width: 24, height: 24)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 16)
                            
                            VStack(spacing:12){
                                VStack(spacing:8){
                                    Text("Enter PIN")
                                        .font(.title2.bold())
                                        .foregroundColor(Color.get(.Text))
                                    Text("Setup new pincode")
                                        .font(.body)
                                        .foregroundColor(Color.get(.Text))
                                }
                                .padding(.bottom, 24)
                                
                                PassCode(
                                    passcode:self.$newpin,
                                    onEnter:{ code in
                                        self.retry = 0
                                        self.page = .confirm
                                    }
                                )
                                .padding(.vertical, 24)
                                
                                Spacer()
                            }
                        }else if(self.page == .confirm){
                            HStack(spacing:0){
                                Spacer()
                                Button{
                                    self.Router.back()
                                } label:{
                                    ZStack{
                                        Image("cross")
                                            .resizable()
                                            .scaledToFit()
                                            .foregroundColor(Color.get(.Text))
                                    }.frame(width: 24, height: 24)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 16)
                            
                            VStack(spacing:12){
                                VStack(spacing:8){
                                    Text("Enter PIN")
                                        .font(.title2.bold())
                                        .foregroundColor(Color.get(.Text))
                                    Text("Confirm pincode")
                                        .font(.body)
                                        .foregroundColor(Color.get(.Text))
                                }
                                .padding(.bottom, 24)
                                
                                PassCode(passcode:self.$confirmationpin, onEnter:{ code in
                                    Task{
                                        do{
                                            if code == self.newpin{
                                                self.update()
                                            }else{
                                                self.vibrate()
                                                self.retry += 1
                                                self.confirmationpin = ""
                                                
                                                if self.retry >= 4{
                                                    self.currentpin = ""
                                                    self.newpin = ""
                                                    self.confirmationpin = ""
                                                    self.page = .setup
                                                    
                                                    throw ApplicationError(title: "", message: "Wrong pin! Please, setup new")
                                                }
                                                
                                                throw ApplicationError(title: "", message: "Wrong pin! You have \(4 - self.retry) attempts")
                                            }
                                        }catch(let error){
                                            self.loading = false
                                            self.Error.handle(error)
                                        }
                                    }
                                })
                                .padding(.vertical, 24)
                                
                                Spacer()
                            }
                        }
                        BottomSheetContainer(isPresented: self.$updated){
                            VStack{
                                Image("success-splash")
                                Text("Pincode updated")
                                    .font(.title.bold())
                                    .foregroundColor(Color.get(.Text, scheme: .light))
                                    .padding(.bottom,20)
                                Button("OK"){
                                    self.updated = false
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1){
                                        self.Router.back()
                                    }
                                }
                                .buttonStyle(.secondary())
                            }
                            .padding(20)
                            .padding(.top,10)
                        }
                    }
                    .frame(
                        maxWidth: .infinity,
                        minHeight: geometry.size.height - geometry.safeAreaInsets.bottom
                    ).onAppear{
                        if self.service.hasPin{
                            self.page = .enter
                        }
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationTitle("")
        .background(Color.get(.Background))
    }
}

struct ChangePinCodeView_Previews: PreviewProvider {
    static var previews: some View {
        ContentViewContainerPreview{
            ChangePinCodeView()
        }
    }
}
