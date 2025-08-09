//
//  ExchangeView.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 18.09.2024.
//

import Foundation
import SwiftUI
import CoreData

extension ExchangeView{
    private var loaderOffset: Double{
        if (self.loading){
            return 50 + self.scrollOffset
        }
        
        if (self.scrollOffset > 0){
            return 0
        }else if(self.scrollOffset < -100){
            return 50 + self.scrollOffset
        }
        
        return 0 + self.scrollOffset / 2
    }
    
    private var sourceCurrency: Binding<String>{
        Binding(
            get:{
                return self.currencies.first(where: {
                    return $0.id.lowercased() == self.sourceAccount.baseCurrencyCode?.lowercased()
                })?.id ?? ""
            },
            set:{ _ in
                
            }
        )
    }
    
    var destinationAccountCard: some View{
        ZStack{
            if (!self.destinationAccountId.isEmpty && !self.destinationAccount.isEmpty){
                CoreAccountCard(
                    style: .short,
                    account: self.destinationAccount.first!
                )
                    .padding(.horizontal, 0)
            }
        }
    }
    
    private func loadAccounts() async throws{
        /*
         if (self.loading){
            return
        }
        self.loading = true
        //Look for accounts
        let accounts = try await services.accounts.getCustomerAccounts(self.sourceAccount?.customer?.id ?? "")
        accounts.value.data.forEach{ account in
            Task{
                //Check if account exists
                let accountsRequest = CoreAccount.fetchRequest()
                accountsRequest.predicate = NSPredicate(format: "id == %@", account.id)
                let response = try self.viewContext.fetch(accountsRequest)
                if (response.isEmpty){
                    let coreAccount = CoreAccount(context: self.viewContext)
                    coreAccount.fetchFromAccount(account: account)
                    coreAccount.customer = company
                    company.addToAccounts(coreAccount)
                }else{
                    response.forEach({
                        $0.fetchFromAccount(account: account)
                        $0.customer = company
                        company.addToAccounts($0)
                    })
                }
            }
        }
        try self.viewContext.save()
        self.loading = false
         */
    }
    
    var sourceAccountCard: some View{
        ZStack{
            if (self.sourceAccount != nil){
                CoreAccountCard(account: self.sourceAccount)
                    .padding(.horizontal, 0)
            }
        }
    }
    
    private var currencies: [Option] {
        return [
            Option(id: "GBP", label: "GBP"),
            Option(id: "EUR", label: "EUR"),
            Option(id: "USD", label: "USD")
        ]
    }
    
    private var destinationCurrencies: [Option] {
        return self.currencies.filter({
            return $0.id.lowercased() != self.sourceCurrency.wrappedValue.lowercased()
        })
    }
    
    private var formDisabled:Bool{
        if (self.sourceAccount == nil || self.destinationAccountId.isEmpty){
            return true
        }
        if (self.sourceCurrency.wrappedValue.isEmpty || self.destinationCurrency.isEmpty){
            return true
        }
        if (self.sourceAmountValue.wrappedValue.isNaN && self.destinationAmountValue.wrappedValue.isNaN){
            return true
        }
        if (self.sourceAmountValue.wrappedValue <= 0 && self.destinationAmountValue.wrappedValue <= 0){
            return true
        }
        if (!self.enoughtSourceBalance){
            return true
        }
        if (!self.isAmountGreaterThanMinimum){
            return true
        }
        return false
    }
    
    private var sourceAmountValue: Binding<Double>{
        Binding(
            get: {
                var amount = self.sourceAmount.replacingOccurrences(of: ",", with: "")
                return Double(amount) ?? 0
            },
            set: { _ in }
        )
    }
    
    private var destinationAmountValue: Binding<Double>{
        Binding(
            get: {
                var amount = self.destinationAmount.replacingOccurrences(of: ",", with: "")
                return Double(amount) ?? 0
            },
            set: { _ in }
        )
    }
    
