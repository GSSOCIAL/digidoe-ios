//
//  CurrencySelectView.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 17.11.2023.
//

import Foundation
import SwiftUI

struct CurrencyIndividualSelectView: View, RouterPage {
    @EnvironmentObject var Store: ApplicationStore
    @EnvironmentObject var Error: ErrorHandlingService
    @EnvironmentObject var Router: RoutingController
    
    @State private var currency: String = ""
    @State private var loading: Bool = false
    
    func prev() async throws{
        self.Router.goTo(AccountTypeSelectionView(), routingType: .backward)
    }
    
    func submit() async throws{
        self.loading = true
        self.Store.onboarding.processing = true
        
        //MARK: On this step create person individual account - customer
        var customerId = ""
        
        if (self.Store.user.customerId != nil){
            customerId = self.Store.user.customerId!
        }else{
            let customer = try await services.kycp.createIndividualCustomer(.init(
                personId: self.Store.user.person!.id
            ))
            //MARK: Store must handle customers here
            let _ = try await self.Store.user.loadCustomers()
            self.Store.user.customerId = customer.id
            customerId = customer.id
        }
        
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
            "GENcorporateservices": self.currency,
            "GENpersonID": self.Store.user.person!.id,
            "GENOcrOutputEdited": outputEdited,
            "GENgender": self.Store.user.person?.genderExtId ?? "",
            "GENdatebirth": self.Store.user.person!.dateOfBirth.asDate()?.asString(kycDateFormat) ?? "",
            "GENcountrybirth": self.Store.user.person?.countryOfBirthExtId ?? ""
        ] as [String : Any]
        
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
        
        //MARK: Create application for customer
        let privateEntity = KYCEntity(
            entityType: KycpService.entityType.individual.rawValue,
            fields: fields
        );
        
        //MARK: Check & create for application
        var application: Application? = try await services.kycp.getApplication(customerId);
        if (application != nil){
            self.Store.onboarding.application.parse(application)
        }
        let individualEntity = self.Store.onboarding.individualEntity
        var ready = false
        //MARK: Cause application create & entity create requests same - check both for application & entity
        if(application == nil || individualEntity == nil){
            application = try await self.Store.onboarding.application.create([privateEntity], customerId: customerId)
            self.Store.onboarding.application.parse(application)
            self.Store.applicationLoaded()
            ready = true
        }else{
            let _ = try await self.Store.onboarding.application.updateEntity(fields, entityId: individualEntity!.id)
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
                            Task{
                                do{
                                    try await self.prev()
                                }catch (let error){
                                    self.Error.handle(error)
                                }
                            }
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
                    RadioGroup(
                        items: self.currencies,
                        value: self.$currency
                    )
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
                        .disabled(self.currency.isEmpty)
                        .buttonStyle(.primary())
                        .padding(.horizontal, 16)
                        .loader(self.$loading)
                }
                .frame(
                    maxWidth: .infinity,
                    minHeight: geometry.size.height - geometry.safeAreaInsets.bottom
                )
                .onAppear{
                    let individualEntity = self.Store.onboarding.individualEntity
                    if (individualEntity != nil && individualEntity!.has("GENcorporateservices")){
                        self.currency = individualEntity!.at("GENcorporateservices")!
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationTitle("")
        .background(Color.get(.Background))
    }
}

struct CurrencyIndividualSelect_Previews: PreviewProvider {
    static var store: ApplicationStore {
        var store = ApplicationStore()
        store.onboarding.corporateServices = [
            KycpService.LookUpResponse.LookUpItem(externalRef: "1", id: 1, name: "USD"),
            KycpService.LookUpResponse.LookUpItem(externalRef: "2", id: 2, name: "EUR")
        ]
        return store
    }
    
    static var previews: some View {
        CurrencyIndividualSelectView()
            .environmentObject(self.store)
    }
}
