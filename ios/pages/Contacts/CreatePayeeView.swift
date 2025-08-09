//
//  CreatePayeeView.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 02.01.2024.
//

import Foundation
import SwiftUI
import Combine
import CoreData

enum RouterPageCallback{
    /**Create payment view**/
    case CreatePayment(CreatePaymentView.CreatePaymentViewFetchDetails)
}

//MARK: - OTP
extension CreatePayeeView{
    func otpConfirmed(operationId: String, sessionId: String, type: ProfileService.ConfirmationType){
        self.verifyOtp = false
        //Finalize the operation
        Task{
            do{
                self.loading = true
                
                let isSuccess = try await services.contacts.finalizeContactOperation(
                    self.customer.id ?? "",
                    operationId: operationId,
                    sessionId: sessionId,
                    confirmationType: type
                )
                
                if (isSuccess){
                    self.loading = false
                    self.processSubmit()
                    return;
                }
                
                throw ApplicationError(title: "Create contact", message: "Failed to create contact, please try again")
            }catch(let error){
                self.loading = false
                self.Error.handle(error)
            }
        }
    }
    
    func otpRejected(operationId: String, sessionId: String?, type: ProfileService.ConfirmationType?){
        self.verifyOtp = false
    }
}

//MARK: - COP
extension CreatePayeeView{
    var copPopup: some View{
        VStack(spacing:0){
            let option: CoreReasonCodeLookupDto? = self.reasonCodeData.first(where: {$0.reasonCode?.lowercased() == self.copCode?.lowercased()})
            switch(self.copCode){
            default:
                VStack(alignment: .center, spacing: 24){
                    ZStack{
                        Image(self.copCode?.lowercased() == "ac01" ? "close-circle-fill" : "user-remove")
                    }
                    .frame(width: 92, height: 92)
                    VStack(alignment: .center, spacing: 12){
                        VStack(alignment:.center, spacing:0){
                            Text("Beneficiary check")
                                .font(.caption)
                                .foregroundColor(Color.get(.Gray))
                                .multilineTextAlignment(.center)
                            Text(option?.header?.replacingOccurrences(of: "%name%", with: self.copName ?? "–", options: .caseInsensitive) ?? "Account not found")
                                .font(.title2.bold())
                                .foregroundColor(Color.get(.Text))
                                .multilineTextAlignment(.center)
                        }
                        Text(option?.reasonDescription?.replacingOccurrences(of: "%name%", with: self.copName ?? "–", options: .caseInsensitive) ?? "")
                            .font(.body)
                            .foregroundColor(Color.get(.Text))
                            .multilineTextAlignment(.center)
                    }
                    VStack(spacing:16){
                        if (self.copCode?.lowercased() != "ac01"){
                            Button{
                                self.copResult = .confirmed
                                self.copWarning = false
                            } label: {
                                HStack{
                                    Spacer()
                                    Text("Confirm Payee Anyway")
                                    Spacer()
                                }
                            }
                            .buttonStyle(.secondary())
                        }
                        Button{
                            self.copResult = .rejected
                            self.copWarning = false
                        } label: {
                            HStack{
                                Spacer()
                                Text("Back to edit")
                                Spacer()
                            }
                        }
                            .buttonStyle(.primary())
                    }
                }
            }
        }
    }
}
//MARK: - Extended Views
extension CreatePayeeView{
    var gbpFields: some View{
        VStack(spacing:12){
            CustomField(value: self.$accountNumber, placeholder: "Account Number", type: .number, maxLength: 8)
                .disabled(self.loading || (self.callback == nil && self.selectedContact?.details.accountNumber?.isEmpty == false && self.accountNumber.isEmpty == false))
            CustomField(value: self.$sortCode, placeholder: "Sort Code", type: .number)
                .disabled(self.loading || (self.callback == nil && self.selectedContact?.details.sortCode?.isEmpty == false && self.sortCode.isEmpty == false))
                .onReceive(Just(self.sortCode), perform:{ _ in
                    //MARK: Remove all non-digits
                    var code = String(self.sortCode.filter("01234567890".contains).prefix(6))
                    self.sortCode = code.inserting(separator: "-", every: 2)
                })
        }
    }
    var eurFields: some View{
        VStack(spacing:12){
            CustomField(
                value: self.$wallet,
                placeholder: "Wallet number",
                maxLength: 13
            )
            .disabled(self.loading || !self.iban.isEmpty || !self.swift.isEmpty || (self.callback == nil && self.selectedContact?.details.accountNumber?.isEmpty == false && self.wallet.isEmpty == false))
            CustomField(value: self.$iban, placeholder: self.currency.lowercased() == "eur" ? "IBAN" : "Account Number/IBAN")
                .onReceive(Just(self.iban), perform:{ _ in
                    self.iban = self.iban.uppercased().replacingOccurrences(of: " ", with: "")
                })
                .disabled(self.loading || !self.wallet.isEmpty || (self.callback == nil && self.selectedContact?.details.iban?.isEmpty == false && self.iban.isEmpty == false))
            CustomField(value: self.$swift, placeholder: "SWIFT/BIC")
                .disabled(self.loading || !self.wallet.isEmpty || (self.callback == nil && self.selectedContact?.details.swiftCode?.isEmpty == false && self.swift.isEmpty == false))
        }
    }
    var addressForm: some View{
        VStack(spacing:12){
            CustomField(value: self.$country, placeholder: "Country", type: .select, options: self.countries, searchable: true)
                .disabled(self.loading || (self.callback == nil && self.selectedContact?.details.address?.countryCode?.isEmpty == false && self.country.isEmpty == false))
                .onChange(of: self.currency){ _ in
                    if (self.currency.lowercased() == "gbp"){
                        self.country = "GB"
                    }else{
                        self.country = ""
                    }
                }
                .onChange(of: self.country){ _ in
                    self.stateForSelectedCountryExists = isStateForCountryExists(self.country)
                }
            if (self.stateForSelectedCountryExists){
                CustomField(value: self.$state, placeholder: "State")
                    .disabled(self.loading || (self.callback == nil && self.selectedContact?.details.address?.state?.isEmpty == false && self.state.isEmpty == false))
            }
            CustomField(value: self.$street, placeholder: "Street")
                .disabled(self.loading || (self.callback == nil && self.selectedContact?.details.address?.street?.isEmpty == false && self.street.isEmpty == false))
            CustomField(value: self.$building, placeholder: "Building")
                .disabled(self.loading || (self.callback == nil && self.selectedContact?.details.address?.building?.isEmpty == false && self.building.isEmpty == false))
            CustomField(value: self.$city, placeholder: "City")
                .disabled(self.loading || (self.callback == nil && self.selectedContact?.details.address?.city?.isEmpty == false && self.city.isEmpty == false))
            CustomField(value: self.$postcode, placeholder: "Postcode")
                .disabled(self.loading || (self.callback == nil && self.selectedContact?.details.address?.postCode?.isEmpty == false && self.postcode.isEmpty == false))
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 36)
    }
}
//MARK: - Process
extension CreatePayeeView{
    func submit() async throws{
        self.loading = true
        
        var type: Contact.ContactType = .sortCode
        if (self.currency.lowercased() == "eur"){
            type = .IBAN
        }else if(self.currency.lowercased() == "usd"){
            type = .USD
        }
        
        let request = Contact(
            type: type,
            currency: self.currency,
            accountHolderName: self.holderName,
            details: .init(
                legalType: self.type == 0 ? .PRIVATE : .BUSINESS,
                accountNumber: self.currency.lowercased() == "gbp" ? self.accountNumber : self.wallet,
                sortCode: String(self.sortCode.filter("01234567890".contains)),
                swiftCode: self.swift,
                iban: self.iban,
                address: .init(
                    countryCode: self.country,
                    state: self.state,
                    city: self.city,
                    street: self.street,
                    building: self.currency.lowercased() != "gbp" ? (self.building.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "none" : self.building) : self.building,
                    postCode: self.postcode,
                    countryName: ""
                )
            )
        )
        if (self.selectedContact != nil){
            do{
                try await services.contacts.deleteCustomerContacts(
                    self.customer.id ?? "",
                    contactId: self.selectedContact!.contactId!
                )
                let contact = try await services.contacts.createCustomerContact(
                    self.customer.id ?? "",
                    contact: request
                )
                self.loading = false
                self.processSubmit(contact)
                return;
            }catch(let error){
                self.loading = false
                self.Error.handle(error)
                return;
            }
            return;
        }
        Task{
            do{
                self.copWarning = false
                self.copResult = nil
                let initiate = try await services.contacts.initiateCreateCustomerContact(
                    self.customer.id ?? "",
                    contact: request
                )
                if (initiate.copResponseCode != nil){
                    self.copCode = initiate.copResponseCode
                    self.copName = initiate.copNameMatch
                    switch(initiate.copResponseCode?.lowercased()){
                    case "match", "internal":
                        break;
                    default:
                        self.copWarning = true
                        self.copResult = nil
                        while(self.copResult == nil){
                            try? await Task.sleep(nanoseconds: 1_000_000_000)
                        }
                        self.copWarning = false
                        if (self.copResult == .rejected){
                            self.loading = false
                            return
                        }
                        break;
                    }
                }
                self.otpOperationId = initiate.operationId
                self.verifyOtp = true
                self.loading = false
                return;
                //TODO: Replace with await (await for otp result and continue
                self.loading = false
                self.processSubmit()
            }catch(let error){
                self.loading = false
                self.Error.handle(error)
                throw error
            }
        }
    }
    
