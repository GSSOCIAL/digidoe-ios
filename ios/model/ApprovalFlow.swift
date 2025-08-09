//
//  ApprovalFlow.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 24.07.2024.
//

import Foundation

public struct ListApprovalFlow{
    public var id: String = ""
    public var createdUtc: String = ""
    public var state: ListApprovalFlowState?
    public var customerId: String?
    public var initiator: UserDto?
    public var protectedObjectData: [String: Any] = [:]
    public var protectedObjectId: String?
    public var definitionId: String = ""
    public var definitionName: String?
    public var protectedType: String?
    
    public struct UserDto: Codable{
        public var id: String = ""
        public var userName: String?
        
        init(dictionary: [String:Any]?){
            if (dictionary != nil){
                if (dictionary!["id"] as? String) != nil{
                    self.id = String(dictionary!["id"] as? String ?? "")
                }
                if (dictionary!["userName"] as? String) != nil{
                    self.userName = String(dictionary!["userName"] as? String ?? "")
                }
            }
        }
        init(id: String, userName: String?){
            self.id = id
            self.userName = userName
        }
    }
    
    public enum ListApprovalFlowState: String, Codable{
        case processing
        case approved
        case rejected
    }
    
    init(dictionary: [String:Any]?){
        if (dictionary != nil){
            if (dictionary!["id"] as? String) != nil{
                self.id = String(dictionary!["id"] as? String ?? "")
            }
            if (dictionary!["createdUtc"] as? String) != nil{
                self.createdUtc = String(dictionary!["createdUtc"] as? String ?? "")
            }
            if (dictionary!["customerId"] as? String) != nil{
                self.customerId = String(dictionary!["customerId"] as? String ?? "")
            }
            if (dictionary!["protectedObjectId"] as? String) != nil{
                self.protectedObjectId = String(dictionary!["protectedObjectId"] as? String ?? "")
            }
            if (dictionary!["definitionId"] as? String) != nil{
                self.definitionId = String(dictionary!["definitionId"] as? String ?? "")
            }
            if (dictionary!["definitionName"] as? String) != nil{
                self.definitionName = String(dictionary!["definitionName"] as? String ?? "")
            }
            if (dictionary!["protectedType"] as? String) != nil{
                self.protectedType = String(dictionary!["protectedType"] as? String ?? "")
            }
            if dictionary!["protectedObjectData"] != nil{
                self.protectedObjectData = (dictionary!["protectedObjectData"] as? [String:Any])!
            }
            if dictionary!["initiator"] != nil{
                self.initiator = UserDto(dictionary: dictionary!["initiator"] as? [String : Any])
            }
            if (dictionary!["state"] as? String) != nil{
                switch((dictionary!["state"] as! String).lowercased()){
                case ListApprovalFlow.ListApprovalFlowState.approved.rawValue.lowercased():
                    self.state = .approved
                break
                case ListApprovalFlow.ListApprovalFlowState.rejected.rawValue.lowercased():
                    self.state = .rejected
                break
                default:
                    self.state = .processing
                }
            }
        }
    }
    
    func has(_ key: String) -> Bool{
        return self.protectedObjectData.keys.first(where: {$0 == key}) != nil
    }
    
    public func at(_ key: String) -> String?{
        if (self.has(key)){
            if let value = self.protectedObjectData[key] as? String{
                return value
            }else if let value = self.protectedObjectData[key] as? Int{
                return String(self.protectedObjectData[key] as! Int)
            }else if let value = self.protectedObjectData[key] as? Double{
                return String(self.protectedObjectData[key] as! Double)
            }
        }
        return nil
    }
    
    public func atDictionary(_ key: String) -> [String: String]?{
        if (self.has(key)){
            if let value = self.protectedObjectData[key] as? [String:String]{
                return value
            }
        }
        return nil
    }
    
    public func int(_ key: String) -> Int?{
        if (self.has(key)){
            if let value = self.protectedObjectData[key] as? Int{
                return value
            }else if let value = self.protectedObjectData[key] as? String{
                return Int(self.protectedObjectData[key] as! String)
            }
        }
        return nil
    }
}

