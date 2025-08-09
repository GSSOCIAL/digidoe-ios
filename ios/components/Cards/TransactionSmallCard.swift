//
//  TransactionSmallCard.swift
//  DigiDoe Business Banking
//
//  Created by Михайло Картмазов on 07.07.2025.
//

import SwiftUI
import Foundation

struct TransactionSmallCard: View{
    @State public var transaction: Transaction
    
    var body: some View{
        HStack{
            VStack(alignment:.leading, spacing: 2){
                Text(self.transaction.creationDate.asDate()?.asString("dd MMM yyyy") ?? "")
                    .font(.subheadline.bold())
                    .foregroundColor(Color.get(.Text))
                HStack(alignment: .center, spacing: 4){
                    Text(self.transaction.creationDate.asDate()?.asString("HH:mm") ?? "")
                        .font(.caption)
                        .foregroundColor(Color.get(.PaleBlack))
                    ZStack{
                        
                    }
                    .frame(width: 4, height: 4)
                    .background(Color.get(.PaleBlack))
                    .clipShape(Circle())
                    Text(self.transaction.currentState.label)
                        .font(.subheadline)
                        .foregroundColor(self.transaction.currentState.color)
                }
            }
            Spacer()
            VStack(alignment:.trailing, spacing: 2){
                Text(String(Double(self.transaction.amount)).formatAsPrice(self.transaction.currency.uppercased()))
                    .font(.subheadline.bold())
                    .foregroundColor(Color.get(.Text))
                ZStack{
                    Image("Content, Edit - Liner")
                        .resizable()
                        .foregroundColor(Color.get(.LightGray))
                }
                .frame(width: 14, height: 14)
            }
        }
    }
}

