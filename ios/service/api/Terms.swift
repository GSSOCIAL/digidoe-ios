//
//  Terms.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 10.01.2024.
//

import Foundation

class TermsService:BaseHttpService{
    override var base:String! { Enviroment.apiBase }
    
    public struct TermsConditionsResponse: Codable{
        public var Id: String
        public var CreatedAt: String
        public var Version: Int
        public var `Type`: Int
        public var EffectiveDate: String
        public var Language: Int
        public var Body: String
        
        func decodeContent() async throws -> Array<Node>{
            var body: String = self.Body
            //MARK: Replace quotes
            body = body.replacingOccurrences(of:"'", with: "\"")
            return try JSONDecoder().decode(Array<Node>.self,from: body.data(using: .utf8)!)
        }
        
        public struct Node: Codable{
            public var tag: String
            public var content: String
            
            enum TagType: String,Codable{
                case text
                case heading
            }
        }
    }
    
    func getTermsConditions() async throws -> TermsConditionsResponse{
        do{
            #if DEBUG
            if Enviroment.useMockData == true{
                if let path = Bundle.main.path(forResource: "termsConditions", ofType: "json"){
                    let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                    return try JSONDecoder().decode(TermsConditionsResponse.self,from:data)
                }
            }
            #endif
            let response = try await self.client.get("policies?language=en&type=termsAndConditions&tenant=\(Whitelabel.Tenant())")
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
            
            return try JSONDecoder().decode(TermsConditionsResponse.self,from:response.response)
        }catch let error{
            throw(error)
        }
    }
    
    func getPrivacyPolicy() async throws -> TermsConditionsResponse{
        do{
            #if DEBUG
            if Enviroment.useMockData == true{
                if let path = Bundle.main.path(forResource: "privacy", ofType: "json"){
                    let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                    return try JSONDecoder().decode(TermsConditionsResponse.self,from:data)
                }
            }
            #endif
            let response = try await self.client.get("policies?language=en&type=privacy&tenant=\(Whitelabel.Tenant())")
            
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
            
            return try JSONDecoder().decode(TermsConditionsResponse.self,from:response.response)
        }catch let error{
            throw(error)
        }
    }
}

