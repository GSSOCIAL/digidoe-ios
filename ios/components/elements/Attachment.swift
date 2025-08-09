//
//  Attachment.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 18.11.2023.
//

import Foundation
import SwiftUI

struct Attachment: View {
    public var name: String = ""
    public var type: FileAttachment.mimeTypesLabel?
    public var documentType: UploadIdentityView.DocumentType? = nil
    
    private var attachmentTypeLabel: String{
        return self.type?.rawValue ?? " - "
    }
    
    init(name: String, type: FileAttachment.mimeTypesLabel?, documentType: UploadIdentityView.DocumentType? = nil){
        self.name = name
        self.type = type
        self.documentType = documentType
    }
    
    var body: some View {
        if self.type != nil{
            HStack(alignment: .center){
                ZStack{
                    Text(self.attachmentTypeLabel)
                        .font(.caption)
                }
                .frame(width: 48,height: 48)
                    .background(Color("Pending").opacity(0.14))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                Text(self.name)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(Color("Text"))
                Spacer()
                if (self.documentType != nil){
                    ZStack{
                        Image(self.documentType!.image)
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(Whitelabel.Color(.Primary))
                            .frame(width: 24)
                    }
                        .frame(width:48,height:48)
                        .background(Whitelabel.Color(.Primary).opacity(0.2))
                        .cornerRadius(12)
                }
            }
            .padding(10)
            .overlay(
                RoundedRectangle(cornerRadius: Styles.cornerRadius)
                    .stroke(Color("BackgroundInput"))
            )
        }
    }
}

struct Attachment_Previews: PreviewProvider {
    static var previews: some View {
        Attachment(name:"Passport.jpg",type:.jpg)
    }
}
