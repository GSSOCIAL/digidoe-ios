//
//  Account.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 01.10.2023.
//

import Foundation

public struct Currency: Decodable{
    var id:Int=3
    var iso:String="GBP"
    var symbol:String="£"
    var name:String="Pound sterling"
}

public struct Account: Codable, Identifiable{
    public var availableBalance: Account.AccountAmount
    public var baseCurrencyCode: String
    public var currentBalance: Account.AccountAmount
    public var id: String
    public var identification: Account.AccountIdentifications
    public var ownerName: String
    public var sortOrder: Int16?
    public var title: String
    public var type: String
    public var bankAccount: Account.BankAccount?
    
    public struct AccountAmount: Codable{
        public var currencyCode: String
        public var value: Float
    }
    
    public struct AccountIdentifications: Codable{
        public var accountNumber: String?
        public var bban: String?
        public var iban: String?
        public var id: String
        public var sortCode: String?
    }
    
    public struct BankAccount: Codable{
        public var bank: Account.BankAccount.Bank?
        
        public struct Bank: Codable{
            public var bankLocation: String?
            public var bankName: String?
            public var id: String?
        }
    }
    
    var isEuroAccount: Bool{
        return self.baseCurrencyCode.lowercased() == "eur"
    }
}
