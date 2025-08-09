//
//  CreatePaymentView.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 01.10.2023.
//

import Foundation
import SwiftUI
import CoreData

extension CreatePaymentView{
    enum CopOperationResult{
        case confirmed
        case rejected
    }
}

extension CreatePaymentView{
    private var requestFailed: Binding<Bool>{
        Binding(
            get: {
                return self.failed != nil
            },
            set: { _ in }
        )
    }
    
    private func fetchAccount() async throws{
        self.loading = true
        //Ask for current account
        if (self.account != nil){
            let response = try await services.accounts.getCustomerAccount(self.account?.customer?.id ?? "", accountId: self.account?.id ?? "")
            let request = CoreAccount.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", self.account!.id!)
            let results = try self.viewContext.fetch(request)
            results.forEach{
                $0.fetchFromAccount(account: response.value!)
            }
            try self.viewContext.save()
        }
        self.loading = false
    }
    
    private func fetchAccounts() async throws{
        self.loading = true
        
        let accounts = try await services.accounts.getCustomerAccounts(self.customer.id ?? "")
        accounts.value.data.forEach{ account in
            Task{
                //Check if account exists
                let request = CoreAccount.fetchRequest()
                request.predicate = NSPredicate(format: "id == %@", account.id)
                let response = try self.viewContext.fetch(request)
                
                if (response.isEmpty){
                    let coreAccount = CoreAccount(context: self.viewContext)
                    coreAccount.fetchFromAccount(account: account)
                    //TODO coreAccount.customer = self.customer
                    self.customer.addToAccounts(coreAccount)
                }else{
                    response.forEach({
                        $0.fetchFromAccount(account: account)
                        //TODO $0.customer = self.customer
                        self.customer.addToAccounts($0)
                    })
                }
            }
        }
        try self.viewContext.save()
        
        self.loading = false
    }
    
    private func loadPurposes() async throws{
        self.loading = true
        
        let response = try await services.payments.getOrderPurposes(self.customer.id ?? "")
        self.purposesData = response
        self.loading = false
    }
    
    private func calculatePrice() async throws -> PaymentsService.PaymentOrderPriceResponse{
        self.loading = true
        
        guard self.account?.customer != nil else{
            throw ApplicationError(title: "No customer", message: "Customer doesnt passed")
        }
        
        var order = self.order
        order.paymentPurpose = self.purposes.first?.id ?? "Other"
        order.paymentPurposeText = "-"
        let result = try await services.payments.calculatePrice(self.account?.customer?.id ?? "", order: order)
        
        self.loading = false
        
        return result
    }
    
    private func handleAmountChange(){
        Task{
            if (self.task?.isCancelled==false){
                self.task?.cancel()
            }
            if (self.amountValue > 0){
                let task = Task.detached(priority: .background){
                    try await Task.sleep(nanoseconds: userDefaultInputLagTimeNanoSeconds)
                    return try await self.calculatePrice()
                }
                self.task = task
                
                do{
                    let result = try await task.value
                    self.totalAmount = String(result.value.totalAmount)
                    self.totalPrice = String(result.value.totalPrice)
                }catch(let error){
                    self.totalAmount = "0"
                    self.totalPrice = "0"
                    if (error as? CancellationError != nil){
                        
                    }else{
                        self.Error.handle(error)
                    }
                    self.loading = false
                }
            }else{
                self.totalAmount = "0"
                self.totalPrice = "0"
            }
        }
    }
    
