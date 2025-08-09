//
//  AccountIdentification.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 02.08.2024.
//

import Foundation
import SwiftUI

struct AccountIdentification: View{
    var currency: String?
    var accountNumber: String?
    var sortCode: String?
    var iban: String?
    var swift: String?
    
    init(currency: String? = nil, accountNumber: String? = nil, sortCode: String? = nil, iban: String? = nil, swift: String? = nil) {
        self.currency = currency
        self.accountNumber = accountNumber
        self.sortCode = sortCode
        self.iban = iban
        self.swift = swift
    }
    
    init(_ data: AccountSimpleDto?){
        self.currency = data?.baseCurrencyCode
        self.accountNumber = data?.identification.accountNumber
        self.sortCode = data?.identification.sortCode
        self.iban = data?.identification.iban
        self.swift = nil
    }
    
    init(_ data: RecipientSimpleDto?){
        self.currency = data?.currency
        self.accountNumber = data?.accountNumber
        self.sortCode = data?.sortCode
        self.iban = data?.iban
        self.swift = data?.swiftCode
    }
    
    init(_ data: TransactionsService.CustomerTransactionModelResult.CustomerTransactionModel.TransactionPartyDetailsModel?, currency: String?){
        self.currency = currency
        self.accountNumber = data?.identification?.accountNumber
        self.sortCode = data?.identification?.sortCode
        self.iban = data?.identification?.iban
        self.swift = data?.identification?.swiftCode
    }
    
    var body: some View{
        VStack(spacing:8){
            switch(currency?.lowercased()){
            case "gbp":
                HStack(alignment: .top, spacing:0){
                    Text("Account Number")
                        .frame(maxWidth: 130, alignment: .leading)
                        .font(.subheadline.bold())
                        .foregroundColor(Color.get(.LightGray))
                    Text(self.accountNumber ?? "–")
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .font(.subheadline.bold())
                        .foregroundColor(Color.get(.MiddleGray))
                }
                HStack(alignment: .top, spacing:0){
                    Text("Sort Code")
                        .frame(maxWidth: 130, alignment: .leading)
                        .font(.subheadline.bold())
                        .foregroundColor(Color.get(.LightGray))
                    Text((self.sortCode ?? "–").filter("01234567890".contains).inserting(separator: "-", every: 2))
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .font(.subheadline.bold())
                        .foregroundColor(Color.get(.MiddleGray))
                }
            case "eur":
                if (self.accountNumber != nil && self.accountNumber!.isEmpty == false){
                    HStack(alignment: .top, spacing:0){
                            Text("Wallet")
                                .frame(maxWidth: 130, alignment: .leading)
                                .font(.subheadline.bold())
                                .foregroundColor(Color.get(.LightGray))
                            Text(self.accountNumber ?? "–")
                                .frame(maxWidth: .infinity, alignment: .trailing)
                                .font(.subheadline.bold())
                                .foregroundColor(Color.get(.MiddleGray))
                    }
                }else{
                    if (self.iban != nil && self.iban?.isEmpty == false){
                        HStack(alignment: .top, spacing:0){
                            Text("IBAN")
                                .frame(maxWidth: 130, alignment: .leading)
                                .font(.subheadline.bold())
                                .foregroundColor(Color.get(.LightGray))
                            Text(self.iban ?? "–")
                                .frame(maxWidth: .infinity, alignment: .trailing)
                                .font(.subheadline.bold())
                                .foregroundColor(Color.get(.MiddleGray))
                        }
                    }
                    if (self.swift != nil && self.swift?.isEmpty == false){
                        HStack(alignment: .top, spacing:0){
                            Text("SWIFT/BIC")
                                .frame(maxWidth: 130, alignment: .leading)
                                .font(.subheadline.bold())
                                .foregroundColor(Color.get(.LightGray))
                            Text(self.swift ?? "–")
                                .frame(maxWidth: .infinity, alignment: .trailing)
                                .font(.subheadline.bold())
                                .foregroundColor(Color.get(.MiddleGray))
                        }
                    }
                }
            case "usd":
                if (self.accountNumber != nil && self.accountNumber!.isEmpty == false){
                    HStack(alignment: .top, spacing:0){
                            Text("Wallet number")
                                .frame(maxWidth: 130, alignment: .leading)
                                .font(.subheadline.bold())
                                .foregroundColor(Color.get(.LightGray))
                            Text(self.accountNumber ?? "–")
                                .frame(maxWidth: .infinity, alignment: .trailing)
                                .font(.subheadline.bold())
                                .foregroundColor(Color.get(.MiddleGray))
                    }
                }else{
                    if (self.iban != nil && self.iban?.isEmpty == false){
                        HStack(alignment: .top, spacing:0){
                            Text("Account Number/IBAN")
                                .frame(maxWidth: 130, alignment: .leading)
                                .font(.subheadline.bold())
                                .foregroundColor(Color.get(.LightGray))
                            Text(self.iban ?? "–")
                                .frame(maxWidth: .infinity, alignment: .trailing)
                                .font(.subheadline.bold())
                                .foregroundColor(Color.get(.MiddleGray))
                        }
                    }
                    if (self.swift != nil && self.swift?.isEmpty == false){
                        HStack(alignment: .top, spacing:0){
                            Text("SWIFT/BIC")
                                .frame(maxWidth: 130, alignment: .leading)
                                .font(.subheadline.bold())
                                .foregroundColor(Color.get(.LightGray))
                            Text(self.swift ?? "–")
                                .frame(maxWidth: .infinity, alignment: .trailing)
                                .font(.subheadline.bold())
                                .foregroundColor(Color.get(.MiddleGray))
                        }
                    }
                }
            default:
                ZStack{
                    
                }
            }
        }
    }
}

struct AccountIdentification_Previews: PreviewProvider {
    static var data1: TransactionsService.CustomerTransactionModelResult.CustomerTransactionModel.TransactionPartyDetailsModel = TransactionsService.CustomerTransactionModelResult.CustomerTransactionModel.TransactionPartyDetailsModel(
        accountId: "",
        accountIdentification: "",
        identification: .init(
            accountNumber: "00004589",
            bban: "DIGD04063900004589",
            iban: "GB04DIGD04063900004589",
            sortCode: "040639",
            swiftCode: "WVMLMPRRXXX"
        ),
        partyDetails: .init(
            name: "",
            type: .person
        )
    )
    
    static var previews: some View {
        VStack{
            AccountIdentification(data1, currency: "gbp")
            Divider()
            AccountIdentification(data1, currency: "eur")
            Divider()
            AccountIdentification(data1, currency: "usd")
            Spacer()
        }.padding()
    }
}
