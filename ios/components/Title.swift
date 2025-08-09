//
//  Title.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 17.11.2023.
//

import Foundation
import SwiftUI

struct TitleView: View {
    @State public var title: LocalizedStringKey?
    @State public var description: LocalizedStringKey?
    
    var body: some View {
        VStack(spacing: 4){
            if self.title != nil{
                Text(self.title!)
                    .font(.title.bold())
                    .frame(maxWidth: .infinity,alignment: .leading)
                    .foregroundColor(Color("Text"))
                    .padding(.bottom,1)
            }
            if self.description != nil{
                Text(self.description!)
                    .font(.body)
                    .frame(maxWidth: .infinity,alignment: .leading)
                    .foregroundColor(Color("LightGray"))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct TitleView_Previews: PreviewProvider {
    static var previews: some View {
        VStack{
            TitleView(title: LocalizedStringKey("Personal Details"), description: LocalizedStringKey("As stated on your official ID . We will need your name to verify your identity"))
                .padding(.horizontal, 16)
            Spacer()
        }
    }
}
