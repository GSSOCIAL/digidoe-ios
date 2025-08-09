//
//  Kycp.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 01.10.2023.
//

import Foundation

struct AttachmentUploadResponse:Decodable{
    var applicationId: String
    var docTypeId: Int
    var entityId: Int
    var entityTypeId: Int
    var title: String
}

class KycpService:BaseHttpService{
    override var base:String! { Enviroment.apiKYCP }
}

//Errors
extension KycpService{
    struct ApiError: Error, Decodable{
        var errors: Array<ApiErrorDetails> = []
        var isCancelled: Bool = false
        var isSuccess: Bool = false
        
        func getMessage() -> String{
            return self.errors.map({ error in
                var context: String = ""
                if (error.data != nil){
                    context = error.data!.map({ root in
                        var childs: String = root.value.joined(separator: ", ")
                        return "\(root.key): \(childs)"
                    }).joined(separator: "\n")
                }else if(error.description != nil){
                    context = error.description!
                }
                return context
            }).joined(separator: ".")
        }
        
        struct ApiErrorDetails: Decodable{
            var code: String?
            var data: [String:[String]]?
            var description: String?
        }
    }
    
    struct ServerError: Error, Decodable{
        var errors: Array<ServerErrorDetails> = []
        var isCancelled: Bool = false
        var isSuccess: Bool = false
        
        func getMessage() -> String{
            return self.errors.map({ error in
                var context: String = ""
                if (error.data != nil){
                    context = error.data!.map({ root in
                        var childs: String = root.value.joined(separator: ", ")
                        return "\(root.key): \(childs)"
                    }).joined(separator: "\n")
                }else if(error.description != nil){
                    context = error.description!
                }
                return context
            }).joined(separator: ".")
        }
        
        struct ServerErrorDetails: Decodable{
            var code: ErrorCodes
            var data: [String:[String]]?
            var description: String?
            
            enum ErrorCodes: String, Decodable{
                case PerTransactionLimitExceededBadRequest
                case DailyLimitExceededBadRequest
                case AmountValidationError
                
                var label: String{
                    switch(self){
                    case .PerTransactionLimitExceededBadRequest:
                        return "Limit exceeded"
                    case .DailyLimitExceededBadRequest:
                        return "Limit exceeded"
                    case .AmountValidationError:
                        return "Exchange value is too low"
                    default:
                        return "Something wrong"
                    }
                }
            }
        }
    }
    
    struct KycpServerError: Error, Decodable{
        var errors: Array<KycpServerErrorDetails> = []
        var isCancelled: Bool = false
        var isSuccess: Bool = false
        
        func getMessage() -> String{
            return self.errors.map({
                var code = "";
                if ($0.code != nil && !$0.code!.isEmpty){
                    code = $0.code!
                }
                return "\(code.isEmpty ? "" : "\(code): " )\($0.description)"
            }).joined(separator: ".")
        }
        
        struct KycpServerErrorDetails: Decodable{
            var code: String?
            var data: String?
            var description: String
        }
    }
    
    struct KycpError: ServicesError, Decodable{
        var message: String? = nil
        var errors: [String:[String]] = [:]
        var status: Int = 0
        var title: String = ""
        var traceId: String = ""
        var type: String = ""
        
        func getMessage() -> String{
            return self.errors.map({ (key, errors) in
                return "\(key): \(errors.joined(separator: ", "))"
            }).joined(separator: ".")
        }
    }
    
    struct KycpSimpleError: Error,Decodable{
        var error : KycpService.KycpErrorData
        
        func getMessage() -> String{
            if self.error.message != nil && self.error.message!.isEmpty == false{
                return self.error.message ?? ""
            }
            if self.error.details!.isEmpty == false{
                var components: [String] = []
                self.error.details.map({ child in
                    child.map({error in
                        if error["message"] != nil{
                            components.append(error["message"]!)
                        }
                    })
                })
                return components.joined(separator: ", ")
            }
            return ""
            //return self.error.details?.first?.values
        }
    }
    
    struct KycpErrorData:  Decodable{
        var code: String? = nil
        var details: [[String:String]]? = []
        var message: String? = ""
    }
}

//Persons
extension KycpService{
    public struct CreatePersonResponse: Codable{
        public var id: String
    }
    
    public struct CreatePersonRequest: Encodable{
        public var givenName: String?
        public var surname: String?
        public var middleName: String?
        
