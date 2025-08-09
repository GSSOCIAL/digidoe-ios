//
//  ContactCard.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 02.01.2024.
//

import Foundation
import SwiftUI

struct ContactCard: View{
    @State public var style: ContactCardStyle = .initial
    @State public var contact: Contact
    @State public var scheme: Color.CustomColorScheme = .auto
    
    @State private var detailsShown: Bool = false
    
    public var handler: ((Contact)->Void)? = nil
    public var actionsHandler: ((Contact)->Void)?
    
    enum ContactCardStyle{
        case initial
        case list
    }
    
    private var components: [String] {
        var components: [String?] = []
        switch (self.contact.currency.lowercased()){
            case "gbp":
                components = [
                    self.contact.details.accountNumber,
                    String((self.contact.details.sortCode ?? "").filter("01234567890".contains)).inserting(separator: "-", every: 2)
                ]
            break;
            case "eur", "usd":
            if (self.contact.details.iban != nil && self.contact.details.iban?.isEmpty == false){
                components = [
                    self.contact.details.iban
                ]
            }else{
                components = [
                    self.contact.details.accountNumber ?? ""
                ]
            }
            break;
            default:
            break;
        }
        
        components = components.filter({ el in
            return el != nil && !el!.isEmpty
        })
        
        if (components.isEmpty){
            return [""]
        }
        return components as! [String]
    }
    