    private func initiateOrder() async throws{
        self.loading = true
        let request: ForexService.CreateForexOrderRequest = .init(
            sourceAccountId: self.sourceAccount.id ?? "",
            targetAccountId: self.destinationAccountId,
            sourceAmount: self.sourceAmountValue.wrappedValue,
            targetAmount: self.destinationAmountValue.wrappedValue,
            orderId: ""
        )
        self.loading = false
        self.Router.goTo(ConfirmExchangeView(
            customerId: self.sourceAccount.customer?.id ?? "",
            order: request
        ))
    }
    
    private var openDestinationAccountTitle: String{
        switch(self.destinationCurrency.lowercased()){
        case "gbp":
            return "You don't have an account in GBP"
        case "eur":
            return "You don't have an account in EUR"
        default:
            return "You don't have an account in USD"
        }
    }
    
    private var openDestinationAccountDescription: String{
        switch(self.destinationCurrency.lowercased()){
        case "gbp":
            return "To proceed, you'll need to open an account."
        case "eur":
            return "To proceed with opening your account, please ensure you have the necessary CRS certificate ready. These documents are essential for compliance with international regulations."
        default:
            return "To proceed with opening your account, please ensure you have the necessary FATCA certificates ready. These documents are essential for compliance with international regulations."
        }
    }
    
    private func openAccount() async throws{
        self.loading = true
        self.creatingAccount = true
        let response = try await services.accounts.openCustomerAccount(self.sourceAccount.customer?.id ?? "", currency: self.destinationCurrency)
        //On this step retrieve account until identification received
        let _ = try await self.retrieveAccount(response.value)
        self.loading = false
        self.creatingAccount = false
        self.destinationAccountId = response.value
        self.destinationAccount.nsPredicate = NSPredicate(format: "id == %@", self.destinationAccountId)
        self.openDestinationAccount = false
    }
    
    private func retrieveAccount(_ accountId: String) async throws -> Bool{
        let account = try await services.accounts.getCustomerAccount(self.sourceAccount.customer?.id ?? "", accountId: accountId)
        if (account.value?.identification != nil){
            if (account.value?.identification.accountNumber?.isEmpty == false || account.value?.identification.sortCode?.isEmpty == false || account.value?.identification.iban?.isEmpty == false || account.value?.identification.sortCode?.isEmpty == false){
                //If account passed - link with internal storage
                let accounts = CoreAccount.fetchRequest()
                accounts.predicate = NSPredicate(format: "id == %@", account.value!.id)
                let request = try self.viewContext.fetch(accounts)
                
                if (request.isEmpty){
                    let coreAccount = CoreAccount(context: self.viewContext)
                    coreAccount.fetchFromAccount(account: account.value!)
                    //TODO coreAccount.customer = self.sourceAccount.customer
                    self.sourceAccount.customer?.addToAccounts(coreAccount)
                }else{
                    request.forEach({
                        $0.fetchFromAccount(account: account.value!)
                        //TODO $0.customer = self.sourceAccount.customer
                        self.sourceAccount.customer?.addToAccounts($0)
                    })
                }
                try self.viewContext.save()
                return true
            }
        }
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        return try await self.retrieveAccount(accountId)
    }
    
    private var enoughtSourceBalance: Bool{
        if (self.sourceAccount != nil){
            if Float(self.sourceAmountValue.wrappedValue) <= self.sourceAccount.availableBalance!.value{
                return true
            }
            return false
        }
        return true
    }
    
    private var isAmountGreaterThanMinimum: Bool{
        if (self.hasSourceAmount){
            return self.sourceAmountValue.wrappedValue >= 50
        }
        if (self.hasDestinationAmount){
            return self.destinationAmountValue.wrappedValue >= 50
        }
        return true
    }
    
    private var hasSourceAmount: Bool{
        if (self.sourceAmountValue.wrappedValue > 0){
            return true
        }
        return false
    }
    
    private var hasDestinationAmount: Bool{
        if (self.destinationAmountValue.wrappedValue > 0){
            return true
        }
        return false
    }
}