        public var dateOfBirth: String?
        public var dateOfDeath: String?
        public var countryOfBirthExtId: String?
        
        public var email: String
        public var phone: String
        public var genderExtId: String?
        public var address: String?
        
        public var prepopulatedOCRResults: KycpService.OCRDecodeResponse.OCRDecodeResult?
    }
    
    public func createPerson(_ request: Person.CreatePersonRequest) async throws -> Person{
        let response = try await self.client.post("kycp/persons", body: request)
        if let error = try? JSONDecoder().decode(KycpServerError.self, from: response.response){
            throw error
        }
        if let error = try? JSONDecoder().decode(KycpService.KycpError.self, from: response.response){
           throw error
        }
        if let error = try? JSONDecoder().decode(KycpService.KycpSimpleError.self, from: response.response){
            throw error
        }
        
        return try JSONDecoder().decode(Person.self, from: response.response)
    }
    
    public func createPerson() async throws -> Person{
        let response = try await self.client.post("kycp/persons")
        
        if let error = try? JSONDecoder().decode(KycpServerError.self, from: response.response){
            throw error
        }
        if let error = try? JSONDecoder().decode(KycpService.KycpError.self, from: response.response){
           throw error
        }
        if let error = try? JSONDecoder().decode(KycpService.KycpSimpleError.self, from: response.response){
            throw error
        }
        
        return try JSONDecoder().decode(Person.self, from: response.response)
    }
    
    public func updatePerson(_ request: Person.CreatePersonRequest) async throws -> Person{
        let response = try await self.client.patch("kycp/persons", body: request)
        
        if let error = try? JSONDecoder().decode(KycpServerError.self, from: response.response){
            throw error
        }
        if let error = try? JSONDecoder().decode(KycpService.KycpError.self, from: response.response){
           throw error
        }
        if let error = try? JSONDecoder().decode(KycpService.KycpSimpleError.self, from: response.response){
            throw error
        }
        
        return try JSONDecoder().decode(Person.self, from: response.response)
    }
    
    public func getPerson() async throws -> Person?{
        #if DEBUG
        if Enviroment.useMockData == true{
            if let path = Bundle.main.path(forResource: "persons", ofType: "json"){
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                return try JSONDecoder().decode(Person.self,from:data)
            }
        }
        #endif
        
        let response = try await self.client.get("kycp/persons")
        
        if (response.statusCode == 404){
            return nil
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
        
        return try JSONDecoder().decode(Person.self, from: response.response)
    }
    
    public struct LivenessSessionResult: Codable{
        public var value: LivenessSessionResultValue
        
        public struct LivenessSessionResultValue: Codable{
            public var correlationId: String?
            public var sessionId: String?
            public var token: String?
        }
    }
    
    public struct LivenessSessionDecodedResult: Codable{
        public var value: LivenessSessionDecodedResultValue
        
        public struct LivenessSessionDecodedResultValue: Codable{
            public var status: String?
        }
    }
    
    public func createLivenessSession() async throws -> LivenessSessionResult {
        let response = try await self.client.post("kycp/persons/liveness/session")
        
        if let error = try? JSONDecoder().decode(KycpServerError.self, from: response.response){
            throw error
        }
        if let error = try? JSONDecoder().decode(KycpService.KycpError.self, from: response.response){
           throw error
        }
        if let error = try? JSONDecoder().decode(KycpService.KycpSimpleError.self, from: response.response){
            throw error
        }
        
        return try JSONDecoder().decode(LivenessSessionResult.self, from: response.response)
    }
    public func setLivenessSessionResult(_ sessionId: String) async throws -> LivenessSessionDecodedResult {
        let response = try await self.client.post("kycp/persons/liveness/session/\(sessionId)/result")
        
        if let error = try? JSONDecoder().decode(KycpServerError.self, from: response.response){
            throw error
        }
        if let error = try? JSONDecoder().decode(KycpService.KycpError.self, from: response.response){
           throw error
        }
        if let error = try? JSONDecoder().decode(KycpService.KycpSimpleError.self, from: response.response){
            throw error
        }
        
        return try JSONDecoder().decode(LivenessSessionDecodedResult.self, from: response.response)
    }
}

//Customers
extension KycpService{
    public struct IndividualCustomer: Codable{
        public struct CreateIndividualCustomerRequest: Codable{
            public var personId: String
        }
        public struct CreateIndividualCustomerResponse: Codable{
            public var id: String
        }
    }
    public struct BusinessCustomer: Codable{
        enum CustomerTypes: String, Codable{
            case emi
            case nfi
        }
        
