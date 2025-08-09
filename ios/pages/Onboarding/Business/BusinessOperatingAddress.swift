//
//  BusinessOperatingAddress.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 29.11.2023.
//

import Foundation
import SwiftUI

struct BusinessOperatingAddressView: View, RouterPage{
    @EnvironmentObject var Store: ApplicationStore
    @EnvironmentObject var Error: ErrorHandlingService
    @EnvironmentObject var Router: RoutingController
    
    @State private var addressSame: Bool = false
    @State private var country: String = ""
    @State private var state: String = ""
    @State private var city: String = ""
    @State private var firstLine: String = ""
    @State private var secondLine: String = ""
    @State private var postcode: String = ""
    
    @State private var loading: Bool = false
    
    func submit() async throws{
        self.loading = true
        
        let entity = self.Store.onboarding.businessEntity
        if (entity == nil){
            throw ServiceError(title: "Entity not found", message: "Couldnt find Your Entity")
        }
        
        var fields: [String:String] = [:]
        
        var firstLine: String = self.firstLine
        var secondLine: String = self.secondLine
        var city: String = self.city
        var country: String = self.country
        var state: String = self.state
        var postCode: String = self.postcode
        
        if (self.addressSame){
            if (entity!.has("GENbusaddstreet")){
                firstLine = entity!.at("GENbusaddstreet")!
            }
            if (entity!.has("GENbusaddbuildingno")){
                secondLine = entity!.at("GENbusaddbuildingno")!
            }
            if (entity!.has("GENbusaddcity")){
                city = entity!.at("GENbusaddcity")!
            }
            if (entity!.has("GENbusaddcountry")){
                country = entity!.at("GENbusaddcountry")!
            }
            if (entity!.has("GENbusaddstate")){
                state = entity!.at("GENbusaddstate")!
            }
            if (entity!.has("GENbusaddpostcode")){
                postCode = entity!.at("GENbusaddpostcode")!
            }
        }
        
        fields = [
            "GENopsaddstreet": firstLine,
            "GENopsaddbuildingno": secondLine,
            "GENopsaddcity": city,
            "GENopsaddpostcode": postCode,
            "GENopsaddcountry": country,
            "GENopsaddstate": state
        ]
        
        if (!self.addressSame){
            let option = self.Store.onboarding.mailingAddressDifferentOptions.first(where: {$0.name.lowercased() == "yes"})
            
            if option != nil{
                fields["GENopsadddifftoregadd"] = String(option!.id)
            }
        }else{
            let option = self.Store.onboarding.mailingAddressDifferentOptions.first(where: {$0.name.lowercased() == "no"})
            
            if option != nil{
                fields["GENopsadddifftoregadd"] = String(option!.id)
            }
        }
        
        let _ = try await self.Store.onboarding.application.updateEntity(fields, entityId: entity!.id)
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
    
    var body: some View {
        GeometryReader{ geometry in
            ScrollView{
                VStack(spacing: 0){
                    Header(back:{
                        self.Router.goTo(BusinessCountryOfOperationView(), routingType: .backward)
                    }, title: "")
                    .padding(.bottom, 16)
                    TitleView(title: LocalizedStringKey("Operating address"), description: LocalizedStringKey("This is where you do majority of your business activity. If you have multiple locations that you operate from, please share details of the largest operating location."))
                        .padding(.horizontal, 16)
                    HStack(spacing:10){
                        Checkbox(checked: self.$addressSame)
                            .disabled(self.loading)
                        Text(LocalizedStringKey("Operating address is same with registered business address"))
                            .foregroundColor(Color("Text"))
                            .font(.subheadline)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 24)
                    if (!self.addressSame){
                        VStack(spacing:24){
                            CustomField(value: self.$country, placeholder: "Country", type: .select, options: self.countries, searchable: true)
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
                    }
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
                    .disabled(self.loading || (!self.addressSame && (self.country.isEmpty || self.city.isEmpty || self.firstLine.isEmpty || self.secondLine.isEmpty ||  (self.stateForSelectedCountryExists ? self.state.isEmpty : false))))
                        .buttonStyle(.primary())
                        .padding(.horizontal, 16)
                        .loader(self.$loading)
                }
                .frame(
                    maxWidth: .infinity,
                    minHeight: geometry.size.height - geometry.safeAreaInsets.bottom
                )
                .onAppear{
                    let businessEntity = self.Store.onboarding.businessEntity
                    if (businessEntity != nil){
                        if (businessEntity!.has("GENopsaddstreet")){
                            self.firstLine = businessEntity!.at("GENopsaddstreet")!
                        }
                        if (businessEntity!.has("GENopsaddbuildingno")){
                            self.secondLine = businessEntity!.at("GENopsaddbuildingno")!
                        }
                        if (businessEntity!.has("GENopsaddcity")){
                            self.city = businessEntity!.at("GENopsaddcity")!
                        }
                        if (businessEntity!.has("GENopsaddpostcode")){
                            self.postcode = businessEntity!.at("GENopsaddpostcode")!
                        }
                        if (businessEntity!.has("GENopsaddcountry")){
                            self.country = businessEntity!.at("GENopsaddcountry")!
                        }
                        if (businessEntity!.has("GENopsaddstate")){
                            self.state = businessEntity!.at("GENopsaddstate")!
                        }
                        if (businessEntity!.has("GENopsadddifftoregadd")){
                            let option = self.Store.onboarding.mailingAddressDifferentOptions.first(where: {$0.name.lowercased() == "no"})
                            if (option != nil && String(option!.id) == businessEntity!.at("GENopsadddifftoregadd")){
                                self.addressSame = true
                            }
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

struct BusinessOperatingAddressView_Previews: PreviewProvider {
    static var store: ApplicationStore {
        var store = ApplicationStore()
        return store
    }
    
    static var previews: some View {
        BusinessOperatingAddressView()
            .environmentObject(self.store)
    }
}