    var identifier: some View{
        HStack{
            ForEach(components.indices, id: \.self){
                Text(components[$0])
                if ($0 < components.count - 1){
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
    
    var avatar: some View{
        return Image("dd-icon")
            .resizable()
            .scaledToFit()
            .frame(width: 20)
    }
    
    var context: some View{
        HStack(spacing:8){
            ZStack{
                self.avatar
            }
            .frame(width: 38, height: 38)
            .background(Color.get(.PaleBlack).opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 4))
            
            VStack{
                HStack(spacing:4){
                    Text(self.contact.accountHolderName)
                        .font(.subheadline.bold())
                        .foregroundColor(Color.get(.Text, scheme: self.scheme))
                        .multilineTextAlignment(.leading)
                    ZStack{
                        Image(self.contact.details.legalType == .PRIVATE ? "user 1" : "building-3")
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(Color.get(.MiddleGray, scheme: self.scheme))
                    }
                    .frame(width: 16, height: 16)
                    if(isContactDetailsMissing(self.contact)){
                        ZStack{
                            Image("danger-small")
                                .resizable()
                                .scaledToFit()
                                .foregroundColor(Color.get(.MiddleGray, scheme: self.scheme))
                        }
                        .frame(width: 16, height: 16)
                    }
                    Spacer()
                }
                    .frame(minHeight: 18)
                VStack{
                    self.identifier
                    if((self.contact.currency.lowercased() == "eur" || self.contact.currency.lowercased() == "usd") && self.contact.details.iban != nil && self.contact.details.iban?.isEmpty == false && self.contact.details.swiftCode != nil){
                        Text(self.contact.details.swiftCode!)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .foregroundColor(Color.get(.MiddleGray, scheme: self.scheme))
                            .font(.subheadline)
                    }
                }
                    .frame(minHeight: 18)
            }
        }
    }
    
    var body: some View{
        switch(self.style){
        case .list:
            ZStack{
                VStack{
                    HStack{
                        if (self.handler != nil){
                            Button{
                                self.handler!(self.contact)
                            } label: {
                                self.context
                            }
                        }else{
                            self.context
                        }
                        VStack(spacing:6){
                            if (self.actionsHandler != nil){
                                Button{
                                    self.actionsHandler!(self.contact)
                                } label: {
                                    VStack(spacing: 1){
                                        ForEach(1...3, id: \.self){ _ in
                                            Circle()
                                                .frame(width: 4, height: 4)
                                                .foregroundColor(Color.get(.MiddleGray, scheme: self.scheme))
                                        }
                                    }
                                    .frame(height: 16)
                                }
                            }
                            Button{
                                self.detailsShown = !self.detailsShown
                            } label: {
                                ZStack{
                                    Image("arrow-d")
                                        .resizable()
                                        .scaledToFit()
                                }
                                .frame(width: 16, height: 16)
                                .rotationEffect(self.detailsShown ? .degrees(180) : .degrees(0))
                                .foregroundColor(Color.get(.MiddleGray, scheme: self.scheme))
                            }
                        }
                    }
                    if (self.detailsShown){
                        VStack(spacing:0){
                            Divider()
                                .overlay(Color.get(.LightGray, scheme: self.scheme))
                                .padding(.vertical, 8)
                            VStack(spacing:0){
                                if (self.contact.details.address?.countryName != nil && !self.contact.details.address!.countryName!.isEmpty){
                                    HStack{
                                        Text("Country:")
                                            .foregroundColor(Color.get(.LightGray, scheme: self.scheme))
                                            .frame(width: 80, alignment: .leading)
                                        Spacer()
                                        Text(self.contact.details.address!.countryName!)
                                            .font(.subheadline.bold())
                                            .foregroundColor(Color.get(.Text, scheme: self.scheme))
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .multilineTextAlignment(.leading)
                                    }
                                }
                                if (self.contact.details.address?.state != nil && !self.contact.details.address!.state!.isEmpty){
                                    HStack(alignment:.top){
                                        Text("State:")
                                            .foregroundColor(Color.get(.LightGray, scheme: self.scheme))
                                            .frame(width: 80, alignment: .leading)
                                        Spacer()
                                        Text(self.contact.details.address!.state!)
                                            .font(.subheadline.bold())
                                            .foregroundColor(Color.get(.Text, scheme: self.scheme))
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .multilineTextAlignment(.leading)
                                    }
                                }
                                if (self.contact.details.address?.city != nil && !self.contact.details.address!.city!.isEmpty){
                                    HStack(alignment:.top){
                                        Text("City:")
                                            .foregroundColor(Color.get(.LightGray, scheme: self.scheme))
                                            .frame(width: 80, alignment: .leading)
                                        Spacer()
                                        Text(self.contact.details.address!.city!)
                                            .font(.subheadline.bold())
                                            .foregroundColor(Color.get(.Text, scheme: self.scheme))
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .multilineTextAlignment(.leading)
                                    }
                                }
                                if (self.contact.details.address?.street != nil && !self.contact.details.address!.street!.isEmpty){
                                    HStack(alignment:.top){
                                        Text("Street:")
                                            .foregroundColor(Color.get(.LightGray, scheme: self.scheme))
                                            .frame(width: 80, alignment: .leading)
                                        Spacer()
                                        Text(self.contact.details.address!.street!)
                                            .font(.subheadline.bold())
                                            .foregroundColor(Color.get(.Text, scheme: self.scheme))
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .multilineTextAlignment(.leading)
                                    }
                                }
                                if (self.contact.details.address?.building != nil && !self.contact.details.address!.building!.isEmpty){
                                    HStack(alignment:.top){
                                        Text("Building:")
                                            .foregroundColor(Color.get(.LightGray, scheme: self.scheme))
                                            .frame(width: 80, alignment: .leading)
                                        Spacer()
                                        Text(self.contact.details.address!.building!)
                                            .font(.subheadline.bold())
                                            .foregroundColor(Color.get(.Text, scheme: self.scheme))
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .multilineTextAlignment(.leading)
                                    }
                                }
                                if (self.contact.details.address?.postCode != nil && !self.contact.details.address!.postCode!.isEmpty){
                                    HStack(alignment:.top){
                                        Text("Postcode:")
                                            .foregroundColor(Color.get(.LightGray, scheme: self.scheme))
                                            .frame(width: 80, alignment: .leading)
                                        Text(self.contact.details.address!.postCode!)
                                            .font(.subheadline.bold())
                                            .foregroundColor(Color.get(.Text, scheme: self.scheme))
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .multilineTextAlignment(.leading)
                                    }
                                }
                            }
                            .font(.subheadline)
                        }
                    }
                }
                .padding(16)
                .background(Color.get(.Section, scheme: self.scheme))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        case .initial:
            self.context
        }
    }
}

struct ContactCards_Previews: PreviewProvider {
    static var previews: some View {
        let contact = Contact(
            type: .sortCode,
            currency: "gbp",
            accountHolderName: "OWNER NAME",
            details: .init(
                legalType: .PRIVATE, 
                address: .init(
                    countryCode: "",
                    state: "",
                    city: "",
                    street: "",
                    building: "",
                    postCode: "",
                    countryName: "United Kingdom")
            )
        )
        VStack{
            ContactCard(contact: contact)
            ContactCard(style: .list, contact: contact)
        }
        .padding()
    }
}

