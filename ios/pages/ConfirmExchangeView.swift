//
//  ConfirmExchangeView.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 19.09.2024.
//

import Foundation
import SwiftUI
import Combine

extension ConfirmExchangeView{
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
    
    private func loadAccounts() async throws{
        self.loading = true
        
        guard self.customerId != nil else{
            throw ApplicationError(title: "", message: "Customer doesnt passed. Please try again")
        }
        
        let response = try await services.accounts.getCustomerAccounts(self.customerId!)
        self.accounts = response.value.data
        
        self.loading = false
    }
    
    private func initiateOrder() async throws{
        do{
            self.loading = true
            self.failed = nil
            if (self.order != nil && self.customerId != nil){
                var order = self.order
                if (self.result != nil){
                    order!.orderId = self.result?.id ?? ""
                }
                let result = try await services.forex.initiate(self.customerId!, body: order!)
                self.expired = false
                self.result = result.value
                self.expiredIn = result.value.secondsToExpire
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(result.value.secondsToExpire)){
                    self.expired = true
                }
            }
            self.loading = false
        }catch(let error){
            self.loading = false
            if (error as? KycpService.ServerError != nil){
                let details = error as! KycpService.ServerError
                self.failed = details.errors.first
                if (self.order != nil){
                    self.result = .init(
                        id: "",
                        sourceAccountId: self.order!.sourceAccountId,
                        targetAccountId: self.order!.targetAccountId,
                        sourceAmount: .init(
                            currencyCode: "",
                            value: self.order!.sourceAmount
                        ),
                        targetAmount: .init(
                            currencyCode: "",
                            value:self.order!.targetAmount
                        ),
                        state: .failed,
                        totalRate: 1,
                        expiresUtc: "",
                        createdUtc: "",
                        secondsToExpire: 0
                    )
                }
                return;
            }
            throw error
        }
    }
    private func confirm() async throws{
        self.loading = true
        self.processing = true
        self.successed = false
        self.expiredIn = 0
        if (self.result != nil){
            self.successedResult = self.result
            let result = try await services.forex.confirm(self.customerId!, orderId: self.result!.id)
            if (result){
                self.successed = true
            }
        }
        self.loading = false
        self.processing = false
    }
    
    private var sourceAccount: Account?{
        let accountId = self.result?.sourceAccountId ?? ""
        return self.accounts.first(where: {$0.id == accountId})
    }
    
    var sourceAccountCard: some View{
        ZStack{
            if (self.sourceAccount != nil){
                AccountCard(account: self.sourceAccount!)
                    .padding(.horizontal, 0)
            }
        }
    }
    
    private var sourceAmountEnough: Bool{
        if (self.sourceAccount != nil){
            var formattedAmount = (String(self.result?.sourceAmount?.value ?? 0)).replacingOccurrences(of: ",", with: ".")
            let amount = Float(formattedAmount) ?? 0
            if amount <= self.sourceAccount!.availableBalance.value{
                return true
            }
        }
        return false
    }
    private var targetAmountEnough: Bool{
        if (self.failed != nil && self.failed!.code == .AmountValidationError){
            return false
        }
        if (self.destinationAccount != nil){
            let formattedAmount = (String(self.result?.targetAmount?.value ?? 0)).replacingOccurrences(of: ",", with: ".")
            let amount = Float(formattedAmount) ?? 0
            return amount > 0
        }
        return false
    }
    
    private var destinationAccount: Account?{
        let accountId = self.result?.targetAccountId ?? ""
        return self.accounts.first(where: {$0.id == accountId})
    }
    
    var destinationAccountCard: some View{
        ZStack{
            if (self.destinationAccount != nil){
                AccountCard(style: .short, account: self.destinationAccount!)
                    .padding(.horizontal, 0)
            }
        }
    }
    
    var successDestinationAccountCard: some View{
        ZStack{
            if (self.destinationAccount != nil){
                AccountCard(style: .shortContext, account: self.destinationAccount!)
                    .padding(.horizontal, 0)
            }
        }
    }
    
    private var sourceCurrency: String{
        if (self.result?.sourceAmount?.currencyCode != nil && self.result?.sourceAmount?.currencyCode.isEmpty == false){
            return self.result?.sourceAmount?.currencyCode.uppercased() ?? ""
        }
        return self.sourceAccount?.baseCurrencyCode.uppercased() ?? ""
    }
    private var targetCurrency: String{
        if (self.result?.targetAmount?.currencyCode != nil && self.result?.targetAmount?.currencyCode.isEmpty == false){
            return self.result?.targetAmount?.currencyCode.uppercased() ?? ""
        }
        return self.destinationAccount?.baseCurrencyCode.uppercased() ?? ""
    }
    private var rate: String{
        return [
            "1".formatAsPrice(self.sourceCurrency.uppercased()),
            String(self.result?.totalRate ?? 0).formatAsPrice(self.targetCurrency.uppercased())
        ].joined(separator: " = ")
    }
    
    private var successSourceCurrency: String{
        return self.successedResult?.sourceAmount?.currencyCode.uppercased() ?? ""
    }
    private var successTargetCurrency: String{
        return self.successedResult?.targetAmount?.currencyCode.uppercased() ?? ""
    }
    private var successRate: String{
        return [
            "1".formatAsPrice(self.sourceCurrency.uppercased()),
            String(self.successedResult?.totalRate ?? 0).formatAsPrice(self.targetCurrency.uppercased())
        ].joined(separator: " = ")
    }
}

