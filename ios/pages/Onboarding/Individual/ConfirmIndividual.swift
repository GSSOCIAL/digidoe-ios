//
//  ConfirmIndividual.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 18.11.2023.
//

import Foundation
import SwiftUI

extension ConfirmIndividualView{
    enum DataGroups{
        case proofIdentity
        case personalAddress
        case currency
        case personName
        case personDateOfBirth
        case personNationality
        case selfie
    }
}

extension ConfirmIndividualView{
    func singleRowContent(label: String, value: String) -> some View{
        VStack{
            HStack{
                Text(LocalizedStringKey(label))
                    .fontWeight(.bold)
                Text(LocalizedStringKey(value))
                Spacer()
            }
        }
    }
    
    func singleValueContent(_ value: String) -> some View{
        VStack{
            HStack{
                Text(LocalizedStringKey(value))
                Spacer()
            }
        }
    }
    
    func getListValue(_ id: String, list: [KycpService.LookUpResponse.LookUpItem]) -> String{
        let option = list.first(where: {String($0.id) == id})
        if (option != nil){
            return String(option!.name)
        }
        return ""
    }
    
    func getListValue(_ ids: Array<String>, list: [KycpService.LookUpResponse.LookUpItem]) -> String{
        return list.filter({ option in
            return ids.firstIndex(of: String(option.id)) != nil
        }).map({
            return String($0.name)
        }).joined(separator: ", ")
    }
}

struct ConfirmIndividualView: View, RouterPage {
    @EnvironmentObject var Store: ApplicationStore
    @EnvironmentObject var Error: ErrorHandlingService
    @EnvironmentObject var Router: RoutingController
    
    @State private var loading: Bool = false
    @State private var page: (any ApplicationRouterPage)?
    @State private var confirmWindow: Bool = false
    
    func submit() async throws{
        self.loading = true
        
        let individualEntity = self.Store.onboarding.individualEntity
        if (individualEntity == nil){
            throw ServiceError(title: "Entity not found", message: "Couldnt find Your Entity")
        }
        //MARK: BE react for string here
        let fields:[String:String] = [
            "GENindisconfirmed": "1"
        ]
        if (self.Store.user.customerId != nil){
            self.Store.onboarding.application.customerId = self.Store.user.customerId!
        }
        self.Store.onboarding.application.finalized = true
        let _ = try await self.Store.onboarding.application.updateEntity(fields, entityId: individualEntity!.id)
        self.loading = false
        
        if (self.Store.onboarding.application.root?.isIndividualEntity == true){
            self.confirmWindow = true;
        }else{
            self.Router.goTo(self.Store.onboarding.currentFlowPage)
        }
    }
    
    func confirm() async throws{
        self.confirmWindow = false
        self.loading = false
        self.Router.goTo(ApplicationInReviewView())
    }
    
    func selfie() -> some View{
        return VStack(spacing:4){
            HStack{
                ZStack{
                    Image("tick-circle")
                }
                .frame(width: 20, height: 20)
                Text(LocalizedStringKey("Selfie Uploaded"))
                    .foregroundColor(Color.get(.Active))
                    .font(.caption)
                Spacer()
            }
        }
    }
    
