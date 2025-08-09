//
//  Customers.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 02.10.2023.
//

import Foundation

class CustomersService:BaseHttpService{
    enum customerImageType: Int, CaseIterable{
        case avatar = 8
    }
    override var base:String! { Enviroment.apiBase }

    func getCustomer(_ customerId:String) async throws -> Customer{
        do{
            if Enviroment.useMockData == true{
                if let path = Bundle.main.path(forResource: "user", ofType: "json"){
                    let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                    return try JSONDecoder().decode(Customer.self,from:data)
                }
            }
            let response = try await self.client.get("api/customers/\(customerId)/")
            return try JSONDecoder().decode(Customer.self, from: response.response)
        }catch let error{
            throw(error)
        }
    }
    
    func getAvatar(_ customerId: String) async throws -> Data{
        do{
            let response = try await self.client.get("api/customers/\(customerId)/images/avatar")
            return response.response
        }catch let error{
            throw(error)
        }
    }
    
    func uploadImage(_ customerId: String, attachment: FileAttachment, documentTypeId: CustomersService.customerImageType) async throws -> Bool{
        do{
            var body = Multipart()
            body.fields.append(.init(key: "Type", value: documentTypeId.rawValue))
            body.fields.append(.init(key: "File", value: attachment.data, filename: attachment.fileName!, fileType: attachment.fileType!))
            
            let response = try await self.client.post("api/customers/\(customerId)/images", body: body)
            return response.statusCode == 201
            /*
             {
                 createdAt = "2023-05-25T14:08:40.436977Z";
                 customerId = "3ab98322-6d3d-4ad4-a465-ccb4978e4f66";
                 fileName = "3902c6b7-97e6-49c6-979b-00a6fe31574d.jpeg";
                 id = "d90f4a6a-41a7-4384-96ed-0d4c91601a63";
                 metadata = "";
                 type = 8;
             }
             */
        }catch let error{
            throw(error)
        }
    }
}