public struct ApprovalFlow{
    public var createdUtc: String = ""
    public var customerId: String?
    public var definition: ApprovalFlowDefinitionDto?
    public var id: String = ""
    public var initiator: ListApprovalFlow.UserDto?
    public var protectedObjectData: [String: Any] = [:]
    public var protectedObjectId: String?
    public var state: ListApprovalFlow.ListApprovalFlowState?
    public var steps: [LinearApprovalStepDto] = []
   
    public struct ApprovalFlowDefinitionDto: Codable{
        public var id: String = ""
        public var customerId: String?
        public var name: String?
        public var protectedType: String?
        
        init(dictionary: [String:Any]?){
            if (dictionary != nil){
                if (dictionary!["id"] as? String) != nil{
                    self.id = String(dictionary!["id"] as? String ?? "")
                }
                if (dictionary!["customerId"] as? String) != nil{
                    self.customerId = String(dictionary!["customerId"] as? String ?? "")
                }
                if (dictionary!["name"] as? String) != nil{
                    self.name = String(dictionary!["name"] as? String ?? "")
                }
                if (dictionary!["protectedType"] as? String) != nil{
                    self.protectedType = String(dictionary!["protectedType"] as? String ?? "")
                }
            }
        }
    }
    
    public struct LinearApprovalStepDto{
        //MARK: StepDto
        public var id: String = ""
        public var isRoot: Bool = false
        public var state: LinearApprovalStepDtoState?
        //MARK: ApprovalStepDto
        public var excludeInitiator: Bool?
        public var approvalListProvider: ApprovalListProviderDto?
        public var decisions: [ApprovalDecisionDto]? = []
        public var approvers: [ListApprovalFlow.UserDto]? = []
        //MARK: LinearApprovalStepDto
        public var minimumDecisions: Int?
        public var nextStepId: String?
        
        public enum LinearApprovalStepDtoState: String, Codable{
            case pending
            case processing
            case approved
            case rejected
            case skipped
        }
        
        public struct ApprovalListProviderDto{
            public var type: String?
            public var data: [String:Any] = [:]
            
            init(dictionary: [String:Any]?){
                if (dictionary != nil){
                    if (dictionary!["type"] as? String) != nil{
                        self.type = String(dictionary!["type"] as? String ?? "")
                    }
                    //Convert data in loop
                }
            }
        }
        
        public struct ApprovalDecisionDto{
            public var user: ListApprovalFlow.UserDto?
            public var decision: ApprovalDecisionDtoDecision?
            public var comment: String?
            public var timestamp: String?
            
            public enum ApprovalDecisionDtoDecision: String, Codable{
                case approved
                case rejected
            }
            
            init(dictionary: [String:Any]?){
                if (dictionary != nil){
                    if (dictionary!["comment"] as? String) != nil{
                        self.comment = String(dictionary!["comment"] as? String ?? "")
                    }
                    if (dictionary!["timestamp"] as? String) != nil{
                        self.timestamp = String(dictionary!["timestamp"] as? String ?? "")
                    }
                    if dictionary!["user"] != nil{
                        self.user = ListApprovalFlow.UserDto(dictionary: dictionary!["user"] as? [String : Any])
                    }
                    //MARK: Enums
                    if (dictionary!["decision"] as? String) != nil{
                        switch((dictionary!["decision"] as! String).lowercased()){
                        case ApprovalDecisionDtoDecision.rejected.rawValue.lowercased():
                            self.decision = .rejected
                        break
                        default:
                            self.decision = .approved
                        }
                    }
                }
            }
        }
        
