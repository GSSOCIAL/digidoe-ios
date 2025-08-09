//
//  BusinessConfirmation.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 29.11.2023.
//

import Foundation
import SwiftUI

extension BusinessConfirmationView{
    enum DataGroups{
        case businessType
        case countryOfIncorporation
        case countryOfOperation
        case businessName
        case registrationNumber
        case dateOfIncorporation
        case address
        case operatingAddress
        case businessConduct
        case businessUsage
        case businessNature
        case businessDescription
        case businessRegulated
        case businessSell
        case businessCustomers
        case turnover
        case moneySend
        case paymentsSend
        case singleLargestPayment
        case internationalPayments
        case depositedMoney
        case size
        case directors
        case structure
    }
}

extension BusinessConfirmationView{
    func singleRowContent(label: String, value: String) -> some View{
        VStack{
            HStack{
                Text(LocalizedStringKey(label))
                    .fontWeight(.bold)
                Text(LocalizedStringKey(value))
                Spacer()
            }
        }
    }
    
    func singleValueContent(_ value: String) -> some View{
        VStack{
            HStack{
                Text(LocalizedStringKey(value))
                Spacer()
            }
        }
    }
    
    func addressContent() -> some View{
        VStack{
            let entity = self.Store.onboarding.businessEntity
            let individualEntity = self.Store.onboarding.individualEntity
            if (entity != nil){
                if (entity!.has("GENbusaddstreet")){
                    HStack{
                        Text(LocalizedStringKey("Address line 1:"))
                            .fontWeight(.bold)
                        Text(entity!.at("GENbusaddstreet")!)
                        Spacer()
                    }
                }
                if (entity!.has("GENbusaddbuildingno") && !entity!.at("GENbusaddbuildingno")!.isEmpty){
                    HStack{
                        Text(LocalizedStringKey("Address line 2:"))
                            .fontWeight(.bold)
                        Text(entity!.at("GENbusaddbuildingno")!)
                        Spacer()
                    }
                }
                if (entity!.has("GENbusaddcity")){
                    HStack{
                        Text(LocalizedStringKey("Town / City:"))
                            .fontWeight(.bold)
                        Text(entity!.at("GENbusaddcity")!)
                        Spacer()
                    }
                }
                if (entity!.has("GENbusaddstate") && !entity!.at("GENbusaddstate")!.isEmpty){
                    HStack{
                        Text(LocalizedStringKey("State:"))
                            .fontWeight(.bold)
                        Text(entity!.at("GENbusaddstate")!)
                        Spacer()
                    }
                }
                if (entity!.has("GENbusaddpostcode") && !entity!.at("GENbusaddpostcode")!.isEmpty){
                    HStack{
                        Text(LocalizedStringKey("Postcode:"))
                            .fontWeight(.bold)
                        Text(entity!.at("GENbusaddpostcode")!)
                        Spacer()
                    }
                }
                if (entity!.has("GENbusaddcountry")){
                    HStack{
                        Text(LocalizedStringKey("Country:"))
                            .fontWeight(.bold)
                        Text(self.getListValue(entity!.at("GENbusaddcountry")!,list: self.Store.onboarding.countries))
                        Spacer()
                    }
                }
            }
        }
    }
    
