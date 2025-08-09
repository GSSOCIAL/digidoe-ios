//
//  BusinessCurrency.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 22.11.2023.
//

import Foundation
import SwiftUI

struct BusinessCurrencyView: View, RouterPage {
    @EnvironmentObject var Store: ApplicationStore
    @EnvironmentObject var Error: ErrorHandlingService
    @EnvironmentObject var Router: RoutingController
    
    @State private var currency: String = ""
    @State private var loading: Bool = false
    
    func submit() async throws{
        self.loading = true
        self.Store.onboarding.processing = true
        //MARK: Create application, organization, etc here
        var customerId = ""
        
        if (self.Store.user.customerId != nil){
            customerId = self.Store.user.customerId!
        }else if(self.Store.user.customers.first(where: {$0.state == .new && $0.type == .business}) != nil){
            customerId = self.Store.user.customers.first(where: {$0.state == .new && $0.type == .business})!.id
        }else{
            // First, create organization
            let address: String = [
                self.Store.onboarding.business.registredAddress.country,
                self.Store.onboarding.business.registredAddress.state,
                self.Store.onboarding.business.registredAddress.city,
                self.Store.onboarding.business.registredAddress.firstLine,
                self.Store.onboarding.business.registredAddress.secondLine,
                self.Store.onboarding.business.registredAddress.postcode,
            ].filter({ el in
                return !el.isEmpty
            }).joined(separator: ".")
            
            let organisation = try await services.kycp.createOrganisation(.init(
                legalName: self.Store.onboarding.business.legalName,
                brandName: self.Store.onboarding.business.legalName,
                registrationNumber: self.Store.onboarding.business.registrationNumber,
                dateOfIncorporation: self.Store.onboarding.business.incorporationDate,
                countryOfIncorporationExtId: self.Store.onboarding.business.registredAddress.country,
                address: .init(
                    countryExtId: Int(self.Store.onboarding.business.registredAddress.country)!,
                    state: self.Store.onboarding.business.registredAddress.state,
                    city: self.Store.onboarding.business.registredAddress.city,
                    street: self.Store.onboarding.business.registredAddress.firstLine,
                    building: self.Store.onboarding.business.registredAddress.secondLine,
                    postCode: self.Store.onboarding.business.registredAddress.postcode
                )
            ))
            self.Store.user.organisation = organisation
            
            //Next, Create Business Customer
            let customer = try await services.kycp.createBusinessCustomer(.init(
                organisationId: organisation.id
            ))
            let _ = try await self.Store.user.loadCustomers()
            
            self.Store.user.customerId = customer.id
            customerId = customer.id
        }
        
        //MARK: Create business entity for customer
        let fields: [String:String] = [
            "GENname": self.Store.onboarding.business.legalName,
            "GEAliasNname": self.Store.onboarding.business.legalName,
            "GENregno": self.Store.onboarding.business.registrationNumber,
            "GENdateincorp": self.Store.onboarding.business.incorporationDate.asDate()?.asString(kycDateFormat) ?? "",
            "GENcountryincorp": self.Store.onboarding.business.registredAddress.country,
            "GENcorporateservices": self.currency,
            "GENbusaddstreet": self.Store.onboarding.business.registredAddress.firstLine,
            "GENbusaddbuildingno":self.Store.onboarding.business.registredAddress.secondLine,
            "GENbusaddcity":self.Store.onboarding.business.registredAddress.city,
            "GENbusaddpostcode":self.Store.onboarding.business.registredAddress.postcode,
            "GENbusaddcountry":self.Store.onboarding.business.registredAddress.country,
            "GENbusaddstate":self.Store.onboarding.business.registredAddress.state
        ];
        
        var outputEdited = 0
        if (self.Store.user.person?.edited == true){
            outputEdited = 1
        }
        
        let kycBusinessEntity = KYCEntity(
            entityType: KycpService.entityType.business.rawValue,
            fields: fields,
            entities: [
                KYCEntity(
                    entityType: KycpService.entityType.individual.rawValue,
                    fields: [
                        "GENname": self.Store.user.person!.givenName,
                        "GENsurname": self.Store.user.person!.surname,
                        "GENmiddlename": self.Store.user.person?.middleName ?? "",
                        "GENmobile": self.Store.user.person!.phone?.replacingOccurrences(of: "+", with: ""),
                        "GENemail": self.Store.user.person!.email,
                        "GENpersonID": self.Store.user.person!.id,
                        "GENOcrOutputEdited": outputEdited,
                        "GENgender": self.Store.user.person?.genderExtId ?? "",
                        "GENdatebirth": self.Store.user.person!.dateOfBirth.asDate()?.asString(kycDateFormat) ?? "",
                        "GENcountrybirth": self.Store.user.person?.countryOfBirthExtId ?? "",
                        "GENresaddstreet": self.Store.user.person?.address?.street ?? "",
                        "GENresaddbuildingno": self.Store.user.person?.address?.building ?? "",
                        "GENresaddcity": self.Store.user.person?.address?.city ?? "",
                        "GENresaddpostcode": self.Store.user.person?.address?.postCode ?? "",
                        "GENresaddcountry": self.Store.user.person?.address?.countryExtId ?? "",
                        "GENresaddstate": self.Store.user.person?.address?.state ?? "",
                    ]
                )
            ]
        );
        
        //MARK: Check & create for application
        var application: Application? = try await services.kycp.getApplication(customerId);
        if (application != nil){
            self.Store.onboarding.application.parse(application)
        }
        let businessEntity = self.Store.onboarding.businessEntity
        var ready = false
        
        if(application == nil || businessEntity == nil){
            //Case when only application exist
            application = try await self.Store.onboarding.application.create([kycBusinessEntity], customerId: customerId)
            self.Store.onboarding.application.parse(application)
            self.Store.applicationLoaded()
            ready = true
        }else{
            let _ = try await self.Store.onboarding.application.updateEntity(fields, entityId: businessEntity!.id)
            ready = true
        }
        Task{
            while(ready == false){
                try? await Task.sleep(nanoseconds: 1_000_000_000)
            }
            self.loading = false
            self.Store.onboarding.processing = false
            self.Router.goTo(self.Store.onboarding.currentFlowPage)
        }
    }
    
