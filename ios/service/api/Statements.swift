//
//  Statements.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 11.01.2024.
//

import Foundation
class StatementsService:BaseHttpService{
    override var base:String! { Enviroment.apiBase }
    
    func getStatement(customerId: String, accountId: String, fileType: String, from: String, to: String) async throws -> Data{
        do{
            let response = try await self.client.get("api/core/customers/\(customerId)/accounts/\(accountId)/reports/statement?fileType=\(fileType)&from=\(from)&to=\(to)")
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
                return response.response
            }
            
            throw ServiceError(title: "Unable to fetch statement", message: "This is server issue. Please try again later")
        }catch let error{
            throw(error)
        }
    }
}

