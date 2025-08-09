//
//  Dictionaries.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 18.11.2024.
//
import Foundation

class DictionariesService: BaseHttpService{
    override var base:String! { Enviroment.apiBase }
}

extension DictionariesService{
    struct ReasonCodeLookupDtoListResult: Codable{
        var value: Array<ReasonCodeLookupDto>
        
        struct ReasonCodeLookupDto: Codable{
            var reasonCode: String?
            var header: String?
            var description: String?
        }
    }
    
    func getCopCodes() async throws -> ReasonCodeLookupDtoListResult{
        let response = try await self.client.get("dictionaries/cop/codes")
        
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
        
        return try JSONDecoder().decode(ReasonCodeLookupDtoListResult.self, from:response.response)
    }
}
