//
//  Store.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 26.09.2023.
//

import Foundation
import SwiftUI
import Combine

class ApplicationStore: ObservableObject{
    private var subscriptions = Set<AnyCancellable>()
    
    @Published var selectedAccountId: String = ""
    @Published var selectedTransactionId: String = ""
    @Published var showTrustedDevicePopup: Bool = false
    @Published var showTrustedNotificationsDisabled: Bool = false
    
    @Published var notification: PushNotification? = nil
    @Published var receivedNotification: PushNotification? = nil
    @Published var confirmOperation: Bool = false
    @Published var loggedIn: Bool = false
    @Published var processLogin: Bool = false
    @Published var processLoginURL: URL? = nil
    
    @ObservedObject var accounts: AccountsStore = AccountsStore()
    @ObservedObject var contacts: ContactsStore = ContactsStore()
    @ObservedObject var user: UserStore = UserStore()
    @ObservedObject var transaction: TransactionStore = TransactionStore()
    @ObservedObject var onboarding: OnboardingStore = OnboardingStore()
    @ObservedObject var payment: PaymentStore = PaymentStore()
    @ObservedObject var deviceData: DeviceDataStore = DeviceDataStore()
        
    init(){
        //MARK: Init storage
        self.transaction.objectWillChange.sink { [weak self] (store) in
            self?.objectWillChange.send()
        }
        .store(in: &self.subscriptions)
        self.accounts.objectWillChange.sink { [weak self] (store) in
            self?.objectWillChange.send()
        }
        .store(in: &self.subscriptions)
        
        self.contacts.objectWillChange.sink { [weak self] (store) in
            self?.objectWillChange.send()
        }
        .store(in: &self.subscriptions)
        
        self.user.objectWillChange.sink { [weak self] (store) in
            self?.objectWillChange.send()
        }
        .store(in: &self.subscriptions)
        self.onboarding.objectWillChange.sink { [weak self] (store) in
            self?.objectWillChange.send()
        }
        .store(in: &self.subscriptions)
        
        self.payment.objectWillChange.sink { [weak self] (store) in
            self?.objectWillChange.send()
        }
        .store(in: &self.subscriptions)
        
        self.deviceData.objectWillChange.sink { [weak self] (store) in
            self?.objectWillChange.send()
        }
        .store(in: &self.subscriptions)
    }
    
    func logout() async throws{
        //Delete FCM token
        Task{
            do{
                let service = DeviceDataService()
                try await service.refreshFBCTok()
            }
        }
        //Logout
        Task{
            do{
                try await services.identity.logout()
            }
        }
        //MARK: Remove all stored data
        let domain = Bundle.main.bundleIdentifier!
        UserDefaults.standard.removePersistentDomain(forName: domain)
        UserDefaults.standard.synchronize()
        
        NotificationCenter.default.post(name: .Logout, object: nil)
        
        //MARK: Clean storage sensetive data
        await MainActor.run{
            self.clean()
            self.accounts.clean()
            self.contacts.clean()
            self.onboarding.clean()
            self.user.clean()
            self.deviceData.clean()
        }
    }
    
    func clean(){
        self.selectedAccountId = ""
        self.selectedTransactionId = ""
        self.loggedIn = false
    }
    