    private func initiateOrder() async throws{
        self.loading = true
        
        guard self.account?.customer?.id != nil else{
            throw ApplicationError(title: "No customer", message: "Customer doesnt passed")
        }
        self.fraudResult = nil
        self.fraudConfirmation = false
        self.fraudAlerts = [:]
        let result = try await services.payments.initiatePayment(self.account?.customer?.id ?? "", order: self.order)
        self.copWarning = false
        self.copResult = nil
        self.copConfirmation = false
        Task{
            if (result.value.copResponseCode != nil){
                self.copCode = result.value.copResponseCode
                self.copName = result.value.copNameMatch
                switch(result.value.copResponseCode?.lowercased()){
                case "internal":
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
                        return;
                    }
                    break;
                }
            }
            if (result.value.fraudAlerts.isEmpty == false){
                self.fraudAlerts = result.value.fraudAlerts
                self.fraudConfirmation = true
                //Await while fraud result
                while(self.fraudResult == nil){
                    try? await Task.sleep(nanoseconds: 1_000_000_000)
                }
                self.fraudConfirmation = false
                self.loading = false
                if (self.fraudResult == .confirmed){
                    return try await self.processOrder(order: result.value)
                }else if(self.fraudResult == .rejected){
                    return;
                }
                return;
            }
            try await self.processOrder(order: result.value)
        }
    }
    
    func processOrder(order: PaymentsService.PaymentOrderModel) async throws{
        //Upload attachments
        
        self.Store.payment.amount = String(self.amountValue)
        self.Store.payment.totalAmount = self.totalAmount
        self.Store.payment.totalPrice = self.totalPrice
        self.Store.payment.orderId = order.id
        self.loading = false
        
        self.Router.goTo(ConfirmPaymentView(
            order: order,
            customer: self.customer,
            account: self.account!,
            payee: self.payee!,
            attachments: self.$attachments,
            callback: .CreatePayment(self.callback)
        ))
    }
    
    /**Load default details*/
    func fetchDetails(){
        if case .CreatePayment(let details) = self.fetch{
            if (details.customer != nil){
                self.customer = details.customer!
            }
            if (details.account != nil){
                self.account = details.account
            }
            if (details.payee != nil){
                self.payee = nil
                self.payee = details.payee
            }
            if (details.amount != nil){
                self.amount = details.amount!
            }
            if (details.purpose != nil){
                self.purpose = details.purpose!
            }
            if (details.purposeDetails != nil){
                self.purposeDetails = details.purposeDetails!
            }
            if (details.reference != nil){
                self.reference = details.reference!
            }
            if (details.forceSepaNormal != nil){
                self.forceSepaNormal = details.forceSepaNormal!
            }
            if (details.isStandingOrder != nil){
                self.repeatPayment = details.isStandingOrder!
            }
            if (details.paymentFrequency != nil){
                self.paymentFrequency = details.paymentFrequency!
            }
            if (details.standingDateFrom != nil){
                self.scheduleStart = details.standingDateFrom!
            }
            if (details.standingDateTo != nil){
                self.scheduleEnd = details.standingDateTo!
            }
            if (details.isScheduleOrder == true){
                self.isScheduleOrder = true
            }
            
            self.handleAmountChange()
        }
    }
}

/**Methods**/
extension CreatePaymentView{
    //MARK: Upload document
    func uploadDocument(_ attachment: FileAttachment){
        //self.attachments.append(attachment)
        Task{
            do{
                self.attachments.append(attachment)
                self.documentLoading = true
                self.processing = attachment.key
                self.errorMessage = nil
                
                let result = try await services.transactionCases.fileUpload(
                    attachment,
                    customerId: self.customer.id ?? "",
                    documentType: .noteDocument
                )
                self.attachments = self.attachments.map({
                    if ($0.key == attachment.key){
                        $0.documentId = result.value.id
                    }
                    return $0
                })
                self.processing = ""
                self.documentLoading = false
            }catch let error{
                if let error = error as? KycpService.ApiError{
                    let message: String? = error.errors.first(where: {$0.code == "ValidationError"})?.description
                    if (message != nil){
                        self.documentLoading = false
                        self.processing = ""
                        self.errorMessage = message
                        return;
                    }
                }
                self.Error.handle(error)
            }
        }
         
    }
    
    func removeAttachment(_ attachment: FileAttachment){
        let index = self.attachments.firstIndex(where: { $0.id == attachment.id})
        
        if (attachment.documentId != nil){
            Task{
                do{
                    let result = try await services.transactionCases.fileDelete(
                        customerId: self.customer.id ?? "",
                        documentId: attachment.documentId ?? ""
                    )
                    if (result == true){
                        self.attachments.remove(at: index!)
                    }else{
                        throw ApplicationError(title: "Unable to remove document", message: "")
                    }
                }catch let error{
                    self.Error.handle(error)
                }
            }
        }else{
            self.attachments.remove(at: index!)
        }
    }
    
    func processPhoto(image: UIImage){
        Task{
            do{
                if let data = image.jpegData(compressionQuality: 0.7){
                    let attachment = FileAttachment(data: data)
                    attachment.fileType = .jpg
                    attachment.fileName = "Scanned.jpg"
                    attachment.key = randomString(length: 6)
                    self.uploadDocument(attachment)
                }else{
                    throw ApplicationError(title: "Unable to take photo", message: "")
                }
            }catch let error{
                self.Error.handle(error)
            }
        }
    }
}

/**Structs**/
extension CreatePaymentView{
    /***
     Use to obtain default values
     */
    struct CreatePaymentViewFetchDetails{
        var customer: CoreCustomer?
        var account: CoreAccount?
        var payee: Contact?
        var amount: String?
        var purpose: String?
        var purposeDetails: String?
        var reference: String?
        var forceSepaNormal: Bool?
        var isStandingOrder: Bool?
        var paymentFrequency: String?
        var standingDateFrom: String?
        var standingDateTo: String?
        var isScheduleOrder: Bool?
    }
}

/**Getters**/
extension CreatePaymentView{
    var callback: CreatePaymentView.CreatePaymentViewFetchDetails{
        return .init(
            customer: self.customer,
            account: self.account,
            payee: self.payee,
            amount: self.amount,
            purpose: self.purpose,
            purposeDetails: self.purposeDetails,
            reference: self.reference,
            forceSepaNormal: self.forceSepaNormal,
            isStandingOrder: self.repeatPayment,
            paymentFrequency: self.paymentFrequency,
            standingDateFrom: self.scheduleStart,
            standingDateTo: self.scheduleEnd,
            isScheduleOrder: self.isScheduleOrder
        )
    }
    var paymentFrequencies: Array<Option> {
        return CreateStandingOrderRequestModel.CreateStandingOrderPeriod.allCases.map({
            return Option(
                id: $0.rawValue,
                label: $0.label
            )
        })
    }
    