    var operatingAddress: [String:String]{
        var output: [String:String] = [:]
        
        let entity = self.Store.onboarding.businessEntity
        var firstLine: String = ""
        var secondLine: String = ""
        var city: String = ""
        var country: String = ""
        var state: String = ""
        var postCode: String = ""
        
        if (entity != nil){
            let option = self.Store.onboarding.mailingAddressDifferentOptions.first(where: {$0.name.lowercased() == "yes"})
            if (option != nil && entity!.has("GENopsadddifftoregadd") && entity!.at("GENopsadddifftoregadd") == String(option!.id)){
                if (entity!.has("GENopsaddstreet")){
                    firstLine = entity!.at("GENopsaddstreet")!
                }
                if (entity!.has("GENopsaddbuildingno")){
                    secondLine = entity!.at("GENopsaddbuildingno")!
                }
                if (entity!.has("GENopsaddcity")){
                    city = entity!.at("GENopsaddcity")!
                }
                if (entity!.has("GENopsaddcountry")){
                    country = entity!.at("GENopsaddcountry")!
                }
                if (entity!.has("GENopsaddstate")){
                    state = entity!.at("GENopsaddstate")!
                }
                if (entity!.has("GENopsaddpostcode")){
                    postCode = entity!.at("GENopsaddpostcode")!
                }
            }else{
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
        }
        
        if (!firstLine.isEmpty){
            output["firstLine"] = firstLine
        }
        if (!secondLine.isEmpty){
            output["secondLine"] = secondLine
        }
        if (!city.isEmpty){
            output["city"] = city
        }
        if (!state.isEmpty){
            output["state"] = state
        }
        if (!postCode.isEmpty){
            output["postCode"] = postCode
        }
        if (!country.isEmpty){
            output["country"] = country
        }
        
        return output;
    }
    
    func operatingAddressContent() -> some View{
        VStack{
            let address = self.operatingAddress
            
            if let value = address["firstLine"]{
                HStack{
                    Text(LocalizedStringKey("Address line 1:"))
                        .fontWeight(.bold)
                    Text(value)
                    Spacer()
                }
            }
            if let value = address["secondLine"]{
                HStack{
                    Text(LocalizedStringKey("Address line 2:"))
                        .fontWeight(.bold)
                    Text(value)
                    Spacer()
                }
            }
            if let value = address["city"]{
                HStack{
                    Text(LocalizedStringKey("Town / City:"))
                        .fontWeight(.bold)
                    Text(value)
                    Spacer()
                }
            }
            if let value = address["state"]{
                HStack{
                    Text(LocalizedStringKey("State:"))
                        .fontWeight(.bold)
                    Text(value)
                    Spacer()
                }
            }
            if let value = address["postCode"]{
                HStack{
                    Text(LocalizedStringKey("Postcode:"))
                        .fontWeight(.bold)
                    Text(value)
                    Spacer()
                }
            }
            if let value = address["country"]{
                HStack{
                    Text(LocalizedStringKey("Country:"))
                        .fontWeight(.bold)
                    Text(self.getListValue(value,list: self.Store.onboarding.countries))
                    Spacer()
                }
            }
        }
    }
    
    func businessRegulatedContent() -> some View{
        VStack{
            let option = self.Store.onboarding.regulatedPositiveOption
            let entity = self.Store.onboarding.businessEntity
            
            HStack{
                Text(LocalizedStringKey("Answer:"))
                    .fontWeight(.bold)
                if (entity != nil && entity!.has("GENregulatedbusiness")){
                    Text(self.getListValue(entity!.at("GENregulatedbusiness")!,list: self.Store.onboarding.regulatedOptions))
                }
                Spacer()
            }
            //MARK: Yes selected
            if (option != nil && entity != nil && entity!.has("GENregulatedbusiness") && String(option!.id) == entity!.at("GENregulatedbusiness")!){
                HStack{
                    Text(LocalizedStringKey("Name of regulated body:"))
                        .fontWeight(.bold)
                    if (entity!.has("GENregulator")){
                        Text(entity!.at("GENregulator")!)
                    }
                    Spacer()
                }
                HStack{
                    Text(LocalizedStringKey("Reference number issued by regulated body:"))
                        .fontWeight(.bold)
                    if (entity!.has("GENregulatorrefencenumber")){
                        Text(entity!.at("GENregulatorrefencenumber")!)
                    }
                    Spacer()
                }
            }
        }
    }
    
    func directorsContent() -> some View{
        VStack{
            ForEach(self.Store.onboarding.directors, id: \.email){ director in
                HStack{
                    Text([director.firstName, director.lastName].joined(separator: " "))
                        .fontWeight(.bold)
                    Spacer()
                }
            }
        }
    }
}

extension BusinessConfirmationView{
    func getListValue(_ id: String, list: [KycpService.LookUpResponse.LookUpItem]) -> String{
        let option = list.first(where: {String($0.id) == id})
        if (option != nil){
            return String(option!.name)
        }
        return ""
    }
    func getListValue(_ ids: Array<String>, list: [KycpService.LookUpResponse.LookUpItem]) -> String{
        return list.filter({ option in
            return ids.firstIndex(of: String(option.id)) != nil
        }).map({
            return String($0.name)
        }).joined(separator: ", ")
    }
}

struct BusinessConfirmationView: View, RouterPage {
    @EnvironmentObject var Store: ApplicationStore
    @EnvironmentObject var Error: ErrorHandlingService
    @EnvironmentObject var Router: RoutingController
    