    func applicationLoaded(){
        if (self.onboarding.application.isApplicationExists){
            let businessEntity = self.onboarding.businessEntity
            if (businessEntity != nil){
                if (businessEntity!.has("GENname")){ //OR GEAliasNname
                    self.onboarding.business.legalName = businessEntity!.at("GENname") ?? ""
                }
                if (businessEntity!.has("GENregno")){
                    self.onboarding.business.registrationNumber = businessEntity!.at("GENregno") ?? ""
                }
                if (businessEntity!.has("GENdateincorp")){
                    self.onboarding.business.incorporationDate = businessEntity!.at("GENdateincorp") ?? ""
                }
                if (businessEntity!.has("GENcountryincorp")){ //OR GENbusaddcountry
                    self.onboarding.business.registredAddress.country = businessEntity!.at("GENcountryincorp") ?? ""
                }
                if (businessEntity!.has("GENbusaddstreet")){
                    self.onboarding.business.registredAddress.firstLine = businessEntity!.at("GENbusaddstreet") ?? ""
                }
                if (businessEntity!.has("GENbusaddbuildingno")){
                    self.onboarding.business.registredAddress.secondLine = businessEntity!.at("GENbusaddbuildingno") ?? ""
                }
                if (businessEntity!.has("GENbusaddcity")){
                    self.onboarding.business.registredAddress.city = businessEntity!.at("GENbusaddcity") ?? ""
                }
                if (businessEntity!.has("GENbusaddpostcode")){
                    self.onboarding.business.registredAddress.postcode = businessEntity!.at("GENbusaddpostcode") ?? ""
                }
                if (businessEntity!.has("GENbusaddstate")){
                    self.onboarding.business.registredAddress.state = businessEntity!.at("GENbusaddstate") ?? ""
                }
            }
        }
        if (self.onboarding.application.isApplicationExists){
            let individualEntity = onboarding.individualEntity
            if (individualEntity != nil){
                if (individualEntity!.has("GENiddocnumber")){
                    var i = 0
                    while(i < individualEntity!.int("GENiddocnumber")!){
                        var attachment = FileAttachment(filename: "Uploaded.jpg")
                        attachment.key = randomString(length: 6)
                        attachment.uploaded = true
                        
                        self.onboarding.proofOfIdentitiesUploaded.append(attachment)
                        i += 1
                    }
                }
                if (individualEntity!.has("GENselfienumber")){
                    if(individualEntity!.int("GENselfienumber")! > 0){
                        var attachment = FileAttachment(filename: "Uploaded.jpg")
                        attachment.key = randomString(length: 6)
                        attachment.uploaded = true
                        
                        self.onboarding.selfie = attachment
                    }
                }
                if (individualEntity!.has("GENresadddocnumber")){
                    var i = 0
                    while(i < individualEntity!.int("GENresadddocnumber")!){
                        var attachment = FileAttachment(filename: "Uploaded.jpg")
                        attachment.key = randomString(length: 6)
                        attachment.uploaded = true
                        
                        self.onboarding.proofOfAddressUploaded.append(attachment)
                        i += 1
                    }
                }
                
                //Fill person details
                if self.user.person == nil || (self.user.person!.id.isEmpty && self.user.person!.givenName?.isEmpty == true){
                    if (self.user.person == nil){
                        self.user.person = .init(
                            countryOfBirth: "",
                            dateOfBirth: "",
                            email: "",
                            gender: "",
                            givenName: "",
                            id: "",
                            phone: "",
                            surname: ""
                        )
                    }
                    if (self.user.person!.givenName?.isEmpty == true && individualEntity!.has("GENname")){
                        self.user.person!.givenName = individualEntity!.at("GENname")!
                    }
                    if (self.user.person!.surname?.isEmpty == true && individualEntity!.has("GENsurname")){
                        self.user.person!.surname = individualEntity!.at("GENsurname")!
                    }
                    if (self.user.person!.middleName == nil || self.user.person!.middleName!.isEmpty) && individualEntity!.has("GENmiddlename"){
                        self.user.person!.middleName = individualEntity!.at("GENmiddlename")!
                    }
                    if (self.user.person!.countryOfBirth?.isEmpty == true && individualEntity!.has("GENresaddcountry")){
                        self.user.person!.countryOfBirth = individualEntity!.at("GENresaddcountry")!
                    }
                }
            }
        }
    }
}

class TransactionStore: ObservableObject{
}

class DeviceDataStore: ObservableObject{
    @Published var deviceId: String? = nil
    @Published var isTrusted: Bool = false
    
    func clean(){
        self.deviceId = nil
        self.isTrusted = false
    }
}

class PaymentStore: ObservableObject{
    @Published var payeeId: String? = nil
    @Published var accountId: String? = nil
    @Published var customerId: String? = nil
    
    @Published var amount: String = ""
    @Published var totalAmount: String = ""
    @Published var totalPrice: String = ""
    @Published var reference: String = ""
    @Published var orderId: String = ""
    
    func clean(){
        self.payeeId = nil
        self.accountId = nil
        self.customerId = nil
        
        self.amount = ""
        self.totalAmount = ""
        self.totalPrice = ""
        self.reference = ""
        self.orderId = ""
    }
}

class AccountsStore: ObservableObject{
    @Published var list: Array<Account> = []
    
    func clean(){
        self.list = []
    }
}

class ContactsStore: ObservableObject{
    @Published var list: Array<Contact> = []
    @Published var customerId: String? = nil
    @Published var selectedContact: Contact? = nil
    
    func clean(){
        self.list = []
        self.customerId = nil
        self.selectedContact = nil
    }
}

class UserStore: ObservableObject{
    @Published var user_id: String? = nil
    @Published var email: String? = nil
    @Published var phone: String? = nil
    @Published var username: String? = nil
    @Published var accountNotRequested: Bool? = false
    
    @Published var customerId: String? = nil
    @Published var previousCustomerId: String? = nil
    
    @Published var person: Person? = nil
    @Published var organisation: Organisation? = nil
    @Published var customers: Array<KycpService.CustomersResponse.Customer> = []
    
    @Published var loading: Bool = false
    
    //Load user
    func load() async throws{
        self.loading = true
        do{
            let defaults = UserDefaults.standard
            if(defaults.value(forKey: "accessToken") != nil){
                let token = try JSONDecoder().decode(AuthenticationService.AccessToken.self,from: defaults.data(forKey: "accessToken")!)
                let data = try AuthenticationService.obtainDataFromAccessToken(token: token)
                
                self.email = data.email
                self.phone = data.phone
                self.username = data.username
                self.accountNotRequested = data.accountNotRequested
                self.user_id = data.customer_id
                
                self.loading = false
            }
            self.loading = false
        }catch(let error){
            self.loading = false
            throw error
        }
    }
    
