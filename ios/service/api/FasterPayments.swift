//
//  FasterPayments.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 26.02.2024.
//

import Foundation
class FasterPaymentsService:BaseHttpService{
    override var base:String! { Enviroment.apiBase }
    
    struct DirectDebitMandatesList: Codable{
        public var mandates: Array<DirectDebitMandate>
        public var lastPage: Bool
        public var page: Int
        public var pageSize: Int
    }
    
    func getMandates(customerId: String, accountId: String) async throws -> DirectDebitMandatesList{
        do{
            let response = try await self.client.get("faster-payments/customers/\(customerId)/accounts/\(accountId)/direct-debit-mandates")
            
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
            
            return try JSONDecoder().decode(DirectDebitMandatesList.self,from:response.response)
        }catch let error{
            throw(error)
        }
    }
    
    func cancelMandates(customerId: String, accountId: String, mandateId: String) async throws -> Bool{
        do{
            let response = try await self.client.delete("faster-payments/customers/\(customerId)/accounts/\(accountId)/direct-debit-mandates/\(mandateId)")
            
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
            
            if (response.statusCode == 204){
                return true
            }
            return false
        }catch let error{
            throw(error)
        }
    }
}