    func personalAddress() -> some View{
        /*
         let document = ProofOfAddressDocumentTypes.first(where: {$0.key == self.Store.onboarding.individual.proofOfAddressDocumentType})
        var attachments: Array<FileAttachment> = self.Store.onboarding.individual.proofOfAddressUploaded
        */
        return VStack(spacing:4){
            HStack{
                ZStack{
                    Image("tick-circle")
                }
                .frame(width: 20, height: 20)
                Text(LocalizedStringKey("Uploaded"))
                    .foregroundColor(Color.get(.Active))
                    .font(.caption)
                Spacer()
            }
            /*
            if (!attachments.isEmpty && false){
                if (document != nil){
                    HStack{
                        Text(LocalizedStringKey("Type of document:"))
                            .fontWeight(.bold)
                        Text(LocalizedStringKey(document!.label))
                        Spacer()
                    }
                }
                VStack(spacing:4){
                    ForEach(attachments, id: \.id){ attachment in
                        HStack(spacing:4){
                            Button(attachment.fileType?.rawValue ?? "-"){}
                                .buttonStyle(.tag(style:.success))
                            Text(attachment.fileName ?? "-")
                                .font(.caption)
                                .foregroundColor(Color("Text"))
                            Spacer()
                        }
                    }
                }
            }else{
                EmptyView()
            }
             */
            if (self.Store.user.person != nil && self.Store.user.person!.address != nil){
                HStack{
                    Text(LocalizedStringKey("Country:"))
                        .fontWeight(.bold)
                    Text(self.getListValue(String(self.Store.user.person!.address!.countryExtId), list: self.Store.onboarding.countries))
                    Spacer()
                }
                if (self.Store.user.person!.address!.state != nil && !self.Store.user.person!.address!.state!.isEmpty){
                    HStack{
                        Text(LocalizedStringKey("State:"))
                            .fontWeight(.bold)
                        Text(self.Store.user.person!.address!.state!)
                        Spacer()
                    }
                }
                if (self.Store.user.person!.address!.city != nil && !self.Store.user.person!.address!.city!.isEmpty){
                    HStack{
                        Text(LocalizedStringKey("City:"))
                            .fontWeight(.bold)
                        Text(self.Store.user.person!.address!.city!)
                        Spacer()
                    }
                }
                if (!self.Store.user.person!.address!.street.isEmpty){
                    HStack{
                        Text(LocalizedStringKey("Street:"))
                            .fontWeight(.bold)
                        Text(self.Store.user.person!.address!.street)
                        Spacer()
                    }
                }
                if (self.Store.user.person!.address!.building != nil && !self.Store.user.person!.address!.building!.isEmpty){
                    HStack{
                        Text(LocalizedStringKey("Building:"))
                            .fontWeight(.bold)
                        Text(self.Store.user.person!.address!.building!)
                        Spacer()
                    }
                }
                if (self.Store.user.person!.address!.postCode != nil && !self.Store.user.person!.address!.postCode!.isEmpty){
                    HStack{
                        Text(LocalizedStringKey("Postcode:"))
                            .fontWeight(.bold)
                        Text(self.Store.user.person!.address!.postCode!)
                        Spacer()
                    }
                }
            }
        }
    }
    
    func proofOfIdentityContent() -> some View{
        return Group{
            VStack(spacing: 4){
                HStack{
                    ZStack{
                        Image("tick-circle")
                    }
                    .frame(width: 20, height: 20)
                    Text(LocalizedStringKey("Uploaded"))
                        .foregroundColor(Color.get(.Active))
                        .font(.caption)
                    Spacer()
                }
            }
        }
    }
    