    func loadPerson() async throws -> Person?{
        self.loading = true
        do{
            let person = try await services.kycp.getPerson()
            if (person != nil){
                self.person = person
            }
            self.loading = false
            return nil
        }catch(let error){
            self.loading = false
            throw error
        }
    }
    
    func loadCustomers() async throws -> KycpService.CustomersResponse?{
        self.loading = true
        do{
            let customers = try await services.kycp.getCustomers()
            if (customers != nil){
                self.customers = customers.customers
            }
            self.loading = false
            return nil
        }catch(let error){
            self.loading = false
            throw error
        }
    }
    
    func clean(){
        self.email = nil
        self.phone = nil
        self.username = nil
        self.customerId = nil
        self.previousCustomerId = nil
        self.person = nil
        self.organisation = nil
        self.customers = []
        self.user_id = nil
    }
}

class OnboardingStore: ObservableObject{
    private var subscriptions = Set<AnyCancellable>()
    
    @Published var countries: [KycpService.LookUpResponse.LookUpItem] = []
    @Published var genders: [KycpService.LookUpResponse.LookUpItem] = []
    @Published var currencies: [KycpService.LookUpResponse.LookUpItem] = []
    @Published var corporateServices: [KycpService.LookUpResponse.LookUpItem] = []
    @Published var companyTypes: [KycpService.LookUpResponse.LookUpItem] = []
    @Published var mailingAddressDifferentOptions: [KycpService.LookUpResponse.LookUpItem] = []
    @Published var businessCategories: [KycpService.LookUpResponse.LookUpItem] = []
    @Published var companyStructure: [KycpService.LookUpResponse.LookUpItem] = []
    @Published var regulatedOptions: [KycpService.LookUpResponse.LookUpItem] = []
    @Published var sellOptions: [KycpService.LookUpResponse.LookUpItem] = []
    @Published var usageOptions: [KycpService.LookUpResponse.LookUpItem] = []
    @Published var customerOptions: [KycpService.LookUpResponse.LookUpItem] = []
    @Published var turnoverOptions: [KycpService.LookUpResponse.LookUpItem] = []
    @Published var moneyOutOptions: [KycpService.LookUpResponse.LookUpItem] = []
    @Published var inwardTransactions: [KycpService.LookUpResponse.LookUpItem] = []
    @Published var paymentsPerMonth: [KycpService.LookUpResponse.LookUpItem] = [
        .init(externalRef:"1000", id: 1000, name: "Less than 1,000"),
        .init(externalRef:"10000", id: 10000, name: "1,000 to 10,000"),
        .init(externalRef:"100000", id: 100000, name: "10,000 to 100,000"),
        .init(externalRef:"1000000", id: 1000000, name: "More than 100,000"),
    ]
    @Published var averageTransactions: [KycpService.LookUpResponse.LookUpItem] = []
    @Published var companySizes: [KycpService.LookUpResponse.LookUpItem] = []
    
    @ObservedObject var person: PersonStore = .init()
    @ObservedObject var application: KYCApplicationStore = .init()
    @ObservedObject var business: KYCBusinessStore = .init()
    
    @Published var customerEmail: String? = nil
    @Published var proofOfIdentityDocumentType: String = ""
    @Published var proofOfIdentitiesUploaded: [FileAttachment] = []
    @Published var selfie: FileAttachment? = nil
    @Published var proofOfAddressDocumentType: String = ""
    @Published var proofOfAddressUploaded: [FileAttachment] = []
    @Published var role: Int = -1
    @Published var processing: Bool = false
    
    func loadCountries() async throws{
        let response = try await services.kycp.getLookUp(.countries)
        self.countries = response.data
    }
    
    func loadGenders() async throws{
        let response = try await services.kycp.getLookUp(.genders)
        self.genders = response.data
    }
    
    func loadCorporateServices() async throws{
        let response = try await services.kycp.getLookUp(.corporateServices)
        self.corporateServices = response.data
    }
    
    func loadCurrencies() async throws{
        let response = try await services.kycp.getLookUp(.currencies)
        self.currencies = response.data
    }
    
    func loadCompanyTypes() async throws{
        let response = try await services.kycp.getLookUp(.companyTypes)
        self.companyTypes = response.data
    }
    
    func loadMailingAddressDifferentOptions() async throws{
        let response = try await services.kycp.getLookUp(.mailingAddressIsDifferent)
        self.mailingAddressDifferentOptions = response.data
    }
    
    func loadBusinessCategories() async throws{
        let response = try await services.kycp.getLookUp(.businessCategories)
        self.businessCategories = response.data
    }
    
    func loadCompanyStructure() async throws{
        let response = try await services.kycp.getLookUp(.companyStructure)
        self.companyStructure = response.data
    }
    
    func loadRegulatoryOptions() async throws{
        let response = try await services.kycp.getLookUp(.regulationOptions)
        self.regulatedOptions = response.data
    }
    
    func loadServiceUsage() async throws{
        let response = try await services.kycp.getLookUp(.serviceUsage)
        self.usageOptions = response.data
    }
    
