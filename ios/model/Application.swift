//
//  Application.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 01.10.2023.
//

import Foundation

public struct Application{
    var id:String? = ""
    var uid:String? = ""
    var programId:Int=1
    var finalized:Bool=false
    var entities:[Entity] = []
    var customerId: String = ""
    
    fileprivate func mapEntities(_ entities: [Entity]) -> [Entity]{
        var output: [Entity] = []
        //Assign entinies
        if entities.count > 0{
            var i = 0
            while(i < entities.count){
                output.append(entities[i])
                if entities[i].entities != nil && entities[i].entities!.count > 0{
                    output.append(contentsOf: self.mapEntities(entities[i].entities!))
                }
                i += 1
            }
        }
        return output
    }
    
    var allAntities: [Entity]{
        return self.mapEntities(self.entities)
    }
    
    var isAccountBusiness: Bool{
        let entity = self.entities.first
        return entity != nil && entity!.entityType == KycpService.entityType.business.rawValue
    }
    
    //MARK: Found personal entity id
    var businessId: Int?{
        return nil
    }
    
    init(dictionary: [String:Any]?){
        if dictionary != nil{
            if (dictionary!["id"] as? Int) != nil{
                self.id = String(dictionary!["id"] as? Int ?? 0)
            }
            if dictionary!["uid"] != nil{
                self.uid = dictionary!["uid"] as? String
            }
            if dictionary!["programId"] != nil{
                self.programId = dictionary!["programId"] as! Int
            }
            if dictionary!["customerId"] != nil{
                self.customerId = dictionary!["customerId"] as! String
            }
            if dictionary!["entities"] != nil{
                let entities = dictionary!["entities"] as? [[String:Any]]
                if entities != nil{
                    self.entities = entities!.map({
                        return Entity(dictionary: $0)
                    })
                }
            }
            if dictionary!["finalized"] != nil{
                self.finalized = dictionary!["finalized"] as! Bool
            }
        }
    }
    
    init(id:String?="",uid:String?="",programId:Int?=1,entities:[Entity]?=[]){
        self.id = id
        self.uid = uid
        if programId != nil{
            self.programId = programId!
        }
        if entities != nil{
            self.entities = entities!
        }
    }
    
    init(id:String?="",uid:String?="",programId:Int?=1,entities:[Entity]?=[],customerId: String){
        self.id = id
        self.uid = uid
        self.customerId = customerId
        if programId != nil{
            self.programId = programId!
        }
        if entities != nil{
            self.entities = entities!
        }
    }
    
    func getPersonalId(_ email: String?) -> Int?{
        if email != nil{
            let personals = self.allAntities.filter({$0.entityType == KycpService.entityType.individual.rawValue})
            let entity = personals.first(where: {
                return $0.fields["GENemail"] as? String == email
            })
            return entity?.id
        }
        return nil
    }
    
    func getBusinessId() -> Int?{
        return self.allAntities.first(where: {
            return $0.entityType == KycpService.entityType.business.rawValue
        })?.id
    }
    
    var individualEntityId: Int? {
        var entity = self.entities.first(where: {$0.entityType == "individual"})
        if (entity != nil){
            return entity!.id
        }
        return nil
    }
    
    var businessEntityId: Int? {
        var entity = self.entities.first(where: {$0.entityType == "business"})
        if (entity != nil){
            return entity!.id
        }
        return nil
    }
    
    var businessEntity: Entity?{
        let id = self.businessEntityId
        if id != nil{
            return self.entities.first(where: {$0.id == id})
        }
        return nil
    }
}

public struct Entity{
    var id:Int?
    var entityType:String?
    var applicationEntityId: Int?
    var fields: [String:Any] = [:]
    var entities: [Entity]? = []
    
    init(dictionary:[String:Any]?){
        if dictionary != nil{
            if dictionary!["id"] != nil{
                self.id = dictionary!["id"] as? Int
            }
            if dictionary!["entityType"] != nil{
                self.entityType = dictionary!["entityType"] as? String
            }
            if dictionary!["applicationEntityId"] != nil{
                self.applicationEntityId = dictionary!["applicationEntityId"] as? Int
            }
            if dictionary!["fields"] != nil{
                self.fields = (dictionary!["fields"] as? [String:Any])!
            }
            if dictionary!["entities"] != nil{
                let entities = dictionary!["entities"] as? [[String:Any]]
                if entities != nil{
                    self.entities = entities!.map({
                        return Entity(dictionary: $0)
                    })
                }
            }
        }
    }
    
    init(id: Int?, entityType: String?, applicationEntityId: Int?) {
        self.id = id
        self.entityType = entityType
        self.applicationEntityId = applicationEntityId
    }
    
    init(id: Int?, entityType: String?, applicationEntityId: Int?, fields: [String:String], entities: [Entity] = []) {
        self.id = id
        self.entityType = entityType
        self.applicationEntityId = applicationEntityId
        self.fields = fields
        self.entities = entities
    }
}
