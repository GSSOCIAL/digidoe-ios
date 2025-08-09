//
//  PersonalAddress.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 18.11.2023.
//

import Foundation
import SwiftUI

struct PersonalAddressView: View, RouterPage{
    @EnvironmentObject var Store: ApplicationStore
    @EnvironmentObject var Error: ErrorHandlingService
    @EnvironmentObject var Router: RoutingController
    
    @State private var loading: Bool = false
    
    @State private var country: String = ""
    @State private var state: String = ""
    @State private var city: String = ""
    @State private var firstLine: String = ""
    @State private var secondLine: String = ""
    @State private var postcode: String = ""
    
    func submit() async throws{
        self.loading = true
        do{
            /*
            guard self.Store.onboarding.application != nil else{
                throw ServiceError(title: "Application not found", message: "Application not found. Please try again")
            }
            let personalEntityId = self.Store.onboarding.application?.getPersonalId(self.Store.user.person?.email)
            guard personalEntityId != nil else{
                throw ServiceError(title: "Entity not found", message: "Couldnt find Your Entity")
            }
            let fields = [
                "GENresaddstreet": self.firstLine,
                "GENresaddbuildingno": self.secondLine,
                "GENresaddcity": self.city,
                "GENresaddpostcode": self.postcode,
                "GENresaddcountry": self.country,
                "GENresaddstate": self.state
            ]
            
            let _ = try await services.kycp.updateEntity(fields, application: self.Store.onboarding.application, entityId: personalEntityId)
            
            //MARK: Store session data
            self.Store.onboarding.individual.country = self.country
            self.Store.onboarding.individual.state = self.state
            self.Store.onboarding.individual.city = self.city
            self.Store.onboarding.individual.firstLine = self.firstLine
            self.Store.onboarding.individual.secondLine = self.secondLine
            self.Store.onboarding.individual.postcode = self.postcode
            self.loading = false
            self.Router.goTo(ConfirmIndividualView())
             */
        }catch(let error){
            self.loading = false
            throw error
        }
    }
    
    var countries: [Option]{
        return self.Store.onboarding.countries.map({
            return .init(id: String($0.id), label: $0.name)
        })
    }
    
    var stateForSelectedCountryExists: Bool{
        return isStateForCountryExists(self.country)
    }
    
    var body: some View {
        GeometryReader{ geometry in
            ScrollView{
                    VStack(spacing: 0){
                        Header(back:{
                            self.Router.back()
                        }, title: "")
                        .padding(.bottom, 16)
                        TitleView(title: LocalizedStringKey("Personal Address"), description: LocalizedStringKey("Please, enter your primary address"))
                                .padding(.horizontal, 16)
                        VStack(spacing:24){
                            CustomField(value: self.$country, placeholder: "Country", type: .select, options: self.countries, searchable: true)
                                .disabled(self.loading)
                            if (self.stateForSelectedCountryExists){
                                CustomField(value: self.$state, placeholder: "State", type: .text)
                                    .disabled(self.loading)
                            }
                            CustomField(value: self.$firstLine, placeholder: "Address Line 1", type: .text)
                                .disabled(self.loading)
                            CustomField(value: self.$secondLine, placeholder: "Address Line 2", type: .text)
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
                        .disabled(self.loading || self.country.isEmpty || self.city.isEmpty || self.firstLine.isEmpty || self.postcode.isEmpty || (self.stateForSelectedCountryExists ? self.state.isEmpty : false))
                            .buttonStyle(.primary())
                            .padding(.horizontal, 16)
                    }
                    .frame(
                        maxWidth: .infinity,
                        minHeight: geometry.size.height - geometry.safeAreaInsets.bottom
                    )
                    .onAppear{
                        /*
                         self.country = self.Store.onboarding.individual.country
                        self.state = self.Store.onboarding.individual.state
                        self.city = self.Store.onboarding.individual.city
                        self.firstLine = self.Store.onboarding.individual.firstLine
                        self.secondLine = self.Store.onboarding.individual.secondLine
                        self.postcode = self.Store.onboarding.individual.postcode
                         */
                    }
                    .onChange(of: self.country){ _ in
                        self.city = ""
                        self.state = ""
                        self.firstLine = ""
                        self.postcode = ""
                    }
                }
        }
        .navigationBarBackButtonHidden(true)
        .navigationTitle("")
        .background(Color.get(.Background))
    }
}

struct PersonalAddressView_Previews: PreviewProvider {
    static var store: ApplicationStore {
        var store = ApplicationStore()
        return store
    }
    
    static var previews: some View {
        PersonalAddressView()
            .environmentObject(self.store)
    }
}