struct ConfirmExchangeView: View, RouterPage{
    @EnvironmentObject var Store: ApplicationStore
    @EnvironmentObject var Error: ErrorHandlingService
    @EnvironmentObject var Router: RoutingController
    
    @State private var scrollOffset : Double = 0
    @State private var loading: Bool = false
    @State private var processing: Bool = false
    @State private var successed: Bool = false
    @State private var successedResult: ForexService.ForexOrderModel.ForexOrderModelValue? = nil
    @State private var accounts: Array<Account> = []
    @State private var expiredIn: Int = 0
    @State private var expired: Bool = false
    @State private var cashAnimationAngle: Double = 0
    
    public var customerId: String? = nil
    public var order: ForexService.CreateForexOrderRequest? = nil
    @State private var result: ForexService.ForexOrderModel.ForexOrderModelValue? = nil
    @State private var failed: KycpService.ServerError.ServerErrorDetails? = nil
    
    var confirmation: some View{
        GeometryReader{ geometry in
            ZStack{
                VStack{
                    ScrollView{
                        VStack(spacing:0){
                            VStack(spacing:12){
                                VStack(spacing:12){
                                    ZStack{
                                        Image("exchange-splash")
                                        Image("exchange")
                                            .rotationEffect(.degrees(self.cashAnimationAngle))
                                            .onAppear{
                                                withAnimation(.interactiveSpring(duration: 0.4)){
                                                    self.cashAnimationAngle = 360
                                                }
                                            }
                                    }
                                    VStack(spacing:8){
                                        Text("Identifier of the FX Order")
                                            .font(.body.weight(.bold))
                                            .foregroundColor(Color.get(.Text))
                                        Text(self.successedResult?.id ?? "")
                                            .font(.caption)
                                            .foregroundColor(Color.get(.LightGray))
                                            .multilineTextAlignment(.center)
                                    }
                                }
                                    .padding(16)
                                Divider()
                                    .overlay(Color.get(.LightGray))
                                VStack(spacing:8){
                                    HStack{
                                        VStack(alignment: .leading, spacing:8){
                                            Text("Source Currency")
                                                .font(.body)
                                                .foregroundColor(Color.get(.LightGray))
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                            HStack{
                                                Text("\(self.successedSourceAmountSequence[0]).")
                                                + Text(self.successedSourceAmountSequence[1])
                                                    .font(.caption)
                                                Spacer()
                                            }
                                                .font(.body.bold())
                                                .foregroundColor(Color.get(.Text))
                                        }
                                        Spacer()
                                    }
                                        .padding(.horizontal, 24)
                                        .padding(.vertical, 8)
                                    HStack{
                                        VStack(alignment: .leading, spacing:8){
                                            ZStack{
                                                Image("arrow-left")
                                                    .resizable()
                                                    .scaledToFit()
                                                    .rotationEffect(.degrees(270))
                                                    .foregroundColor(Whitelabel.Color(.Primary))
                                            }
                                            .frame(
                                                width:24,
                                                height:24
                                            )
                                        }
                                        Spacer()
                                    }
                                        .padding(.horizontal, 24)
                                        .padding(.vertical, 0)
                                    HStack{
                                        VStack(alignment: .leading, spacing:8){
                                            Text("Target Currency")
                                                .font(.body)
                                                .foregroundColor(Color.get(.LightGray))
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                            HStack{
                                                Text("\(self.successedDestinationAmountSequence[0]).")
                                                + Text(self.successedDestinationAmountSequence[1])
                                                    .font(.caption)
                                                Spacer()
                                            }
                                                .font(.body.bold())
                                                .foregroundColor(Color.get(.Text))
                                        }
                                        Spacer()
                                    }
                                        .padding(.horizontal, 24)
                                        .padding(.vertical, 8)
                                    HStack{
                                        VStack(alignment: .leading, spacing:8){
                                            Text("Applied Conversion Rate")
                                                .font(.body)
                                                .foregroundColor(Color.get(.LightGray))
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                            Text(self.successRate)
                                                .font(.subheadline)
                                                .foregroundColor(Color.get(.Text))
                                                .padding(12)
                                                .background(Color.get(.LightGray).opacity(0.08))
                                                .clipShape(RoundedRectangle(cornerRadius: 50))
                                        }
                                        Spacer()
                                    }
                                        .padding(.horizontal, 24)
                                        .padding(.vertical, 8)
                                    HStack{
                                        VStack(alignment: .leading, spacing:8){
                                            Text("Target account")
                                                .font(.body)
                                                .foregroundColor(Color.get(.LightGray))
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                            if (self.destinationAccount != nil){
                                                VStack{
                                                    self.successDestinationAccountCard
                                                }
                                            }
                                        }
                                        Spacer()
                                    }
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 8)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                            }
                                .frame(maxWidth: .infinity)
                                .background(Color.get(.Background))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .padding(16)
                            Spacer()
                            Button{
                                self.Router.goTo(MainView(), routingType: .backward)
                            } label:{
                                HStack{
                                    Spacer()
                                    Text("OK")
                                    Spacer()
                                }
                            }
                                .buttonStyle(.primary())
                                .padding(.top, 12)
                                .padding(.horizontal, 16)
                        }
                        .frame(
                            maxWidth: .infinity,
                            minHeight: geometry.size.height - geometry.safeAreaInsets.bottom
                        )
                    }
                }
            }
            .background(Color.get(.Section))
        }
    }
    