    @State private var confirmWindow: Bool = false
    @State private var loading: Bool = false
    
    func submit() async throws{
        self.loading = true
        let entity = self.Store.onboarding.businessEntity
        if (entity == nil){
            throw ServiceError(title: "Entity not found", message: "Couldnt find Your Entity")
        }
        //MARK: BE react for string here
        let fields:[String: String] = [
            "GENcompisconfirmed": "1"
        ]
        if (self.Store.user.customerId != nil){
            self.Store.onboarding.application.customerId = self.Store.user.customerId!
        }
        self.Store.onboarding.application.finalized = true
        let _ = try await self.Store.onboarding.application.updateEntity(fields, entityId: entity!.id)
        self.loading = false
        self.confirmWindow = true
    }
    
    func confirm() async throws{
        self.loading = true
        self.confirmWindow = false
        self.loading = false
        self.Router.goTo(ApplicationInReviewView())
    }
    
    var isOtherBusinessCategory: Bool{
        let entity = self.Store.onboarding.businessEntity
        if (entity != nil && entity!.has("GENnatureofbusiness")){
            return BusinessNatureView.isOtherSelected(entity!.at("GENnatureofbusiness")!)
        }
        return false
    }
    
    func group(_ type: DataGroups) -> some View{
        var label: String = ""
        var icon: String = ""
        var container: (any View)? = nil
        
        let entity = self.Store.onboarding.businessEntity
        let individualEntity = self.Store.onboarding.individualEntity
        
        switch (type){
        case .businessType:
            label = "Business type"
            icon = "buildings-2"
            if (entity != nil && entity!.has("GENcompanytype")){
                container = self.singleValueContent(self.getListValue(entity!.at("GENcompanytype")!,list: self.Store.onboarding.companyTypes))
            }
        case .countryOfIncorporation:
            label = "Country of incorporation"
            icon = "location"
            if (entity != nil && entity!.has("GENcountryincorp")){
                container = self.singleValueContent(self.getListValue(entity!.at("GENcountryincorp")!,list: self.Store.onboarding.countries))
            }
        case .countryOfOperation:
            label = "Country of operation or physical presence"
            icon = "location-add"
            if (entity != nil && entity!.has("GENcountriesofbusiness")){
                container = self.singleValueContent(self.getListValue(entity!.atArray("GENcountriesofbusiness")!,list: self.Store.onboarding.countries))
            }
        case .businessName:
            label = "Business Legal name"
            icon = "briefcase"
            if (entity != nil && entity!.has("GENname")){
                container = self.singleValueContent(entity!.at("GENname")!)
            }
        case .registrationNumber:
            label = "Registration Number"
            icon = "building-4"
            if (entity != nil && entity!.has("GENregno")){
                container = self.singleValueContent(entity!.at("GENregno")!)
            }
        case .dateOfIncorporation:
            label = "Date of incorporation"
            icon = "calendar"
            if (entity != nil && entity!.has("GENdateincorp")){
                container = self.singleValueContent(entity!.at("GENdateincorp")!)
            }
        case .address:
            label = "Business Address"
            icon = "location"
            container = self.addressContent()
        case .operatingAddress:
            label = "Operating Address"
            icon = "location"
            container = self.operatingAddressContent()
        case .businessConduct: //MARK: No screen
            label = "Where else do you conduct business?"
            icon = "global"
            container = self.singleValueContent("")
        case .businessUsage:
            label = "How will you use \(Whitelabel.BrandName())?"
            icon = "bank"
            if (entity != nil && entity!.has("GENservicesusage")){
                container = self.singleValueContent(self.getListValue(entity!.atArray("GENservicesusage")!,list: self.Store.onboarding.usageOptions))
            }
        case .businessNature:
            label = "Nature of business"
            icon = "briefcase"
            if (entity != nil && entity!.has("GENnatureofbusiness")){
                container = self.singleValueContent(self.getListValue(entity!.at("GENnatureofbusiness")!,list: self.Store.onboarding.businessCategories))
            }
        case .businessDescription:
            label = "Describe your business"
            icon = "document-text"
            if (entity != nil && entity!.has("GENnatureofbusinessdescription")){
                container = self.singleValueContent(entity!.at("GENnatureofbusinessdescription")!)
            }
        case .businessRegulated:
            label = "Is your business regulated?"
            icon = "security-user"
            container = self.businessRegulatedContent()
        case .businessSell:
            label = "How do you sell your product or service"
            icon = "shopping-cart"
            if (entity != nil && entity!.has("GENformatforsales")){
                container = self.singleValueContent(self.getListValue(entity!.atArray("GENformatforsales")!,list: self.Store.onboarding.sellOptions))
            }
        case .businessCustomers:
            label = "Who are your customers"
            icon = "people 1"
            if (entity != nil && entity!.has("GENtypeofcustomers")){
                container = self.singleValueContent(self.getListValue(entity!.atArray("GENtypeofcustomers")!,list: self.Store.onboarding.customerOptions))
            }
        case .turnover:
            label = "Annual turnover"
            icon = "moneys"
            if (entity != nil && entity!.has("GENannualturnover")){
                container = self.singleValueContent(self.getListValue(entity!.at("GENannualturnover")!,list: self.Store.onboarding.turnoverOptions))
            }
        case .moneySend:
            label = "How much money will be sent out from your account each month?"
            icon = "money-spend"
            if (entity != nil && entity!.has("GENaveragetransactionvalue")){
                container = self.singleValueContent(self.getListValue(entity!.at("GENaveragetransactionvalue")!,list: self.Store.onboarding.paymentsPerMonth))
            }
        case .paymentsSend:
            label = "How many payments will you send out each month?"
            icon = "money-spend"
            if (entity != nil && entity!.has("GENaveragetransactionvolumes")){
                container = self.singleValueContent(self.getListValue(entity!.at("GENaveragetransactionvolumes")!,list: self.Store.onboarding.averageTransactions))
            }
        case .singleLargestPayment:
            label = "What is the single largest payment value that you expect each month?"
            icon = "location"
            if (entity != nil && entity!.has("GENsinglelargestpayment")){
                container = self.singleValueContent(entity!.at("GENsinglelargestpayment")!)
            }
        case .depositedMoney:
            label = "How much money will be deposited in your account each month?"
            icon = "money-spend"
            if (entity != nil && entity!.has("GENaverageaccountdeposit")){
                container = self.singleValueContent(entity!.at("GENaverageaccountdeposit")!)
            }
        case .size:
            label = "Company size"
            icon = "buildings-2"
            if (entity != nil && entity!.has("GENaveragecompanysize")){
                container = self.singleValueContent(self.getListValue(entity!.at("GENaveragecompanysize")!,list: self.Store.onboarding.companySizes))
            }
        case .directors:
            label = "Directors"
            icon = "people 1"
            container = self.directorsContent()
        case .structure:
            label = "Type of business structure"
            icon = "buildings"
            if (entity != nil && entity!.has("GENstructure")){
                container = self.singleValueContent(self.getListValue(entity!.at("GENstructure")!,list: self.Store.onboarding.companyStructure))
            }
        case .internationalPayments:
            label = "International payments"
            icon = "location"
            if (entity != nil && entity!.has("GENcountriesofpayments")){
                container = self.singleValueContent(self.getListValue(entity!.atArray("GENcountriesofpayments")!,list: self.Store.onboarding.countries))
            }
        }
        return HStack(alignment:.top, spacing: 12){
            ZStack{
                Image(icon)
                    .foregroundColor(Whitelabel.Color(.Primary))
            }
                .frame(width: 48, height: 48)
                .background(Whitelabel.Color(.Primary).opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            VStack{
                Text(LocalizedStringKey(label))
                    .foregroundColor(Color("Text"))
                    .font(.caption.bold())
                    .frame(maxWidth: .infinity, alignment: .leading)
                Group{
                    if (container != nil){
                        AnyView(container!)
                    }
                }
                    .foregroundColor(Color("LightGray"))
                    .font(.caption)
            }
            Spacer()
        }
            .padding(10)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                .stroke(Color("BackgroundInput"))
                .foregroundColor(Color.clear)
                .background(.clear)
            )
            .padding(.horizontal, 16)
    }
    