        public struct CreateBusinessCustomerRequest: Codable{
            public var organisationId: String
            public var customerType: BusinessCustomer.CustomerTypes = .nfi
        }
        
        public struct CreateBusinessCustomerResponse: Codable{
            public var id: String
        }
    }
    
    public struct CustomersResponse: Codable{
        public var customers: Array<CustomersResponse.Customer> = []
        public enum CustomerType: String, Codable, CaseIterable{
            case business
            case individual
        }
        public enum CustomerState: String, Codable, CaseIterable{
            case new
            case review
            case active
            case inactive
            case approvedForExternal
            case rejected
        }
        
        public struct Customer: Codable{
            var id: String
            var name: String
            var type: CustomerType
            var state: CustomerState
        }
    }
    
    public func getCustomers() async throws -> CustomersResponse{
        #if DEBUG
        if Enviroment.useMockData == true{
            if let path = Bundle.main.path(forResource: "customers", ofType: "json"){
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                return try JSONDecoder().decode(CustomersResponse.self,from:data)
            }
        }
        #endif
        
        let response = try await self.client.get("kycp/customers")
        if let error = try? JSONDecoder().decode(KycpServerError.self, from: response.response){
            throw error
        }
        if let error = try? JSONDecoder().decode(KycpService.KycpError.self, from: response.response){
           throw error
        }
        if let error = try? JSONDecoder().decode(KycpService.KycpSimpleError.self, from: response.response){
            throw error
        }
        
        return try JSONDecoder().decode(CustomersResponse.self, from: response.response)
    }
    
    public func createIndividualCustomer(_ request: IndividualCustomer.CreateIndividualCustomerRequest) async throws -> IndividualCustomer.CreateIndividualCustomerResponse{
        let response = try await self.client.post("kycp/customers/individual", body: request)
        
        if let error = try? JSONDecoder().decode(KycpServerError.self, from: response.response){
            throw error
        }
        if let error = try? JSONDecoder().decode(KycpService.KycpError.self, from: response.response){
           throw error
        }
        if let error = try? JSONDecoder().decode(KycpService.KycpSimpleError.self, from: response.response){
            throw error
        }
        
        return try JSONDecoder().decode(IndividualCustomer.CreateIndividualCustomerResponse.self, from: response.response)
    }
    
    public func createBusinessCustomer(_ request: BusinessCustomer.CreateBusinessCustomerRequest) async throws -> BusinessCustomer.CreateBusinessCustomerResponse{
        let response = try await self.client.post("kycp/customers/business", body: request)
        
        if let error = try? JSONDecoder().decode(KycpServerError.self, from: response.response){
            throw error
        }
        if let error = try? JSONDecoder().decode(KycpService.KycpError.self, from: response.response){
           throw error
        }
        if let error = try? JSONDecoder().decode(KycpService.KycpSimpleError.self, from: response.response){
            throw error
        }
        
        return try JSONDecoder().decode(BusinessCustomer.CreateBusinessCustomerResponse.self, from: response.response)
    }
}

//Application & entities
extension KycpService{
    enum entityType: String{
        case individual = "individual"
        case business = "business"
    }
    
    fileprivate func _createApplication(_ application: Application) async throws -> Application{
        let body: [String:Any] = [
            "programId":application.programId,
            "customerId": application.customerId,
            "entities":application.entities.map({
                return self.mapEntity($0)
            })
        ]
        let response = try await self.client.post("kycp/applications",body: try JSONSerialization.data(withJSONObject: body, options: .prettyPrinted))
        
        if let error = try? JSONDecoder().decode(KycpService.KycpServerError.self, from: response.response){
            throw error
        }
        if let error = try? JSONDecoder().decode(KycpService.KycpError.self, from: response.response){
           throw error
        }
        if let error = try? JSONDecoder().decode(KycpService.KycpSimpleError.self, from: response.response){
            throw error
        }
        
        let data = try JSONSerialization.jsonObject(with: response.response, options: []) as? [String: Any]
        return Application(dictionary: data)
    }
    