    /**If account have enough funds to process payment*/
    private var enoughtFunds: Bool{
        if (self.account != nil){
            var formattedAmount = self.totalAmount.replacingOccurrences(of: ",", with: ".")
            let amount = Float(formattedAmount) ?? 0
            if amount <= self.account!.availableBalance!.value{
                return true
            }
            return false
        }
        return true
    }
    
    /**Check if form valid**/
    private var formDisabled:Bool{
        if self.account != nil && self.payee != nil{
            //Replace comma with dot
            if(!self.enoughtFunds){
                return true
            }
            var formattedAmount = self.totalAmount.replacingOccurrences(of: ",", with: ".")
            if(self.amountValue <= 0){
                return true
            }
            if (self.purpose.isEmpty){
                return true
            }
            if (self.purpose.lowercased() == "other" && self.purposeDetails.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty){
                return true
            }
            if (self.repeatPayment){
                if (self.scheduleStart.isEmpty){
                    return true
                }
                if (self.paymentFrequency.isEmpty){
                    return true
                }
            }
            return false
        }
        return true
    }
    
    /**Purposes list*/
    private var purposes: Array<Option> {
        return self.purposesData.map({
            return Option(
                id: $0.key ?? "",
                label: $0.value ?? ""
            )
        })
    }
    
    /**Amount**/
    var amountValue: Double{
        var amount = self.amount.replacingOccurrences(of: ",", with: "")
        return Double(amount) ?? 0
    }
    
    /**Order model**/
    var order: PaymentsService.CreateOrderPaymentRequest{
        var reference = self.reference.trimmingCharacters(in: .whitespacesAndNewlines)
        if reference.isEmpty{
            var message = "Payment to"
            if self.payee != nil{
                let contactName = self.payee!.accountHolderName
                message = String("Payment to \(contactName)")
            }
            reference = message
        }
        reference = String(reference.prefix(140))
        
        let amount = String(self.amountValue)
        var rails: PaymentsService.CreateOrderPaymentRequest.CreateOrderRequestRail = .fps
        var scheme: PaymentsService.CreateOrderPaymentRequest.CreateOrderRequestScheme? = nil
        
        //MARK: GPT Accounts
        if (self.account?.baseCurrencyCode?.lowercased() == "gbp"){
            reference = String(reference.prefix(35))
        }else if(self.account?.baseCurrencyCode?.lowercased() == "usd"){
            rails = .swift
        }else if(self.account?.baseCurrencyCode?.lowercased() == "eur"){
            rails = .sepa
            scheme = .sepaInstant
            if (self.forceSepaNormal){
                scheme = .sepaNormal
            }
        }
        
        self.Store.payment.reference = reference
        var request =  PaymentsService.CreateOrderPaymentRequest(
            debtorAccountId: self.account?.id ?? "",
            payeeContactId: self.payee?.contactId ?? "",
            paymentRails: rails,
            paymentScheme: scheme,
            amount: .init(
                currencyCode: self.account?.baseCurrencyCode ?? "",
                value: Decimal(string: amount) ?? Decimal(0)
            ),
            paymentPurpose: self.purpose,
            paymentPurposeText: self.purposeDetails.trimmingCharacters(in: .whitespacesAndNewlines),
            reference: reference,
            documentIds: self.attachments.filter({
                return $0.documentId != nil
            }).map({
                return $0.documentId!
            })
        )
        if (self.repeatPayment && self.scheduleStart.isEmpty == false){
            var period : CreateStandingOrderRequestModel.CreateStandingOrderPeriod = CreateStandingOrderRequestModel.CreateStandingOrderPeriod.allCases.first(where: {$0.label.lowercased() == self.paymentFrequency.lowercased()}) ?? .monthly
            
            let dateFormatter = DateFormatter()
            let enUSPosixLocale = Locale(identifier: "en_US_POSIX")
            dateFormatter.locale = enUSPosixLocale
            dateFormatter.dateFormat = "'T'HH:mm:ssZZZZZ"
            dateFormatter.calendar = Calendar(identifier: .gregorian)

            let iso8601String = dateFormatter.string(from: Date())
            if (self.scheduleEnd != nil && self.scheduleEnd.isEmpty == false){
                request.standingOrder = .init(
                    endDate: "\(self.scheduleEnd)\(iso8601String)",
                    isConfirmed: true,
                    period: period,
                    startDate: "\(self.scheduleStart)\(iso8601String)"
                )
            }else{
                request.standingOrder = .init(
                    isConfirmed: true,
                    period: period,
                    startDate: "\(self.scheduleStart)\(iso8601String)"
                )
            }
        }
        return request
    }
}

/** Some extended views */
extension CreatePaymentView{
    var accountCard: some View{
        ZStack{
            if (self.account != nil){
                CoreAccountCard(
                    account: self.account!
                )
                    .padding(.horizontal, 16)
            }
        }
    }
    
