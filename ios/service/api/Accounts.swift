//
//  Accounts.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 01.10.2023.
//

import Foundation

class AccountsService: BaseHttpService{
    override var base:String! { Enviroment.apiBase }
    
    struct AccountsGetResponse: Codable{
        public var value: AccountsGetResponseValue
        
        struct AccountsGetResponseValue: Codable{
            public var data: Array<Account> = []
            public var pageNumber: Int
            public var pageSize: Int
            public var total: Int
        }
    }
    
    struct AccountGetResponse: Codable{
        public var value: Account?
    }
    
    struct AccountCreateResponse: Codable{
        public var value: String
    }
    
    func getCustomerAccounts(_ customerId:String) async throws -> AccountsGetResponse {
        do{
            #if DEBUG
            if Enviroment.useMockData == true{
                if let path = Bundle.main.path(forResource: "accounts", ofType: "json"){
                    let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                    return try JSONDecoder().decode(AccountsGetResponse.self,from:data)
                }
            }
            #endif
            let response = try await self.client.get("api/core/customers/\(customerId)/accounts")
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
            return try JSONDecoder().decode(AccountsGetResponse.self,from:response.response)
        }catch let error{
            throw(error)
        }
    }
    
    func openCustomerAccount(_ customerId: String, currency: String) async throws -> AccountCreateResponse{
        do{
            let response = try await self.client.post("api/core/customers/\(customerId)/accounts?currency=\(currency)")
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
            return try JSONDecoder().decode(AccountCreateResponse.self,from:response.response)
        }
    }
    
    func getCustomerAccount(_ customerId:String, accountId:String) async throws -> AccountGetResponse {
        do{
            let response = try await self.client.get("api/core/customers/\(customerId)/accounts/\(accountId)")
            
            return try JSONDecoder().decode(AccountGetResponse.self,from:response.response)
        }catch let error{
            throw(error)
        }
    }
    
    func updateAccountTitle(_ customerId: String, accountId: String, title: String) async throws -> Bool{
        do{
            let data = [
                "title":title
            ]
            let response = try await self.client.patch("api/core/customers/\(customerId)/accounts/\(accountId)",body: data)
            
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
            if response.statusCode == 200{
                return true
            }
            throw ServiceError(title: "Unable to update account",message: "Its service error. Try again later")
        }catch let error{
            throw(error)
        }
    }
}

extension AccountsService{
    struct AccountLimitSimpleDtoPaginationResponseResult: Codable{
        public var value: AccountLimitSimpleDtoPaginationResponseResultValue
        
        struct AccountLimitSimpleDtoPaginationResponseResultValue: Codable{
            public var data: Array<AccountLimitSimpleDtoAccountLimitSimpleDto> = []
            public var pageNumber: Int
            public var pageSize: Int
            public var total: Int
        }
        
        struct AccountLimitSimpleDtoAccountLimitSimpleDto: Codable{
            public var id: String
            public var accountId: String
            public var userId: String
            public var userName: String?
            public var userEmail: String?
            public var userPhone: String?
            public var dailyLimit: Double
            public var perTransactionLimit: Double
        }
    }
    
    struct AccountLimitSimpleDtoResponseResult: Codable{
        public var value: AccountLimitSimpleDtoPaginationResponseResult.AccountLimitSimpleDtoAccountLimitSimpleDto
    }
    
    /// Get account limits for a customer's users
    func getAccountLimits(_ customerId:String, accountId:String) async throws -> AccountLimitSimpleDtoPaginationResponseResult {
        let response = try await self.client.get("api/core/customers/\(customerId)/accounts/\(accountId)/limits")
        return try JSONDecoder().decode(AccountLimitSimpleDtoPaginationResponseResult.self,from:response.response)
    }
    /// Update  account limits for a customer's users
    func updateAccountLimits(_ customerId:String, accountId:String, accountLimitId: String, dailyLimit: Double, perTransactionLimit: Double) async throws -> AccountLimitSimpleDtoResponseResult {
        var request = [
            "dailyLimit": dailyLimit,
            "perTransactionLimit": perTransactionLimit
        ]
        let response = try await self.client.patch("api/core/customers/\(customerId)/accounts/\(accountId)/limits/\(accountLimitId)", body: request)
        return try JSONDecoder().decode(AccountLimitSimpleDtoResponseResult.self,from:response.response)
    }
}
