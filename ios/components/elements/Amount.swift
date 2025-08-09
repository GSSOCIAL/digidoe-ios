//
//  Amount.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 07.10.2024.
//

import Foundation
import SwiftUI

struct Amount: View{
    @State var amount: String = "0.00"
    
    var sequence: Array<Substring> {
        return self.amount.split(separator: ".")
    }
    
    var body: some View{
        Group{
            Text("\(self.sequence[0]).")
            + Text(self.sequence[1])
                .font(.caption)
        }
            .font(.body.bold())
    }
}

struct Amount_Previews: PreviewProvider {
    static var previews: some View {
        VStack{
            Amount(amount: "GBP14.50")
        }
        .padding()
    }
}

