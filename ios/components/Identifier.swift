//
//  Identifier.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 03.01.2024.
//

import Foundation
import SwiftUI

struct Identifier: View{
    @State public var components: [String?] = []
    @State public var scheme: Color.CustomColorScheme = .auto
    
    private var formattedComponents: [String]{
        var components: [String?] = self.components.filter({ el in
            return el != nil && !el!.isEmpty
        })
        
        if (components.isEmpty){
            return [""]
        }
        
        return components as! [String]
    }
    
    var body: some View{
        HStack{
            ForEach(self.formattedComponents.indices, id: \.self){ index in
                Text(self.formattedComponents[index])
                if (index < formattedComponents.count - 1){
                    ZStack{
                        
                    }
                    .frame(width: 6, height: 6)
                    .background(Color.get(.MiddleGray, scheme: self.scheme))
                    .clipShape(Circle())
                }
            }
        }
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .foregroundColor(Color.get(.MiddleGray, scheme: self.scheme))
            .font(.subheadline)
    }
}


struct Identifier_Previews: PreviewProvider {
    static var previews: some View {
        VStack{
            Identifier()
        }.padding()
    }
}
