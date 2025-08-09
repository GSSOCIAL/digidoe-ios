//
//  CreatePersonAddress.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 04.12.2023.
//

import Foundation
import SwiftUI

extension CreatePersonAddressView{
    func submit() async throws{
        self.loading = true
        
        let response = try await services.kycp.updatePerson(Person.CreatePersonRequest(
            email: self.Store.user.email ?? "",
            phone: self.Store.user.phone ?? "",
            address: .init(
                countryExtId: Int(self.country)!,
                state: self.state,
                city: self.city,
                street: self.firstLine,
                building: self.secondLine,
                postCode: self.postcode
            )
        ))
        let personModified = self.Store.user.person?.edited
        
        self.Store.user.person = response
        self.Store.user.person?.edited = personModified
        self.Store.onboarding.customerEmail = self.Store.user.email
       
        //Pass KYC application
        let individualEntity = self.Store.onboarding.individualEntity
        if (individualEntity != nil){
            var outputEdited = 0
            if (self.Store.user.person?.edited == true){
                outputEdited = 1
            }
            
            var fields = [
                "GENname": self.Store.user.person!.givenName,
                "GENsurname": self.Store.user.person!.surname,
                "GENmiddlename": self.Store.user.person?.middleName ?? "",
                "GENmobile": self.Store.user.person!.phone?.replacingOccurrences(of: "+", with: ""),
                "GENemail": self.Store.user.person!.email,
                "GENpersonID": self.Store.user.person!.id,
                "GENOcrOutputEdited": outputEdited,
                "GENgender": self.Store.user.person!.genderExtId ?? "",
                "GENdatebirth": self.Store.user.person!.dateOfBirth.asDate()?.asString(kycDateFormat) ?? "",
                "GENcountrybirth": self.Store.user.person!.countryOfBirthExtId ?? ""
            ] as [String:Any]
            
            if (self.Store.user.person?.address?.street != nil){
                fields["GENresaddstreet"] = self.Store.user.person?.address!.street ?? ""
            }
            if (self.Store.user.person?.address?.building != nil){
                fields["GENresaddbuildingno"] = self.Store.user.person?.address!.building!
            }
            if (self.Store.user.person?.address?.city != nil){
                fields["GENresaddcity"] = self.Store.user.person?.address!.city!
            }
            if (self.Store.user.person?.address?.postCode != nil){
                fields["GENresaddpostcode"] = self.Store.user.person?.address!.postCode!
            }
            if (self.Store.user.person?.address?.countryExtId != nil){
                fields["GENresaddcountry"] = String((self.Store.user.person!.address!.countryExtId))
            }
            if (self.Store.user.person?.address?.state != nil){
                fields["GENresaddstate"] = self.Store.user.person?.address!.state!
            }
            
            let _ = try await self.Store.onboarding.application.updateEntity(
                fields,
                entityId: individualEntity!.id
            )
            //Fetch application
            if (self.Store.user.customerId != nil){
                var application: Application? = try await services.kycp.getApplication(self.Store.user.customerId!);
                if (application != nil){
                    self.Store.onboarding.application.parse(application)
                    self.Store.applicationLoaded()
                }
            }
        }
        
        self.loading = false
        self.Router.goTo(self.Store.onboarding.currentFlowPage)
    }
    
    var countries: [Option]{
        return self.Store.onboarding.countries.map({
            return .init(id: String($0.id), label: $0.name)
        })
    }
    
    var stateForSelectedCountryExists: Bool{
        return isStateForCountryExists(self.country)
    }
    
    struct PersonAddress: Codable{
        public var country: String
        public var state: String
        public var city: String
        public var firstLine: String
        public var secondLine: String
        public var postcode: String
    }
}

extension CreatePersonAddressView{
}

struct CreatePersonAddressView: View, RouterPage {
    @EnvironmentObject var Store: ApplicationStore
    @EnvironmentObject var Error: ErrorHandlingService
    @EnvironmentObject var Router: RoutingController
    
    @State private var country: String = ""
    @State private var state: String = ""
    @State private var city: String = ""
    @State private var firstLine: String = ""
    @State private var secondLine: String = ""
    @State private var postcode: String = ""
    
    @State private var loading: Bool = false
    
    var body: some View {
        GeometryReader{ geometry in
            ScrollView{
                VStack(spacing: 0){
                    Header(back:{
                        self.Router.goTo(CreatePersonView(), routingType: .backward)
                    }, title: "")
                    .padding(.bottom, 16)
                    TitleView(title: LocalizedStringKey("Personal Address"), description: LocalizedStringKey("Please, enter your primary address"))
                        .padding(.horizontal, 16)
                    VStack(spacing:24){
                        CustomField(
                            value: self.$country,
                            placeholder: "Country",
                            type: .select,
                            options: self.countries,
                            searchable: true
                        )
                            .disabled(self.loading)
                        if (self.stateForSelectedCountryExists){
                            CustomField(value: self.$state, placeholder: "State", type: .text)
                                .disabled(self.loading)
                        }
                        CustomField(value: self.$firstLine, placeholder: "Street", type: .text)
                            .disabled(self.loading)
                        CustomField(value: self.$secondLine, placeholder: "Building", type: .text)
                            .disabled(self.loading)
                        CustomField(value: self.$city, placeholder: "City", type: .text)
                            .disabled(self.loading)
                        CustomField(value: self.$postcode, placeholder: "Postcode", type: .text)
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
                    .disabled(self.loading || self.country.isEmpty || self.city.isEmpty || self.secondLine.isEmpty || self.firstLine.isEmpty || (self.stateForSelectedCountryExists ? self.state.isEmpty : false))
                        .buttonStyle(.primary())
                        .padding(.horizontal, 16)
                        .loader(self.$loading)
                }
                .frame(
                    maxWidth: .infinity,
                    minHeight: geometry.size.height - geometry.safeAreaInsets.bottom
                )
                .onAppear{
                    self.country = self.Store.onboarding.person.countryOfBirthExt
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationTitle("")
        .background(Color.get(.Background))
    }
}

struct CreatePersonAddressView_Previews: PreviewProvider {
    static var store: ApplicationStore {
        var store = ApplicationStore()
        return store
    }
    
    static var previews: some View {
        CreatePersonAddressView()
            .environmentObject(self.store)
    }
}