    func loadSellOptions() async throws{
        let response = try await services.kycp.getLookUp(.salesChannels)
        self.sellOptions = response.data
    }
    
    func loadCustomerOptions() async throws{
        let response = try await services.kycp.getLookUp(.customers)
        self.customerOptions = response.data
    }
    
    func loadTurnoverOptions() async throws{
        let response = try await services.kycp.getLookUp(.turnover)
        self.turnoverOptions = response.data
    }
    
    func loadVolumeBands() async throws{
        let response = try await services.kycp.getLookUp(.volumeBands)
        self.averageTransactions = response.data
    }
    
    func loadCompanySize() async throws{
        let response = try await services.kycp.getLookUp(.sizeBands)
        self.companySizes = response.data
    }
    
    init(){
        self.person.objectWillChange.sink { [weak self] (store) in
            self?.objectWillChange.send()
        }
        .store(in: &self.subscriptions)
        self.application.objectWillChange.sink { [weak self] (store) in
            self?.objectWillChange.send()
        }
        .store(in: &self.subscriptions)
        self.business.objectWillChange.sink { [weak self] (store) in
            self?.objectWillChange.send()
        }
        .store(in: &self.subscriptions)
    }
    
    func clean(){
        self.person.clean()
        self.application.clean()
        self.business.clean()
        
        self.customerEmail = ""
        self.proofOfIdentityDocumentType = ""
        self.proofOfIdentitiesUploaded = []
        self.selfie = nil
        self.proofOfAddressDocumentType = ""
        self.proofOfAddressUploaded = []
    }
    
    var individualEntity: KYCEntity?{
        return self.application.allEntities.first(where: {entity in
            return (entity.isIndividualEntity == true && self.customerEmail != nil && entity.at("GENemail") == self.customerEmail)
        })
    }
    var businessEntity: KYCEntity?{
        let root = self.application.root
        if (root != nil && root!.isIndividualEntity == false){
            return root
        }
        return self.application.allEntities.first(where: {entity in
            return (entity.isIndividualEntity == false)
        })
    }
    
    var flow: [KYCStep]{
        var flow: [KYCStep] = []
        
        if (!self.application.isApplicationExists){
            flow.append(.ChooseAccountType)
        }
        
        //Look at top-level entity to detect flow type
        let root = self.application.root
        if (root != nil){
            if (root!.isIndividualEntity){
                let individual = self.individualEntity
                flow.append(.IndividualCurrency)
                if (individual == nil){
                    return flow
                }
                if (!individual!.has("GENcorporateservices")){
                    return flow
                }
                flow.append(.VerifyPersonalIdentity)
                if (!individual!.has("GENselfienumber")){
                    return flow
                }
                flow.append(.ProofOfAddress)
                if (!individual!.has("GENresadddocnumber")){
                    return flow
                }
                flow.append(.ConfirmIndividual)
                if (!individual!.has("GENindisconfirmed")){
                    return flow
                }
            }else{
                flow.append(.IncorporationCountry)
                if (!root!.has("GENname")){
                    return flow
                }
                flow.append(.BusinessAdress)
                if (!root!.has("GENbusaddcity")){
                    return flow
                }
                flow.append(.BusinessCurrency)
                if (!root!.has("GENcorporateservices")){
                    return flow
                }
                flow.append(.VerifyPersonalIdentity)
                //MARK: Business - individual information
                let individual = self.individualEntity
                if (individual == nil){
                    return flow
                }
                if (individual != nil){
                    if (!individual!.has("GENselfienumber")){
                        return flow
                    }
                    
                    flow.append(.ProofOfAddress)
                    if (!individual!.has("GENresadddocnumber")){
                        return flow
                    }
                    
                    flow.append(.ConfirmIndividual)
                    if (!individual!.has("GENindisconfirmed")){
                        return flow
                    }
                    
                    flow.append(.BusinessCompanyRole)
                    if (!root!.has("GENdirectorsadded")){
                        return flow
                    }
                    
                    flow.append(.BusinessCompanyType)
                    if (!root!.has("GENcompanytype")){
                        return flow
                    }
                    flow.append(.BusinessCountryOfOperation)
                    if (!root!.has("GENcountriesofbusiness")){
                        return flow
                    }
                    flow.append(.BusinessOperatingAddress)
                    if (!root!.has("GENopsadddifftoregadd")){
                        return flow
                    }
                    flow.append(.BusinessUsage)
                    if (!root!.has("GENservicesusage")){
                        return flow
                    }
                    flow.append(.BusinessNature)
                    if (!root!.has("GENnatureofbusiness")){
                        return flow
                    }else{
                        let option = root!.at("GENnatureofbusiness")
                        if (option != nil){
                            if (BusinessNatureView.isOtherSelected(option!)){
                                flow.append(.BusinessDescription)
                                if (!root!.has("GENnatureofbusinessdescription")){
                                    return flow
                                }
                            }
                        }
                    }
                    flow.append(.BusinessRegulated)
                    if (!root!.has("GENregulatedbusiness")){
                        return flow
                    }
                    //If business regulated - switch to regulatory
                    let regulatedPositiveOption = self.regulatedPositiveOption
                    if (regulatedPositiveOption != nil && root!.at("GENregulatedbusiness") != nil){
                        let option = root!.at("GENregulatedbusiness")
                        if (String(regulatedPositiveOption!.id) == String(option!)){
                            flow.append(.BusinessRegulatory)
                            
                            if (!root!.has("GENregulator")){
                                return flow
                            }
                        }
                    }
                    flow.append(.BusinessSell)
                    if (!root!.has("GENformatforsales")){
                        return flow
                    }
                    flow.append(.BusinessCustomers)
                    if (!root!.has("GENtypeofcustomers")){
                        return flow
                    }
                    flow.append(.BusinessTurnover)
                    if (!root!.has("GENannualturnover")){
                        return flow
                    }
                    flow.append(.BusinessMoneySend)
                    if (!root!.has("GENaveragetransactionvalue")){
                        return flow
                    }
                    flow.append(.BusinessPayments)
                    if (!root!.has("GENaveragetransactionvolumes")){
                        return flow
                    }
                    flow.append(.BusinessLargestSinglePayment)
                    if (!root!.has("GENsinglelargestpayment")){
                        return flow
                    }
                    flow.append(.BusinessInternational)
                    if (!root!.has("GENcountriesofpayments")){
                        return flow
                    }
                    flow.append(.BusinessDeposit)
                    if (!root!.has("GENaverageaccountdeposit")){
                        return flow
                    }
                    flow.append(.BusinessCompanySize)
                    if (!root!.has("GENaveragecompanysize")){
                        return flow
                    }
                    flow.append(.BusinessType)
                    if (!root!.has("GENstructure")){
                        return flow
                    }
                    flow.append(.BusinessConfirmation)
                    if (!root!.has("GENcompisconfirmed")){
                        return flow
                    }
                    if (individual != nil && individual!.has("GENindisconfirmed")){
                        flow.append(.inReview)
                        return flow
                    }
                }
            }
        }
        
        return flow;
    }
    
