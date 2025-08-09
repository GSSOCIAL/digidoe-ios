//
//  Transactions.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 02.10.2023.
//

import Foundation

struct TransactionResponse:Decodable{
    var total:Int
    var transactions: [Transaction]
}

//MARK: - Models
extension TransactionsService{
    
}

//MARK: - Methods
extension TransactionsService{
    func getStandingOrderTransactions(customerId: String, accountId: String, orderId: String,page:Int=1,pageSize:Int=50) async throws -> GetTransactionsResponse{
        let response = try await self.client.get("api/core/customers/\(customerId)/accounts/\(accountId)/transactions?orderId=\(orderId)")
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
        
        return try JSONDecoder().decode(GetTransactionsResponse.self, from: response.response)
    }
}

class TransactionsService:BaseHttpService{
    override var base:String! { Enviroment.apiBase }
    
    public struct GetTransactionsResponse: Codable{
        public var value: GetTransactionsResponseDetails
        
        public struct GetTransactionsResponseDetails: Codable{
            public var data: Array<Transaction> = []
            public var pageNumber: Int
            public var pageSize: Int
            public var total: Int
        }
    }
    
    func getAccountTransactions(_ customerId: String, accountId: String,from:Date?,to:Date?,page:Int=1,pageSize:Int=50) async throws -> GetTransactionsResponse{
        do{
            #if DEBUG
            if Enviroment.useMockData == true{
                var resource = "transactions"
                if (from != nil){
                    resource = "transactions1"
                }
                if let path = Bundle.main.path(forResource: resource, ofType: "json"){
                    let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                    return try JSONDecoder().decode(GetTransactionsResponse.self,from:data)
                }
            }
            #endif
            let response = try await self.client.get("api/core/customers/\(customerId)/accounts/\(accountId)/transactions?pageNumber=\(page)&pageSize=\(pageSize)&startDateTime=\(from!.asStringDate())&endDateTime=\(to!.asStringDate())")
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
            
            return try JSONDecoder().decode(GetTransactionsResponse.self, from: response.response)
        }catch let error{
            throw(error)
        }
    }
    
    func getTransaction(_ customerId: String, accountId: String, transactionId: String) async throws -> CustomerTransactionModelResult{
        if Enviroment.isPreview{
            let path = Bundle.main.path(forResource: "transaction", ofType: "json")
            let response = try Data(contentsOf: URL(fileURLWithPath: path!), options: .mappedIfSafe)
            return try JSONDecoder().decode(CustomerTransactionModelResult.self, from: response)
        }
        let response = try await self.client.get("api/core/customers/\(customerId)/accounts/\(accountId)/transactions/\(transactionId)")
        
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
        return try JSONDecoder().decode(CustomerTransactionModelResult.self, from: response.response)
    }
    
    func getTransactionReport(_ customerId: String, accountId: String, transactionId: String) async throws -> Data{
        let response = try await self.client.get("api/core/customers/\(customerId)/accounts/\(accountId)/transactions/\(transactionId)/export")
        
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
        
        return response.response
    }
    
    struct PopupEventRequest: Codable{
        public var `Type` = "TransactionSettled"
        public var Version: Int = 6
        public var Payload: PopupEventRequestPayload = .init()
        public var Nonce: Int = randomId(length: 9)
        
        struct PopupEventRequestPayload: Codable{
            public var TransactionId: String = UUID().uuidString
            public var Status: String = "Settled"
            public var Scheme: String = "Transfer"
            public var EndToEndTransactionId: String = UUID().uuidString
            public var Amount: Int = 600
            public var TimestampSettled: String = "2023-12-16T05:22:11.787Z"
            public var TimestampCreated: String = "2023-12-16T05:22:11.41Z"
            public var CurrencyCode: String = "GBP"
            public var DebitCreditCode: String = "Credit"
            public var Reference: String = "TEST 0001"
            public var IsReturn: Bool = false
            public var ActualEndToEndTransactionId: String = UUID().uuidString
            
            public var Account: PopupEventRequestPayloadAccount = .init()
            public var CounterpartAccount: PopupEventRequestPayloadCounterpartAccount = .init()
            
            struct PopupEventRequestPayloadAccount: Codable{
                public var IBAN: String = "GB80CLRB04063900000026"
                public var BBAN: String = "CLRB04063900000026"
                public var OwnerName: String = "Not Provided"
                public var TransactionOwnerName: String = "DigiDoe"
                public var InstitutionName: String = "DigiDoe"
            }
            
            struct PopupEventRequestPayloadCounterpartAccount: Codable{
                public var IBAN: String = "GB80CLRB04063900000026"
                public var BBAN: String = "CLRB04063900000026"
                public var OwnerName: String = "Not Provided"
                public var TransactionOwnerName: String = "DigiDoe"
                public var InstitutionName: String = "DigiDoe"
            }
        }
    }
    
    public struct CustomerTransactionModelResult: Codable{
        public var value: CustomerTransactionModel
        
        public struct CustomerTransactionModel: Codable{
            var id: String
            var endToEndTransactionId: String
            var createdUtc: String
            var updatedUtc: String?
            var transactionSubType: String?
            var transactionType: TransactionType
            var reference: String?
            var executionDate: String
            var currentState: Transaction.state
            var paymentRails: Transaction.paymentRails
            var paymentScheme: Transaction.paymentScheme?
            var linkedTransactionId: String?
            var number: Int
            var paymentOrder: SimplePaymentOrderModel?
            var metadataId: String?
            var amount: TransactionAmountValue
            var balance: Double
            var feeAmount: TransactionAmountValue?
            var hasAttachments: Bool
            //Sender
            var remitter: TransactionPartyDetailsModel?
            //Receiver
            var beneficiary: TransactionPartyDetailsModel?
            
            public struct TransactionAmountValue: Codable{
                public var currencyCode: String
                public var value: Double
            }
            
            public struct TransactionPartyDetailsModel: Codable{
                public var accountId: String?
                public var accountIdentification: String?
                public var identification: IdentificationDto?
                public var partyDetails: PartyDetailsModel?
                
                public struct PartyDetailsModel: Codable{
                    public var name: String?
                    public var type: PartyDetailsType
                    
                    public enum PartyDetailsType: String, Codable{
                        case person
                        case organisation
                    }
                }
                
                public struct IdentificationDto: Codable{
                    public var accountNumber: String?
                    public var bban: String?
                    public var iban: String?
                    public var sortCode: String?
                    public var swiftCode: String?
                }
            }
            
            public enum TransactionType: String, Codable{
                case system
                case customer
            }
            
            public struct SimplePaymentOrderModel: Codable{
                var id: String
                var state: String
                var purpose: String?
                var standingOrder: CreateStandingOrderRequestModel?
                
                public enum state: String, Codable{
                    case received
                    case pendingApproval
                    case pending
                    case accepted
                    case completed
                    case rejected
                    case cancelled
                }
                
                public enum purpose: String, Codable{
                    case other
                    case migrantTransfers
                    case remittanceForFamily
                    case remittanceTowardsPersonal
                    case education
                    case healthService
                    case businessTravel
                    case travelForPilgrimage
                    case travelForMedicalTreatment
                    case travelForEducation
                    case otherTravel
                }
            }
        }
    }
    
    func popupAccount(_ account: PopupEventRequest.PopupEventRequestPayload.PopupEventRequestPayloadAccount) async throws{
        do{
            #if DEBUG
            var request = PopupEventRequest()
            request.Payload.Account = account
            
            let response = try await self.client.post("faster-payments/events", body: request)
            
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
            
            
            #endif
        }catch let error{
            throw(error)
        }
    }
}
