//
//  Forex.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 19.09.2024.
//

import Foundation

class ForexService: BaseHttpService{
    override var base:String! { Enviroment.apiBase }
}

extension ForexService{
    struct CreateForexOrderRequest: Codable{
        var sourceAccountId: String
        var targetAccountId: String
        var sourceAmount: Double
        var targetAmount: Double
        var orderId: String
    }
    struct ForexOrderModel: Codable{
        var value: ForexOrderModelValue
        
        struct ForexOrderModelValue: Codable{
            var id: String
            var sourceAccountId: String
            var targetAccountId: String
            var sourceAmount: Amount? = nil
            var targetAmount: Amount? = nil
            var state: ForexOrderModelState
            var totalRate: Double
            var reason: String? = nil
            var expiresUtc: String
            var createdUtc: String
            var secondsToExpire: Int
        }
        struct Amount: Codable{
            var currencyCode: String
            var value: Double
        }
        enum ForexOrderModelState: String, Codable{
            case new
            case rateExpired
            case pending
            case booked
            case processing
            case completed
            case failed
        }
    }
    
    func initiate(_ customerId: String, body: CreateForexOrderRequest) async throws -> ForexOrderModel{
        let response = try await self.client.post("api/core/customers/\(customerId)/forex/initiate", body: body)
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
        
        return try JSONDecoder().decode(ForexOrderModel.self,from:response.response)
    }
}

extension ForexService{
    func confirm(_ customerId: String, orderId: String) async throws -> Bool{
        let response = try await self.client.post("api/core/customers/\(customerId)/forex/\(orderId)/confirm")
        if (response.statusCode == 200){
            return true
        }
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
        return false
    }
}
