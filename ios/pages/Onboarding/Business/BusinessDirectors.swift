//
//  BusinessDirectors.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 29.11.2023.
//

import Foundation
import SwiftUI

extension BusinessDirectorsView{
    struct BusinessDirector{
        public var firstName: String
        public var lastName: String
        public var middleName: String
        public var email: String
        public var phone: String
        public var id: String
        public var applicationEntityId: String?
    }
}

struct BusinessDirectorsView: View, RouterPage{
    @EnvironmentObject var Store: ApplicationStore
    @EnvironmentObject var Error: ErrorHandlingService
    @EnvironmentObject var Router: RoutingController
    
    @State private var loading: Bool = false
    
    var directorsAdded: Bool{
        return !self.Store.onboarding.directors.isEmpty
    }
    
    func submit() async throws{
        self.loading = true
        
        //MARK: Here we should check director & create entity
        if (self.Store.onboarding.isCountryIsUK(self.countryOfIncorporation)){
            //Call directors check
            let companyInfo = try await services.kycp.getCompanyDetails(
                companyNumber: self.Store.onboarding.business.registrationNumber,
                personId: self.Store.user.person?.id
            )
            //Check for directors
            if (companyInfo.officersNumber != self.Store.onboarding.directors.count){
                //Director mismatch
                throw ServiceError(
                    title: "Wrong amount of directors",
                    message: "Please add all company directors"
                )
            }
        }
        let entity = self.Store.onboarding.businessEntity
        if (entity == nil || entity!.id == nil){
            throw ServiceError(title: "Entity not found", message: "Couldnt find Your Entity")
        }
        //MARK: On this step send ALL directors to application
        let individualEntity = self.Store.onboarding.individualEntity
        let email = individualEntity?.at("GENemail")
        
        var entities: [KYCEntity] = self.Store.onboarding.directors.map({director in
            var entity = KYCEntity()
            
            if (!director.id.isEmpty){
                entity.id = Int(director.id)
            }
            if (director.applicationEntityId != nil && !director.applicationEntityId!.isEmpty){
                entity.applicationEntityId = Int(director.applicationEntityId!)
            }
            
            entity.fields = [
                "GENname": director.firstName,
                "GENsurname": director.lastName,
                "GENmiddlename": director.middleName,
                "GENemail": director.email,
                "GENmobile": director.phone.replacingOccurrences(of: "+", with: "") ?? "",
                "GENiscompanydirector": self.Store.onboarding.role == 1 ? "1" : "2"
            ]
            
            return entity
        }).filter({ entity in
            //Remove own entity from directors list
            if (individualEntity?.id != nil && entity.id == individualEntity!.id){
                return false
            }
            let _email = entity.fields["GENemail"] as? String
            if (email != nil && _email != nil){
                if (email!.lowercased() == _email!.lowercased()){
                    return false
                }
            }
            return true
        })
        //Modify onboarder
        if (individualEntity != nil){
            var onboarder = individualEntity
            onboarder!.fields["GENiscompanydirector"] = self.Store.onboarding.role == 0 ? "0" : self.Store.onboarding.role == 1 ? "1" : "2"
            entities.append(onboarder!)
        }
        
        let _ = try await self.Store.onboarding.application.modifyEntities(entities, rootEntityId: entity!.id!, keep: true)
        self.loading = false
        self.Router.goTo(BusinessCompanyTypeView())
    }
    
    func editDirector(_ director: BusinessDirectorsView.BusinessDirector?){
        self.Store.onboarding.business.activeDirectorEmail = director?.email ?? ""
        self.Router.goTo(BusinessAddDirectorsView())
    }
    
    var countryOfIncorporation: String{
        let businessEntity = self.Store.onboarding.businessEntity
        if (businessEntity != nil && businessEntity!.has("GENcountryincorp")){
            return businessEntity!.at("GENcountryincorp")!
        }
        return ""
    }
    
    var body: some View {
        GeometryReader{ geometry in
            ScrollView{
                VStack(spacing: 0){
                    Header(back:{
                        self.Router.goTo(BusinessCompanyRoleView(), routingType: .backward)
                    }, title: "")
                        .padding(.bottom, 16)
                    TitleView(
                        title: LocalizedStringKey("Directors"),
                        description: self.Store.onboarding.isCountryIsUK(self.countryOfIncorporation) ? LocalizedStringKey("Add all directors of the business as stated with Companies House") : LocalizedStringKey("Add all directors of the business")
                    )
                        .padding(.horizontal, 16)
                    HStack{
                        Button{
                            self.editDirector(nil)
                        } label: {
                            Text("Add Directors")
                        }
                            .buttonStyle(.secondary(image: "add"))
                            .disabled(self.loading)
                        Spacer()
                    }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    Text(LocalizedStringKey("DIRECTORS"))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .font(.caption)
                        .foregroundColor(Color("PaleBlack"))
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                    
                    VStack(spacing:24){
                        ForEach(self.Store.onboarding.directors, id: \.email){ director in
                            Button{
                                self.editDirector(director)
                            } label: {
                                HStack{
                                    ZStack{
                                        Text([director.firstName, director.lastName].map({ el in
                                            return String(el.prefix(1))
                                        }).joined(separator: " "))
                                            .font(.caption)
                                    }
                                        .frame(width: 38, height: 38)
                                        .foregroundColor(Color("Pending"))
                                        .background(Color("Pending").opacity(0.08))
                                        .clipShape(.circle)
                                    Text([director.firstName, director.lastName].joined(separator: " "))
                                        .font(.subheadline)
                                        .foregroundColor(Color("Text"))
                                    Spacer()
                                }
                            }
                                .buttonStyle(.next(outline: true))
                                .disabled(self.loading)
                        }
                    }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
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
                        .disabled(self.loading || !self.directorsAdded)
                        .buttonStyle(.primary())
                        .padding(.horizontal, 16)
                        .loader(self.$loading)
                }
                    .frame(
                        maxWidth: .infinity,
                        minHeight: geometry.size.height - geometry.safeAreaInsets.bottom
                    )
                    .onAppear{
                    }
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationTitle("")
        .background(Color.get(.Background))
    }
}

struct BusinessDirectorsView_Previews: PreviewProvider {
    static var store: ApplicationStore {
        var store = ApplicationStore()
        return store
    }
    
    static var previews: some View {
        BusinessDirectorsView()
            .environmentObject(self.store)
    }
}