    func processSubmit(_ contact: Contact? = nil){
        if (self.callback != nil){
            if case .CreatePayment(let details) = self.callback {
                self.Store.payment.accountId = details.account?.id
                self.Router.stack.removeLast()
                self.Router.goTo(
                    CreatePaymentView(
                        customer: details.customer!,
                        fetch: self.callback,
                        attachments: self.attachments
                    )
                )
            }
        }
        self.Router.back()
    }
}

struct CreatePayeeView: View, RouterPage {
    public var customer: CoreCustomer
    public var selectedContact: Contact? = nil
    public var callback: RouterPageCallback? = nil
    
    @EnvironmentObject var Store: ApplicationStore
    @EnvironmentObject var Error: ErrorHandlingService
    @EnvironmentObject var Router: RoutingController
    
    @State private var holderName: String = ""
    @State private var accountNumber: String = ""
    @State private var sortCode: String = ""
    @State private var iban: String = ""
    @State private var type: Int = 0
    @State private var country: String = "GB"
    @State private var city: String = ""
    @State private var state: String = ""
    @State private var street: String = ""
    @State private var building: String = ""
    @State private var postcode: String = ""
    @State private var currency: String = "GBP"
    @State private var wallet: String = ""
    @State private var swift: String = ""
    @State private var stateForSelectedCountryExists: Bool = false
    
