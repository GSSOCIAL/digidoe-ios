//
//  VerifyPersonalIdentityView.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 17.11.2023.
//

import Foundation
import SwiftUI

extension VerifyPersonalIdentityView{
    var proofOfIdentifyLoaded: Binding<Bool>{
        Binding(
            get: {
                #if targetEnvironment(simulator) && DEBUG
                    return true
                #else
                    return !self.Store.onboarding.proofOfIdentitiesUploaded.isEmpty
                #endif
            },
            set: { value in
                
            })
    }
    var selfieLoaded: Binding<Bool>{
        Binding(
            get: {
                #if targetEnvironment(simulator) && DEBUG
                    return true
                #else
                    return self.Store.onboarding.selfie != nil
                #endif
            },
            set: { value in
                
            })
    }
    var livelinessPassed: Binding<Bool>{
        Binding(
            get: {
                let individualEntity = self.Store.onboarding.individualEntity
                if (individualEntity != nil && individualEntity?.fields.first(where: {$0.key == "GENLivelinessCheckResult"}) != nil){
                    let field: String? = individualEntity!.fields.first(where: {$0.key == "GENLivelinessCheckResult"})!.value as? String
                    if (field?.isEmpty == false ){
                        return true
                    }
                }
                return false
            }, set: { value in
                
            })
    }
}

struct VerifyPersonalIdentityView: View, RouterPage {
    @EnvironmentObject var Store: ApplicationStore
    @EnvironmentObject var Error: ErrorHandlingService
    @EnvironmentObject var Router: RoutingController
    
    @State private var loading: Bool = false
    @State public var livenessError: Bool = false
    
    func submit() async throws{
        self.loading = true
        
        let individualEntity = self.Store.onboarding.individualEntity
        if (individualEntity == nil || self.Store.onboarding.application.isApplicationExists == false){
            throw ServiceError(title: "Entity not found", message: "Couldnt find Your Entity")
        }
        var fields:[String:Int] = [:]
        
        #if targetEnvironment(simulator) && DEBUG
            fields["GENiddocnumber"] = 1
            fields["GENselfienumber"] = 1
        #else
            if self.Store.onboarding.proofOfIdentitiesUploaded.count > 0{
            var i = 0
            var identities = self.Store.onboarding.proofOfIdentitiesUploaded.filter({ item in return !item.uploaded })
            while(i<identities.count){
                let _ = try await services.kycp.uploadDocument(
                    identities[i], 
                    applicationId: self.Store.onboarding.application.id!,
                    entityId: individualEntity!.id, 
                    entityTypeId: KycpService.entityType.individual,
                    title: "ProofOfIdentity",
                    type: identities[i].documentType!.id
                )
                i += 1
            }
            fields["GENiddocnumber"] = self.Store.onboarding.proofOfIdentitiesUploaded.count
        }
        //Selfie
        if self.Store.onboarding.selfie != nil{
            if (self.Store.onboarding.selfie?.uploaded == false){
                let _ = try await services.kycp.uploadDocument(
                    self.Store.onboarding.selfie!,
                    applicationId: self.Store.onboarding.application.id!,
                    entityId: individualEntity!.id,
                    entityTypeId: KycpService.entityType.individual,
                    title: "Selfie",
                    type: .selfie
                )
            }
            fields["GENselfienumber"] = 1
        }
        #endif
        let _ = try await self.Store.onboarding.application.updateEntity(fields, entityId: individualEntity!.id)
        self.loading = false
        self.Router.goTo(self.Store.onboarding.currentFlowPage)
    }
    
    var body: some View {
        GeometryReader{ geometry in
            ZStack{
                ScrollView{
                    VStack(spacing: 0){
                        ZStack{
                            
                        }
                        .frame(maxWidth: .infinity, maxHeight: 50)
                        .padding(.bottom, 16)
                        
                        TitleView(
                            title: LocalizedStringKey("Verify your personal identity"),
                            description: LocalizedStringKey("Please be assured that all your data is encrypted and secure")
                        )
                        .padding(.horizontal, 16)
                        VStack(spacing:12){
                            Button{
                                self.Router.goTo(UploadIdentityView())
                            } label: {
                                Text(LocalizedStringKey("Proof of identity"))
                            }
                            .buttonStyle(.detailed(
                                image:"document",
                                description: "Passport, Driving licence and National Identification Card",
                                checked: self.proofOfIdentifyLoaded
                            ))
                            .disabled(self.loading)
                            
                            Button{
                                self.Router.goTo(LivelinessView())
                            } label: {
                                Text(LocalizedStringKey("Liveness check"))
                            }
                            .buttonStyle(.detailed(
                                image:"camera",
                                description: "Follow instructions on the next screen to verify that it’s really you",
                                checked: self.livelinessPassed
                            ))
                            .disabled(self.loading)
                            
                            Button{
                                self.Router.goTo(TakeSelfieView())
                            } label: {
                                Text(LocalizedStringKey("Take a selfie"))
                            }
                            .buttonStyle(.detailed(
                                image:"camera",
                                description: "To make sure that it’s you",
                                checked: self.selfieLoaded
                            ))
                            .disabled(self.loading || self.selfieLoaded.wrappedValue)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 24)
                        VStack(alignment: .leading){
                            Text("In adherence to regulatory requirements, we need to confirm your identity before proceeding with the account opening process")
                                .font(.caption)
                                .foregroundColor(Color.get(.LightGray))
                                .multilineTextAlignment(.leading)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)
                        Spacer()
                        Button{
                            Task{
                                do{
                                    try await self.submit()
                                }catch(let error){
                                    self.loading = false
                                    self.Error.handle(error)
                                }
                            }
                        } label: {
                            HStack{
                                Text(LocalizedStringKey("Continue"))
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .disabled((self.loading || self.proofOfIdentifyLoaded.wrappedValue == false || self.selfieLoaded.wrappedValue == false || self.livelinessPassed.wrappedValue == false))
                        .buttonStyle(.primary())
                        .padding(.horizontal, 16)
                        .loader(self.$loading)
                    }
                    .frame(
                        maxWidth: .infinity,
                        minHeight: geometry.size.height - geometry.safeAreaInsets.bottom
                    )
                }
                
                //MARK: Popup
                PresentationSheet(isPresented: self.$livenessError){
                    VStack(spacing: 24){
                        ZStack{
                            Image("danger")
                        }
                        .frame(width: 80, height: 80)
                        VStack(alignment: .center, spacing: 6){
                            Text("Liveness error")
                                .font(.body.bold())
                                .foregroundColor(Color.get(.Text))
                            Text("Something went wrong with liveness check. Please try again")
                                .multilineTextAlignment(.center)
                                .font(.caption)
                                .foregroundColor(Color.get(.LightGray))
                        }
                        HStack(spacing: 16){
                            Button{
                                self.Router.goTo(LivelinessView())
                            } label:{
                                HStack{
                                    Spacer()
                                    Text(LocalizedStringKey("Try again"))
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
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationTitle("")
        .background(Color("Background"))
    }
}

struct VerifyPersonalIdentityView_Previews: PreviewProvider {
    static var store: ApplicationStore {
        var store = ApplicationStore()
        return store
    }
    
    static var error: ErrorHandlingService {
        var error = ErrorHandlingService()
        return error
    }
    
    static var previews: some View {
        VerifyPersonalIdentityView()
            .environmentObject(self.store)
            .environmentObject(self.error)
    }
}