    var currentFlowPage: any View{
        let flow = self.flow
        let last = flow.last
        if (last != nil){
            return self.application.relatedScreen(last!)
        }
        return AccountTypeSelectionView()
    }
    
    var regulatedPositiveOption: KycpService.LookUpResponse.LookUpItem?{
        return self.regulatedOptions.first(where: {$0.name.lowercased() == "yes"})
    }
    func isCountryIsUK(_ country: String) -> Bool{
        return country == "39461"
    }
    
    var directors: [BusinessDirectorsView.BusinessDirector] {
        var directors: [BusinessDirectorsView.BusinessDirector] = []
        //MARK: Apply application added directors
        let businessEntity = self.businessEntity
        let individualEntity = self.individualEntity
        let isBusinessDirector = self.role
        
        if (businessEntity != nil && businessEntity!.entities.isEmpty == false){
            let _ = businessEntity!.entities.map({ entity in
                if (isBusinessDirector == 0 && entity.id == individualEntity?.id){
                    
                }else if(entity.id != nil){
                    //Transform entity to director entity
                    directors.append(.init(
                        firstName: entity.at("GENname") ?? "",
                        lastName: entity.at("GENsurname") ?? "",
                        middleName: entity.at("GENmiddlename") ?? "",
                        email: entity.at("GENemail") ?? "",
                        phone: entity.at("GENmobile") ?? "",
                        id: String(entity.id!)
                    ))
                }
            })
        }
        //Add local directors & exlude those who alredy on BE
        let _ = self.business.directors.map({ director in
            //MARK: Check is alredy on list?
            let _email = director.email.lowercased()
            let _phone = director.phone.lowercased().filter("01234567890".contains)
            let index = directors.firstIndex(where: { entity in
                if (entity.email.lowercased() == _email){
                    return true
                }
                if(entity.phone.lowercased().filter("01234567890".contains) == _phone){
                    return true
                }
                return false
            })
            if (index == nil){
                directors.append(director)
            }
        })
        
        return directors
    }
}

enum KYCStep{
    case ChooseAccountType
    case IncorporationCountry
    case BusinessAdress
    case BusinessCurrency
    case VerifyPersonalIdentity
    case ProofOfAddress
    case ConfirmIndividual
    case BusinessCompanyRole
    case BusinessDirectors
    case BusinessCompanyType
    case BusinessCountryOfOperation
    case BusinessOperatingAddress
    case BusinessUsage
    case BusinessNature
    case BusinessRegulated
    case BusinessSell
    case BusinessRegulatory
    case BusinessCustomers
    case BusinessTurnover
    case BusinessMoneySend
    case BusinessPayments
    case BusinessLargestSinglePayment
    case BusinessInternational
    case BusinessDeposit
    case BusinessCompanySize
    case BusinessType
    case BusinessConfirmation
    case IndividualCurrency
    case BusinessDescription
    case inReview
}