    var currencies: [Option]{
        return self.Store.onboarding.corporateServices.map({
            return Option(
                id: String($0.id),
                label: $0.name
            )
        })
    }
    
    var body: some View {
        GeometryReader{ geometry in
            ScrollView{
                    VStack(spacing: 0){
                        if (!self.Store.onboarding.application.isApplicationExists){
                            Header(back:{
                                self.Router.goTo(BusinessAddressView(), routingType: .backward)
                            }, title: "")
                            .padding(.bottom, 16)
                        }else{
                            ZStack{
                                
                            }
                            .frame(maxWidth: .infinity, maxHeight: 50)
                            .padding(.bottom, 16)
                        }
                        TitleView(
                            title: LocalizedStringKey("In which currency would you prefer to open your account?"),
                            description: LocalizedStringKey("You can open account in other currency after registration.")
                        )
                            .padding(.horizontal, 16)
                        RadioGroup(items: self.currencies, value: self.$currency)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 24)
                            .disabled(self.loading)
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
                            .disabled(self.loading || self.currency.isEmpty)
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
                        if (businessEntity != nil && businessEntity!.has("GENcorporateservices")){
                            self.currency = businessEntity!.at("GENcorporateservices")!
                        }
                    }
                }
        }
        .navigationBarBackButtonHidden(true)
        .navigationTitle("")
        .background(Color.get(.Background))
    }
}

struct BusinessCurrencyView_Previews: PreviewProvider {
    static var store: ApplicationStore {
        var store = ApplicationStore()
        return store
    }
    
    static var previews: some View {
        BusinessCurrencyView()
            .environmentObject(self.store)
    }
}
