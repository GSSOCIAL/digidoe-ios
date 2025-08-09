//
//  StandingOrderDetailsView.swift
//  DigiDoe Business Banking
//
//  Created by Михайло Картмазов on 01.07.2025.
//

import Foundation
import SwiftUI
import LinkPresentation

/**Getters*/
extension StandingOrderDetailsView{
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
    var transactionAmount: Array<Substring> {
        if (self.order != nil){
            return String(Double(self.order!.amount!.value)).formatAsPrice(self.order!.amount!.currencyCode.rawValue.uppercased()).split(separator: ".")
        }
        return []
    }
    var feesAmount: Double{
        return (self.order?.orderPriceComponents?.filter({ component in
            return component.amount != nil
        }).reduce(0){ result, component in
            return result + component.amount!.value
        })! ?? 0
    }
}

/**Methods*/
extension StandingOrderDetailsView{
    func getOrder() async throws{
        self.loading = true
        let response = try await services.orders.getOrder(
            self.customerId,
            orderId: self.orderId
        )
        self.order = response.value
        self.title = self.order?.standingOrder?.description ?? ""
        self.loading = false
        try await self.getTransactions()
    }
    func cancelOrder() async throws{
        self.loading = true
        let response = try await services.standingOrders.cancelOrder(
            customerId: self.customerId,
            orderId: self.order?.standingOrder?.id ?? ""
        )
        if (response){
            try await self.getOrder()
        }
        self.afterCancel = true
        self.loading = false
    }
    func handleCancelOrder(){
        Task{
            do{
                try await self.cancelOrder()
            }catch let error{
                self.loading = false
                self.Error.handle(error)
            }
        }
    }
    func handleUpdateOrder(){
        Task{
            do{
                try await self.updateOrder()
            }catch let error{
                self.loading = false
                self.Error.handle(error)
            }
        }
    }
    func updateOrder() async throws{
        self.loading = true
        if (self.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false){
            let response = try await services.standingOrders.updateOrder(
                customerId: self.customerId,
                orderId: self.order?.standingOrder?.id ?? "",
                description: self.title
            )
        }
        self.loading = false
    }
    func getTransactions() async throws{
        self.loading = true
        if (self.account != nil){
            let response = try await services.transactions.getStandingOrderTransactions(
                customerId: self.customerId,
                accountId: self.account?.id ?? "",
                orderId: self.orderId
            )
            self.transactionsList = response.value.data
        }
        self.loading = false
    }
    func fetchAccount(accountId: String){
        Task{
            do{
                if let account = try await services.accounts.getCustomerAccount(self.customerId, accountId: accountId) as? AccountsService.AccountGetResponse{
                    if (account.value != nil){
                        let coreAccount = CoreAccount(context: self.viewContext)
                        coreAccount.fetchFromAccount(account: account.value!)
                        self.account = coreAccount
                        try await self.getTransactions()
                    }
                }
            }catch let error{
                self.loading = false
                self.Error.handle(error)
            }
        }
    }
}