    fileprivate func mapEntity(_ entity: Entity) -> [String:Any]{
        var output:[String:Any] = [:]
        if entity.id != nil{
            output["id"] = entity.id
        }
        if entity.entityType != nil{
            output["entityType"] = entity.entityType
            output["entityTypeId"] = entity.entityType! == KycpService.entityType.business.rawValue ? 12 : 27
        }
        if (entity.applicationEntityId != nil){
            output["applicationEntityId"] = entity.applicationEntityId
        }
        output["fields"] = entity.fields
        if entity.entities != nil && entity.entities!.isEmpty == false{
            output["entities"] = entity.entities!.map({ el in
                return self.mapEntity(el)
            })
        }
        return output
    }
    
    fileprivate func findEntityChild(_ entities: [Entity], neededEntityId: Int?, tree: Entity?, fields: [String:Any]? = [:]) -> Entity?{
        var childs:Entity? = tree
        var i = 0
        while(i < entities.count){
            if entities[i].id != nil{
                //MARK: Entity found
                if entities[i].id == neededEntityId{
                    var entity = entities[i]
                    if fields != nil{
                        entity.fields = fields!
                    }
                    return entity
                }else if entities[i].entities != nil && !entities[i].entities!.isEmpty{
                    let child = self.findEntityChild(entities[i].entities!, neededEntityId: neededEntityId, tree: entities[i], fields: fields)
                    if child != nil{
                        var entity = entities[i]
                        entity.entities = [child!]
                        return entity
                    }
                }
            }
            i += 1
        }
        
        return nil
    }
    
    fileprivate func filterEntityForUpdate(_ entity: Entity, neededEntityId: Int?) -> Entity{
        if entity.id != nil && entity.id != neededEntityId{
            var updated = entity
            //MARK: Attach any field
            let field = updated.fields.first(where: {key,value in
                return key.isEmpty == false
            })
            if (updated.fields.isEmpty){
                updated.fields = [field!.key: field?.value ?? ""]
            }
            if updated.entities != nil && updated.entities!.count > 0{
                let entities: [Entity] = updated.entities!
                updated.entities = entities.map({
                    return self.filterEntityForUpdate($0, neededEntityId: neededEntityId)
                })
            }
            return updated
        }
        return entity
    }
    
    public func createApplication(_ entities: [Entity], customerId: String) async throws -> Application{
        let application = Application(
            id:"",
            uid: "",
            programId: 1,
            entities: entities,
            customerId: customerId
        )
        return try await self._createApplication(application)
    }
    
    public func getApplication(_ customerId: String) async throws -> Application?{
        let response = try await self.client.get("kycp/applications?customerId=\(customerId)")
        if response.statusCode == 404{
            return nil
        }
        
        if let error = try? JSONDecoder().decode(KycpService.KycpServerError.self, from: response.response){
            throw error
        }
        if let error = try? JSONDecoder().decode(KycpService.KycpError.self, from: response.response){
           throw error
        }
        if let error = try? JSONDecoder().decode(KycpService.KycpSimpleError.self, from: response.response){
            throw error
        }
        
        let data = try JSONSerialization.jsonObject(with: response.response, options: []) as? [String: Any]
        return Application(dictionary: data)
    }
    
    fileprivate func _updateApplication(_ application: Application) async throws -> Application{
        var entity = application.entities.first
        if entity != nil{
            let field = entity!.fields.first(where: {key,value in
                return key.isEmpty == false
            })
            entity!.fields = [field!.key: field?.value ?? ""]
            entity!.entities = []
            
            let body: [String:Any] = [
                "id":application.id,
                "uid":application.uid,
                "programId":application.programId,
                "finalized":application.finalized,
                "customerId": application.customerId,
                "entities":[entity!].map({
                    return self.mapEntity($0)
                })
            ]
            let response = try await self.client.post("kycp/applications",body: try JSONSerialization.data(withJSONObject: body, options: .prettyPrinted))
            if let error = try? JSONDecoder().decode(KycpService.KycpError.self, from: response.response){
               throw error
            }
            if let error = try? JSONDecoder().decode(KycpService.KycpSimpleError.self, from: response.response){
                throw error
            }
            
            let data = try JSONSerialization.jsonObject(with: response.response, options: []) as? [String: Any]
            return Application(dictionary: data)
        }else{
            throw ServiceError(title: "At least one entity should presented")
        }
    }
    
    func updateApplication(application: Application) async throws -> Application{
        return try await self._updateApplication(application)
    }
    