    var body: some View {
        GeometryReader{ geometry in
            ZStack{
                ScrollView{
                    VStack(spacing: 0){
                        Header(back:{
                            self.Router.goTo(BusinessTypeView(), routingType: .backward)
                        }, title: "")
                        .padding(.bottom, 16)
                        TitleView(title: LocalizedStringKey("Confirm business details"), description: LocalizedStringKey("Please check all data you entered"))
                            .padding(.horizontal, 16)
                        VStack(spacing:0){
                            Text(LocalizedStringKey("DETAILS"))
                                .font(.caption)
                                .foregroundColor(Color("PaleBlack"))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                            VStack(spacing:12){
                                VStack(spacing:12){
                                    self.group(.businessType)
                                    self.group(.countryOfIncorporation)
                                    self.group(.countryOfOperation)
                                    self.group(.businessName)
                                    self.group(.registrationNumber)
                                }
                                VStack(spacing:12){
                                    self.group(.dateOfIncorporation)
                                    self.group(.address)
                                    self.group(.operatingAddress)
                                    self.group(.businessUsage)
                                }
                                VStack(spacing:12){
                                    self.group(.businessNature)
                                    //MARK: Only if other is selected
                                    if(self.isOtherBusinessCategory){
                                        self.group(.businessDescription)
                                    }
                                    self.group(.businessRegulated)
                                    self.group(.businessSell)
                                    self.group(.businessCustomers)
                                }
                                VStack(spacing:12){
                                    self.group(.turnover)
                                    self.group(.moneySend)
                                    self.group(.paymentsSend)
                                    self.group(.singleLargestPayment)
                                    self.group(.internationalPayments)
                                }
                                VStack(spacing:12){
                                    self.group(.depositedMoney)
                                    self.group(.size)
                                    //MARK: Add directors
                                    //self.group(.directors)
                                    self.group(.structure)
                                }
                            }
                        }
                        .padding(.bottom, geometry.safeAreaInsets.bottom * 2 + 40)
                        Spacer()
                    }
                    .frame(
                        maxWidth: .infinity,
                        minHeight: geometry.size.height - geometry.safeAreaInsets.bottom
                    )
                }
                .overlay(
                    VStack{
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
                                Text(LocalizedStringKey("Confirm"))
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .disabled(self.loading)
                        .buttonStyle(.primary())
                        .padding(.horizontal, 16)
                        .loader(self.$loading)
                    }
                        .ignoresSafeArea()
                        .padding(.vertical, 12)
                        .padding(.bottom, geometry.safeAreaInsets.bottom * 2 + 12)
                        .background(Color("Background"))
                        .compositingGroup()
                        .cornerRadius(16, corners: [.topLeft, .topRight])
                        .offset(y: geometry.safeAreaInsets.bottom)
                        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: -4)
                    , alignment: .bottom
                )
            }
            //MARK: Popup
            PresentationSheet(isPresented: self.$confirmWindow){
                VStack{
                    Image("success-splash")
                    Text(LocalizedStringKey("Thank you for providing the details."))
                        .font(.title.bold())
                        .foregroundColor(Color.get(.Text))
                        .padding(.bottom,1)
                        .multilineTextAlignment(.center)
                    Text(LocalizedStringKey("Our application has been successfully submitted. We normally take about 24 hours to get the account ready, will notify you when it’s ready."))
                        .font(.subheadline)
                        .foregroundColor(Color.get(.LightGray))
                        .multilineTextAlignment(.center)
                        .padding(.bottom,20)
                    
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
                            Text(LocalizedStringKey("OK"))
                            Spacer()
                        }
                    }
                    .buttonStyle(.secondary())
                }
                .padding(20)
                .padding(.top,10)
                .padding(.bottom, geometry.safeAreaInsets.bottom)
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationTitle("")
        .background(Color.get(.Background))
        .onAppear{
            let ent = self.Store.onboarding.businessEntity
        }
    }
}

struct BusinessConfirmationView_Previews: PreviewProvider {
    static var store: ApplicationStore {
        var store = ApplicationStore()
        return store
    }
    
    static var previews: some View {
        BusinessConfirmationView()
            .environmentObject(self.store)
    }
}


