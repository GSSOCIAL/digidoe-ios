//
//  ApprovalCard.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 24.07.2024.
//

import Foundation
import SwiftUI

struct ApprovalCard: View{
    @State public var item: ListApprovalFlow
    
    private var formattedComponents: [String]{
        let frm = DateFormatter()
        frm.locale = Locale(identifier: "en_US_POSIX")
        frm.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        let itemDate = frm.date(from: item.createdUtc)
        
        var components: [String?] = [
            itemDate?.asString("HH:mm"),
            item.initiator?.userName ?? ""
        ].filter({ el in
            return el != nil && !el!.isEmpty
        })
        
        if (components.isEmpty){
            return []
        }
        
        return components as! [String]
    }
    
    public var status: some View{
        ZStack{
            switch(self.item.state){
            case .approved:
                Text("Approved")
                    .foregroundColor(Color.get(.Active))
            case .rejected:
                Text("Rejected")
                    .foregroundColor(Color.get(.Danger))
            default:
                Text("Processing")
                    .foregroundColor(Color.get(.LightGray))
            }
        }
    }
    
    private var isFraud: Bool{
        if (self.item.has("fraudAlerts")){
            let alerts = self.item.atDictionary("fraudAlerts")
            if (alerts != nil && alerts?.isEmpty == false){
                return true
            }
        }
        return false
    }
    
    var identifier: some View{
        VStack(spacing: 2){
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
                Spacer()
            }
            HStack(spacing:6){
                self.status
                if (self.isFraud){
                    Text("Possible fraud")
                        .font(.caption)
                        .padding(.vertical, 2)
                        .padding(.horizontal, 4)
                        .foregroundColor(Color.white)
                        .background(Color.get(.Danger))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                Spacer()
            }
        }
            .font(.caption)
            .foregroundColor(Color.get(.Text))
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    var body: some View{
        VStack(spacing: 6){
            HStack(alignment:.top){
                Text((self.item.at("payeeContactName") ?? "-").trimmingCharacters(in: .whitespacesAndNewlines))
                    .font(.subheadline.bold())
                    .foregroundColor(Color.get(.Text))
                    .frame(maxWidth: .infinity, alignment: .leading)
                Spacer()
                HStack{
                    Text((self.item.at("amount") ?? "0").formatAsPrice(self.item.at("currency")?.uppercased() ?? ""))
                        .font(.subheadline.bold())
                        .foregroundColor(Color.get(.Text))
                        .overlay(
                            RoundedRectangle(cornerRadius: 2)
                                .foregroundColor(Color.get(.Text))
                                .frame(height: 2)
                                .opacity(0)
                        )
                }
            }
            HStack{
                self.identifier
                Spacer()
            }
            HStack(alignment: .top){
                Text("Ref: \(self.item.at("reference") ?? "")")
                    .foregroundColor(Color.get(.LightGray))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                /*
                Text("Balance: \((self.item.at("balance") ?? "0").formatAsPrice(self.item.at("currency")?.uppercased() ?? ""))")
                    .foregroundColor(Color.get(.LightGray))
                    .frame(maxWidth: .infinity, alignment: .trailing)
                 */
                Spacer()
            }
        }
            .font(.caption.weight(.medium))
            .padding(.horizontal,16)
            .padding(.vertical,12)
            .background(Color.get(.Section))
    }
}
