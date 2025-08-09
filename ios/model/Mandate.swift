//
//  Mandate.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 26.02.2024.
//

import Foundation

public struct DirectDebitMandate: Codable{
    public var mandateId: String?
    public var payerName: String?
    public var payerBban: String?
    public var payerAccountNumber: String?
    public var payerSortCode: String?
    public var reference: String?
    public var serviceUserNumber: String?
    public var originatorName: String?
    public var state: String?
}