    func _updateEntity(application: Application) async throws -> Application{
        do{
            let body: [String:Any] = [
                "id":application.id!,
                "uid":application.uid!,
                "customerId": application.customerId,
                "entities":application.entities.map({
                    return self.mapEntity($0)
                })
            ]
            let response = try await self.client.post("kycp/applications",body: try JSONSerialization.data(withJSONObject: body, options: .prettyPrinted))
            if let error = try? JSONDecoder().decode(KycpService.KycpServerError.self, from: response.response){
                throw error
            }
            if let error = try? JSONDecoder().decode(KycpService.KycpError.self, from: response.response){
               throw error
            }
            if let error = try? JSONDecoder().decode(KycpService.KycpSimpleError.self, from: response.response){
                throw error
            }
            
            let data = try JSONSerialization.jsonObject(with: response.response, options: []) as? [String: Any]
            return Application(dictionary: data)
        }catch(let error){
            throw error
        }
    }
    
    func update(_ body: [String:Any]) async throws -> Application{
        print("[REQUEST] ––", body)
        let response = try await self.client.post("kycp/applications",body: try JSONSerialization.data(withJSONObject: body, options: .prettyPrinted))
        if let error = try? JSONDecoder().decode(KycpService.KycpServerError.self, from: response.response){
            throw error
        }
        if let error = try? JSONDecoder().decode(KycpService.KycpError.self, from: response.response){
           throw error
        }
        if let error = try? JSONDecoder().decode(KycpService.KycpSimpleError.self, from: response.response){
            throw error
        }
        
        let data = try JSONSerialization.jsonObject(with: response.response, options: []) as? [String: Any]
        print("[RESPONSE] –– ", data)
        return Application(dictionary: data)
    }
    
    func updateEntity(_ fields:[String:Any]?=[:], application: Application?, entityId: Int?) async throws -> Application{
        do{
            guard let application = application else{
                throw ServiceError(title: "Application not passed")
            }
            if (application.id == nil || application.uid == nil){
                throw ServiceError(title: "Application id not passed")
            }
            guard entityId != nil else{
                throw ServiceError(title: "Entity id not passed")
            }
            
            var _application: Application = Application(
                id: application.id,
                uid: application.uid,
                customerId: application.customerId
            )
            
            let entity = self.findEntityChild(application.entities, neededEntityId: entityId, tree: nil, fields: fields)
            if entity != nil{
                _application.entities = [entity!]
            }
            _application.entities = _application.entities.map({
                return self.filterEntityForUpdate($0,neededEntityId: entityId!)
            })
            return try await self._updateEntity(application: _application)
        }catch(let error){
            throw error
        }
    }
    
    func addEntity(_ entities: [Entity], application: Application?, rootEntityId: Int?) async throws -> Application{
        do{
            guard let application = application else{
                throw ServiceError(title: "Application not passed")
            }
            if (application.id == nil || application.uid == nil){
                throw ServiceError(title: "Application id not passed")
            }
            
            var _application: Application = Application(
                id: application.id,
                uid: application.uid,
                customerId: application.customerId
            )
            if rootEntityId != nil{
                var entity = self.findEntityChild(application.entities, neededEntityId: rootEntityId, tree: nil, fields: nil)
                if entity != nil{
                    entity!.entities = entities
                    _application.entities = [entity!]
                }
            }else{
                _application.entities = entities
            }
            _application.entities = _application.entities.map({
                return self.filterEntityForUpdate($0,neededEntityId: nil)
            })
            return try await self._updateEntity(application: _application)
        }catch(let error){
            throw error
        }
    }
}

//Lookups
extension KycpService{
    enum LookUpFields: Int{
        case genders = 2
        case countries = 4
        case mailingAddressIsDifferent = 7
        case employeeStatuses = 9
        case regulationOptions = 10
        case corporateServices = 12
        case companyTypes = 35
        case currencies = 36
        case businessCategories = 38
        case salesChannels = 39
        case customers = 40
        case turnover = 41
        case volumeBands = 42
        case sizeBands = 43
        case companyStructure = 47
        case serviceUsage = 61
    }
    struct LookUpResponse: Decodable{
        var data: Array<LookUpItem>
        var pageNumber: Int
        var pageSize: Int
        var total: Int
        
        struct LookUpItem: Decodable{
            var externalRef: String
            var id: Int
            var name: String
        }
    }
    