class KYCApplicationStore: ObservableObject{
    @Published public var id: String?
    @Published public var uid: String?
    @Published public var programId: Int = 1
    @Published public var finalized: Bool = false
    @Published public var entities: [KYCEntity] = []
    @Published public var customerId: String = ""
    
    func clean(){
        self.id = nil
        self.uid = nil
        self.programId = 1
        self.finalized = false
        self.entities = []
        self.customerId = ""
    }
    
    func parse(_ application: Application?){
        self.clean()
        if (application != nil && application?.id != nil){
            self.id = application!.id!
            self.uid = application!.uid!
            self.programId = application!.programId
            self.finalized = application!.finalized
            self.customerId = application!.customerId
            let _ = application?.entities.map({
                let entity = self.transformEntity($0)
                self.entities.append(entity)
            })
        }
    }
    
    func transformEntity(_ entity: Entity) -> KYCEntity{
        var item: KYCEntity = KYCEntity()
        item.id = entity.id
        item.entityType =  entity.entityType ?? "individual"
        item.applicationEntityId = entity.applicationEntityId
        item.fields = entity.fields
        if (entity.entities != nil && entity.entities!.isEmpty == false){
            item.entities = entity.entities!.map({
                return self.transformEntity($0)
            })
        }
        return item;
    }
    
    func relatedScreen(_ step: KYCStep) -> any View{
        switch(step){
        case .ChooseAccountType:
            return AccountTypeSelectionView()
        case .IncorporationCountry:
            return CountryOfIncorporationView()
        case .BusinessAdress:
            return BusinessAddressView()
        case  .BusinessCurrency:
            return BusinessCurrencyView()
        case .VerifyPersonalIdentity:
            return VerifyPersonalIdentityView()
        case .ProofOfAddress:
            return ProofOfAddressView()
        case .ConfirmIndividual:
            return ConfirmIndividualView()
        case .BusinessCompanyRole:
            return BusinessCompanyRoleView()
        case .BusinessDirectors:
            return BusinessDirectorsView()
        case .BusinessCompanyType:
            return BusinessCompanyTypeView()
        case .BusinessCountryOfOperation:
            return BusinessCountryOfOperationView()
        case .BusinessOperatingAddress:
            return BusinessOperatingAddressView()
        case .BusinessUsage:
            return BusinessUsageView()
        case .BusinessNature:
            return BusinessNatureView()
        case .BusinessRegulated:
            return BusinessRegulatedView()
        case .BusinessSell:
            return BusinessSellView()
        case .BusinessRegulatory:
            return BusinessRegulatoryView()
        case .BusinessCustomers:
            return BusinessCustomersView()
        case .BusinessTurnover:
            return BusinessTurnoverView()
        case .BusinessMoneySend:
            return BusinessMoneySendView()
        case .BusinessPayments:
            return BusinessPaymentsView()
        case .BusinessLargestSinglePayment:
            return BusinessLargestSinglePaymentView()
        case .BusinessInternational:
            return BusinessInternationalView()
        case .BusinessDeposit:
            return BusinessDepositView()
        case .BusinessCompanySize:
            return BusinessCompanySizeView()
        case .BusinessType:
            return BusinessTypeView()
        case .BusinessConfirmation:
            return BusinessConfirmationView()
        case .IndividualCurrency:
            return CurrencyIndividualSelectView()
        case .BusinessDescription:
            return BusinessDescriptionView()
        case .inReview:
            return ApplicationInReviewView()
        }
    }
    
    var isApplicationExists: Bool {
        return self.id != nil && self.id!.isEmpty == false
    }
    
    var allEntities: [KYCEntity]{
        return self.collectEntities(self.entities)
    }
    
    func collectEntities(_ entities: [KYCEntity]) -> [KYCEntity]{
        var output: [KYCEntity] = []
        if (entities.count > 0){
            var i = 0;
            while(i < entities.count){
                output.append(entities[i])
                if (entities[i].entities.count > 0){
                    output.append(contentsOf: self.collectEntities(entities[i].entities))
                }
                i += 1
            }
        }
        return output
    }
    
    var root: KYCEntity?{
        return self.entities.first
    }
    
    /**
    Simple post request
     */
    func post(_ application: Application) async throws -> Application{
        func convertToEntity(_ entity: Entity) -> KYCEntity{
            var output = KYCEntity()
            output.fields = entity.fields
            output.id = entity.id
            output.entityType = entity.entityType ?? "individual"
            output.applicationEntityId = entity.applicationEntityId
            if (entity.entities != nil){
                output.entities = entity.entities!.map({ child in
                    return convertToEntity(child)
                })
            }
            return output
        }
        
        var body: [String:Any] = [
            "id": application.id!,
            "uid": application.uid!,
            "finalized": application.finalized,
            "customerId": application.customerId,
            "programId": application.programId,
            "entities":
                application.entities.map({ entity in
                    return self.mapEntityForPost(convertToEntity(entity))
                })
        ]
        
        #if DEBUG
        print("KYC:POST – ", body)
        #endif
        return try await services.kycp.update(body)
    }
    