        init(dictionary: [String:Any]?){
            if (dictionary != nil){
                if (dictionary!["id"] as? String) != nil{
                    self.id = String(dictionary!["id"] as? String ?? "")
                }
                if (dictionary!["nextStepId"] as? String) != nil{
                    self.nextStepId = String(dictionary!["nextStepId"] as? String ?? "")
                }
                //MARK: Booleans
                if dictionary!["isRoot"] != nil{
                    self.isRoot = dictionary!["isRoot"] as! Bool
                }
                if dictionary!["excludeInitiator"] != nil{
                    self.excludeInitiator = dictionary!["excludeInitiator"] as? Bool
                }
                //MARK: Integers
                if dictionary!["minimumDecisions"] != nil{
                    self.minimumDecisions = dictionary!["minimumDecisions"] as? Int
                }
                //MARK: Objects
                if dictionary!["approvalListProvider"] != nil{
                    self.approvalListProvider = ApprovalListProviderDto(dictionary: dictionary!["approvalListProvider"] as? [String : Any])
                }
                if dictionary!["decisions"] != nil{
                    let decisions = dictionary!["decisions"] as? [[String:Any]]
                    if decisions != nil{
                        self.decisions = decisions!.map({
                            return ApprovalDecisionDto(dictionary: $0)
                        })
                    }
                }
                if dictionary!["approvers"] != nil{
                    let approvers = dictionary!["approvers"] as? [[String:Any]]
                    if approvers != nil{
                        self.approvers = approvers!.map({
                            return ListApprovalFlow.UserDto(dictionary: $0)
                        })
                    }
                }
                //MARK: Enums
                if (dictionary!["state"] as? String) != nil{
                    switch((dictionary!["state"] as! String).lowercased()){
                    case LinearApprovalStepDtoState.pending.rawValue.lowercased():
                        self.state = .pending
                    break
                    case LinearApprovalStepDtoState.approved.rawValue.lowercased():
                        self.state = .approved
                    break
                    case LinearApprovalStepDtoState.rejected.rawValue.lowercased():
                        self.state = .rejected
                    break
                    case LinearApprovalStepDtoState.skipped.rawValue.lowercased():
                        self.state = .skipped
                    break
                    default:
                        self.state = .processing
                    }
                }
            }
        }
    }
    
    init(dictionary: [String:Any]?){
        if (dictionary != nil){
            if (dictionary!["createdUtc"] as? String) != nil{
                self.createdUtc = String(dictionary!["createdUtc"] as? String ?? "")
            }
            if (dictionary!["customerId"] as? String) != nil{
                self.customerId = String(dictionary!["customerId"] as? String ?? "")
            }
            if (dictionary!["id"] as? String) != nil{
                self.id = String(dictionary!["id"] as? String ?? "")
            }
            if (dictionary!["protectedObjectId"] as? String) != nil{
                self.protectedObjectId = String(dictionary!["protectedObjectId"] as? String ?? "")
            }
            //MARK: Objects
            if dictionary!["definition"] != nil{
                self.definition = ApprovalFlowDefinitionDto(dictionary: dictionary!["definition"] as? [String : Any])
            }
            if dictionary!["initiator"] != nil{
                self.initiator = ListApprovalFlow.UserDto(dictionary: dictionary!["initiator"] as? [String : Any])
            }
            if dictionary!["steps"] != nil{
                let steps = dictionary!["steps"] as? [[String:Any]]
                if steps != nil{
                    self.steps = steps!.map({
                        return LinearApprovalStepDto(dictionary: $0)
                    })
                }
            }
            //MARK: Enums
            if (dictionary!["state"] as? String) != nil{
                switch((dictionary!["state"] as! String).lowercased()){
                case ListApprovalFlow.ListApprovalFlowState.approved.rawValue.lowercased():
                    self.state = .approved
                break
                case ListApprovalFlow.ListApprovalFlowState.rejected.rawValue.lowercased():
                    self.state = .rejected
                break
                default:
                    self.state = .processing
                }
            }
            //MARK: Data
            if dictionary!["protectedObjectData"] != nil{
                self.protectedObjectData = (dictionary!["protectedObjectData"] as? [String:Any])!
            }
        }
    }
    
    func has(_ key: String) -> Bool{
        return self.protectedObjectData.keys.first(where: {$0 == key}) != nil
    }
    
    public func at(_ key: String) -> String?{
        if (self.has(key)){
            if let value = self.protectedObjectData[key] as? String{
                return value
            }else if let value = self.protectedObjectData[key] as? Int{
                return String(self.protectedObjectData[key] as! Int)
            }
        }
        return nil
    }
    
    public func atDictionary(_ key: String) -> [String: String]?{
        if (self.has(key)){
            if let value = self.protectedObjectData[key] as? [String:String]{
                return value
            }
        }
        return nil
    }
    
    public func int(_ key: String) -> Int?{
        if (self.has(key)){
            if let value = self.protectedObjectData[key] as? Int{
                return value
            }else if let value = self.protectedObjectData[key] as? String{
                return Int(self.protectedObjectData[key] as! String)
            }
        }
        return nil
    }
}