    public func getLookUp(_ id: LookUpFields) async throws -> LookUpResponse{
        #if DEBUG
        if Enviroment.useMockData == true{
            if let path = Bundle.main.path(forResource: "lookup", ofType: "json"){
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                return try JSONDecoder().decode(LookUpResponse.self,from:data)
            }
        }
        #endif
        let response = try await self.client.get("kycp/lookups/\(id.rawValue)?pageSize=500")
        if let error = try? JSONDecoder().decode(KycpService.KycpServerError.self, from: response.response){
            throw error
        }
        if let error = try? JSONDecoder().decode(KycpService.KycpError.self, from: response.response){
           throw error
        }
        if let error = try? JSONDecoder().decode(KycpService.KycpSimpleError.self, from: response.response){
            throw error
        }
        
        return try JSONDecoder().decode(KycpService.LookUpResponse.self, from: response.response)
    }
}

//Documents
extension KycpService{
    enum DocType: Int{
        case passport = 56 //Certified copy of Passport - Photo and Information, and Signature pages required
        case proofOfAddress = 57 //Certified copy of Proof of Address: (Utility Bill, Drivers License, Bank Statement, Maximum of 6 months old)
        case idCard = 54 //Government/Nationality issued ID Card
        case searchResult = 16 //Internet Search and/or any public search results
        case screenshot = 15 //Screening Result
        case wealth = 8 //Source of Wealth Corroboration Document
        case selfie = 60 //Selfie
        case notSpecified = 61 //Non-specified type of Document
        case residencePermit = 59 //Residence Permit
    }
    
    struct OCRDecodeResponse: Codable{
        public var value: OCRDecodeResult?
        
        struct OCRDecodeResult: Codable{
            var dateOfBirth: String?
            var dateOfExpiration: String?
            var dateOfIssue: String?
            var documentType: String? //idDocument.nationalIdentityCard
            var firstName: String?
            var gender: String?
            var id: String?
            var lastName: String?
            var middleName: String?
            var nationality: String?
            var placeOfBirth: String?
        }
        struct OCRDecodeResultExtended: Codable{
            var dateOfBirth: OCRDecodeResultExtendedValue?
            var dateOfExpiration: OCRDecodeResultExtendedValue?
            var dateOfIssue: OCRDecodeResultExtendedValue?
            var documentType: OCRDecodeResultExtendedValue?
            var firstName: OCRDecodeResultExtendedValue?
            var gender: OCRDecodeResultExtendedValue?
            var id: OCRDecodeResultExtendedValue?
            var lastName: OCRDecodeResultExtendedValue?
            var middleName: OCRDecodeResultExtendedValue?
            var nationality: OCRDecodeResultExtendedValue?
            var placeOfBirth: OCRDecodeResultExtendedValue?
            
            struct OCRDecodeResultExtendedValue: Codable{
                var value: String
                var id: String
            }
        }
    }
    
    struct OCRDecodeResponseShort: Codable{
        public var value: String
    }
    
    func uploadDocument(_ attachment:FileAttachment, applicationId: String, entityId: Int?, entityTypeId: KycpService.entityType, title: String, type: DocType) async throws -> Bool{
        do{
            guard let entityId = entityId else{
                throw ServiceError(title: "Entity id not passed")
            }
            
            var body = Multipart()
            body.fields.append(.init(key: "title", value: title))
            body.fields.append(.init(key: "docTypeId", value: type.rawValue))
            body.fields.append(.init(key: "applicationId", value: applicationId))
            body.fields.append(.init(key: "entityId", value: entityId))
            body.fields.append(.init(key: "entityTypeId", value: entityTypeId == .business ? 12 : 27))
            body.fields.append(.init(key: "file", value: attachment.data, filename: attachment.fileName!, fileType: attachment.fileType!))
            
            let response = try await self.client.post("kycp/documents/upload", body: body)
            
            if let error = try? JSONDecoder().decode(KycpService.KycpServerError.self, from: response.response){
                throw error
            }
            if let error = try? JSONDecoder().decode(KycpService.KycpError.self, from: response.response){
               throw error
            }
            if let error = try? JSONDecoder().decode(KycpService.KycpSimpleError.self, from: response.response){
                throw error
            }
            
            return response.statusCode == 200 ? true : false
        }catch (let error){
            throw(error)
        }
    }
    
