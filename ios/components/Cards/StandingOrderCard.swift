//
//  StandingOrderCard.swift
//  DigiDoe Business Banking
//
//  Created by Михайло Картмазов on 29.06.2025.
//

import Foundation
import SwiftUI

struct StandingOrderCard: View{
    @State public var order: PaymentOrderExtendedDto
    
    private var formattedComponents: [String]{
        let components: [String?] = [
            self.order.standingOrder?.state.label,
            "Billed \(self.order.standingOrder?.period.frequency(self.order.standingOrder?.startDate.asDate() ?? Date()) ?? "")",
        ].filter({ el in
            return el != nil && !el!.isEmpty
        })
        
        if (components.isEmpty){
            return []
        }
        
        return components as! [String]
    }
    
    var identifier: some View{
        HStack{
            ForEach(self.formattedComponents.indices, id: \.self){ index in
                let component: String = self.formattedComponents[index]
                Text(component)
                if (index < self.formattedComponents.count - 1){
                    ZStack{
                        
                    }
                    .frame(width: 4, height: 4)
                    .background(Color.get(.PaleBlack))
                    .clipShape(Circle())
                }
            }
        }
            .font(.caption)
            .foregroundColor(Color.get(.PaleBlack))
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    var body: some View{
        VStack(spacing: 5){
            HStack(alignment:.top){
                VStack(spacing: 5){
                    HStack(alignment: .top, spacing: 8){
                        Text(self.order.standingOrder?.description ?? "-")
                            .multilineTextAlignment(.leading)
                            .font(.subheadline.bold())
                            .foregroundColor(Color.get(.Text))
                        Spacer()
                    }
                    self.identifier
                }
                Spacer()
                HStack{
                    if (self.order.standingOrder?.state == .active){
                        ZStack{
                            Image("standing")
                                .foregroundColor(Color.get(.Text))
                        }
                        .frame(width: 34, height: 34)
                    }
                }
            }
            HStack(alignment: .top){
                VStack(alignment: .leading, spacing: 5){
                    Text("Start Date: \((self.order.standingOrder?.startDate.asDate() ?? Date()).asString("dd MMM yyyy"))")
                    if (self.order.standingOrder?.endDate != nil){
                        Text("End Date: \((self.order.standingOrder?.endDate?.asDate() ?? Date()).asString("dd MMM yyyy"))")
                    }
                    if (self.order.standingOrder?.state == .cancelled){
                        Text("Total payments: \((self.order.standingOrder?.totalOperations ?? 0))")
                    }
                    if (self.order.standingOrder?.state == .active && self.order.standingOrder?.nextExecutionDate != nil){
                        Group{
                            Text("Next payment date: ")
                            + Text((self.order.standingOrder?.nextExecutionDate.asDate() ?? Date()).asString("dd MMM yyyy"))
                                .underline()
                        }
                    }
                }
                .font(.caption)
                .foregroundColor(Color.get(.LightGray))
                Spacer()
                Text(String((self.order.amount?.value ?? 0) * -1).formatAsPrice(self.order.amount?.currencyCode.rawValue.uppercased() ?? ""))
                    .font(.body.bold())
                    .foregroundColor(Color.get(.Text))
            }
        }
            .font(.caption.weight(.medium))
            .padding(.horizontal,16)
            .padding(.vertical,12)
            .background(Color.get(.Section))
    }
}
