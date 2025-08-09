//
//  Orders.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 26.07.2024.
//

import Foundation

class OrdersService: BaseHttpService{
    override var base:String! { Enviroment.apiBase }
}

extension OrdersService{
    struct PaymentOrderResult: Decodable{
        public var value: PaymentOrderExtendedDto
    }

    /// Return order by id
    func getOrder(_ customerId:String, orderId: String) async throws -> PaymentOrderResult {
        if Enviroment.isPreview{
            let path = Bundle.main.path(forResource: "order", ofType: "json")
            let response = try Data(contentsOf: URL(fileURLWithPath: path!), options: .mappedIfSafe)
            return try JSONDecoder().decode(PaymentOrderResult.self, from: response)
        }
        
        let response = try await self.client.get("api/core/customers/\(customerId)/payments/\(orderId)")
        return try JSONDecoder().decode(PaymentOrderResult.self, from: response.response)
    }
}
