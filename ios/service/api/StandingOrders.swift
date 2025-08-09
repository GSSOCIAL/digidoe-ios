//
//  StandingOrders.swift
//  DigiDoe Business Banking
//
//  Created by Михайло Картмазов on 29.06.2025.
//
import Foundation

class StandingOrdersService: BaseHttpService{
    override var base:String! { Enviroment.apiBase }
}

//MARK: - Models
extension StandingOrdersService{
    struct PaymentOrderExtendedDtoPaginationResponse: Codable{
        var value: PaymentOrderExtendedDtoPaginationResponseValue
        
        struct PaymentOrderExtendedDtoPaginationResponseValue: Codable{
            var data: Array<PaymentOrderExtendedDto>?
            var pageNumber: Int
            var pageSize: Int
            var total: Int
        }
    }
}

//MARK: - Methods
extension StandingOrdersService{
    func getList(_ customerId: String, accountId: String, state: StandingOrderDto.StandingOrderState?, pageNumber: Int = 1, pageSize: Int = 50) async throws -> PaymentOrderExtendedDtoPaginationResponse{
        let state = state?.rawValue ?? ""
        let response = try await self.client.get("api/core/customers/\(customerId)/standing-orders?accountId=\(accountId)&state=\(state)&pageNumber=\(pageNumber)&pageSize=\(pageSize)")
        
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
        return try JSONDecoder().decode(PaymentOrderExtendedDtoPaginationResponse.self,from:response.response)
    }
    
    func cancelOrder(customerId:String, orderId: String) async throws -> Bool{
        let response = try await self.client.delete("api/core/customers/\(customerId)/standing-orders/\(orderId)")
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
        return response.statusCode == 200
    }
    func updateOrder(customerId:String, orderId: String, description: String) async throws -> Bool{
        var body = [
            "description": description
        ]
        let response = try await self.client.patch("api/core/customers/\(customerId)/standing-orders/\(orderId)?description=\(description)", body: body)
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
        return response.statusCode == 200
    }
}