    @State private var loading: Bool = false
    
    //OTP
    @State private var verifyOtp: Bool = false
    @State private var otpOperationId: String = ""
    //COP
    @State private var copCode: String? = nil
    @State private var copName: String? = nil
    @State private var copResult: CreatePaymentView.CopOperationResult? = nil
    @State private var copWarning: Bool = false
    @FetchRequest(sortDescriptors:[]) var reasonCodeData: FetchedResults<CoreReasonCodeLookupDto>
    
    //Attachments
    @Binding public var attachments: Array<FileAttachment>
    
    var legalTypes: [Tab]{
        var tabs: [Tab] = []
        tabs.append(.init(icon: Image("user"), title: "Individual", id: 0))
        tabs.append(.init(icon: Image("building-4"), title: "Business", id: 1))
        return tabs
    }
    
    var countries: [Option]{
        return countryCodes
    }
    
    var currencies: [Option]{
        return [
            Option(
                id: "EUR",
                label: "EUR"
            ),
            Option(
                id: "GBP",
                label: "GBP"
            ),
            Option(
                id: "USD",
                label: "USD"
            ),
        ]
    }
    
    var formPassed: Bool{
        if (self.holderName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty){
            return false
        }
        if (self.currency.lowercased() == "gbp"){
            if (self.accountNumber.isEmpty || self.sortCode.isEmpty){
                return false
            }
        }else{
            if (self.wallet.isEmpty && self.swift.isEmpty && self.iban.isEmpty){
                return false
            }
            if (!self.swift.isEmpty && self.iban.isEmpty){
                return false
            }
            if (!self.iban.isEmpty && self.swift.isEmpty){
                return false
            }
            if (!self.wallet.isEmpty && self.wallet.count != 13){
                return false
            }
            //Adress check
            if (self.country.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty){
                return false
            }
            if (self.stateForSelectedCountryExists && self.state.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty){
                return false
            }
            if (self.street.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty){
                return false
            }
            if (self.city.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty){
                return false
            }
        }
        return true
    }
    