struct ExchangeView: View, RouterPage{
    @EnvironmentObject var Store: ApplicationStore
    @EnvironmentObject var Error: ErrorHandlingService
    @EnvironmentObject var Router: RoutingController
    
    @State private var scrollOffset : Double = 0
    @State private var loading: Bool = false
    @State private var creatingAccount: Bool = false
    
    @FetchRequest(
        sortDescriptors: [
            SortDescriptor(\.sortOrder)
        ]
    ) var accounts: FetchedResults<CoreAccount>
    @FetchRequest(
        sortDescriptors: [
            SortDescriptor(\.sortOrder)
        ],
        predicate: NSPredicate(format:"id == ''")
    ) var destinationAccount: FetchedResults<CoreAccount>
    
    @State private var sourceAmount: String = ""
    @State private var destinationCurrency: String = ""
    @State private var destinationAmount: String = ""
    @State private var destinationAccountId: String = ""
    @State private var selectDestinationAccount: Bool = false
    @State private var openDestinationAccount: Bool = false
    
    @EnvironmentObject var manager: DataController
    @Environment(\.managedObjectContext) private var viewContext
    
    public var sourceAccount: CoreAccount
    
    var loader: some View{
        GeometryReader{ geometry in
            ZStack{
                VStack{
                    ScrollView{
                        VStack(spacing:0){
                            VStack(spacing:12){
                                Spacer()
                                VStack(spacing:24){
                                    Loader(
                                        size: .normal,
                                        style: .gray
                                    )
                                    Text("Opening an account")
                                        .font(.body)
                                        .foregroundColor(Color.get(.Text))
                                        .multilineTextAlignment(.center)
                                }
                                Spacer()
                            }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                            Spacer()
                        }
                        .frame(
                            maxWidth: .infinity,
                            minHeight: geometry.size.height - geometry.safeAreaInsets.bottom
                        )
                    }
                }
            }
            .background(Color.get(.Background))
        }
    }
    
