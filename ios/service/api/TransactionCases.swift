//
//  TransactionCases.swift
//  DigiDoe Business Banking
//
//  Created by Михайло Картмазов on 23.01.2025.
//
import Foundation

class TransactionCasesService: BaseHttpService{
    override var base:String! { Enviroment.apiBase }
    
    enum documentType: String,Codable{
        case noteDocument
        case RequestInfoDocument
    }
    
    public struct UploadAttachmentResponse: Codable{
        public var value: UploadAttachmentResponseValue
        
        struct UploadAttachmentResponseValue: Codable{
            var blobId: String
            var externalFileName: String
            var id: String
            var mimeType: String
            var userId: String
            /*
             var userName: String
             var updatedUtc: String
             var createdUtc: String
             var description: String
             var informationRequestId: String
             var isPublic: Bool
             var state: String
             var noteId: String
             */
        }
    }
    
    func fileUpload(_ attachment:FileAttachment,customerId: String, documentType: documentType) async throws -> UploadAttachmentResponse{
        do{
            var body = Multipart()
            
            body.fields.append(.init(key: "documentType", value: documentType.rawValue))
            body.fields.append(.init(key: "file", value: attachment.data, filename: attachment.fileName!, fileType: attachment.fileType!))
            
            let response = try await self.client.post("transaction-case/customers/\(customerId)/file/upload", body: body)
            
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
            return try JSONDecoder().decode(UploadAttachmentResponse.self, from: response.response)
        }catch let error{
            throw(error)
        }
    }
    
    func fileDelete(customerId: String, documentId: String) async throws -> Bool{
        let response = try await self.client.delete("transaction-case/customers/\(customerId)/file/\(documentId)")
        
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
    
    func addNotes(customerId: String, transactionId: String, documentIds: Array<String>) async throws{
        do{
            let body: [String:Any] = [
                "documentIds": documentIds
            ]
            let response = try await self.client.post("transaction-case/customers/\(customerId)/notes/\(transactionId)", body: try JSONSerialization.data(withJSONObject: body, options: .prettyPrinted))
            
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
            
            return;
        }catch let error{
            throw(error)
        }
    }
}

extension TransactionCasesService{
    struct NoteDocument: Codable, Identifiable{
        var blobId: String
        var description: String
        var externalFileName: String
        var id: String
        var noteId: String?
        var mimeType: String
    }
    
    struct GetTransactionNotesResponse: Codable{
        var value: Array<NoteDocument> = []
    }
    
    func getDocuments(customerId: String, transactionId: String) async throws -> GetTransactionNotesResponse{
        do{
            let response = try await self.client.get("transaction-case/customers/\(customerId)/notes/documents/?transactionId=\(transactionId)")
            
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
            
            return try JSONDecoder().decode(GetTransactionNotesResponse.self,from: response.response)
        }catch let error{
            throw(error)
        }
    }
    
    func getDocument(customerId: String, documentId: String) async throws -> Data{
        let response = try await self.client.get("transaction-case/customers/\(customerId)/file/\(documentId)")
        
        if (response.statusCode == 200){
            return response.response
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
        
        throw ApplicationError(title: "Unable to download document", message: "")
    }
}