/**Views*/
extension StandingOrderDetailsView{
    var state: some View{
        return HStack(spacing: 6){
            if (self.order?.standingOrder?.state == .cancelled){
                Group{
                    Text(self.order?.cancellationReason ?? "")
                }
                .font(.caption)
                .foregroundColor(Color.get(.Danger))
                .multilineTextAlignment(.leading)
                Spacer()
            }else{
                if (self.order?.standingOrder?.state != .completed && self.order?.standingOrder?.nextExecutionDate != nil){
                    Group{
                        Text("Next payment date: ")
                        + Text((self.order?.standingOrder?.nextExecutionDate.asDate() ?? Date()).asString("dd MMM yyyy"))
                            .underline()
                    }
                    .font(.caption)
                    .foregroundColor(Color.get(.Text))
                    ZStack{
                        
                    }
                    .frame(width: 4, height: 4)
                    .background(Color.get(.PaleBlack))
                    .clipShape(Circle())
                }
                Text(self.order?.standingOrder?.state.label ?? "")
                    .font(.caption)
                    .foregroundColor(self.order?.standingOrder?.state.color ?? Color.get(.PaleBlack))
                Spacer()
            }
        }.padding(.horizontal, 16)
    }
    var scheduleCard: some View{
        return VStack(alignment: .leading, spacing:8){
            Text("Payment Schedule")
                .font(.body.bold())
                .frame(maxWidth: .infinity, alignment: .leading)
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color("SectionDivider"))
            //MARK: - Sender body
            VStack(spacing:8){
                HStack(alignment: .top, spacing:0){
                    Text("Billing interval")
                        .frame(maxWidth: 130, alignment: .leading)
                        .font(.subheadline.bold())
                        .foregroundColor(Color.get(.LightGray))
                    Text((self.order?.standingOrder?.period.frequency(self.order?.standingOrder?.startDate.asDate() ?? Date()) ?? "").capitalizedSentence)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .font(.subheadline.bold())
                        .foregroundColor(Color.get(.MiddleGray))
                }
                HStack(alignment: .top, spacing:0){
                    Text("Start Date")
                        .frame(maxWidth: 130, alignment: .leading)
                        .font(.subheadline.bold())
                        .foregroundColor(Color.get(.LightGray))
                    Text((self.order?.standingOrder?.startDate.asDate() ?? Date()).asString("dd MMM yyyy"))
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .font(.subheadline.bold())
                        .foregroundColor(Color.get(.MiddleGray))
                }
                HStack(alignment: .top, spacing:0){
                    Text("End Date")
                        .frame(maxWidth: 130, alignment: .leading)
                        .font(.subheadline.bold())
                        .foregroundColor(Color.get(.LightGray))
                    Text(self.order?.standingOrder?.endDate == nil ? "Until further notice" : (self.order?.standingOrder?.endDate?.asDate() ?? Date()).asString("dd MMM yyyy"))
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .font(.subheadline.bold())
                        .foregroundColor(Color.get(.MiddleGray))
                }
                if (self.order?.standingOrder?.state == .active){
                    Button{
                        self.beforeCancel = true
                    } label:{
                        HStack{
                            Spacer()
                            Text("Cancel standing order")
                            Spacer()
                        }
                    }
                    .buttonStyle(.secondaryGray())
                    .disabled(self.loading)
                    .loader(self.$loading)
                }
            }
        }
        .padding(12)
        .background(Color.get(.Section))
        .clipShape(
            RoundedRectangle(cornerRadius: 16)
        )
        .padding(.horizontal, 16)
    }
    var sender: some View{
        return VStack(alignment: .leading, spacing:8){
            Text("Sender Details")
                .font(.body.bold())
                .frame(maxWidth: .infinity, alignment: .leading)
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color("SectionDivider"))
            if (self.order != nil){
                VStack(spacing:8){
                    HStack(alignment: .top, spacing:0){
                        Text("Name")
                            .frame(maxWidth: 130, alignment: .leading)
                            .font(.subheadline.bold())
                            .foregroundColor(Color.get(.LightGray))
                        Text(self.order?.debtorAccount?.title ?? "–")
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .font(.subheadline.bold())
                            .foregroundColor(Color.get(.MiddleGray))
                    }
                    AccountIdentification(
                        self.order?.debtorAccount
                    )
                }
            }
        }
        .padding(12)
        .background(Color.get(.Section))
        .clipShape(
            RoundedRectangle(cornerRadius: 16)
        )
        .padding(.horizontal, 16)
    }
    var recipient: some View{
        return VStack(alignment: .leading, spacing:8){
            Text("Recipient Details")
                .font(.body.bold())
                .frame(maxWidth: .infinity, alignment: .leading)
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color("SectionDivider"))
            if (self.order != nil){
                VStack(spacing:8){
                    HStack(alignment: .top, spacing:0){
                        Text("Name")
                            .frame(maxWidth: 130, alignment: .leading)
                            .font(.subheadline.bold())
                            .foregroundColor(Color.get(.LightGray))
                        Text(self.order?.recipient?.accountHolderName ?? "–")
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .font(.subheadline.bold())
                            .foregroundColor(Color.get(.MiddleGray))
                    }
                    AccountIdentification(
                        self.order?.recipient
                    )
                }
            }
        }
        .padding(12)
        .background(Color.get(.Section))
        .clipShape(
            RoundedRectangle(cornerRadius: 16)
        )
        .padding(.horizontal, 16)
    }
    var amount: some View{
        return VStack(alignment: .leading, spacing:8){
            Text("Amount")
                .font(.body.bold())
                .frame(maxWidth: .infinity, alignment: .leading)
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color("SectionDivider"))
            if (self.order != nil){
                VStack(spacing:8){
                    HStack(alignment: .top, spacing:0){
                        Text("Transferred")
                            .frame(maxWidth: 130, alignment: .leading)
                            .font(.subheadline.bold())
                            .foregroundColor(Color.get(.LightGray))
                        HStack{
                            Spacer()
                            Text(String(Double(self.order?.amount?.value ?? 0)).formatAsPrice(self.order?.amount?.currencyCode.rawValue.uppercased() ?? ""))
                                .frame(alignment: .trailing)
                                .font(.subheadline.bold())
                                .foregroundColor(Color.get(.MiddleGray))
                        }
                    }
                    HStack(alignment: .top, spacing:0){
                        Text("Fee")
                            .frame(maxWidth: 130, alignment: .leading)
                            .font(.subheadline.bold())
                            .foregroundColor(Color.get(.LightGray))
                        HStack{
                            Spacer()
                            Text(String(self.feesAmount).formatAsPrice(self.order?.amount?.currencyCode.rawValue.uppercased() ?? ""))
                                .frame(alignment: .trailing)
                                .font(.subheadline.bold())
                                .foregroundColor(Color.get(.MiddleGray))
                        }
                    }
                    HStack(alignment: .top, spacing:0){
                        Text("Reference")
                            .frame(maxWidth: 130, alignment: .leading)
                            .font(.subheadline.bold())
                            .foregroundColor(Color.get(.LightGray))
                        Text(self.order?.reference ?? "")
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .font(.subheadline.bold())
                            .foregroundColor(Color.get(.MiddleGray))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .padding(12)
        .background(Color.get(.Section))
        .clipShape(
            RoundedRectangle(cornerRadius: 16)
        )
        .padding(.horizontal, 16)
    }
    var transactions: some View{
        return VStack(alignment: .leading, spacing:8){
            Text("TXs list")
                .font(.body.bold())
                .frame(maxWidth: .infinity, alignment: .leading)
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color("SectionDivider"))
            if (self.order != nil && self.account != nil){
                VStack(spacing:8){
                    ForEach(Array(self.transactionsList.enumerated()), id: \.1.transactionId){ (index, item) in
                        Button{
                            self.Router.goTo(
                                TransactionDetailsView(
                                    account: self.account!,
                                    transactionRef: item
                                )
                            )
                        } label: {
                            TransactionSmallCard(
                                transaction: item
                            )
                        }
                    }
                }
            }
        }
        .padding(12)
        .background(Color.get(.Section))
        .clipShape(
            RoundedRectangle(cornerRadius: 16)
        )
        .padding(.horizontal, 16)
    }
    
    var cancelationPopup: some View{
        VStack(alignment: .center, spacing: 8){
            ZStack{
                Image("document-ask")
            }
            .frame(width: 220, height: 160)
            VStack(alignment: .center, spacing: 8){
                Text("Do you want to cancel this Standing order?")
                    .font(.body.bold())
                    .foregroundColor(Color.get(.Text))
                    .multilineTextAlignment(.center)
                Text("Transactions that have already passed all internal checks will still be processed. All other scheduled payments will be cancelled.")
                    .font(.caption)
                    .foregroundColor(Color.get(.LightGray))
                    .multilineTextAlignment(.center)
            }
            VStack(alignment: .center, spacing: 16){
                Button{
                    self.beforeCancel = false
                } label:{
                    HStack{
                        Spacer()
                        Text("No")
                        Spacer()
                    }
                }
                .buttonStyle(.secondary())
                .fixedSize(horizontal: false, vertical: true)
                Button{
                    self.handleCancelOrder()
                    self.beforeCancel = false
                } label:{
                    HStack{
                        Spacer()
                        Text("Yes, I want to cancel")
                        Spacer()
                    }
                }
                .buttonStyle(.primary())
                .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, 10)
        }
    }
    var cancelationToast: some View{
        HStack(alignment: .center, spacing: 16){
            Text("Standing Order has been Cancelled")
                .font(.subheadline)
                .foregroundColor(Color.white)
                .multilineTextAlignment(.leading)
            Spacer()
            ZStack{
                Image("tick-linear")
                    .resizable()
                    .foregroundColor(Color.white)
            }.frame(width: 24, height: 24)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(Color.get(.Active))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .onAppear{
            DispatchQueue.main.asyncAfter(deadline: .now() + 3){
                self.afterCancel = false
            }
        }
    }
}

struct StandingOrderDetailsView: View, RouterPage {
    @EnvironmentObject var Store: ApplicationStore
    @EnvironmentObject var Error: ErrorHandlingService
    @EnvironmentObject var Router: RoutingController
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var loading: Bool = false
    @State private var scrollOffset : Double = 0
    
    @State private var order: PaymentOrderExtendedDto?
    @State private var transactionsList: Array<Transaction> = []
    
    @State public var customerId: String
    @State public var account: CoreAccount?
    @State public var orderId: String
    
    @State private var beforeCancel: Bool = false
    @State private var afterCancel: Bool = false
    @State private var title: String = ""
    @State private var titleFieldFocused: Bool = false
    @State private var titleFieldResponder: Bool = false
    
    
    init(customerId: String, account: CoreAccount, orderId: String){
        self.customerId = customerId
        self.account = account
        self.orderId = orderId
    }
    
    init(customerId: String, accountId: String, orderId: String){
        self.customerId = customerId
        self.orderId = orderId
        //Fetch account
        self.fetchAccount(accountId: accountId)
    }
    
    
    var body: some View {
        ApplicationNavigatorContainerView{
            GeometryReader{ geometry in
                ZStack{
                    ScrollView{
                        VStack(spacing: 0){
                            VStack(spacing:0){
                                Header(back:{
                                    self.Router.back()
                                }, title: "Standing order details")
                                
                                HStack(spacing: 16){
                                    ZStack{
                                        Image("time")
                                            .renderingMode(.template)
                                            .foregroundColor(Color.get(.MiddleGray))
                                    }
                                    .frame(width: 52, height: 52)
                                    .background(Color("SectionDivider"))
                                    .clipShape(
                                        RoundedRectangle(cornerRadius: 16)
                                    )
                                    VStack{
                                        ZStack{
                                            CustomFieldResponder(
                                                value: self.$title,
                                                responder: self.$titleFieldResponder,
                                                placeholder: "Title",
                                                type: .text,
                                                onEditingChanged: { focus in
                                                    self.titleFieldFocused = focus
                                                    if (focus == false){
                                                        self.handleUpdateOrder()
                                                    }
                                                },
                                                paddings:[0,0,0,37]
                                            )
                                        }.overlay(
                                            ZStack{
                                                Button{
                                                    if (self.titleFieldFocused){
                                                        self.handleUpdateOrder()
                                                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to:nil, from:nil, for:nil)
                                                    }else{
                                                        self.titleFieldResponder = true
                                                    }
                                                } label:{
                                                    if (self.titleFieldFocused){
                                                        if (self.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false){
                                                            Image("tick-circle-pending")
                                                        }else{
                                                            Image("tick-circle-disabled")
                                                        }
                                                    }else{
                                                        Image("edit-2-linear")
                                                    }
                                                }
                                            }
                                                .frame(width: 24, height:24)
                                                .padding(13)
                                            ,alignment: .trailing
                                        )
                                        if (self.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty){
                                            HStack{
                                                Text("Please enter a standing order title")
                                                    .font(.caption)
                                                    .foregroundColor(Color.get(.Danger))
                                                    .multilineTextAlignment(.leading)
                                                Spacer()
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal,16)
                            }
                            .offset(
                                y: self.scrollOffset < 0 ? self.scrollOffset : 0
                            )
                            
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
                            
                            VStack(spacing:12){
                                self.state
                                
                                self.scheduleCard
                                self.sender
                                self.recipient
                                self.amount
                                self.transactions
                            }
                            .padding(.top,20)
                            .offset(
                                y: self.loading && self.scrollOffset > -100 ? Swift.abs(100 - self.scrollOffset) : 0
                            )
                            .onAppear{
                                Task{
                                    do{
                                        try await self.getOrder()
                                    }catch(let error){
                                        self.loading = false
                                        self.Error.handle(error)
                                    }
                                }
                            }
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
                    .onChange(of: scrollOffset){ _ in
                        if (!self.loading && self.scrollOffset <= -100){
                            Task{
                                do{
                                    try await self.getOrder()
                                }catch(let error){
                                    self.loading = false
                                    self.Error.handle(error)
                                }
                            }
                        }
                    }
                    //MARK: Popups
                    PresentationSheet(isPresented: self.$beforeCancel){
                        VStack{
                            self.cancelationPopup
                        }
                        .padding(.bottom, geometry.safeAreaInsets.bottom)
                        .padding(20)
                        .padding(.top,10)
                    }
                }
                .overlay(
                    ZStack{
                        if (self.afterCancel){
                            self.cancelationToast
                        }
                    }
                    , alignment: .bottom
                )
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationTitle("")
        .background(Color.get(.Background))
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to:nil, from:nil, for:nil)
        }
    }
}

