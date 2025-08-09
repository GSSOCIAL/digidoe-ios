//
//  TransactionCard.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 02.10.2023.
//

import Foundation
import SwiftUI

struct TransactionCard: View{
    @State public var transaction: Transaction
    
    private var formattedComponents: [String]{
        var components: [String?] = [
            self.transaction.DateObject()?.asStringDateTime(),
            self.transaction.bankTransactionAccountOwnerName,
        ].filter({ el in
            return el != nil && !el!.isEmpty
        })
        
        if (components.isEmpty){
            return []
        }
        
        return components as! [String]
    }
    
    public var transactionStatus: some View{
        ZStack{
            switch(self.transaction.currentState){
            case .completed:
                Text("Completed")
                    .foregroundColor(Color.get(.Active))
            case .failed:
                Text("Failed")
                    .foregroundColor(Color.get(.Danger))
            case .pending:
                Text("Pending")
                    .foregroundColor(Color.get(.LightGray))
            default:
                Text(self.transaction.currentState.rawValue)
            }
        }
    }
    
    var identifier: some View{
        HStack{
            ForEach(self.formattedComponents.indices, id: \.self){ index in
                let component: String = self.formattedComponents[index]
                Text(component)
                ZStack{
                    
                }
                .frame(width: 6, height: 6)
                .background(Color.get(.MiddleGray))
                .clipShape(Circle())
            }
            self.transactionStatus
        }
            .font(.caption)
            .foregroundColor(Color.get(.Text))
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    var body: some View{
        VStack{
            HStack(alignment:.top){
                HStack(alignment: .top, spacing: 8){
                    if (self.transaction.hasAttachments){
                        ZStack{
                            Image("Content, Edit - Liner")
                                .resizable()
                                .foregroundColor(Color.get(.LightGray))
                        }
                        .frame(width: 14, height: 14)
                    }
                    Text(self.transaction.counterpartName ?? "-")
                        .multilineTextAlignment(.leading)
                        .font(.subheadline.bold())
                        .foregroundColor(Color.get(.Text))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                Spacer()
                HStack{
                    Text(String(Double(self.transaction.amount)).formatAsPrice(self.transaction.currency.uppercased()))
                        .font(.subheadline.bold())
                        .foregroundColor(Color.get(.Text))
                        .overlay(
                            RoundedRectangle(cornerRadius: 2)
                                .foregroundColor(Color.get(.Text))
                                .frame(height: 2)
                                .opacity(self.transaction.currentState == .failed ? 1 : 0)
                        )
                }
            }
            HStack{
                self.identifier
                Spacer()
            }
            HStack(alignment: .top){
                Group{
                    Text("Ref: \(self.transaction.reference ?? "-")")
                }
                    .foregroundColor(Color.get(.LightGray))
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                /*
                 if (self.transaction.currentState != .pending && self.transaction.currentState != .failed){
                    Text("Balance: \(String(Double(self.transaction.balance)).formatAsPrice(self.transaction.currency.uppercased()))")
                        .foregroundColor(Color.get(.LightGray))
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                 */
                Spacer()
                if (self.transaction.hasStandingOrder && self.transaction.amount < 0){
                    ZStack{
                        Image("standing")
                            .foregroundColor(Color.get(.Text))
                    }
                    .frame(width: 20, height: 20)
                }
            }
        }
            .font(.caption.weight(.medium))
            .padding(.horizontal,16)
            .padding(.vertical,12)
            .background(Color.get(.Section))
    }
}
