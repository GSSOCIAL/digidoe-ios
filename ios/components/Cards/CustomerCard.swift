//
//  CustomerCard.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 09.01.2024.
//

import Foundation
import SwiftUI
import CoreData

struct CustomerCard: View{
    @State public var style: CustomerCardStyle = .initial
    @State public var customer: CoreCustomer
    
    enum CustomerCardStyle{
        case initial
        case list
    }
    
    var avatar: some View{
        return Image("dd-icon")
            .resizable()
            .scaledToFit()
    }
    
    var customerState: String{
        switch (self.customer.state?.lowercased()){
        case "active":
            return "Active"
        case "new":
            return "Onboarding"
        case "review":
            return "Review"
        default:
            return ""
        }
    }
    
    var customerStateColor: Color{
        switch (self.customer.state?.lowercased()){
        case "active":
            return Whitelabel.Color(.Primary)
        case "new":
            return Color.get(.LightGray)
        case "review":
            return Color.get(.LightGray)
        default:
            return Color.get(.LightGray)
        }
    }
    
    var context: some View{
        HStack(spacing: 14){
            ZStack{
                self.avatar
                    .frame(maxWidth: 26)
            }
                .frame(width: 45, height: 45)
                .background(Color.get(.Background))
                .clipShape(Circle())
            VStack(spacing: 2){
                Text(self.customer.name ?? "–")
                    .font(.body.bold())
                    .foregroundColor(Color.get(.Text))
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(self.customerState)
                    .font(.body)
                    .foregroundColor(self.customerStateColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            Spacer()
        }
    }
    
    var body: some View{
        switch(self.style){
        case .list:
            self.context
                .padding(.vertical,12)
                .padding(.horizontal,16)
                .background(Color.get(.Section))
                .clipShape(RoundedRectangle(cornerRadius: 16))
        case .initial:
            self.context
        }
    }
}