    var loader: some View{
        GeometryReader{ geometry in
            ZStack{
                VStack{
                    ScrollView{
                        VStack(spacing:0){
                            VStack(spacing:0){
                                Header(back:{
                                    self.Router.back()
                                }, title: "Quote")
                            }
                            VStack(spacing:12){
                                Spacer()
                                VStack(spacing:24){
                                    Loader(
                                        size: .normal,
                                        style: .gray
                                    )
                                    Text("Exchange is in progress, please wait")
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
    
    private var sourceAmountSequence: Array<Substring> {
        return String(self.result?.sourceAmount?.value ?? 0).formatAsPrice(self.sourceCurrency.uppercased()).split(separator: ".")
    }
    
    private var destinationAmountSequence: Array<Substring> {
        return String(self.result?.targetAmount?.value ?? 0).formatAsPrice(self.targetCurrency.uppercased()).split(separator: ".")
    }
    
    private var successedSourceAmountSequence: Array<Substring> {
        return String(self.successedResult?.sourceAmount?.value ?? 0).formatAsPrice(self.successSourceCurrency).split(separator: ".")
    }
    
    private var successedDestinationAmountSequence: Array<Substring> {
        return String(self.successedResult?.targetAmount?.value ?? 0).formatAsPrice(self.successTargetCurrency).split(separator: ".")
    }
    
    var body: some View {
        ApplicationNavigatorContainerView{
            if (self.processing){
                self.loader
            }
            else if (self.successed){
                self.confirmation
            }else{
                GeometryReader{ geometry in
                    ZStack{
                        ScrollView{
                            VStack(spacing:0){
                                VStack(spacing:0){
                                    Header(back:{
                                        self.Router.back()
                                    }, title: "Quote")
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
                                VStack(spacing:12){
                                    if (self.sourceAccount != nil){
                                        VStack{
                                            self.sourceAccountCard
                                        }
                                        .padding(.horizontal, 16)
                                    }
                                    if (self.result != nil){
                                        VStack(alignment: .leading, spacing: 6){
                                            Text("Total")
                                                .multilineTextAlignment(.leading)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                                .foregroundColor(Color.get(.LightGray))
                                            HStack(spacing:12){
                                                VStack(alignment: .leading, spacing:2){
                                                    Text("Sending")
                                                        .font(.caption.weight(.medium))
                                                        .foregroundColor(Color.get(.LightGray))
                                                    HStack{
                                                        Text("\(self.sourceAmountSequence[0]).")
                                                            .font(.body.bold())
                                                        + Text(self.sourceAmountSequence[1])
                                                            .font(.caption)
                                                    }
                                                        .foregroundColor(Color.get(.Text))
                                                }
                                                Spacer()
                                                ZStack{
                                                    Image("arrow-left")
                                                        .resizable()
                                                        .scaledToFit()
                                                        .rotationEffect(.degrees(180))
                                                        .foregroundColor(Whitelabel.Color(.Primary))
                                                }
                                                .frame(
                                                    width:24,
                                                    height:24
                                                )
                                                Spacer()
                                                VStack(alignment: .trailing, spacing:2){
                                                    Text("Receiving")
                                                        .font(.caption.weight(.medium))
                                                        .foregroundColor(Color.get(.LightGray))
                                                    if (!targetAmountEnough){
                                                        Text("\(targetCurrency) -.--")
                                                            .font(.body.bold())
                                                            .foregroundColor(Color.get(.Text))
                                                            .multilineTextAlignment(.trailing)
                                                    }else{
                                                        HStack{
                                                            Text("\(self.destinationAmountSequence[0]).")
                                                                .font(.body.bold())
                                                            + Text(self.destinationAmountSequence[1])
                                                                .font(.caption)
                                                        }
                                                            .foregroundColor(Color.get(.Text))
                                                            .multilineTextAlignment(.trailing)
                                                    }
                                                }
                                            }
                                            .padding(16)
                                            .background(Color.get(.LightGray).opacity(0.08))
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                            .padding(.vertical, 12)
                                            if (!targetAmountEnough){
                                                HStack{
                                                    VStack{
                                                        Text("Exchange value is too low")
                                                            .font(.subheadline)
                                                            .foregroundColor(Color.get(.Danger))
                                                            .padding(2)
                                                            .multilineTextAlignment(.leading)
                                                    }
                                                    Spacer()
                                                }
                                                .frame(maxWidth: .infinity)
                                            }else if (!self.sourceAmountEnough){
                                                HStack{
                                                    VStack{
                                                        Text("Account balance is too low")
                                                            .font(.subheadline)
                                                            .foregroundColor(Color.get(.Danger))
                                                            .padding(2)
                                                            .multilineTextAlignment(.leading)
                                                    }
                                                    Spacer()
                                                }
                                                .frame(maxWidth: .infinity)
                                            }else if (self.expired){
                                                VStack(alignment: .leading){
                                                    Text("The rate has expired, please click \"Get quote\" to try again.")
                                                        .font(.subheadline)
                                                        .foregroundColor(Color.get(.Danger))
                                                        .padding(2)
                                                        .multilineTextAlignment(.leading)
                                                }
                                                .frame(maxWidth: .infinity)
                                            }else{
                                                HStack(spacing:12){
                                                    Text(self.rate)
                                                        .font(.subheadline)
                                                        .foregroundColor(Color.get(.Text))
                                                        .padding(12)
                                                        .background(Color.get(.LightGray).opacity(0.08))
                                                        .clipShape(RoundedRectangle(cornerRadius: 50))
                                                    ExpiredBar(
                                                        timeout: self.$expiredIn
                                                    )
                                                }
                                            }
                                        }
                                        .padding(16)
                                        .background(Color.get(.Section))
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                        .padding(.horizontal, 16)
                                    }
                                    if (self.destinationAccount != nil){
                                        VStack{
                                            VStack(alignment: .leading, spacing: 8){
                                                Text("Target account")
                                                    .multilineTextAlignment(.leading)
                                                    .frame(maxWidth: .infinity, alignment: .leading)
                                                    .foregroundColor(Color.get(.LightGray))
                                                self.destinationAccountCard
                                            }
                                            .padding(16)
                                            .background(Color.get(.Section))
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                            .padding(.horizontal, 16)
                                        }
                                    }
                                    Spacer()
                                    if (self.sourceAmountEnough && targetAmountEnough && self.expired){
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
                                                Text("Get quote")
                                                Spacer()
                                            }
                                        }
                                        .disabled(self.loading)
                                        .loader(self.$loading)
                                        .buttonStyle(.primary())
                                        .padding(.horizontal, 16)
                                    }else{
                                        Button{
                                            Task{
                                                do{
                                                    try await self.confirm()
                                                }catch let error{
                                                    self.loading = false
                                                    self.processing = false
                                                    self.Error.handle(error)
                                                }
                                            }
                                        } label: {
                                            HStack{
                                                Spacer()
                                                Text("Confirm")
                                                Spacer()
                                            }
                                        }
                                        .disabled(self.loading || !self.sourceAmountEnough || !self.targetAmountEnough)
                                        .loader(self.$loading)
                                        .buttonStyle(.primary())
                                        .padding(.horizontal, 16)
                                    }
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
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationTitle("")
        .onAppear{
            Task{
                do{
                    try await self.loadAccounts()
                    try await self.initiateOrder()
                }catch(let error){
                    self.loading = false
                    self.Error.handle(error)
                }
            }
        }
    }
}

struct ConfirmExchangeView_Previews: PreviewProvider {
    static var previews: some View {
        ContentViewContainerPreview{
            ConfirmExchangeView()
        }
    }
}