    /***
     Create KYC application
     */
    func create(_ entities: [KYCEntity], customerId: String?) async throws -> Application{
        var body: [String:Any] = [
            "entities": []
        ]
        if (self.id != nil){
            body["id"] = self.id!
        }
        if (self.uid != nil){
            body["uid"] = self.uid!
        }
        if (customerId != nil){
            body["customerId"] = customerId!
        }
        body["entities"] = entities.map({ entity in
            return self.mapEntityForPost(entity)
        })
        
        #if DEBUG
        print("KYC:Create Application – ", body)
        #endif
        let res = try await services.kycp.update(body)
        return res
    }
    
    /***
     Add entity to application
     */
    func createEntity(_ entity: KYCEntity, rootEntityId: Int?) async throws -> Application{
        var body: [String:Any] = [
            "id": self.id!,
            "uid": self.uid!,
            "entities": []
        ]
        var entities: [KYCEntity] = []
        
        if (rootEntityId != nil){
            func loop(_ entities: [KYCEntity]) -> [KYCEntity]{
                var modified = entities
                var i = 0;
                while(i < modified.count){
                    if (modified[i].id == rootEntityId){
                        modified[i].entities.append(entity)
                        break
                    }else if(modified[i].entities.isEmpty == false){
                        modified[i].entities = loop(modified[i].entities)
                    }
                    i += 1;
                }
                return modified
            }
            entities = loop(self.entities)
        }else{
            entities = [entity]
        }
        
        body["entities"] = entities.map({ entity in
            return self.mapEntityForPost(entity)
        })
        
        #if DEBUG
        print("KYC:Add Entity – ", body)
        #endif
        let res = try await services.kycp.update(body)
        self.entities = self.convertEntities(res.entities)
        
        return res
    }
    
    /***
     Add entities
     */
    func addEntities(_ with: [KYCEntity], rootEntityId: Int?, keep: Bool = false) async throws -> Application{
        var body: [String:Any] = [
            "id": self.id!,
            "uid": self.uid!,
            "finalized": self.finalized,
            "customerId": self.customerId,
            "programId": self.programId,
            "entities": []
        ]
        var postEntities: [KYCEntity] = []
        
        if (rootEntityId != nil){
            func loop(_ entities: [KYCEntity]) -> [KYCEntity]{
                var modified = entities
                var i = 0;
                while(i < modified.count){
                    if (modified[i].id == rootEntityId){
                        modified[i].entities.append(contentsOf: with)
                    }else if(modified[i].entities.isEmpty == false){
                        modified[i].entities = loop(modified[i].entities)
                    }
                    i += 1;
                }
                return modified
            }
            postEntities = loop(self.entities)
        }else{
            postEntities = with
        }
        
        body["entities"] = postEntities.map({ entity in
            return self.mapEntityForPost(entity)
        })
        
        #if DEBUG
        print("KYC:Add Entities – ", body)
        #endif
        
        let res = try await services.kycp.update(body)
        self.entities = self.convertEntities(res.entities)
        
        return res
    }
    
    /***
     Update entities
     */
    func modifyEntities(_ with: [KYCEntity], rootEntityId: Int?, keep: Bool = false) async throws -> Application{
        var body: [String:Any] = [
            "id": self.id!,
            "uid": self.uid!,
            "finalized": self.finalized,
            "customerId": self.customerId,
            "programId": self.programId,
            "entities": []
        ]
        var postEntities: [KYCEntity] = []
        
        if (rootEntityId != nil){
            func loop(_ entities: [KYCEntity]) -> [KYCEntity]{
                var modified = entities
                var i = 0;
                while(i < modified.count){
                    if (modified[i].id == rootEntityId){
                        modified[i].entities = with
                    }else if(modified[i].entities.isEmpty == false){
                        modified[i].entities = loop(modified[i].entities)
                    }
                    i += 1;
                }
                return modified
            }
            postEntities = loop(self.entities)
        }else{
            postEntities = with
        }
        
        body["entities"] = postEntities.map({ entity in
            return self.mapEntityForPost(entity)
        })
        
        #if DEBUG
        print("KYC:Modify Entities – ", body)
        #endif
        
        let res = try await services.kycp.update(body)
        self.entities = self.convertEntities(res.entities)
        
        return res
    }
    
    /***
     Update requested entity
     */
    func updateEntity(_ fields:[String:Any]?=[:], entityId: Int?) async throws -> Application{
        if (self.id == nil || self.uid == nil){
            throw ServiceError(title: "Application id not passed")
        }
        guard entityId != nil else{
            throw ServiceError(title: "Entity id not passed")
        }

        /***
         Loop through entities and modify requested
        */
        func loop(_ entities: [KYCEntity]) -> [KYCEntity]{
            var modified = entities
            var i = 0;
            while(i < modified.count){
                if (modified[i].id == entityId){
                    fields?.forEach({ field in
                        modified[i].fields[field.key] = field.value
                    })
                }else if(modified[i].entities.isEmpty == false){
                    modified[i].entities = loop(modified[i].entities)
                }
                i += 1;
            }
            return modified
        }
        
        //Collect body
        var body: [String:Any] = [
            "id": self.id!,
            "uid": self.uid!,
            "customerId": self.customerId,
            "entities": []
        ]
        if (self.finalized){
            body["finalized"] = self.finalized
        }
        
        body["entities"] = loop(self.entities).map({ entity in
            return self.mapEntityForPost(entity)
        })
        
        #if DEBUG
        print("KYC:Update Entity – ", body)
        #endif
        let res = try await services.kycp.update(body)
        
        //Merge data
        self.entities = self.convertEntities(res.entities)
        
        return res
    }
    
