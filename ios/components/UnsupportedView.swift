//
//  UnsupportedView.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 02.10.2023.
//

import Foundation
import SwiftUI

struct UnsupportedView: View{
    var body: some View{
        ZStack{
            Text("Unsopported view")
                .padding(16)
                .frame(maxWidth: .infinity)
                .foregroundColor(Color("LightGray"))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color("Divider"), style: .init(lineWidth:1, dash: [2,2]))
                )
        }
    }
}

struct UnsupportedView_Previews: PreviewProvider {
    static var previews: some View {
        UnsupportedView()
    }
}
