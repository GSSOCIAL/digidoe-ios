//
//  Payments.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 04.01.2024.
//

import Foundation
import Foundation

//MARK: - Models
extension PaymentsService{
    
}

//MARK: - Methods
class PaymentsService:BaseHttpService{
    override var base:String! { Enviroment.apiBase }
    
    public struct PaymentOrderPriceResponse: Codable{
        public var value: PaymentOrderPriceResponseDetails
        
        public struct PaymentOrderPriceResponseDetails: Codable{
            public var intialAmount: Double
            public var totalAmount: Double
            public var totalPrice: Double
        }
    }
    
    public struct CreateOrderPaymentRequest: Codable{
        public var debtorAccountId: String
        public var payeeContactId: String
        public var paymentRails: CreateOrderRequestRail
        public var paymentScheme: CreateOrderRequestScheme?
        public var amount: CreateOrderRequestAmount
        public var paymentPurpose: String?
        public var paymentPurposeText: String?
        public var reference: String = ""
        public var requestedExecutionDate: String?
        public var endToEndTransactionId: String?
        public var documentIds: Array<String> = []
        public var standingOrder: CreateStandingOrderRequestModel?
        
        public enum CreateOrderRequestRail: String, Codable{
            case fps
            case sepa
            case swift
            case bacs
            case digidoe
        }
        
        public enum CreateOrderRequestScheme: String, Codable{
            case sepaNormal
            case sepaInstant
            case bacsDD
            case chaps
        }
        
        public struct CreateOrderRequestAmount: Codable{
            public var currencyCode: String
            public var value: Decimal
        }
    }
    
    public struct PaymentOrderInitiateResponse: Codable{
        public var value: PaymentOrderModel
    }
    
    public struct PaymentOrderModel: Codable{
        public var id: String
        public var createdBy: String
        public var createdUtc: String
        public var debtorAccountId: String
        public var payeeContactId: String
        public var paymentRails: CreateOrderPaymentRequest.CreateOrderRequestRail
        public var paymentScheme: CreateOrderPaymentRequest.CreateOrderRequestScheme?
        public var amount: CreateOrderPaymentRequest.CreateOrderRequestAmount
        public var currentState: String
        public var paymentPurpose: String?
        public var reference: String = ""
        public var requestedExecutionDate: String?
        public var endToEndTransactionId: String?
        public var fraudAlerts: [String:String] = [:]
        public var copNameMatch: String?
        public var copResponseCode: String?
        public var standingOrder: CreateStandingOrderRequestModel?
        
        public enum copPaymentResponseCode: String, Codable{
            case match
            case aC01
            case mbam
            case bamm
            case pamm
            case maintenance
            case scns
            case cass
            case opto
            case acns
            case ivcr
            case panm
            case banm
            case annm
            case notregistred
            case timeout
            case `internal`
        }
    }

    public struct InitiateOperationResponse: Codable{
        public var value: ContactsService.InitiateOperationResponse
    }
    
    public struct CheckConfirmationOperationStateResponse: Codable{
        var confirmationState: ConfirmationOperationState;
        
        public enum ConfirmationOperationState: String, Codable{
            case pending
            case confirmed
            case rejected
            case timeout
        }
    }
    
    func initiatePayment(_ customerId: String, order: CreateOrderPaymentRequest) async throws -> PaymentOrderInitiateResponse{
        do{
            let response = try await self.client.post("api/core/customers/\(customerId)/payments/initiate", body: order)
            if let error = try? JSONDecoder().decode(KycpService.ServerError.self, from: response.response){
                throw error
            }
            if let error = try? JSONDecoder().decode(KycpService.ApiError.self, from: response.response){
                throw error
            }
            if let error = try? JSONDecoder().decode(KycpServerError.self, from: response.response){
                throw error
            }
            if let error = try? JSONDecoder().decode(KycpService.KycpError.self, from: response.response){
                throw error
            }
            if let error = try? JSONDecoder().decode(KycpService.KycpSimpleError.self, from: response.response){
                throw error
            }
            return try JSONDecoder().decode(PaymentOrderInitiateResponse.self,from:response.response)
        }catch let error{
            throw(error)
        }
    }
    
