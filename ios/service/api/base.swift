//
//  base.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 01.10.2023.
//

import Foundation
import UIKit

class BaseHttpService{
    var client: httpClient!
    var base: String! { Enviroment.apiBase }
    var headers: [String:String]=[
        "x-api-version":"1.0",
        "Content-Type":"application/json",
        "Accept":"application/json"
    ]
    
    init(){
        self.client = httpClient(self.base,headers: self.headers)
        
        self.client.beforeRequest = self.beforeRequest
        self.client.afterRequest = self.afterRequest
    }
    
    func beforeRequest(_ request:Request<Any>) async throws -> Request<Any>{
        var request = request
        
        //MARK: Check for additional headers
        if request.headers?.keys.contains("Authorization") == false{
            let defaults = UserDefaults.standard
            if defaults.value(forKey: "accessToken") != nil{
                let token = try JSONDecoder().decode(AuthenticationService.AccessToken.self,from: defaults.data(forKey: "accessToken")!)
                request.headers!["Authorization"] = "Bearer \(token.access_token)"
                #if DEBUG
                print("Append access token to request")
                #endif
            }
        }
        
        return request
    }
    
    func afterRequest(data:Data?,response:URLResponse?,request:Request<Any>) async throws -> (data:Data?,response:URLResponse?,request:Request<Any>,replace:Bool){
        
        let urlResponse = response as? HTTPURLResponse
        if let statusCode = urlResponse?.statusCode{
            if statusCode == 401{
                #if DEBUG
                print("Request failed - no user signed in. Try to obtain new token")
                #endif
                let service = await AuthenticationService()
                let token = try await service.getRefreshToken()
                
                var request = request
                request.headers!["Authorization"] = "Bearer \(token)"
                
                let (response,_,urlResponse) = try await self.client.send(request)
                return (response,urlResponse,request,false)
            }
        }
        
        return (data,response,request,false)
    }
}

struct services{
    static let accounts = AccountsService()
    static let identity = IdentityService()
    static let customers = CustomersService()
    static let transactions = TransactionsService()
    static let kycp = KycpService()
    static let contacts = ContactsService()
    static let payments = PaymentsService()
    static let terms = TermsService()
    static let statements = StatementsService()
    static let fasterPayments = FasterPaymentsService()
    static let profiles = ProfileService()
    static let mls = MLSService()
    static let orders = OrdersService()
    static let dictionarise = DictionariesService()
    static let forex = ForexService()
    static let transactionCases = TransactionCasesService()
    static let maintenance = MaintenanceService()
    static let standingOrders = StandingOrdersService()
}
