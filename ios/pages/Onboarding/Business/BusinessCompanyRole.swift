//
//  BusinessCompanyRole.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 26.11.2023.
//

import Foundation
import SwiftUI

struct BusinessCompanyRoleView: View, RouterPage {
    @EnvironmentObject var Store: ApplicationStore
    @EnvironmentObject var Error: ErrorHandlingService
    @EnvironmentObject var Router: RoutingController
    
    @State private var role: Int = -1
    @State private var loading: Bool = false
    @State private var mismatch: Bool = false
    
    func submit() async throws{
        self.loading = true
        
        let individualEntity = self.Store.onboarding.individualEntity
        let businessEntity = self.Store.onboarding.businessEntity
        
        if (individualEntity == nil || businessEntity == nil){
            throw ServiceError(title: "Entity not found", message: "Couldnt find Your Entity")
        }
        
        if(businessEntity!.has("GENcountryincorp") == false){
            throw ServiceError(title: "Entity not found", message: "Business data incorrect")
        }
        
        //MARK: Here we should check director & create entity
        if (self.Store.onboarding.isCountryIsUK(businessEntity!.at("GENcountryincorp")!) && self.role != 0){
            //Call directors check
            let companyInfo = try await services.kycp.getCompanyDetails(companyNumber: self.Store.onboarding.business.registrationNumber, personId: self.Store.user.person?.id)
            //Check for directors
            if (companyInfo.isPersonOfficer == false){
                self.mismatch = true
                self.loading = false
                return;
            }
        }
        
        try await self.updateEntity()
    }
    
    func confirm() async throws{
        self.mismatch = false
        self.role = 0
        try await self.updateEntity()
    }
    
    func updateEntity() async throws{
        self.loading = true
        
        let individualEntity = self.Store.onboarding.individualEntity
        
        if (individualEntity == nil){
            throw ServiceError(title: "Entity not found", message: "Couldnt find Your Entity")
        }
        
        let fields:[String:String] = [
            "GENiscompanydirector": String(self.role)
        ]
        //let _ = try await self.Store.onboarding.application.updateEntity(fields, entityId: individualEntity!.id)
        //Add store directors
        self.Store.onboarding.role = self.role
        self.loading = false
        self.Router.goTo(BusinessDirectorsView())
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
                            title: LocalizedStringKey("Tell us about your role in the company")
                        )
                            .padding(.horizontal, 16)
                        VStack(spacing:10){
                            let option1Selected: Binding<Bool> = Binding(get: {
                                return self.role == 1
                            }, set: { _ in })
                            Button(LocalizedStringKey("I am the only director and shareholder")){
                                self.role = 1
                            }
                            .buttonStyle(.radio(image:"user 1", description: LocalizedStringKey("You are the only director and shareholder with more than 25%"), checked: option1Selected))
                            .disabled(self.loading)
                            
                            let option2Selected: Binding<Bool> = Binding(get: {
                                return self.role == 2
                            }, set: { _ in })
                            Button(LocalizedStringKey("I am one of the directors or shareholders")){
                                self.role = 2
                            }
                            .buttonStyle(.radio(image:"people", description: LocalizedStringKey("You are one of the director and shareholder with more than 25%"), checked: option2Selected))
                            .disabled(self.loading)
                            
                            let option3Selected: Binding<Bool> = Binding(get: {
                                return self.role == 0
                            }, set: { _ in })
                            Button(LocalizedStringKey("I am neither a director nor a shareholder")){
                                self.role = 0
                            }
                            .buttonStyle(.radio(image:"briefcase l", description: LocalizedStringKey("You are applying on behalf of your employer or client"), checked: option3Selected))
                            .disabled(self.loading)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 24)
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
                        .disabled(self.loading || self.role == -1)
                        .buttonStyle(.primary())
                        .padding(.horizontal, 16)
                        .loader(self.$loading)
                    }
                    .frame(
                        maxWidth: .infinity,
                        minHeight: geometry.size.height - geometry.safeAreaInsets.bottom
                    )
                    .onAppear{
                        self.role = self.Store.onboarding.role
                    }
                }
                //MARK: Popup
                PresentationSheet(isPresented: self.$mismatch){
                    VStack{
                        Image("danger")
                        Text(LocalizedStringKey("We observe you are not a director in Companies House. Would you like to apply still?"))
                            .font(.title2.bold())
                            .foregroundColor(Color.get(.Text))
                            .padding(.bottom,20)
                            .multilineTextAlignment(.center)
                        HStack(spacing:10){
                            Button{
                                Task{
                                    do{
                                        try await self.confirm()
                                    }catch(let error){
                                        self.loading = false
                                        self.Error.handle(error)
                                    }
                                }
                            } label:{
                                HStack{
                                    Spacer()
                                    Text(LocalizedStringKey("Continue"))
                                    Spacer()
                                }
                            }
                            .buttonStyle(.secondary())
                            Button{
                                Task{
                                    do{
                                        try await self.Store.logout()
                                        DispatchQueue.main.async{
                                            self.mismatch = false
                                            self.Router.home()
                                        }
                                    }catch(let error){
                                        self.loading = false
                                        self.Error.handle(error)
                                    }
                                }
                            } label:{
                                HStack{
                                    Spacer()
                                    Text(LocalizedStringKey("Logoff"))
                                    Spacer()
                                }
                            }
                            .buttonStyle(.secondaryDanger())
                        }
                    }
                    .padding(.bottom, geometry.safeAreaInsets.bottom)
                    .padding(20)
                    .padding(.top,10)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationTitle("")
        .background(Color.get(.Background))
    }
}

struct BusinessCompanyRoleView_Previews: PreviewProvider {
    static var store: ApplicationStore {
        var store = ApplicationStore()
        return store
    }
    
    static var previews: some View {
        BusinessCompanyRoleView()
            .environmentObject(self.store)
    }
}