    var payeeCard: some View{
        ContactCard(style: .initial, contact: self.payee!)
    }
    
    var accountPopup: some View{
        ScrollView{
            VStack(spacing: 12){
                Text("Please choose an account")
                    .font(.title2.bold())
                    .foregroundColor(Color.get(.Text, scheme: .light))
                    .frame(maxWidth:.infinity, alignment: .leading)
                    .multilineTextAlignment(.leading)
                
                VStack(spacing: 8){
                    ForEach(self.accounts, id:\.id){ account in
                        Button{
                            self.account = account
                            self.selectAccount = false
                        } label:{
                            CoreAccountCard(
                                style: .list,
                                account: account
                            )
                        }
                    }
                }
            }
        }
    }
    
    var amountForm: some View{
        VStack(spacing: 16){
            VStack(spacing:2){
                CustomField(
                    value: self.$amount,
                    placeholder: "Amount",
                    type: .price,
                    dimension: self.account?.baseCurrencyCode?.uppercased() ?? ""
                )
                .disabled(self.account == nil || self.payee == nil)
                .onChange(of: self.amount, perform: { _ in
                    self.handleAmountChange()
                    return;
                })
                if (self.enoughtFunds == false){
                    Text("Not enough money in account")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(Color.get(.Danger))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            
            VStack(spacing:6){
                HStack(spacing: 8){
                    Text("Total amount with fee:")
                    Text(self.totalAmount.formatAsPrice(self.account?.baseCurrencyCode?.uppercased() ?? ""))
                    Spacer()
                }
                HStack(spacing: 8){
                    Text("Fee:")
                    Text(self.totalPrice.formatAsPrice(self.account?.baseCurrencyCode?.uppercased() ?? ""))
                    Spacer()
                }
            }
            .font(.subheadline)
            .foregroundColor(Color.get(.MiddleGray))
            
            VStack(spacing:16){
                CustomField(
                    value: self.$purpose,
                    placeholder: "Purpose of payment",
                    type: .select,
                    options: self.purposes
                )
                    .disabled(self.loading || self.account == nil)
                if (self.purpose.lowercased() == "other"){
                    VStack{
                        CustomField(
                            value: self.$purposeDetails,
                            placeholder: "Enter your purpose of payment"
                        )
                            .disabled(self.loading || self.account == nil)
                        if (self.purposeDetails.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty){
                            Text("Please fill in this field")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(Color.get(.Danger))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
            }
            
            CustomField(
                value: self.$reference,
                placeholder: "Reference",
                type: .textarea
            )
                .disabled(self.loading || self.account == nil || self.payee == nil)
            
            if( self.account != nil && self.account?.baseCurrencyCode?.lowercased() == "eur"){
                HStack(alignment:.top){
                    ZStack{
                        Image("info-circle")
                            .foregroundColor(Color.get(.MiddleGray))
                            .tooltip(side: .topRight){
                                Text("SEPA Normal is Standard Bank Transfer\nprocessed within 2 business days.")
                            }
                    }
                    .frame(maxWidth: 24, maxHeight: 24)
                    .padding(.trailing, 12)
                    Text("Force SEPA Normal")
                        .font(.subheadline.weight(.medium))
                        .multilineTextAlignment(.leading)
                        .foregroundColor(Color.get(.MiddleGray))
                    Spacer()
                    Toggle(isOn: self.$forceSepaNormal){
                        EmptyView()
                    }
                    .disabled(self.loading || self.account == nil || self.payee == nil)
                    .padding(0)
                    .labelsHidden()
                }
                .frame(alignment:.leading)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
    }
    
    var relatedDocuments: some View{
        VStack(spacing: 0){
            VStack(spacing: 8){
                HStack(spacing: 4){
                    Text("Related Documents")
                        .foregroundColor(Color.get(.Text))
                        .font(.body)
                    Text("(optional)")
                        .foregroundColor(Color.get(.LightGray))
                        .font(.body)
                    Spacer()
                }
                VStack(spacing: 8){
                    if (self.errorMessage != nil){
                        HStack{
                            Text(self.errorMessage!)
                                .font(.subheadline.bold())
                                .foregroundColor(Color.get(.Danger))
                            Spacer()
                        }
                    }
                    ForEach(self.attachments, id: \.key){ attachment in
                        HStack(spacing: 8){
                            ZStack{
                                Text((attachment.fileType?.rawValue  ?? "").uppercased())
                                    .font(.caption)
                                    .foregroundColor(Color.get(.Pending))
                            }
                            .frame(width: 48,height: 48)
                            .background(Color.get(.Pending).opacity(0.14))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            VStack{
                                Text(attachment.fileName ?? "")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundColor(Color.get(.Text))
                                    .multilineTextAlignment(.leading)
                            }
                            Spacer()
                            if (self.processing == attachment.key){
                                ZStack{
                                    Loader(size: .small)
                                }
                            }else{
                                Button{
                                    self.removeAttachment(attachment)
                                } label:{
                                    ZStack{
                                        Image("trash")
                                            .foregroundColor(Color.get(.Danger))
                                    }
                                    .frame(width: 24, height: 24)
                                }
                                .disabled(self.loading)
                            }
                        }
                        .padding(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.get(.BackgroundInput))
                                .foregroundColor(Color.clear)
                                .background(.clear)
                        )
                    }
                }
                VStack(spacing: 8){
                    HStack{
                        Text("Image or PDF, up to 20 Mb")
                        Spacer()
                    }
                    .font(.subheadline.bold())
                    .foregroundColor(Color.get(.LightGray))
                    Button{
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to:nil, from:nil, for:nil)
                        self.selectDocument = true
                    } label:{
                        HStack{
                            Spacer()
                            ZStack{
                                Image("add")
                                    .resizable()
                                    .scaledToFit()
                                    .foregroundColor(.black)
                            }
                            .frame(width: 18)
                            Text("Add a document")
                                .font(.subheadline.bold())
                            Spacer()
                        }
                    }
                    .buttonStyle(.secondary())
                    .disabled(self.loading || self.documentLoading)
                }
            }
            .padding(.horizontal, 16)
        }
    }
    
    var standingOrder: some View{
        VStack(spacing: 16){
            if (self.isScheduleOrder == false){
                VStack(spacing: 8){
                    HStack(spacing: 4){
                        Text("Standing order")
                            .foregroundColor(Color.get(.Text))
                            .font(.body)
                        Text("(optional)")
                            .foregroundColor(Color.get(.LightGray))
                            .font(.body)
                        Spacer()
                    }
                    VStack(spacing: 8){
                        HStack(alignment: .center, spacing: 10){
                            Checkbox(checked: self.$repeatPayment)
                            Group{
                                Text("Make this a standing order ")
                                    .foregroundColor(Color.get(.Text))
                                + Text("(Repeat payment)")
                                    .foregroundColor(Whitelabel.Color(.Primary))
                            }
                            .font(.subheadline)
                            .multilineTextAlignment(.leading)
                            Spacer()
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
            if (self.repeatPayment || self.isScheduleOrder){
                VStack(spacing: 8){
                    HStack(spacing: 8){
                        ZStack{
                            Image("standing")
                        }
                        .frame(width: 20, height: 20)
                        Text("Payment frequency")
                            .foregroundColor(Color.get(.Text))
                            .font(.body)
                        Spacer()
                    }
                    VStack(spacing: 8){
                        CustomField(
                            value: self.$paymentFrequency,
                            placeholder: "",
                            type: .select,
                            options: self.paymentFrequencies
                        )
                    }
                }
                .padding(.horizontal, 16)
                VStack(spacing: 8){
                    HStack(spacing: 8){
                        ZStack{
                            Image("standing")
                        }
                        .frame(width: 20, height: 20)
                        Text("Pick a date to schedule payment")
                            .foregroundColor(Color.get(.Text))
                            .font(.body)
                        Spacer()
                    }
                    VStack(spacing: 8){
                        CustomField(
                            value: self.$scheduleStart,
                            placeholder: "Start Date",
                            type: .date,
                            dateRangeFrom: Date()...
                        )
                            .disabled(self.loading)
                            .onChange(of: self.scheduleStart){ _ in
                                if (self.scheduleEnd.isEmpty == false){
                                    let start = self.scheduleStart.asDate()
                                    let end = self.scheduleEnd.asDate()
                                    if (start != nil && end != nil){
                                        if (start! >= end!){
                                            self.scheduleEnd = ""
                                            self.scheduleEndRangeFrom = (self.scheduleStart.asDate() ?? Date())...
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 1){
                                                self.scheduleEnd = (self.scheduleStart.asDate() ?? Date()).add(.day, value: 1).asStringDate()
                                            }
                                        }
                                    }
                                }
                            }
                        CustomField(
                            value: self.$scheduleEnd,
                            placeholder: "End Date",
                            type: .date,
                            dateRangeFrom: self.$scheduleEndRangeFrom.wrappedValue
                        )
                            .disabled(self.loading)
                            .onChange(of: self.scheduleEnd){ _ in
                                if (self.scheduleEnd.asDate() ?? Date() < self.scheduleStart.asDate() ?? Date()){
                                    //self.scheduleStart = self.scheduleEnd
                                }
                            }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }
    
    var copPopup: some View{
        VStack(spacing:0){
            let option: CoreReasonCodeLookupDto? = self.reasonCodeData.first(where: {$0.reasonCode?.lowercased() == self.copCode?.lowercased()})
            switch(self.copCode?.lowercased()){
            case "match", "internal":
                VStack(alignment: .center, spacing: 24){
                    ZStack{
                        Image("tick-square-large")
                            .resizable()
                            .scaledToFit()
                    }
                    .frame(width: 92, height: 92)
                    VStack(alignment: .center, spacing: 12){
                        VStack(alignment:.center, spacing:4){
                            Text(option?.header?.replacingOccurrences(of: "%name%", with: self.copName ?? "–", options: .caseInsensitive) ?? "Account not found")
                                .font(.body.weight(.medium))
                                .foregroundColor(Color.get(.Text))
                                .multilineTextAlignment(.center)
                            Text(option?.reasonDescription?.replacingOccurrences(of: "%name%", with: self.copName ?? "–", options: .caseInsensitive) ?? "")
                                .font(.caption)
                                .foregroundColor(Color.get(.Gray))
                                .multilineTextAlignment(.center)
                        }
                        .onAppear{
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: {
                                self.copResult = .confirmed
                            })
                        }
                    }
                }
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
                        if (self.payee != nil){
                            VStack{
                                HStack{
                                    ContactCard(
                                        style: .initial,
                                        contact: self.payee!,
                                        scheme: .light
                                    )
                                    Button{
                                        self.Router.goTo(CreatePayeeView(
                                            customer: self.customer,
                                            selectedContact: self.payee,
                                            //callback: .CreatePayment(self.account, self.payee, self.customer, self.amount, self.purpose, self.purposeDetails, self.reference),
                                            attachments: self.$attachments
                                        ))
                                    } label:{
                                        VStack(alignment: .center, spacing:4){
                                            ZStack{
                                                Image("edit")
                                                    .foregroundColor(Whitelabel.Color(.OnQuaternary))
                                            }
                                            .frame(width: 20, height: 20)
                                            Text("Edit")
                                                .font(.body)
                                                .foregroundColor(Whitelabel.Color(.OnQuaternary))
                                        }
                                    }
                                    .buttonStyle(.tertiary())
                                }
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(16)
                            }
                            .background(Color("MiddlePrimary"))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                    }
                    VStack(spacing:16){
                        if (self.copCode?.lowercased() != "ac01"){
                            Button{
                                self.copConfirmation = true
                            } label: {
                                HStack{
                                    Spacer()
                                    Text("Continue")
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
                                Text("Reject")
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

struct CreatePaymentView: View, RouterPage {
    @EnvironmentObject var Store: ApplicationStore
    @EnvironmentObject var Error: ErrorHandlingService
    @EnvironmentObject var Router: RoutingController
    @EnvironmentObject var manager: DataController
    @Environment(\.managedObjectContext) private var viewContext
    
    @State public var customer: CoreCustomer
    @State public var account: CoreAccount?
    @State public var payee: Contact? = nil
    @State public var fetch: RouterPageCallback? = nil
    
    @State private var amount: String = ""
    @State private var totalAmount: String = "0"
    @State private var totalPrice: String = "0"
    
    @State private var purposesData: [String:String] = [:]
    @State private var purpose: String = ""
    @State private var purposeDetails: String = ""
    @State private var reference: String = ""
    @State private var loading: Bool = false
    @State private var forceSepaNormal: Bool = false
    @State private var toolTipShowed: Bool = false
    @State private var task: Task<PaymentsService.PaymentOrderPriceResponse, any Error>?
    
    @State private var selectAccount: Bool = false
    
    @State private var failed: KycpService.ServerError.ServerErrorDetails? = nil
    //FRAUD Check
    @State private var fraudConfirmation: Bool = false
    @State private var fraudAlerts: [String:String] = [:]
    @State private var fraudResult: FraudView.FraudOperationResult? = nil
    //MARK: - Storage
    @State private var copCode: String? = nil
    @State private var copName: String? = nil 
    @State private var copResult: CreatePaymentView.CopOperationResult? = nil
    @State private var copWarning: Bool = false
    @State private var copConfirmation: Bool = false
    
    @State private var documentLoading: Bool = false
    @State private var selectDocument: Bool = false
    @State private var fileSelection: Bool = false
    @State public var attachments: Array<FileAttachment> = []
    @State private var errorMessage: String? = nil
    @State private var takePhoto: Bool = false
    @State private var processing: String = ""
    
    //MARK: – Standing order
    @State private var repeatPayment: Bool = false
    @State private var paymentFrequency: String = CreateStandingOrderRequestModel.CreateStandingOrderPeriod.daily.rawValue
    @State private var scheduleStart: String = ""
    @State private var scheduleEnd: String = ""
    @State private var scheduleEndRangeFrom: PartialRangeFrom<Date>? = Date()...
    
    @FetchRequest(
        sortDescriptors:[]
    ) var reasonCodeData: FetchedResults<CoreReasonCodeLookupDto>
    @FetchRequest(
        sortDescriptors:[
            SortDescriptor(\.sortOrder)
        ]
    ) var accounts: FetchedResults<CoreAccount>
    
    @State public var isScheduleOrder: Bool = false
    
    var body: some View {
        ApplicationNavigatorContainerView{
            GeometryReader{ geometry in
                ZStack{
                    ScrollView{
                        VStack(spacing: 0){
                            Header(back:{
                                self.Router.back()
                            }, title: "Payment")
                            .padding(.bottom, 16)
                            
                            //MARK: Account selector
                            Text("From")
                                .font(.body.weight(.medium))
                                .foregroundColor(Color("MiddleGray"))
                                .padding(.horizontal, 16)
                                .padding(.top, 16)
                                .padding(.bottom, 8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            if (self.account == nil){
                                Button{
                                    self.selectAccount = true
                                } label:{
                                    HStack{
                                        Text("Select the account")
                                            .foregroundColor(Color.get(.MiddleGray))
                                        Spacer()
                                    }
                                }
                                .buttonStyle(.secondaryNext(image: "money 1"))
                                .disabled(self.loading)
                                .padding(.horizontal, 16)
                            }else{
                                Button{
                                    self.selectAccount = true
                                } label:{
                                    self.accountCard
                                }
                                .disabled(self.loading)
                            }
                            
                            ZStack{}
                                .frame(maxWidth: .infinity, minHeight: 1,maxHeight: 1)
                                .background(
                                    Color("Divider")
                                )
                                .padding(.vertical, 16)
                                .overlay(
                                    Circle()
                                        .stroke(Color("Divider"), style: .init(lineWidth: 1))
                                        .background(Color("Background"))
                                        .frame(width: 24, height: 24)
                                        .overlay(
                                            Path{ path in
                                                path.move(to: .init(x: 6, y: 10))
                                                path.addLine(to: .init(x: 12, y: 16))
                                                path.addLine(to: .init(x: 18, y: 10))
                                            }
                                                .stroke(Color("Divider"), style: .init(lineWidth: 1))
                                        )
                                )
                            
                            //MARK: Payee selector
                            Text("To")
                                .font(.body.weight(.medium))
                                .foregroundColor(Color.get(.MiddleGray))
                                .padding(.horizontal, 16)
                                .padding(.bottom, 8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            if (self.payee == nil){
                                Button{
                                    self.Store.contacts.customerId = self.Store.payment.customerId
                                    self.Router.goTo(
                                        PayeesView(
                                            customer: self.customer,
                                            account: self.account,
                                            currency: self.account?.baseCurrencyCode ?? "",
                                            attachments: self.$attachments,
                                            callback: .CreatePayment(self.callback)
                                        )
                                    )
                                } label:{
                                    HStack{
                                        Text("Select the payee")
                                            .foregroundColor(Color.get(.MiddleGray))
                                        Spacer()
                                    }
                                }
                                .buttonStyle(.secondaryNext(image: "money 1"))
                                .padding(.horizontal, 16)
                                .disabled(self.loading)
                            }else{
                                Button{
                                    self.Router.goTo(
                                        PayeesView(
                                            customer: self.customer,
                                            account: self.account,
                                            currency: self.account?.baseCurrencyCode ?? "",
                                            attachments: self.$attachments,
                                            callback: .CreatePayment(self.callback)
                                        )
                                    )
                                } label:{
                                    ContactCard(
                                        style: .initial,
                                        contact: self.payee!
                                    )
                                }
                                .buttonStyle(.secondaryNext())
                                .padding(.horizontal, 16)
                                .disabled(self.loading)
                            }
                            
                            self.amountForm
                            
                            VStack(spacing: 16){
                                self.standingOrder
                                self.relatedDocuments
                            }
                            Spacer()
                            Button{
                                Task{
                                    do{
                                        try await self.initiateOrder()
                                    }catch let error{
                                        self.loading = false
                                        if (error as? KycpService.ServerError != nil){
                                            let details = error as! KycpService.ServerError
                                            self.failed = details.errors.first
                                        }else{
                                            self.Error.handle(error)
                                        }
                                    }
                                }
                            } label: {
                                HStack{
                                    Spacer()
                                    Text("Next")
                                    Spacer()
                                }
                            }
                            .padding(.horizontal, 16)
                            .buttonStyle(.primary())
                            .disabled(self.formDisabled)
                            .loader(self.$loading)
                            
                            //MARK: Media importer
                            MediaUploaderContainer(
                                isPresented: self.$fileSelection,
                                onImport: { url in
                                    var attachment = FileAttachment(url: url);
                                    attachment.key = randomString(length: 6)
                                    
                                    self.uploadDocument(attachment)
                                    DispatchQueue.main.async {
                                        self.fileSelection = false
                                    }
                                },
                                onError: { error in
                                    DispatchQueue.main.async {
                                        self.fileSelection = false
                                    }
                                    self.Error.handle(error)
                                }
                            )
                        }
                        .frame(
                            maxWidth: .infinity,
                            minHeight: geometry.size.height - geometry.safeAreaInsets.bottom
                        )
                        .onAppear{
                            Task{
                                do{
                                    if (self.isScheduleOrder){
                                        self.repeatPayment = true
                                    }
                                    self.scheduleStart = Date().asStringDate()
                                    if (self.account != nil){
                                        try await self.fetchAccount()
                                    }else{
                                        try await self.fetchAccounts()
                                    }
                                    //By default - load accounts related with user
                                    if (self.payee != nil){
                                        self.accounts.nsPredicate = NSPredicate(
                                            format: "lowercase:(type) != 'mmb' AND customer == %@ AND lowercase:(baseCurrencyCode) == %@",
                                            self.customer,
                                            self.payee?.currency.lowercased() ?? ""
                                        )
                                    }else{
                                        self.accounts.nsPredicate = NSPredicate(
                                            format: "lowercase:(type) != 'mmb' AND customer == %@",
                                            self.customer
                                        )
                                    }
                                    try await self.loadPurposes()
                                    self.fetchDetails()
                                }catch(let error){
                                    self.Error.handle(error)
                                    self.loading = false
                                }
                            }
                        }
                        .onChange(of: self.copWarning, perform:{ _ in
                            if (self.copWarning == false && self.copResult == nil && self.copCode != nil){
                                if (self.copCode?.lowercased() == "match"){
                                    self.copResult = .confirmed
                                }else{
                                    self.copResult = .rejected
                                }
                            }
                        })
                    }
                    
                    //MARK: Popups
                    PresentationSheet(isPresented: self.$selectAccount){
                        VStack{
                            self.accountPopup
                                .frame(
                                    maxHeight: geometry.size.height - (geometry.safeAreaInsets.bottom + 100)
                                )
                        }
                        .padding(.bottom, geometry.safeAreaInsets.bottom)
                        .padding(20)
                        .padding(.top,10)
                    }
                    
                    PresentationSheet(isPresented: self.requestFailed){
                        VStack{
                            Image("danger")
                            Text(self.failed?.code.label ?? "")
                                .font(.title2.bold())
                                .foregroundColor(Color.get(.Text))
                                .padding(.bottom,5)
                                .multilineTextAlignment(.center)
                            Text(self.failed?.description ?? "")
                                .font(.subheadline)
                                .foregroundColor(Color.get(.LightGray))
                                .multilineTextAlignment(.center)
                                .padding(.bottom,20)
                                Button{
                                    self.failed = nil
                                } label:{
                                    HStack{
                                        Spacer()
                                        Text(LocalizedStringKey("OK"))
                                        Spacer()
                                    }
                                }
                                .buttonStyle(.secondary())
                        }
                        .padding(.bottom, geometry.safeAreaInsets.bottom)
                        .padding(20)
                        .padding(.top,10)
                    }
                    
                    //MARK: COP
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
                    PresentationSheet(isPresented: self.$copConfirmation){
                        VStack(alignment: .center, spacing: 24){
                            ZStack{
                                Image("danger")
                            }
                                .frame(width: 92, height: 92)
                            Text("Initiating this payment may lead to funds being sent to the wrong Account and \(Whitelabel.BrandName()) may not be able to recover the money")
                                .font(.body.weight(.medium))
                                .foregroundColor(Color.get(.Text))
                                .multilineTextAlignment(.center)
                            VStack(spacing: 12){
                                Button{
                                    self.copResult = .confirmed
                                    self.copWarning = false
                                    self.copConfirmation = false
                                } label:{
                                    HStack{
                                        Spacer()
                                        Text(LocalizedStringKey("Continue"))
                                        Spacer()
                                    }
                                }
                                    .fixedSize(horizontal: false, vertical: true)
                                    .buttonStyle(.secondary())
                                Button{
                                    self.copResult = .rejected
                                    self.copWarning = false
                                    self.copConfirmation = false
                                } label:{
                                    HStack{
                                        Spacer()
                                        Text(LocalizedStringKey("Reject"))
                                        Spacer()
                                    }
                                }
                                .fixedSize(horizontal: false, vertical: true)
                                .buttonStyle(.primary())
                            }
                        }
                        .padding(.bottom, geometry.safeAreaInsets.bottom)
                        .padding(20)
                        .padding(.top,10)
                    }
                    //MARK: Related documents
                    //MARK: File Uploader
                    PresentationSheet(isPresented: self.$selectDocument){
                        HStack(spacing: 20){
                            Button{
                                self.selectDocument = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1){
                                    self.takePhoto = true
                                }
                            } label:{
                                HStack{
                                    Text(LocalizedStringKey("Take a photo"))
                                }
                            }
                            .buttonStyle(.action(image:"scan"))
                            Button{
                                self.selectDocument = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1){
                                    self.fileSelection = true
                                }
                            } label:{
                                HStack{
                                    Text(LocalizedStringKey("Select from files"))
                                }
                            }
                            .buttonStyle(.action(image:"folder-add"))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top,10)
                        .padding(.horizontal,10)
                        .padding(.bottom, geometry.safeAreaInsets.bottom)
                    }
                    
                    //MARK: Camera
                    if (self.takePhoto){
                        CameraPickerView(
                            onDismiss: {
                                self.takePhoto = false
                            },
                            onImagePicked: { image in
                                self.processPhoto(image: image)
                            }
                        )
                        .ignoresSafeArea(.all)
                        .edgesIgnoringSafeArea(.all)
                    }
                }
            }
            .fraud(
                isPresented: self.$fraudConfirmation,
                result: self.$fraudResult,
                alerts: self.$fraudAlerts
            )
        }
        .navigationBarBackButtonHidden(true)
        .navigationTitle("")
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to:nil, from:nil, for:nil)
        }
    }
}
