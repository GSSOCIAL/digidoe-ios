//
//  LivelinessView.swift
//  DigiDoe Business Banking
//
//  Created by Михайло Картмазов on 29.05.2025.
//


import Foundation
import SwiftUI
import Combine
import AzureAIVisionFaceUI

extension LivelinessView{
    
}

extension LivelinessView{
    func generateToken() async throws{
        self.loading = true
        let token = try await services.kycp.createLivenessSession()
        self.token = token.value.token ?? ""
        self.sessionId = token.value.sessionId ?? ""
        self.loading = false
    }
    
    func processLivenessResult() async throws{
        self.loading = true
        let result = try await services.kycp.setLivenessSessionResult(self.sessionId)
        //Modify existing application
        let application = try await services.kycp.getApplication(self.Store.user.customerId!)
        if (application != nil){
            self.Store.onboarding.application.parse(application)
            self.Store.applicationLoaded()
        }
        let req = try await self.Store.onboarding.application.post(application!)
        if (req != nil){
            self.Store.onboarding.application.parse(req)
            self.Store.applicationLoaded()
        }
        self.Router.stack.removeLast()
        self.Router.goTo(VerifyPersonalIdentityView(), routingType: .backward)
        self.loading = false
    }
}

struct LivelinessView: View,RouterPage{
    @EnvironmentObject var Store: ApplicationStore
    @EnvironmentObject var Router: RoutingController
    @EnvironmentObject var Error: ErrorHandlingService
    
    //Liveness
    @State private var livenessDetectionResult: LivenessDetectionResult? = nil
    @State private var token: String = ""
    @State private var sessionId: String = ""
    @State private var loading: Bool = false
    
    var body: some View{
        ZStack{
            GeometryReader{ geometry in
                ZStack{
                    if (self.token.isEmpty == false){
                        FaceLivenessDetectorView(
                            result: self.$livenessDetectionResult,
                            sessionAuthorizationToken: self.token
                        )
                        .onChange(of: livenessDetectionResult) { result in
                            if let result = result{
                                if case let .success(success) = result{
                                    Task{
                                        do{
                                            let result = try await self.processLivenessResult()
                                        }catch let error{
                                            self.loading = false
                                            self.Error.handle(error)
                                        }
                                    }
                                }
                                if case let .failure(error) = result{
                                    if (error.livenessError == .userCanceledSession){
                                        self.Router.stack.removeLast()
                                        self.Router.goTo(VerifyPersonalIdentityView(), routingType: .backward)
                                    }else{
                                        self.Router.stack.removeLast()
                                        self.Router.goTo(VerifyPersonalIdentityView(livenessError: true), routingType: .backward)
                                    }
                                }
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 5){
                               self.livenessDetectionResult = nil
                           }
                        }
                    }else{
                        VStack{
                            Spacer()
                            HStack{
                                Spacer()
                                Loader(size:.small)
                                Spacer()
                            }
                            Spacer()
                        }
                    }
                }
            }
        }
        .onAppear{
            Task{
                do{
                    self.token = ""
                    self.sessionId = ""
                    self.loading = false
                    let result = try await self.generateToken()
                }catch let error{
                    self.loading = false
                    self.Error.handle(error)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationTitle("")
        .background(Color.black)
    }
}
