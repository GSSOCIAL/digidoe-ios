//
//  ConfirmOperation.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 04.04.2024.
//

import Foundation
import SwiftUI
import UIKit
import Combine

struct ConfirmOperation: View {
    @EnvironmentObject var Store: ApplicationStore
    @EnvironmentObject var Error: ErrorHandlingService
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    @State public var notification: PushNotification? = nil
    
    @State private var loading: Bool = false
    @State private var scrollOffset : Double = 0
    
    @State public var onClose: () -> Void = {}
    
    @State private var showOperationState: Bool = false
    @State private var operationState: ProfileService.ConfirmationState? = nil
    
    // MARK: - Methods
    /// Reject action
    func rejectOperation() async throws{
        self.loading = false
        Task{
            do{
                guard let operationId = self.notification?.operationId else{
                    throw ApplicationError(title: "", message: "Operation not defined. Please try again")
                }
                guard let sessionId = self.notification?.sessionId else{
                    throw ApplicationError(title: "", message: "Session not defined. Please try again")
                }
                guard let code = self.notification?.code else{
                    throw ApplicationError(title: "", message: "Code not defined. Please try again")
                }
                
                //Reject operation
                let response = try await services.profiles.sessionReject(operationId: operationId, sessionId: sessionId, code: code)
                
                self.loading = false
                self.onClose()
                //self.presentationMode.wrappedValue.dismiss()
            }catch(let error){
                self.loading = false
                self.onClose()
               // self.presentationMode.wrappedValue.dismiss()
            }
        }
    }
    
    /// Approve action
    func approveOperation() async throws{
        self.loading = true
        
        guard let operationId = self.notification?.operationId else{
            throw ApplicationError(title: "", message: "Operation not defined. Please try again")
        }
        guard let sessionId = self.notification?.sessionId else{
            throw ApplicationError(title: "", message: "Session not defined. Please try again")
        }
        guard let code = self.notification?.code else{
            throw ApplicationError(title: "", message: "Code not defined. Please try again")
        }
        //Check for operation type
        let response = try await services.profiles.sessionConfirm(operationId: operationId, sessionId: sessionId, code: code)
        
        if (response.value.state == .Confirmed){
            self.loading = false
            //self.presentationMode.wrappedValue.dismiss()
            self.onClose()
        }else{
            //Show error
        }
        self.loading = false
    }
    
    func verifySession() async throws{
        self.loading = true
        
        guard let operationId = self.notification?.operationId else{
            throw ApplicationError(title: "", message: "Operation not defined. Please try again")
        }
        guard let sessionId = self.notification?.sessionId else{
            throw ApplicationError(title: "", message: "Session not defined. Please try again")
        }
        
        let response = try await services.profiles.sessionStatus(operationId: operationId, sessionId: sessionId)
        
        self.loading = false
        
        if (response.value != .Pending){
            self.operationState = response.value
            self.showOperationState = true
        }
    }
    
    private var operationStateTitle: String{
        switch(self.operationState){
        case .Confirmed:
            return "Operation already approved"
        case .Rejected:
            return "Operation already rejected"
        default:
            return "Operation expired"
        }
    }
    
    private var operationStateDescription: String{
        switch(self.operationState){
        case .Confirmed, .Rejected:
            return "This operation has been completed and requires no further action."
        default:
            return "The operation time has expired. Please initiate the operation again."
        }
    }
    
