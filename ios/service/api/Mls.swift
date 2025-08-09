//
//  Mls.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 20.07.2024.
//

import Foundation

class MLSService: BaseHttpService{
    override var base:String! { Enviroment.apiBase }
}

extension MLSService{
    struct ListApprovalFlowDtoPaginationResponseResult{
        public var value: ListApprovalFlowDtoPaginationResponseResultValue? = nil
        
        init(dictionary: [String:Any]?){
            if (dictionary != nil){
                if dictionary!["value"] != nil{
                    self.value = ListApprovalFlowDtoPaginationResponseResultValue(dictionary: dictionary!["value"] as? [String : Any])
                }
            }
        }
        
        struct ListApprovalFlowDtoPaginationResponseResultValue{
            public var data: Array<ListApprovalFlow> = []
            public var pageNumber: Int = 1
            public var pageSize: Int = 1
            public var total: Int = 0
            
            init(dictionary: [String:Any]?){
                if (dictionary != nil){
                    if (dictionary!["pageNumber"] as? Int) != nil{
                        self.pageNumber = dictionary!["pageNumber"] as? Int ?? 1
                    }
                    if (dictionary!["pageSize"] as? Int) != nil{
                        self.pageSize = dictionary!["pageSize"] as? Int ?? 1
                    }
                    if (dictionary!["total"] as? Int) != nil{
                        self.total = dictionary!["total"] as? Int ?? 0
                    }
                    if dictionary!["data"] != nil{
                        let data = dictionary!["data"] as? [[String:Any]]
                        if data != nil{
                            self.data = data!.map({
                                return ListApprovalFlow(dictionary: $0)
                            })
                        }
                    }
                }
            }
        }
    }

    /// Returns list of approval flows for customer
    func getFlows(_ customerId:String, state: ListApprovalFlow.ListApprovalFlowState? = nil, startDate: String?, endDate: String?, pageNumber: Int = 1, pageSize: Int = 20) async throws -> ListApprovalFlowDtoPaginationResponseResult {
        var queryItems: [String] = []
        if (state != nil){
            queryItems.append("state=\(state!.rawValue)")
        }
        if (startDate != nil){
            queryItems.append("startDate=\(startDate!)")
        }
        if (endDate != nil){
            queryItems.append("endDate=\(endDate!)")
        }
        var parameters = queryItems.isEmpty ? "" : "&\(queryItems.joined(separator: "&"))"
        
        if Enviroment.isPreview{
            let path = Bundle.main.path(forResource: "flows", ofType: "json")
            let response = try Data(contentsOf: URL(fileURLWithPath: path!), options: .mappedIfSafe)
            let data = try JSONSerialization.jsonObject(with: response, options: []) as? [String: Any]
            return ListApprovalFlowDtoPaginationResponseResult(dictionary: data)
        }
        
        let response = try await self.client.get("mls/flow?customerId=\(customerId)&pageNumber=\(pageNumber)&pageSize=\(pageSize)\(parameters)")
        
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
        
        let data = try JSONSerialization.jsonObject(with: response.response, options: []) as? [String: Any]
        return ListApprovalFlowDtoPaginationResponseResult(dictionary: data)
    }
}

extension MLSService{
    struct ApprovalFlowDtoResponseResult{
        public var value: ApprovalFlow? = nil
        
        init(dictionary: [String:Any]?){
            if (dictionary != nil){
                if dictionary!["value"] != nil{
                    self.value = ApprovalFlow(dictionary: dictionary!["value"] as? [String : Any])
                }
            }
        }
    }
    
    /// Returns flow by id
    func getFlow(_ flowId:String) async throws -> ApprovalFlowDtoResponseResult {
        if Enviroment.isPreview{
            let path = Bundle.main.path(forResource: "flowOrder", ofType: "json")
            let response = try Data(contentsOf: URL(fileURLWithPath: path!), options: .mappedIfSafe)
            let data = try JSONSerialization.jsonObject(with: response, options: []) as? [String: Any]
            return ApprovalFlowDtoResponseResult(dictionary: data)
        }
        let response = try await self.client.get("mls/flow/\(flowId)")
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
        
        let data = try JSONSerialization.jsonObject(with: response.response, options: []) as? [String: Any]
        return ApprovalFlowDtoResponseResult(dictionary: data)
    }
}

extension MLSService{
    struct ApprovalDecisionDto: Encodable{
        public var user: ListApprovalFlow.UserDto
        public var decision: ApprovalFlow.LinearApprovalStepDto.ApprovalDecisionDto.ApprovalDecisionDtoDecision
        public var comment: String?
        public var timestamp: String?
    }
    
    struct InitiateOperationResponseDto: Codable{
        public var value: InitiateOperationResponse
        struct InitiateOperationResponse: Codable{
            public var operationId: String
        }
    }
    
    /// Approves or rejects flow
    func decision(_ flowId:String, data: ApprovalDecisionDto) async throws -> InitiateOperationResponseDto {
        let response = try await self.client.patch("mls/flow/\(flowId)/decision", body: data)
        
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
        
        return try JSONDecoder().decode(InitiateOperationResponseDto.self,from:response.response)
    }
}

extension MLSService{
    /// Finalize Approves or rejects flow.
    func finalize(operationId: String, sessionId: String, confirmationType: ProfileService.ConfirmationType? = .OtpEmail) async throws -> Bool{
        let response = try await self.client.patch("mls/flow/decision/finalize", body: [
            "operationId": operationId,
            "sessionId": sessionId,
            "type": confirmationType != nil ? confirmationType!.rawValue : ""
        ])
        if (response.statusCode == 200){
            return true
        }
        
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
        
        return false
    }
}
