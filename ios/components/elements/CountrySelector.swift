//
//  CountrySelector.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 29.11.2023.
//

import Foundation
import SwiftUI

struct CountrySelector: View {
    @Binding public var value: Array<String>
    public var options: [Option] = []
    
    @State private var showCountryList: Bool = false
    @State private var query: String = ""
    
    var queriedOptions: [Option] {
        if self.query.isEmpty{
            return self.options
        }
        let query = self.query.lowercased()
        return self.options.filter({$0.label.lowercased().contains(query)})
    }
    
    var list: some View{
        ForEach(self.queriedOptions, id: \.id){ option in
            Button{
                self.select(option)
            } label:{
                Text(option.label)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .multilineTextAlignment(.leading)
                    .padding(.horizontal,15)
                    .padding(.vertical,20)
            }
            .background(self.value.firstIndex(of: option.id) != nil ? Whitelabel.Color(.Primary).opacity(0.3) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 9))
            .padding(.horizontal,20)
            .foregroundColor(Color("Text"))
        }
    }
    
    func select(_ option: Option){
        let index = self.value.firstIndex(of: option.id)
        if (index == nil){
            self.value.append(option.id)
        }else{
            self.value.remove(at: index!)
        }
        self.showCountryList = false
    }
    
    var body: some View {
        VStack{
            HStack{
                Button(LocalizedStringKey("Add Countries")){
                    self.showCountryList = true
                }
                .buttonStyle(.secondary(image: "add"))
                Spacer()
            }
            .padding(.bottom, 12)
            Text(LocalizedStringKey("COUNTRIES"))
                .frame(maxWidth: .infinity, alignment: .leading)
                .font(.caption)
                .foregroundColor(Color("PaleBlack"))
                .padding(.vertical, 12)
            
            VStack(spacing:6){
                ForEach(self.value, id: \.self){ id in
                    Button{
                        self.select(.init(id: id, label: ""))
                    } label:{
                        HStack(alignment: .center){
                            Text(self.options.first(where: {$0.id == id})?.label ?? "-")
                                .foregroundColor(Color("Text"))
                            Spacer()
                            ZStack{
                                Image("trash")
                                    .foregroundColor(Color("Danger"))
                            }
                            .frame(width: 24, height: 24)
                            .padding(.leading, 10)
                        }
                    }
                    .padding(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                        .stroke(Color("BackgroundInput"))
                        .foregroundColor(Color.clear)
                        .background(.clear)
                        
                    )
                }
            }
        }.sheet(isPresented: self.$showCountryList){
            VStack{
                SearchField(query: self.$query)
                    .padding()
                ScrollView{
                    self.list
                }
                Spacer()
            }
        }
    }
}

struct CountrySelectorPreview: View {
    @State private var value: Array<String> = []
    var body: some View {
        CountrySelector(value: self.$value, options: [
            .init(id: "1", label: "Option 1"),
            .init(id: "2", label: "Option 2"),
            .init(id: "3", label: "Option 3"),
            .init(id: "4", label: "Option 4")
        ])
            .padding()
    }
}

struct CountrySelectorPreview_Previews: PreviewProvider {
    static var previews: some View {
        CountrySelectorPreview()
    }
}