    var body: some View {
        ApplicationNavigatorContainerView{
            GeometryReader{ geometry in
                ZStack{
                    ScrollView{
                        VStack(spacing: 0){
                            Header(back:{
                                self.processSubmit()
                            }, title: self.selectedContact == nil ? "Add new payee" : "Edit Payee")
                            Text(LocalizedStringKey("Please enter the payee’s account details"))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .font(.title2.bold())
                                .foregroundColor(Color.get(.Text))
                                .multilineTextAlignment(.leading)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 16)
                            
                            VStack(spacing:12){
                                CustomField(value: self.$currency, placeholder: "Select currency", type: .select, options: self.currencies)
                                    .disabled(self.loading || (self.callback == nil && self.selectedContact?.currency.isEmpty == false && self.currency.isEmpty == false))
                                CustomField(value: self.$holderName, placeholder: "Account holder's name")
                                    .disabled(self.loading || (self.callback == nil && self.selectedContact?.accountHolderName.isEmpty == false && self.holderName.isEmpty == false))
                                if (self.currency.lowercased() == "gbp"){
                                    self.gbpFields
                                }else{
                                    self.eurFields
                                }
                                Text(LocalizedStringKey("Legal Type"))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .font(.subheadline.weight(.medium))
                                    .multilineTextAlignment(.leading)
                                    .foregroundColor(Color.get(.MiddleGray))
                                Tabs(tabs: self.legalTypes, selectedTab: $type)
                                    .disabled(self.loading || (self.callback == nil && self.selectedContact != nil))
                            }
                            .padding(.horizontal, 16)
                            
                            Text(LocalizedStringKey("Recipient Address"))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .font(.title2.bold())
                                .foregroundColor(Color.get(.Text))
                                .multilineTextAlignment(.leading)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 16)
                                .padding(.top, 46)
                            
                            self.addressForm
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
                            } label:{
                                HStack{
                                    Spacer()
                                    Text(LocalizedStringKey(self.selectedContact == nil ?  "Confirm New Payee" : "Save"))
                                    Spacer()
                                }
                            }
                            .buttonStyle(.primary())
                            .disabled(!self.formPassed || self.loading)
                            .loader(self.$loading)
                            .padding(.horizontal, 16)
                        }
                        .frame(
                            maxWidth: .infinity,
                            minHeight: geometry.size.height - geometry.safeAreaInsets.bottom
                        )
                    }
                    
                    //MARK: – Overlays
                    if (self.verifyOtp){
                        OTPView(operationId: self.$otpOperationId, onVerify: self.otpConfirmed, onCancel: self.otpRejected)
                            .environmentObject(self.Error)
                    }
                    if (self.copWarning){
                        PresentationSheet(isPresented: self.$copWarning){
                            VStack{
                                self.copPopup
                            }
                            .padding(.bottom, geometry.safeAreaInsets.bottom)
                            .padding(20)
                            .padding(.top,10)
                        }
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationTitle("")
        .background(Color.get(.Background))
        .onAppear{
            if (self.selectedContact != nil){
                //Prefill data
                if (self.selectedContact?.currency.isEmpty == false){
                    self.currency = self.selectedContact!.currency.uppercased()
                }
                if (self.selectedContact?.accountHolderName.isEmpty == false){
                    self.holderName = self.selectedContact!.accountHolderName
                }
                if (self.selectedContact?.details.accountNumber?.isEmpty == false){
                    if (self.currency.lowercased() == "eur"){
                        self.wallet = self.selectedContact!.details.accountNumber!
                    }else{
                        self.accountNumber = self.selectedContact!.details.accountNumber!
                    }
                }
                if (self.selectedContact?.details.sortCode?.isEmpty == false){
                    self.sortCode = self.selectedContact!.details.sortCode!
                }
                if (self.selectedContact?.details.iban?.isEmpty == false){
                    self.iban = self.selectedContact!.details.iban!
                }
                if (self.selectedContact?.details.swiftCode?.isEmpty == false){
                    self.swift = self.selectedContact!.details.swiftCode!
                }
                if ((self.selectedContact?.details.legalType) != nil){
                    if (self.selectedContact!.details.legalType == .PRIVATE){
                        self.type = 0
                    }else{
                        self.type = 1
                    }
                }
                if (self.selectedContact?.details.address != nil){
                    DispatchQueue.main.asyncAfter(deadline: .now()+0.1){
                        if (self.selectedContact!.details.address!.countryCode?.isEmpty == false){
                            self.country = self.selectedContact!.details.address!.countryCode!.uppercased()
                            self.stateForSelectedCountryExists = isStateForCountryExists(self.country)
                        }
                        if (self.selectedContact!.details.address!.state?.isEmpty == false){
                            self.state = self.selectedContact!.details.address!.state!
                        }
                        if (self.selectedContact!.details.address!.city?.isEmpty == false){
                            self.city = self.selectedContact!.details.address!.city!
                        }
                        if (self.selectedContact!.details.address!.street?.isEmpty == false){
                            self.street = self.selectedContact!.details.address!.street!
                        }
                        if (self.selectedContact!.details.address!.building?.isEmpty == false){
                            self.building = self.selectedContact!.details.address!.building!
                        }
                        if (self.selectedContact!.details.address!.postCode?.isEmpty == false){
                            self.postcode = self.selectedContact!.details.address!.postCode!
                        }
                    }
                }
            }
        }
        .onChange(of: self.copWarning, perform:{ _ in
            if (self.copWarning == false && self.copResult == nil){
                self.copResult = .rejected
            }
        })
    }
}