    func group(_ type: DataGroups) -> some View{
        var label: String = ""
        var icon: String = ""
        var container: (any View)? = nil
        
        switch (type){
        case .proofIdentity:
            label = "Proof your indentity"
            icon = "document-cloud"
            container = self.proofOfIdentityContent()
        case .personalAddress:
            label = "Personal Address"
            icon = "location"
            container = self.personalAddress()
        case .currency:
            label = "In which currency would you prefer to open your individual account?"
            icon = "moneys"
            if (self.individualEntity != nil){
                container = self.singleRowContent(
                    label: "Currency:",
                    value: self.getListValue(self.individualEntity!.at("GENcorporateservices") ?? "",list: self.Store.onboarding.corporateServices)
                )
            }
        case .personName:
            label = "Full name"
            icon = "user"
            container = self.singleValueContent([self.Store.user.person?.givenName ?? "", self.Store.user.person?.surname ?? ""].joined(separator: " "))
        case .personDateOfBirth:
            label = "Date Of Birth"
            icon = "calendar"
            container = self.singleValueContent(self.Store.user.person?.dateOfBirth ?? "")
        case .selfie:
            label = "Identity Verification"
            icon = "camera"
            container = self.selfie()
        case .personNationality:
            label = "Nationality"
            icon = "courthouse"
            container = self.singleValueContent(self.getListValue(String(self.Store.user.person?.address?.countryExtId ?? 0), list: self.Store.onboarding.countries))
        }
        
        return HStack(alignment:.top, spacing: 12){
            ZStack{
                Image(icon)
                    .foregroundColor(Whitelabel.Color(.Primary))
            }
                .frame(width: 48, height: 48)
                .background(Whitelabel.Color(.Primary).opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            VStack{
                Text(LocalizedStringKey(label))
                    .foregroundColor(Color.get(.Text))
                    .font(.caption.bold())
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Group{
                    if (container != nil){
                        AnyView(container!)
                    }
                }
                    .foregroundColor(Color.get(.LightGray))
                    .font(.caption)
            }
            Spacer()
        }
            .padding(10)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.get(.BackgroundInput))
                .foregroundColor(Color.clear)
                .background(.clear)
            )
            .padding(.horizontal, 16)
    }
    
    var individualEntity: KYCEntity?{
        return self.Store.onboarding.individualEntity
    }
    
    var body: some View {
        GeometryReader{ geometry in
            ZStack{
                ScrollView{
                    VStack(spacing: 0){
                        Header(back:{
                            self.Router.goTo(ProofOfAddressView(), routingType: .backward)
                        }, title: "")
                        .padding(.bottom, 16)
                        TitleView(
                            title: LocalizedStringKey("Confirm your Personal Details"),
                            description: LocalizedStringKey("Please, check all  your information that you uploaded"))
                            .padding(.horizontal, 16)
                        VStack(spacing:0){
                            Text(LocalizedStringKey("PERSONAL INFORMATION"))
                                .font(.caption)
                                .foregroundColor(Color("PaleBlack"))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                            VStack(spacing:12){
                                self.group(.personName)
                                self.group(.personDateOfBirth)
                                self.group(.personNationality)
                            }
                        }
                        if (individualEntity != nil && individualEntity!.has("GENcorporateservices")){
                            VStack(spacing:0){
                                Text(LocalizedStringKey("ACCOUNT PREFERENCES"))
                                    .font(.caption)
                                    .foregroundColor(Color("PaleBlack"))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                VStack(spacing:12){
                                    self.group(.currency)
                                }
                            }
                        }
                        VStack(spacing:0){
                            Text(LocalizedStringKey("IDENTITY VERIFICATION"))
                                .font(.caption)
                                .foregroundColor(Color("PaleBlack"))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                            VStack(spacing:12){
                                self.group(.proofIdentity)
                                self.group(.selfie)
                            }
                        }
                        
                        VStack(spacing:0){
                            Text(LocalizedStringKey("ADDRESS VERIFICATION"))
                                .font(.caption)
                                .foregroundColor(Color("PaleBlack"))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                            VStack(spacing:12){
                                self.group(.personalAddress)
                            }
                        }
                            .padding(.bottom, geometry.safeAreaInsets.bottom * 2 + 40)
                        Spacer()
                    }
                    .frame(
                        maxWidth: .infinity,
                        minHeight: geometry.size.height - geometry.safeAreaInsets.bottom
                    )
                }.overlay(
                    VStack{
                        Button{
                            Task{
                                do{
                                    try await self.submit()
                                }catch(let error){
                                    self.loading = false
                                    self.Error.handle(error)
                                }
                            }
                        } label: {
                            HStack{
                                Text(LocalizedStringKey("Confirm"))
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .disabled(self.loading)
                        .buttonStyle(.primary())
                        .padding(.horizontal, 16)
                        .loader(self.$loading)
                    }
                        .ignoresSafeArea()
                        .padding(.vertical, 12)
                        .padding(.bottom, geometry.safeAreaInsets.bottom * 2 + 12)
                        .background(Color.get(.Background))
                        .compositingGroup()
                        .cornerRadius(16, corners: [.topLeft, .topRight])
                        .offset(y: geometry.safeAreaInsets.bottom)
                        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: -4)
                    , alignment: .bottom
                )
                //MARK: Popup
                PresentationSheet(isPresented: self.$confirmWindow){
                    VStack{
                        Image("success-splash")
                        Text("Thank you for providing the details.")
                            .font(.title.bold())
                            .foregroundColor(Color.get(.Text))
                            .multilineTextAlignment(.center)
                            .padding(.bottom,1)
                        Text("Your application has been successfully submitted. We normally take about 24 hours to get the account ready, will notify you when it’s ready.")
                            .font(.subheadline)
                            .foregroundColor(Color.get(.LightGray))
                            .multilineTextAlignment(.center)
                            .padding(.bottom,20)
                        
                        Button("OK"){
                            Task{
                                do{
                                    try await self.confirm()
                                }catch(let error){
                                    self.loading = false
                                    self.Error.handle(error)
                                }
                            }
                        }
                        .buttonStyle(.secondary())
                    }
                    .padding(20)
                    .padding(.top,10)
                    .padding(.bottom, geometry.safeAreaInsets.bottom)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationTitle("")
        .background(Color.get(.Background))
    }
}

struct ConfirmIndividualView_Previews: PreviewProvider {
    static var store: ApplicationStore {
        var store = ApplicationStore()
        return store
    }
    
    static var previews: some View {
        ConfirmIndividualView()
            .environmentObject(self.store)
    }
}
