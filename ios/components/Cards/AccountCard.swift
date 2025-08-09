//
//  AccountCard.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 01.10.2023.
//

import Foundation
import SwiftUI

struct AccountCard: View{
    @State public var style: AccountCardStyle = .initial
    @State public var account: Account
    @State public var scheme: Color.CustomColorScheme = .auto
    public var editable: Bool = false
    
    enum AccountCardStyle{
        case initial
        case list
        case context
        case short
        case shortContext
    }
    
    private var components: [String] {
        var components: [String] = []
        switch (self.account.baseCurrencyCode.lowercased()){
            case "gbp":
                components = [
                    self.account.identification.accountNumber ?? "",
                    String((self.account.identification.sortCode ?? "").filter("01234567890".contains)).inserting(separator: "-", every: 2),
                ]
            break;
            case "eur":
                if (self.account.identification.iban != nil && self.account.identification.iban?.isEmpty == false){
                    components = [
                        self.account.identification.iban ?? ""
                    ]
                }else{
                    components = [
                        self.account.identification.accountNumber ?? ""
                    ]
                }
            break;
            case "usd":
            if (self.account.identification.accountNumber != nil && self.account.identification.accountNumber?.isEmpty == false){
                components = [
                    self.account.identification.accountNumber ?? ""
                ]
            }else{
                components = [
                    self.account.identification.iban ?? ""
                ]
            }
            default:
            break;
        }
        return components
    }
    
    var identifier: some View{
        HStack{
            ForEach(components.indices, id: \.self){
                Text(components[$0])
                if ($0 < components.count - 1){
                    ZStack{
                        
                    }
                    .frame(width: 6, height: 6)
                    .background(Color.get(.MiddleGray, scheme: self.style == .initial ? .light : self.scheme))
                    .clipShape(Circle())
                }
            }
        }
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .foregroundColor(Color.get(.MiddleGray, scheme: self.style == .initial ? .light : self.scheme))
            .font(.subheadline)
    }
    
    var avatar: some View{
        switch (self.account.baseCurrencyCode.lowercased()){
        case "gbp":
            return Image("GB")
        case "eur":
            return Image("EU")
        case "usd":
            return Image("US")
        default:
            return Image("")
        }
    }
    
    var context: some View{
        HStack{
            ZStack{
                self.avatar
            }
            .frame(width: 40, height: 40)
            .padding(.trailing, 10)
            
            VStack(alignment: .leading,spacing: 0){
                HStack{
                    Text(self.account.ownerName)
                        .font(.body.bold())
                        .multilineTextAlignment(.leading)
                    ZStack{
                        Image("user 1")
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(Whitelabel.Color(.Primary, scheme: self.scheme))
                    }
                    .frame(width: 16, height: 16)
                    Spacer()
                }
                Text(self.account.title)
                    .font(.body)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .multilineTextAlignment(.leading)
                    .padding(.vertical, 4)
                self.identifier
            }
            .foregroundColor(Color.get(.Text, scheme: self.scheme))
        }
        .frame(maxWidth: .infinity)
    }
    
    var availableBalance: Array<Substring> {
        return String(self.account.availableBalance.value).formatAsPrice(self.account.availableBalance.currencyCode.uppercased()).split(separator: ".")
    }
    
    var currentBalance: Array<Substring> {
        return String(self.account.currentBalance.value).formatAsPrice(self.account.currentBalance.currencyCode.uppercased()).split(separator: ".")
    }
    
    var body: some View{
        switch (self.style){
        case .short:
            HStack(spacing:14){
                ZStack{
                    self.avatar
                }
                .frame(width: 38, height: 38)
                VStack(spacing:4){
                    Text(self.account.title)
                        .font(.body.bold())
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .multilineTextAlignment(.leading)
                    self.identifier
                }
                .foregroundColor(Color.get(.Text, scheme: self.scheme))
                Spacer()
            }
        case .shortContext:
            HStack(spacing:0){
                VStack(spacing:4){
                    Text(self.account.title)
                        .font(.body.bold())
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .multilineTextAlignment(.leading)
                    self.identifier
                }
                .foregroundColor(Color.get(.Text, scheme: self.scheme))
                Spacer()
            }
        case .context:
            self.context
        case .initial:
            VStack(spacing:0){
                HStack(alignment:.top){
                    ZStack{
                        self.avatar
                    }
                    .frame(width: 45, height: 45)
                    .padding(.trailing,14)
                    VStack(spacing:2){
                        Text(self.account.title)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .font(.body)
                            .foregroundColor(Color.get(.Text, scheme: .light))
                        self.identifier
                    }
                    if (self.editable){
                        Spacer()
                        VStack{
                            ZStack{
                                Image("edit")
                                    .resizable()
                                    .scaledToFit()
                                    .foregroundColor(Whitelabel.Color(.Primary, scheme: self.scheme))
                            }.frame(width: 24, height: 24)
                        }
                    }
                }
                .padding(.vertical,12)
                .padding(.horizontal,16)
                .background(Color.white.opacity(0.5))
                VStack{
                    HStack{
                        Text("\(self.currentBalance[0]).")
                            .font(.title2.bold())
                        + Text("\(self.currentBalance[1])")
                            .font(.body)
                            .foregroundColor(Color.get(.Gray, scheme: .light))
                        Spacer()
                    }
                    HStack{
                        Text("Available balance: \(String(self.account.availableBalance.value).formatAsPrice(self.account.currentBalance.currencyCode.uppercased()))")
                            .font(.caption)
                            .foregroundColor(Color.get(.Gray, scheme: .light))
                        Spacer()
                    }
                }
                .padding(.vertical,12)
                .padding(.horizontal,16)
                .foregroundColor(Color.get(.Text, scheme: .light))
            }
            .background(Whitelabel.Color(.Tertiary))
            .clipShape(
                RoundedRectangle(cornerRadius: 16)
            )
        case .list:
            HStack{
                ZStack{
                    self.avatar
                }
                .frame(width: 45, height: 45)
                .padding(.trailing,14)
                VStack(alignment: .leading,spacing: 0){
                    HStack{
                        Text("\(self.availableBalance[0]).")
                            .font(.body.bold())
                        + Text(self.availableBalance[1])
                            .font(.caption)
                            .foregroundColor(Color.get(.Gray))
                        Spacer()
                    }
                    .foregroundColor(Color.get(.Text))
                    Text(self.account.title)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .multilineTextAlignment(.leading)
                        .padding(.vertical, 4)
                    self.identifier
                }
                .foregroundColor(Color.get(.Text))
            }
            .frame(maxWidth: .infinity)
            .padding(16)
            .background(
                Color.get(.Section)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
}

struct AccountCards_Previews: PreviewProvider {
    static var previews: some View {
        let account = Account(
            availableBalance: .init(currencyCode: "gbp", value: 1.0089663e+08),
            baseCurrencyCode: "gbp",
            currentBalance: .init(currencyCode: "gbp", value: 10.4),
            id: "",
            identification: .init(
                accountNumber: "00002972",
                bban: "DIGD04063900002972",
                iban: "GB13DIGD04063900002972",
                id: "",
                sortCode: "040639"
            ),
            ownerName: "MISHA KA",
            sortOrder: 1,
            title: "New Account GBP",
            type: "payments"
        )
        VStack{
            AccountCard(account: account, editable: true)
            AccountCard(style: .list, account: account)
            AccountCard(style: .context, account: account)
            AccountCard(style: .short, account: account)
        }
        .padding()
    }
}