    //MARK: - Body
    var body: some View {
        ApplicationNavigatorContainerView{
            GeometryReader{ geometry in
                ZStack{
                    ScrollView{
                        VStack(spacing: 0){
                            VStack(spacing: 0){
                                Header(back:{
                                    Task{
                                        do{
                                            try await self.rejectOperation()
                                        }catch(let error){
                                            self.loading = false
                                            self.Error.handle(error)
                                        }
                                    }
                                }, title: "Notification")
                            }
                            .padding(.bottom, 16)
                            .offset(
                                y: self.scrollOffset < 0 ? self.scrollOffset : 0
                            )
                            //MARK: Body
                            VStack(spacing:12){
                                Text(self.notification?.label ?? "")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .multilineTextAlignment(.leading)
                                    .font(.title2.bold())
                                    .foregroundColor(Color.get(.MiddleGray))
                                    .padding(.horizontal, 16)
                                if (self.notification != nil){
                                    VStack(spacing:12){
                                        if (self.notification?.type == .CreateOrder && ((self.notification! as? CreateOrderNotification) != nil)){
                                            HStack(alignment: .top, spacing:16){
                                                Text("Remitter account")
                                                    .frame(maxWidth: .infinity, alignment: .leading)
                                                    .font(.subheadline)
                                                    .foregroundColor(Color.get(.LightGray))
                                                    .multilineTextAlignment(.leading)
                                                HStack{
                                                    if ((self.notification! as! CreateOrderNotification).accountNumber != nil){
                                                        Text((self.notification! as! CreateOrderNotification).accountNumber ?? "")
                                                            .scaledToFill()
                                                            .minimumScaleFactor(0.6)
                                                            .lineLimit(1)
                                                        ZStack{
                                                            
                                                        }
                                                            .frame(width: 6, height: 6)
                                                            .background(Color.get(.MiddleGray))
                                                            .clipShape(Circle())
                                                        Text((self.notification! as! CreateOrderNotification).sortCode ?? "")
                                                            .scaledToFill()
                                                            .minimumScaleFactor(0.6)
                                                            .lineLimit(1)
                                                    }else{
                                                        Text((self.notification! as! CreateOrderNotification).iban ?? "")
                                                            .scaledToFit()
                                                            .minimumScaleFactor(0.6)
                                                            .lineLimit(1)
                                                    }
                                                }
                                                    .frame(maxWidth: .infinity, alignment: .trailing)
                                                    .font(.subheadline.bold())
                                                    .foregroundColor(Color.get(.MiddleGray))
                                                    .multilineTextAlignment(.trailing)
                                            }
                                        }
                                        ForEach(self.notification!.context, id: \.self) { item in
                                            HStack(alignment: .top, spacing:16){
                                                Text(item.label)
                                                    .frame(maxWidth: .infinity, alignment: .leading)
                                                    .font(.subheadline)
                                                    .foregroundColor(Color.get(.LightGray))
                                                    .multilineTextAlignment(.leading)
                                                Text(item.value)
                                                    .frame(maxWidth: .infinity, alignment: .trailing)
                                                    .font(.subheadline.bold())
                                                    .foregroundColor(Color.get(.MiddleGray))
                                                    .multilineTextAlignment(.trailing)
                                            }
                                        }
                                    }
                                    .padding(12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .foregroundColor(Color.get(.Section))
                                    )
                                    .padding(.horizontal, 16)
                                }
                            }
                            Spacer()
                            HStack(spacing: 16){
                                Button{
                                    Task{
                                        do{
                                            try await self.rejectOperation()
                                        }catch(let error){
                                            self.loading = false
                                            self.Error.handle(error)
                                        }
                                    }
                                } label:{
                                    HStack{
                                        Spacer()
                                        Text("Reject")
                                        Spacer()
                                    }
                                }
                                    .buttonStyle(.secondaryDanger())
                                    .disabled(self.loading)
                                
                                Button{
                                    Task{
                                        do{
                                            try await self.approveOperation()
                                        }catch(let error){
                                            self.loading = false
                                            self.Error.handle(error)
                                        }
                                    }
                                } label:{
                                    HStack{
                                        Spacer()
                                        Text("Approve")
                                        Spacer()
                                    }
                                }
                                    .buttonStyle(.secondaryActive())
                                    .disabled(self.loading)
                            }
                            .padding(.horizontal, 16)
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
                    
                    //MARK: Popup
                    if (self.showOperationState){
                        PresentationSheet(isPresented: self.$showOperationState){
                            VStack(spacing:24){
                                ZStack{
                                    Image("danger")
                                }
                                .frame(width: 80, height: 80)
                                VStack(spacing: 6){
                                    Text(self.operationStateTitle)
                                        .font(.body.bold())
                                        .foregroundColor(Color.get(.Text))
                                    Text(self.operationStateDescription)
                                        .multilineTextAlignment(.center)
                                        .font(.caption)
                                        .foregroundColor(Color.get(.LightGray))
                                }
                                HStack(spacing: 16){
                                    Button{
                                        self.onClose()
                                    } label:{
                                        HStack{
                                            Spacer()
                                            Text("Ok")
                                            Spacer()
                                        }
                                    }
                                    .buttonStyle(.secondary())
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
        .background(Color.get(.Background))
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to:nil, from:nil, for:nil)
        }
        .onAppear{
            Task{
                do{
                    try await self.verifySession()
                }catch(let error){
                    self.operationState = .Timeout
                    self.showOperationState = true
                }
            }
        }
    }
}

struct ConfirmOperationViewParent: View{
    @EnvironmentObject var Store: ApplicationStore
    @EnvironmentObject var Error: ErrorHandlingService
    
    var notification: PushNotification{
        return CreateOrderNotification( dictionary: [
            "gcm.message_id": "1712210607757674",
            "operationData_debtor_account.identification.sort_code": "040639",
            "type": "OperationConfirmationRequest",
            "data_userAgent": "DigiDoe%20Business%20Banking/2024032701 CFNetwork/1474 Darwin/23.3.0",
            "data_operationName": "Payment order for 1 GBP",
            "google.c.a.e": "1",
            "google.c.fid": "foVONWb870Z1nJKeALJA9V",
            "google.c.sender.id": "503284485344",
            "data_middleName": "Alekseevich",
            "operationData_created_utc": "04/04/2024 05:52:42 +00:00",
            "operationData_amount_value": "1",
            "operationData_reference": "Payment to Aleksandr Shmidt",
            "data_ipAddress": "20.254.80.146",
            "operationData_id": "ac7adc48-0336-4e28-ba86-b6be12fde3aa",
            "operation_type": "CreateOrder",
            "data_requestTimeStamp": "2024-04-04T06:03:26.2431002\\u002B00:00",
            "data_firstName": "Vitalii",
            "data_lastName": "Kolosov",
            "operation_id": "0642faa4-340c-4307-a822-f2c665195ada",
            "session_id": "72d3eb60-fd61-42b0-8845-a644b5b0d419",
            "operationData_amount_currency_code": "GBP",
            "id": "76f47a93-f23a-46ba-aa83-aac1724d752c",
            "operationData_payee_contact.account_holder_name": "Aleksandr Shmidt",
            "operationData_debtor_account.identification.account_number": "00003381090909",
            "data_displayName": "Vitalii Kolosov",
            "code": "204357",
            "operationData_debtor_account.identification.iban":"GB28DIGD04063900003381"
        ])
        return UserSignInNotification(dictionary: [
            "data_firstName": "Vitalii",
            "data_lastName": "Kolosov",
            "data_displayName": "Vitalii Kolosov",
            "data_ipAddress": "20.254.80.146",
            "data_operationName": "Login",
            "data_requestTimeStamp": "2024-04-04T06:03:26.2431002\\u002B00:00",
            "data_middleName": "Alekseevich",
            "data_userAgent": "DigiDoe%20Business%20Banking/2024032701 CFNetwork/1474 Darwin/23.3.0",
            "operation_id": "0642faa4-340c-4307-a822-f2c665195ada",
            "session_id": "72d3eb60-fd61-42b0-8845-a644b5b0d419",
            "id": "76f47a93-f23a-46ba-aa83-aac1724d752c",
            "gcm.message_id": "1712210607757674",
            "google.c.a.e": "1",
            "google.c.fid": "foVONWb870Z1nJKeALJA9V",
            "google.c.sender.id": "503284485344",
            "type": "OperationConfirmationRequest",
            "operation_type": "UserSignIn",
            "code": "267962"
        ])
    }
    
    var body: some View{
        ConfirmOperation(notification: self.notification)
            .environmentObject(self.Error)
    }
}

struct ConfirmOperationView_Previews: PreviewProvider {
    static var store: ApplicationStore {
        var store = ApplicationStore()
        return store
    }
    
    static var error: ErrorHandlingService {
        var error = ErrorHandlingService()
        return error
    }
    
    static var previews: some View {
        ConfirmOperationViewParent()
            .environmentObject(self.store)
            .environmentObject(self.error)
    }
}
