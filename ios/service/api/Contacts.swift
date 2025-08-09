//
//  Contacts.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 02.01.2024.
//

import Foundation

class ContactsService: BaseHttpService{
    override var base:String! { Enviroment.apiBase }
    
    public struct GetCustomersResponse: Codable{
        public var data: Array<Contact> = []
        public var pageNumber: Int
        public var pageSize: Int
        public var total: Int
    }
    
    public struct InitiateOperationResponse: Codable{
        public var operationId: String
        public var copNameMatch: String?
        public var copResponseCode: String?
    }
    
    func getCustomerContacts(_ customerId: String, page: Int = 1, size: Int = 50, currency: String? = nil, query: String? = nil) async throws -> ContactsService.GetCustomersResponse{
        do{
            #if DEBUG
            
            #endif
            let response = try await self.client.get("contacts/customers/\(customerId)/contacts?pageNumber=\(page)&pageSize=\(size)&name=\(query ?? "")&currency=\(currency ?? "")")
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
            return try JSONDecoder().decode(ContactsService.GetCustomersResponse.self,from:response.response)
        }catch let error{
            throw(error)
        }
    }
    
    func createCustomerContact(_ customerId:String, contact: Contact) async throws -> Contact{
        do{
            let response = try await self.client.post("contacts/customers/\(customerId)/contacts", body: contact)
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
            
            return try JSONDecoder().decode(Contact.self,from:response.response)
        }catch let error{
            throw(error)
        }
    }
    
    func initiateCreateCustomerContact(_ customerId: String, contact: Contact) async throws -> InitiateOperationResponse{
        do{
            let response = try await self.client.post("contacts/customers/\(customerId)/contacts/initiate", body: contact)
            
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
            
            return try JSONDecoder().decode(InitiateOperationResponse.self,from:response.response)
        }catch(let error){
            throw error
        }
    }
    
    func finalizeContactOperation(_ customerId: String, operationId: String, sessionId: String, confirmationType: ProfileService.ConfirmationType? = .OtpEmail) async throws -> Bool{
        let response = try await self.client.post("contacts/customers/\(customerId)/contacts/confirmation/finalize", body: [
            "operationId": operationId,
            "sessionId": sessionId,
            "type": confirmationType != nil ? confirmationType!.rawValue : ""
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
    
    func deleteCustomerContacts(_ customerId: String, contactId: String) async throws{
        do{
            #if DEBUG
            
            #endif
            let response = try await self.client.delete("contacts/customers/\(customerId)/contacts/\(contactId)")
            
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
            
        }catch let error{
            throw(error)
        }
    }
    
    func initiateDeleteCustomerContacts(_ customerId: String, contactId: String) async throws -> InitiateOperationResponse{
        let response = try await self.client.delete("contacts/customers/\(customerId)/contacts/\(contactId)/initiate")
        
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
        
        return try JSONDecoder().decode(InitiateOperationResponse.self,from:response.response)
    }
}