    func confirmOrder(_ customerId: String, orderId: String) async throws -> PaymentOrderPriceResponse?{
        do{
            let response = try await self.client.post("api/core/customers/\(customerId)/payments/\(orderId)/confirm")
            
            if let error = try? JSONDecoder().decode(KycpService.ApiError.self, from: response.response){
                throw error
            }
            if let error = try? JSONDecoder().decode(KycpServerError.self, from: response.response){
                throw error
            }
            if let error = try? JSONDecoder().decode(KycpService.KycpError.self, from: response.response){
                throw error
            }
            if let error = try? JSONDecoder().decode(KycpService.KycpSimpleError.self, from: response.response){
                throw error
            }
            
            if(response.response.isEmpty){
                return nil
            }
            
            return try JSONDecoder().decode(PaymentOrderPriceResponse.self,from:response.response)
        }catch let error{
            throw(error)
        }
    }
    
    func initiateConfirmOrder(_ customerId: String, orderId: String, alerts: [String:Bool]?) async throws -> PaymentsService.InitiateOperationResponse{
        let response = try await self.client.post("api/core/customers/\(customerId)/payments/\(orderId)/confirm/initiate", body: alerts)
        
        if let error = try? JSONDecoder().decode(KycpService.ApiError.self, from: response.response){
            throw error
        }
        if let error = try? JSONDecoder().decode(KycpServerError.self, from: response.response){
            throw error
        }
        if let error = try? JSONDecoder().decode(KycpService.KycpError.self, from: response.response){
            throw error
        }
        if let error = try? JSONDecoder().decode(KycpService.KycpSimpleError.self, from: response.response){
            throw error
        }
        
        return try JSONDecoder().decode(PaymentsService.InitiateOperationResponse.self,from:response.response)
    }
    
    func finalizeOrder(_ customerId: String, operationId: String, sessionId: String, confirmationType: ProfileService.ConfirmationType? = .OtpEmail) async throws -> Bool{
        
        let response = try await self.client.post("api/core/customers/\(customerId)/payments/confirmation/finalize", body: [
            "operationId": operationId,
            "sessionId": sessionId,
            "type": confirmationType?.rawValue ?? ""
        ])
        
        if (response.statusCode == 200){
            return true
        }
        
        if let error = try? JSONDecoder().decode(KycpService.ApiError.self, from: response.response){
            throw error
        }
        if let error = try? JSONDecoder().decode(KycpServerError.self, from: response.response){
            throw error
        }
        if let error = try? JSONDecoder().decode(KycpService.KycpError.self, from: response.response){
            throw error
        }
        if let error = try? JSONDecoder().decode(KycpService.KycpSimpleError.self, from: response.response){
            throw error
        }
        
        return false
    }
    
    func calculatePrice(_ customerId: String, order: CreateOrderPaymentRequest) async throws -> PaymentOrderPriceResponse{
        do{
            let response = try await self.client.post("api/core/customers/\(customerId)/payments/calculate-price", body: order)
            
            if let error = try? JSONDecoder().decode(KycpService.ApiError.self, from: response.response){
                throw error
            }
            if let error = try? JSONDecoder().decode(KycpServerError.self, from: response.response){
                throw error
            }
            if let error = try? JSONDecoder().decode(KycpService.KycpError.self, from: response.response){
                throw error
            }
            if let error = try? JSONDecoder().decode(KycpService.KycpSimpleError.self, from: response.response){
                throw error
            }
            
            return try JSONDecoder().decode(PaymentOrderPriceResponse.self,from:response.response)
        }catch let error{
            throw(error)
        }
    }
}

extension PaymentsService{
    func getOrderPurposes(_ customerId: String) async throws -> [String:String]{
        do{
            let response = try await self.client.get("api/core/customers/\(customerId)/payments/order-purposes")
            
            if let error = try? JSONDecoder().decode(KycpService.ApiError.self, from: response.response){
                throw error
            }
            
            if let error = try? JSONDecoder().decode(KycpServerError.self, from: response.response){
                throw error
            }
            
            if let error = try? JSONDecoder().decode(KycpService.KycpError.self, from: response.response){
               throw error
            }
            
            if let error = try? JSONDecoder().decode(KycpService.KycpSimpleError.self, from: response.response){
                throw error
            }
            
            return try JSONDecoder().decode([String:String].self,from:response.response)
        }catch let error{
            throw(error)
        }
    }
}