    func uploadOCR(_ attachment: FileAttachment, entityId: String?, entityType: String?) async throws -> OCRDecodeResponseShort{
        var body = Multipart()
        body.fields.append(.init(key: "entityId", value: entityId ?? ""))
        body.fields.append(.init(key: "entityType", value: entityType ?? ""))
        body.fields.append(.init(key: "file", value: attachment.data, filename: attachment.fileName!, fileType: attachment.fileType!))
        
        let response = try await self.client.post("kycp/documents/ocr", body: body)
        
        if let error = try? JSONDecoder().decode(KycpService.KycpServerError.self, from: response.response){
            throw error
        }
        if let error = try? JSONDecoder().decode(KycpService.KycpError.self, from: response.response){
           throw error
        }
        if let error = try? JSONDecoder().decode(KycpService.KycpSimpleError.self, from: response.response){
            throw error
        }
        
        return try JSONDecoder().decode(KycpService.OCRDecodeResponseShort.self, from: response.response)
    }
    
    func getOCR(_ jobId: String) async throws -> OCRDecodeResponse{
        let response = try await self.client.get("kycp/documents/ocr/\(jobId)")
        
        if let error = try? JSONDecoder().decode(KycpService.KycpServerError.self, from: response.response){
            throw error
        }
        if let error = try? JSONDecoder().decode(KycpService.KycpError.self, from: response.response){
           throw error
        }
        if let error = try? JSONDecoder().decode(KycpService.KycpSimpleError.self, from: response.response){
            throw error
        }
        
        return try JSONDecoder().decode(KycpService.OCRDecodeResponse.self, from: response.response)
    }
}

//Companies
extension KycpService{
    enum CompanyStatus:String,Decodable{
        case active
    }
    enum CompanyType:String,Decodable{
        case ltd
    }
    struct CompanyAddress: Decodable{
        public var addressLine1: String?
        public var addressLine2: String?
        public var country: String?
        public var locality: String?
        public var postalCode: String?
    }
    
    struct Company: Decodable{
        var address:CompanyAddress?
        var companyNumber: String //as Registration number?
        var dateOfCreation: String //as Incorportation date?
        var title:String
        var description:String?
        var companyStatus:String?
        var companyType:String?
    }
    
    struct CompaniesResponse:Decodable{
        var data: [Company] = []
    }
    struct OfficersCountResponse: Decodable{
        var isPersonOfficer: Bool = false
        var officersNumber: Int = 0
    }
    
    func searchCompany(_ query: String, pageSize: Int = 20, pageNumber: Int = 1) async throws -> [KycpService.Company]{
        let response = try await self.client.get("kycp/companies-house/companies?name=\(query.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!)&pageSize=\(pageSize)&pageNumber=\(pageNumber)")
        
        if let error = try? JSONDecoder().decode(KycpService.KycpServerError.self, from: response.response){
            throw error
        }
        if let error = try? JSONDecoder().decode(KycpService.KycpError.self, from: response.response){
           throw error
        }
        if let error = try? JSONDecoder().decode(KycpService.KycpSimpleError.self, from: response.response){
            throw error
        }
        let companies = try JSONDecoder().decode(CompaniesResponse.self, from: response.response)
        return companies.data
    }
    
    func getCompanyDetails(companyNumber: String, personId: String?) async throws -> OfficersCountResponse{
        guard personId != nil else{
            throw ServiceError(title: "Failed to get company", message: "Person empty")
        }
        let response = try await self.client.get("kycp/companies-house/companies/\(companyNumber)?personId=\(personId!)")
        
        if let error = try? JSONDecoder().decode(KycpService.KycpServerError.self, from: response.response){
            throw error
        }
        if let error = try? JSONDecoder().decode(KycpService.KycpError.self, from: response.response){
           throw error
        }
        if let error = try? JSONDecoder().decode(KycpService.KycpSimpleError.self, from: response.response){
            throw error
        }
        
        return try JSONDecoder().decode(OfficersCountResponse.self, from: response.response)
    }
}

//Ogranisations
extension KycpService{
    public func createOrganisation(_ request: Organisation.CreateOrganisationRequest) async throws -> Organisation{
        let response = try await self.client.post("kycp/organisations", body: request)
        
        if let error = try? JSONDecoder().decode(KycpServerError.self, from: response.response){
            throw error
        }
        if let error = try? JSONDecoder().decode(KycpService.KycpError.self, from: response.response){
           throw error
        }
        if let error = try? JSONDecoder().decode(KycpService.KycpSimpleError.self, from: response.response){
            throw error
        }
        
        return try JSONDecoder().decode(Organisation.self, from: response.response)
    }
}
