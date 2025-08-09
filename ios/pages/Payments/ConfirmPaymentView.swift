//
//  ConfirmPaymentView.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 05.01.2024.
//

import Foundation
import SwiftUI
import LocalAuthentication
import CoreData

/**Methods*/
extension ConfirmPaymentView{
    func otpConfirmed(operationId: String, sessionId: String, type: ProfileService.ConfirmationType){
        self.verifyOtp = false
        //Finalize the operation
        Task{
            do{
                self.loading = true
                
                let isSuccess = try await services.payments.finalizeOrder(
                    self.customer.id ?? "",
                    operationId: operationId,
                    sessionId: sessionId,
                    confirmationType: type
                )
                
                
                if (isSuccess == true){
                    self.loading = false
                    self.paid = true
                    return;
                }
                
                self.loading = false
                throw ApplicationError(title: "Payment", message: "Failed to create contact, please try again")
            }catch(let error){
                self.loading = false
                self.Error.handle(error)
            }
        }
    }
    
    func otpRejected(operationId: String, sessionId: String?, type: ProfileService.ConfirmationType?){
        self.verifyOtp = false
        //Dismiss creating contact?
        /*
        Task{
            do{
                self.loading = true
                
                guard self.Store.payment.customerId != nil else{
                    throw ApplicationError(title: "No customer", message: "Customer doesnt passed")
                }
                
                let isSuccess = try await services.payments.finalizeOrder(self.Store.payment.customerId!, operationId: operationId, sessionId: sessionId ?? "", confirmationType: type)
                
                self.loading = false
            }catch(let error){
                self.loading = false
                self.Error.handle(error)
            }
        }
         */
    }
    
    private func confirmOrder() async throws{
        self.loading = true
        
        var alerts: [String: Bool] = [:]
        let _ = self.order?.fraudAlerts.map({
            alerts[$0.key] = true
        })
        let initiate = try await services.payments.initiateConfirmOrder(
            self.customer.id ?? "",
            orderId: self.order?.id ?? "",
            alerts: alerts
        )
        self.otpOperationId = initiate.value.operationId
        
        self.verifyOtp = true
        self.loading = false
    }
    
    func pay() async throws{
        self.verificationScreen = true
        
        if Biometrics.isEnabled(){
            let context = LAContext()
            var error: NSError?

            if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
                let reason = "Confirm payment"

                context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authenticationError in
                    if success {
                        DispatchQueue.main.async {
                            self.verificationScreen = false
                            self.process()
                        }
                    }
                }
            }
        }
    }
    
    func process(){
        Task{
            do{
                try await self.confirmOrder()
            }catch(let error){
                self.loading = false
                self.Error.handle(error)
                
                DispatchQueue.main.asyncAfter(deadline: .now()+0.2){
                    self.verificationScreen = false
                }
            }
        }
    }
}

/**Getters**/
extension ConfirmPaymentView{
    
}

/**Views**/
extension ConfirmPaymentView{
    var accountCard: some View{
        ZStack{
            if (self.account != nil){
                CoreAccountCard(
                    account: self.account
                )
                    .padding(.horizontal, 16)
            }
        }
    }
    
