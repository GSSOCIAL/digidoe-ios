//
//  View.swift
//  DigiDoe Business Banking
//
//  Created by Михайло Картмазов on 06.08.2025.
//

import Foundation
import SwiftUI

struct WhitelabelView: View{
    var body: some View{
        return ZStack{
            ZStack{
                Image("ufo")
                ZStack{
                    Image(Whitelabel.Image(.logoSmall))
                        .resizable()
                        .scaledToFit()
                }
                .frame(
                    width: 68,
                    height: 68
                )
                .offset(
                    x: 6,
                    y: 24
                )
                .rotationEffect(.degrees(17))
            }
        }
    }
}

#Preview {
    WhitelabelView()
}
