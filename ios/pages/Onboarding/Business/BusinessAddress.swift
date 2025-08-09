//
//  BusinessAddress.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 26.11.2023.
//

import Foundation
import SwiftUI

struct BusinessAddressView: View, RouterPage{
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
    
    func submit() async throws{
        self.loading = true
        
        //MARK: Store session data
        
        self.Store.onboarding.business.registredAddress.country = self.country
        self.Store.onboarding.business.registredAddress.state = self.state
        self.Store.onboarding.business.registredAddress.city = self.city
        self.Store.onboarding.business.registredAddress.firstLine = self.firstLine
        self.Store.onboarding.business.registredAddress.secondLine = self.secondLine
        self.Store.onboarding.business.registredAddress.postcode = self.postcode
        
        self.loading = false
        self.Router.goTo(BusinessCurrencyView())
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
                        self.Router.goTo(CountryOfIncorporationView(), routingType: .backward)
                    }, title: "")
                    .padding(.bottom, 16)
                    TitleView(title: LocalizedStringKey("Registered business address"), description: LocalizedStringKey("The official address registered with a government body. This can be different from the address at which you have your business or coworking space"))
                        .padding(.horizontal, 16)
                    VStack(spacing:24){
                        CustomField(value: self.$country, placeholder: "Country", type: .select, options: self.countries, searchable: true)
                            .disabled(true)
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
                    .disabled(self.loading || self.country.isEmpty || self.city.isEmpty || self.firstLine.isEmpty || self.secondLine.isEmpty ||  (self.stateForSelectedCountryExists ? self.state.isEmpty : false))
                        .buttonStyle(.primary())
                        .padding(.horizontal, 16)
                        .loader(self.$loading)
                }
                .frame(
                    maxWidth: .infinity,
                    minHeight: geometry.size.height - geometry.safeAreaInsets.bottom
                )
                .onAppear{
                    self.country = self.Store.onboarding.business.registredAddress.country
                    self.state = self.Store.onboarding.business.registredAddress.state
                    self.city = self.Store.onboarding.business.registredAddress.city
                    self.firstLine = self.Store.onboarding.business.registredAddress.firstLine
                    self.secondLine = self.Store.onboarding.business.registredAddress.secondLine
                    self.postcode = self.Store.onboarding.business.registredAddress.postcode
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationTitle("")
        .background(Color.get(.Background))
    }
}

struct BusinessAddressView_Previews: PreviewProvider {
    static var store: ApplicationStore {
        var store = ApplicationStore()
        return store
    }
    
    static var previews: some View {
        BusinessAddressView()
            .environmentObject(self.store)
    }
}