    var body: some View {
        ApplicationNavigatorContainerView{
            if (self.creatingAccount){
                self.loader
            }else{
                GeometryReader{ geometry in
                    ZStack{
                        ScrollView{
                            VStack(spacing:0){
                                VStack(spacing:0){
                                    Header(back:{
                                        self.Router.back()
                                    }, title: "Exchange")
                                }
                                .offset(
                                    y: self.scrollOffset < 0 ? self.scrollOffset : 0
                                )
                                
                                //MARK: Loader
                                HStack{
                                    Spacer()
                                    Loader(size:.small)
                                        .offset(y: self.loaderOffset)
                                        .opacity(self.loading ? 1 : self.scrollOffset > -10 ? 0 : -self.scrollOffset / 100)
                                    Spacer()
                                }
                                .frame(
                                    maxWidth: .infinity,
                                    maxHeight: 0
                                )
                                .zIndex(3)
                                .offset(y: 0)
                                
                                //MARK: Content
                                VStack(spacing:16){
                                    //MARK: Account selector
                                    VStack(spacing: 12){
                                        Text("From")
                                            .font(.body.weight(.medium))
                                            .foregroundColor(Color("MiddleGray"))
                                            .padding(.horizontal, 16)
                                            .padding(.top, 16)
                                            .padding(.bottom, 8)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        
                                        if (self.sourceAccount != nil){
                                            self.sourceAccountCard
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                    
                                    Text("Sell")
                                        .font(.caption.weight(.medium))
                                        .foregroundColor(Color("MiddleGray"))
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 2)
                                        .background(
                                            RoundedRectangle(cornerRadius: 20)
                                                .stroke(Color.get(.BackgroundInput))
                                        )
                                        .padding(.horizontal, 16)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    
                                    VStack(spacing:12){
                                        HStack(spacing:12){
                                            CustomField(
                                                value: self.sourceCurrency,
                                                placeholder: "Currency",
                                                type: .select,
                                                options: self.currencies
                                            )
                                                .disabled(true)
                                                .frame(maxWidth: 120)
                                            CustomField(
                                                value: self.$sourceAmount,
                                                placeholder: "Amount",
                                                type: .price
                                            )
                                                .frame(maxWidth: .infinity)
                                                .disabled(self.hasDestinationAmount || self.loading)
                                        }
                                        if (self.hasSourceAmount && !self.isAmountGreaterThanMinimum){
                                            HStack{
                                                Text("Minimum exchange value is 50")
                                                    .font(.subheadline)
                                                    .foregroundColor(Color.get(.Danger))
                                                    .multilineTextAlignment(.leading)
                                                    .frame(maxWidth: .infinity, alignment: .leading)
                                                Spacer()
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                    if (!self.enoughtSourceBalance){
                                        HStack{
                                            Text("Insufficient account balance")
                                                .font(.subheadline)
                                                .foregroundColor(Color.get(.Danger))
                                                .multilineTextAlignment(.leading)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                            Spacer()
                                        }
                                        .padding(.horizontal, 16)
                                    }
                                    ZStack{}
                                        .frame(maxWidth: .infinity, maxHeight: 1)
                                        .background(
                                            Color("Divider")
                                        )
                                        .padding(.vertical, 16)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.get(.Divider), style: .init(lineWidth: 1))
                                                .background(Color.get(.BackgroundInput))
                                                .clipShape(Circle())
                                                .frame(width: 24, height: 24)
                                                .overlay(
                                                    Path{ path in
                                                        path.move(to: .init(x: 6, y: 11))
                                                        path.addLine(to: .init(x: 12, y: 16))
                                                        path.addLine(to: .init(x: 18, y: 11))
                                                    }
                                                        .stroke(Color.get(.MiddleGray), style: .init(lineWidth: 2))
                                                )
                                        )
                                    Text("Buy")
                                        .font(.caption.weight(.medium))
                                        .foregroundColor(Color("MiddleGray"))
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 2)
                                        .background(
                                            RoundedRectangle(cornerRadius: 20)
                                                .stroke(Color.get(.BackgroundInput))
                                        )
                                        .padding(.horizontal, 16)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    VStack(spacing:12){
                                        HStack(spacing:12){
                                            CustomField(
                                                value: self.$destinationCurrency,
                                                placeholder: "Currency",
                                                type: .select, options: self.destinationCurrencies
                                            )
                                                .frame(maxWidth: 120)
                                                .disabled(self.loading)
                                                .onChange(of:self.destinationCurrency){ _ in
                                                    self.destinationAccountId = ""
                                                    self.destinationAccount.nsPredicate = NSPredicate(format: "id == ''")
                                                    
                                                    self.accounts.nsPredicate = NSPredicate(
                                                        format: "lowercase:(baseCurrencyCode) == %@ AND lowercase:(type) != 'mmb' AND id != %@ AND customer == %@",
                                                        self.destinationCurrency.lowercased(),
                                                        self.sourceAccount.id ?? "",
                                                        self.sourceAccount.customer ?? ""
                                                    )
                                                    Task{
                                                        let request = CoreAccount.fetchRequest()
                                                        request.predicate = self.accounts.nsPredicate
                                                        let results = try self.viewContext.fetch(request)
                                                        
                                                        if (results.isEmpty){
                                                            self.openDestinationAccount = true
                                                        }
                                                    }
                                                }
                                            CustomField(
                                                value: self.$destinationAmount,
                                                placeholder: "Amount",
                                                type: .price
                                            )
                                                .frame(maxWidth: .infinity)
                                                .disabled(self.hasSourceAmount || self.loading)
                                        }
                                        
                                        if (self.hasDestinationAmount && !self.isAmountGreaterThanMinimum){
                                            HStack{
                                                Text("Minimum exchange value is 50")
                                                    .font(.subheadline)
                                                    .foregroundColor(Color.get(.Danger))
                                                    .multilineTextAlignment(.leading)
                                                    .frame(maxWidth: .infinity, alignment: .leading)
                                                Spacer()
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                    if (!self.destinationCurrency.isEmpty){
                                        VStack(spacing: 12){
                                            Text("Target account")
                                                .font(.body.weight(.medium))
                                                .foregroundColor(Color("MiddleGray"))
                                                .padding(.horizontal, 16)
                                                .padding(.top, 16)
                                                .padding(.bottom, 8)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                            if (!self.destinationAccountId.isEmpty && !self.destinationAccount.isEmpty){
                                                Button{
                                                    self.selectDestinationAccount = true
                                                } label:{
                                                    self.destinationAccountCard
                                                }
                                                .disabled(self.loading || self.accounts.isEmpty)
                                                .buttonStyle(.secondaryNext(size: .small))
                                            }else{
                                                Button{
                                                    self.selectDestinationAccount = true
                                                } label:{
                                                    HStack{
                                                        Text("Select an account")
                                                            .foregroundColor(Color.get(.MiddleGray))
                                                        Spacer()
                                                    }
                                                }
                                                .buttonStyle(.secondaryNext(image: "money 1"))
                                                .disabled(self.loading || self.accounts.isEmpty)
                                            }
                                            if (self.accounts.isEmpty){
                                                VStack(spacing:8){
                                                    HStack(spacing:16){
                                                        ZStack{
                                                            ZStack{
                                                                
                                                            }
                                                            .frame(
                                                                width: 20,
                                                                height: 20
                                                            )
                                                            .background(Color.get(.Danger))
                                                            .clipShape(Circle())
                                                            ZStack{
                                                                RoundedRectangle(cornerRadius: 6)
                                                                    .frame(width: 12, height: 2)
                                                                    .background(Color.white)
                                                                    .rotationEffect(.degrees(45))
                                                                RoundedRectangle(cornerRadius: 6)
                                                                    .frame(width: 12, height: 2)
                                                                    .background(Color.white)
                                                                    .rotationEffect(.degrees(-45))
                                                            }
                                                            .blendMode(.destinationOut)
                                                        }
                                                        .compositingGroup()
                                                        Text("You don't have Accounts in chosen currency")
                                                            .font(.caption.weight(.medium))
                                                            .foregroundColor(Color.get(.Danger))
                                                            .multilineTextAlignment(.leading)
                                                            .frame(maxWidth: .infinity, alignment: .leading)
                                                            .padding(.horizontal, 16)
                                                    }
                                                    .padding(.horizontal, 14)
                                                    .padding(.vertical, 19)
                                                    .background(Color.get(.Danger).opacity(0.08))
                                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                                    Button{
                                                        Task{
                                                            do{
                                                                try await self.openAccount()
                                                            }catch(let error){
                                                                self.loading = false
                                                                self.creatingAccount = false
                                                                self.Error.handle(error)
                                                            }
                                                        }
                                                    } label:{
                                                        HStack(spacing: 8){
                                                            Text("Open a New Account")
                                                                .font(.subheadline.weight(.medium))
                                                            ZStack{
                                                                RoundedRectangle(cornerRadius: 6)
                                                                    .frame(width: 12, height: 2)
                                                                    .background(Whitelabel.Color(.Primary))
                                                                RoundedRectangle(cornerRadius: 6)
                                                                    .frame(width: 12, height: 2)
                                                                    .background(Whitelabel.Color(.Primary))
                                                                    .rotationEffect(.degrees(90))
                                                            }
                                                            Spacer()
                                                        }
                                                        .foregroundColor(Whitelabel.Color(.Primary))
                                                    }
                                                    .disabled(self.loading)
                                                }
                                            }
                                        }
                                        .padding(.horizontal, 16)
                                    }
                                    Spacer()
                                    Button{
                                        Task{
                                            do{
                                                try await self.initiateOrder()
                                            }catch let error{
                                                self.loading = false
                                                self.Error.handle(error)
                                            }
                                        }
                                    } label: {
                                        HStack{
                                            Spacer()
                                            Text("Get Quote")
                                            Spacer()
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                    .buttonStyle(.primary())
                                    .disabled(self.formDisabled || self.loading)
                                    .loader(self.$loading)
                                }
                                .frame(maxWidth: .infinity)
                                .offset(
                                    y: self.loading && self.scrollOffset > -100 ? Swift.abs(100 - self.scrollOffset) : 0
                                )
                                Spacer()
                            }
                            .background(GeometryReader {
                                Color.clear.preference(key: RefreshViewOffsetKey.self, value: -$0.frame(in: .named("scroll")).origin.y)
                            })
                            .onPreferenceChange(RefreshViewOffsetKey.self) { position in
                                self.scrollOffset = position
                            }
                            .frame(
                                maxWidth: .infinity,
                                minHeight: geometry.size.height - geometry.safeAreaInsets.bottom
                            )
                        }
                        .coordinateSpace(name: "scroll")
                        
                        //MARK: Popups
                        PresentationSheet(isPresented: self.$selectDestinationAccount){
                            VStack{
                                ScrollView{
                                    VStack(spacing: 12){
                                        Text("Select the Account")
                                            .font(.title2.bold())
                                            .foregroundColor(Color.get(.Text, scheme: .light))
                                            .frame(maxWidth:.infinity, alignment: .leading)
                                            .multilineTextAlignment(.leading)
                                        VStack(spacing: 8){
                                            ForEach(self.accounts, id:\.id){ account in
                                                Button{
                                                    self.destinationAccountId = ""
                                                    self.destinationAccount.nsPredicate = NSPredicate(format: "id == %@", account.id ?? "")
                                                    
                                                    DispatchQueue.main.asyncAfter(deadline: .now()+0.1){
                                                        self.destinationAccountId = account.id ?? ""
                                                        self.selectDestinationAccount = false
                                                    }
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
                                .frame(maxHeight: geometry.size.height - (geometry.safeAreaInsets.bottom + 100))
                            }
                            .padding(20)
                            .padding(.top,10)
                            .padding(.bottom, geometry.safeAreaInsets.bottom)
                        }
                        
                        PresentationSheet(isPresented: self.$openDestinationAccount){
                            VStack(spacing:24){
                                ZStack{
                                    Image("danger")
                                }
                                .frame(width: 80, height: 80)
                                VStack(spacing: 6){
                                    Text(self.openDestinationAccountTitle)
                                        .font(.body.bold())
                                        .foregroundColor(Color.get(.Text))
                                    Text(self.openDestinationAccountDescription)
                                        .multilineTextAlignment(.center)
                                        .font(.caption)
                                        .foregroundColor(Color.get(.LightGray))
                                }
                                HStack(spacing: 16){
                                    Button{
                                        self.openDestinationAccount = false
                                    } label:{
                                        HStack{
                                            Spacer()
                                            Text("Cancel")
                                            Spacer()
                                        }
                                    }
                                    .buttonStyle(.secondary())
                                    Button{
                                        Task{
                                            do{
                                                self.openDestinationAccount = false
                                                try await self.openAccount()
                                            }catch(let error){
                                                self.loading = false
                                                self.creatingAccount = false
                                                self.Error.handle(error)
                                            }
                                        }
                                    } label:{
                                        HStack{
                                            Spacer()
                                            Text("Open account")
                                            Spacer()
                                        }
                                    }
                                    .buttonStyle(.primary())
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 24)
                            .padding(.bottom, geometry.safeAreaInsets.bottom)
                        }
                        
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationTitle("")
        .onAppear{
            Task{
                do{
                    
                    self.accounts.nsPredicate = NSPredicate(
                        format: "lowercase:(type) != 'mmb' AND id != %@ AND customer == %@",
                        self.sourceAccount.id ?? "",
                        self.sourceAccount.customer ?? ""
                    )
                     
                    try await self.loadAccounts()
                }catch(let error){
                    self.loading = false
                    self.Error.handle(error)
                }
            }
        }
    }
}