    var standingOrderCard: some View{
        VStack(spacing:16){
            VStack(alignment: .leading, spacing:4){
                HStack(spacing: 8){
                    ZStack{
                        Image("standing")
                    }
                    .frame(width: 20, height: 20)
                    Text("Payment Schedule")
                        .font(.body)
                        .foregroundColor(Color.get(.LightGray))
                    Spacer()
                }
                HStack{
                    Text("Standing Order | \(self.order?.standingOrder?.period.label ?? "–")")
                        .font(.body.bold())
                }
                    .foregroundColor(Color.get(.Text))
            }
            .padding(.horizontal, 16)
            
            VStack(alignment: .leading, spacing:4){
                HStack(spacing: 8){
                    ZStack{
                        Image("standing")
                    }
                    .frame(width: 20, height: 20)
                    Text("Billing Interval")
                        .font(.body)
                        .foregroundColor(Color.get(.LightGray))
                    Spacer()
                }
                if (self.order?.standingOrder != nil && self.order?.standingOrder?.startDate.asDate() != nil){
                    HStack{
                        Text("Billed  \(self.order!.standingOrder!.period.frequency(self.order!.standingOrder!.startDate.asDate()!))")
                            .font(.body.bold())
                    }
                    .foregroundColor(Color.get(.Text))
                }
            }
            .padding(.horizontal, 16)
            
            HStack(spacing: 16){
                VStack(alignment: .leading, spacing:4){
                    HStack(spacing: 8){
                        Text("Start Date")
                            .font(.body)
                            .foregroundColor(Color.get(.LightGray))
                        Spacer()
                    }
                    HStack{
                        Text((self.order?.standingOrder?.startDate.asDate() ?? Date()).asString("dd MMM yyyy"))
                            .font(.body.bold())
                    }
                        .foregroundColor(Color.get(.Text))
                }
                if (self.order?.standingOrder?.endDate != nil){
                    VStack(alignment: .leading, spacing:4){
                        HStack(spacing: 8){
                            Text("End Date")
                                .font(.body)
                                .foregroundColor(Color.get(.LightGray))
                            Spacer()
                        }
                        HStack{
                            Text((self.order?.standingOrder?.endDate?.asDate() ?? Date()).asString("dd MMM yyyy"))
                                .font(.body.bold())
                        }
                        .foregroundColor(Color.get(.Text))
                    }
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 16)
        .background(Color.get(.Section))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
    }
    
    var approvalDeadline: some View{
        VStack(spacing:16){
            VStack(alignment: .leading, spacing:4){
                Text("Approval Deadline: This standing order must be approved before the first payment date; otherwise, it will be automatically cancelled, and no payments will be processed. For organizations with a single director, approval will be applied automatically.")
                    .font(.subheadline)
                    .foregroundColor(Color.get(.Danger))
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 16)
        .background(Color.get(.Section))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
    }
}

struct ConfirmPaymentView: View, RouterPage {
    @EnvironmentObject var Store: ApplicationStore
    @EnvironmentObject var Error: ErrorHandlingService
    @EnvironmentObject var Router: RoutingController
    
    @State public var order: PaymentsService.PaymentOrderModel? = nil
    @State public var customer: CoreCustomer
    @State public var account: CoreAccount
    @State public var payee: Contact
    
    @State private var amount: String = ""
    @State private var reference: String = ""
    @State private var loading: Bool = false
    
    @State private var code: String = ""
    @State private var retry: Int = 0
    @State private var verificationScreen: Bool = false
    @State private var paid: Bool = false
    
    //OTP
    @State private var verifyOtp: Bool = false
    @State private var otpOperationId: String = ""
    
    //Attachments
    @Binding public var attachments: Array<FileAttachment>
    
    //Callback
    @State public var callback: RouterPageCallback? = nil
    
    let service: pin = pin()
    
    private var orderAmount: Array<Substring> {
        return self.Store.payment.amount.formatAsPrice(self.account.baseCurrencyCode?.uppercased() ?? "").split(separator: ".")
    }
    private var orderFee: Array<Substring> {
        return self.Store.payment.totalPrice.formatAsPrice(self.account.baseCurrencyCode?.uppercased() ?? "").split(separator: ".")
    }
    private var orderTotal: Array<Substring> {
        return self.Store.payment.totalAmount.formatAsPrice(self.account.baseCurrencyCode?.uppercased() ?? "").split(separator: ".")
    }
    
    var body: some View {
        ApplicationNavigatorContainerView{
            GeometryReader{ geometry in
                ZStack{
                    ScrollView{
                        VStack(spacing: 0){
                            Header(back:{
                                self.Router.stack.removeLast()
                                self.Router.goTo(
                                    CreatePaymentView(
                                        customer: self.customer,
                                        account: self.account,
                                        payee: self.payee,
                                        fetch: self.callback,
                                        attachments: self.attachments
                                    ),
                                    routingType: .backward
                                )
                            }, title: "Confirm Payment")
                                .padding(.bottom, 16)
                            
                            self.accountCard
                                .padding(.bottom, 12)
                            
                            if (self.order?.standingOrder != nil){
                                self.standingOrderCard
                            }
                            
                            VStack(spacing:16){
                                VStack(alignment: .leading, spacing:4){
                                    Text("Amount")
                                        .font(.body)
                                        .foregroundColor(Color.get(.LightGray))
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    HStack{
                                        Text("\(self.orderAmount[0]).")
                                            .font(.body.bold())
                                        + Text(self.orderAmount[1])
                                            .font(.caption)
                                        Spacer()
                                    }
                                        .foregroundColor(Color.get(.Text))
                                }
                                .padding(.horizontal, 16)
                                VStack(alignment: .leading, spacing:4){
                                    Text("Fee")
                                        .font(.body)
                                        .foregroundColor(Color.get(.LightGray))
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    HStack{
                                        Text("\(self.orderFee[0]).")
                                            .font(.body.bold())
                                        + Text(self.orderFee[1])
                                            .font(.caption)
                                        Spacer()
                                    }
                                        .foregroundColor(Color.get(.Text))
                                }
                                .padding(.horizontal, 16)
                                Divider()
                                    .overlay(Color.get(.LightGray))
                                VStack(alignment: .leading, spacing:4){
                                    Text("Total amount")
                                        .font(.body)
                                        .foregroundColor(Color.get(.LightGray))
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    HStack{
                                        Text("\(self.orderTotal[0]).")
                                            .font(.title2.bold())
                                        + Text(self.orderTotal[1])
                                            .font(.subheadline)
                                        Spacer()
                                    }
                                        .foregroundColor(Color.get(.Text))
                                }
                                .padding(.horizontal, 16)
                            }
                            .padding(.vertical, 16)
                            .background(Color.get(.Section))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .padding(.horizontal, 16)
                            .padding(.bottom, 12)
                            
                            VStack(spacing:16){
                                VStack(alignment: .leading, spacing:4){
                                    Text("Recipient")
                                        .font(.body)
                                        .foregroundColor(Color.get(.LightGray))
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    if (self.payee != nil){
                                        ContactCard(
                                            style: .initial,
                                            contact: self.payee
                                        )
                                    }
                                }
                                .padding(.horizontal, 16)
                                 
                                VStack(alignment: .leading, spacing:4){
                                    Text("Reference")
                                        .font(.body)
                                        .foregroundColor(Color.get(.LightGray))
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    Text(self.Store.payment.reference)
                                        .font(.body.bold())
                                        .foregroundColor(Color.get(.Text))
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .multilineTextAlignment(.leading)
                                        .lineLimit(6)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .padding(.horizontal, 16)
                            }
                            .padding(.vertical, 16)
                            .background(Color.get(.Section))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .padding(.horizontal, 16)
                            .padding(.bottom, 12)
                            
                            if (self.order?.standingOrder != nil && self.customer.type?.lowercased() == "business"){
                                self.approvalDeadline
                            }
                            
                            Button("Edit Information"){
                                self.Router.stack.removeLast()
                                self.Router.goTo(
                                    CreatePaymentView(
                                        customer: self.customer,
                                        account: self.account,
                                        payee: self.payee,
                                        fetch: self.callback,
                                        attachments: self.attachments
                                    ),
                                    routingType: .backward
                                )
                            }
                                .padding(.horizontal, 16)
                                .foregroundColor(Whitelabel.Color(.Primary))
                                .padding(.bottom, 16)
                            
                            Spacer()
                            
                            Button{
                                Task{
                                    do{
                                        try await pay()
                                    }catch let error{
                                        self.loading = false
                                        self.Error.handle(error)
                                    }
                                }
                            } label: {
                                HStack{
                                    Spacer()
                                    Text("Pay")
                                    Spacer()
                                }
                            }
                            .padding(.horizontal, 16)
                            .buttonStyle(.primary())
                            .loader(self.$loading)
                            
                            BottomSheetContainer(isPresented: self.$verificationScreen){
                                Group{
                                    Text("Confirm your payment")
                                        .font(.title2.bold())
                                        .foregroundColor(Color.get(.Text, scheme: .light))
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.bottom,15)
                                    
                                    PassCode(passcode: self.$code, onEnter: { code in
                                        Task{
                                            do{
                                                if self.service.verify(code){
                                                    self.code = ""
                                                    self.verificationScreen = false
                                                    
                                                    self.process()
                                                }else{
                                                    self.retry += 1
                                                    
                                                    if self.retry >= 4{
                                                        self.code = ""
                                                        
                                                        self.loading = true
                                                        try await self.Store.logout()
                                                        self.loading = false
                                                        self.Router.home()
                                                        return;
                                                    }
                                                    self.code = ""
                                                    
                                                    throw ApplicationError(title: "", message: "Wrong pin! You have \(4 - self.retry) attempts")
                                                }
                                            }catch(let error){
                                                self.loading = false
                                                DispatchQueue.main.asyncAfter(deadline: .now()+0.2){
                                                    self.Error.handle(error)
                                                }
                                            }
                                        }
                                    }, scheme: .light)
                                }
                                .padding(20)
                                .padding(.top,10)
                            }
                        }
                        .frame(
                            maxWidth: .infinity,
                            minHeight: geometry.size.height - geometry.safeAreaInsets.bottom
                        )
                    }
                    
                    //MARK: - Popups
                    PresentationSheet(isPresented: self.$paid){
                        VStack{
                            Image("payment")
                            VStack(alignment: .center, spacing: 10){
                                Text("Your payment is being processed.")
                                    .font(.title.bold())
                                    .foregroundColor(Color.get(.Text))
                                Text("Thank you for choosing us.")
                                    .font(.caption)
                                    .foregroundColor(Color.get(.LightGray))
                            }
                            .padding(.bottom,20)
                            Button{
                                self.paid = false
                                self.Router.goTo(AccountMainView(
                                    account: self.account
                                ), routingType: .backward)
                            } label:{
                                HStack{
                                    Spacer()
                                    Text("OK")
                                    Spacer()
                                }
                            }
                            .buttonStyle(.primary())
                        }
                        .padding(20)
                        .padding(.top,10)
                        .padding(.bottom, geometry.safeAreaInsets.bottom)
                    }
                    
                    if (self.verifyOtp){
                        OTPView(operationId: self.$otpOperationId, onVerify: self.otpConfirmed, onCancel: self.otpRejected)
                            .environmentObject(self.Error)
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationTitle("")
        .background(Color.get(.Background))
    }
}
