//
//  Maintenance.swift
//  DigiDoe Business Banking
//
//  Created by Михайло Картмазов on 28.03.2025.
//

import Foundation

class MaintenanceService:BaseHttpService{
    override var base:String! { Enviroment.storageBase }

    struct MaintenanceResponse: Codable{
        public var iOS_ver: String;
        public var isUpdateRequired: Bool;
        public var maintenance: Bool;
        public var msgTitle: String;
        public var msgBody: String;
    }
    
    func getMaintenance() async throws -> MaintenanceResponse{
        do{
            #if DEBUG
            let response = try await self.client.get("release/rel2.json")
            #else
            let response = try await self.client.get("release/rel.json")
            #endif
            
            return try JSONDecoder().decode(MaintenanceResponse.self, from: response.response)
        }catch let error{
            throw(error)
        }
    }
}