    func mapEntityForPost(_ entity: KYCEntity) -> [String:Any]{
        var output:[String:Any] = [:]
        if entity.id != nil{
            output["id"] = entity.id
        }
        if !entity.entityType.isEmpty{
            output["entityType"] = entity.entityType
            //output["entityTypeId"] = entity.isIndividualEntity ? 27 : 12
        }
        if (entity.applicationEntityId != nil){
            output["applicationEntityId"] = entity.applicationEntityId
        }
        output["fields"] = entity.fields
        if entity.entities.isEmpty == false{
            output["entities"] = entity.entities.map({ el in
                return self.mapEntityForPost(el)
            })
        }
        return output
    }
    
    
    /***
     Convert entities
     */
    func convertEntities(_ entities: [Entity]) -> [KYCEntity]{
        return entities.map({ entity in
            var modified = KYCEntity(
                id: entity.id,
                entityType: entity.entityType ?? "individual",
                applicationEntityId: entity.applicationEntityId,
                fields: entity.fields,
                entities: []
            )
            if (entity.entities != nil && entity.entities!.isEmpty == false){
                modified.entities = self.convertEntities(entity.entities!)
            }
            return modified
        })
    }
    
}

struct KYCEntity{
    public var id: Int?
    public var entityType: String = "individual"
    public var applicationEntityId: Int?
    public var fields: [String:Any] = [:]
    public var entities: [KYCEntity] = []
    
    public func at(_ key: String) -> String?{
        if (self.has(key)){
            if let value = self.fields[key] as? String{
                return value
            }else if let value = self.fields[key] as? Int{
                return String(self.fields[key] as! Int)
            }
        }
        return nil
    }
    
    public func atArray(_ key: String) -> [String]?{
        if (self.has(key)){
            if let value = self.fields[key] as? [String]{
                return value
            }else if let value = self.fields[key] as? String{
                return [value]
            }else if let value = self.fields[key] as? Int{
                return [String(self.fields[key] as! Int)]
            }
        }
        return nil
    }
    
    public func int(_ key: String) -> Int?{
        if (self.has(key)){
            if let value = self.fields[key] as? Int{
                return value
            }else if let value = self.fields[key] as? String{
                return Int(self.fields[key] as! String)
            }
        }
        return nil
    }
    
    public func has(_ key: String) -> Bool{
        return self.fields.keys.first(where: {$0 == key}) != nil
    }
    
    public var isIndividualEntity: Bool{
        return self.entityType == "individual"
    }
}

class KYCBusinessStore: ObservableObject{
    private var subscriptions = Set<AnyCancellable>()
    @ObservedObject public var registredAddress: AddressStore = .init()
    
    @Published public var legalName: String = ""
    @Published public var registrationNumber: String = ""
    @Published public var incorporationDate: String = ""
    @Published public var directors: Array<BusinessDirectorsView.BusinessDirector> = []
    @Published public var activeDirectorEmail: String = ""
    
    init(){
        self.registredAddress.objectWillChange.sink { [weak self] (store) in
            self?.objectWillChange.send()
        }
        .store(in: &self.subscriptions)
    }
    
    func clean(){
        self.legalName = ""
        self.registrationNumber = ""
        self.incorporationDate = ""
        self.activeDirectorEmail = ""
        self.directors = []
        self.registredAddress.clean()
    }
}
class PersonStore: ObservableObject{
    @Published public var givenName: String = ""
    @Published public var surName: String = ""
    @Published public var middleName: String = ""
    @Published public var dateOfBirth: String = ""
    @Published public var countryOfBirthExt: String = ""
    @Published public var email: String = ""
    @Published public var phone: String = ""
    @Published public var genderExt: String = ""
    
    func clean(){
        self.givenName = ""
        self.surName = ""
        self.middleName = ""
        self.dateOfBirth = ""
        self.countryOfBirthExt = ""
        self.email = ""
        self.phone = ""
        self.genderExt = ""
    }
}

class AddressStore: ObservableObject{
    @Published public var country: String = ""
    @Published public var city: String = ""
    @Published public var state: String = ""
    @Published public var firstLine: String = ""
    @Published public var secondLine: String = ""
    @Published public var postcode: String = ""
    
    func clean(){
        self.country = ""
        self.city = ""
        self.state = ""
        self.firstLine = ""
        self.secondLine = ""
        self.postcode = ""
    }
}
