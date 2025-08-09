//
//  BusinessAddDirector.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 07.12.2023.
//

import Foundation
import SwiftUI

extension BusinessAddDirectorsView{
    var activeDirector: BusinessDirectorsView.BusinessDirector?{
        if (self.Store.onboarding.business.activeDirectorEmail.isEmpty){
            return nil
        }
        return self.Store.onboarding.directors.first(where: {director in
            return director.email.lowercased() == self.Store.onboarding.business.activeDirectorEmail.lowercased()
        })
    }
    
    var isOnboarder: Bool{
        let individualEntity = self.Store.onboarding.individualEntity
        if (individualEntity != nil && individualEntity!.id != nil && self.activeDirector != nil){
            return self.activeDirector!.id == String(individualEntity!.id!)
        }
        return false
    }
}

struct BusinessAddDirectorsView: View, RouterPage {
    @EnvironmentObject var Store: ApplicationStore
    @EnvironmentObject var Error: ErrorHandlingService
    @EnvironmentObject var Router: RoutingController
    
    @State private var loading: Bool = false
    
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var middleName: String = ""
    @State private var email: String = ""
    @State private var phone: String = ""
    
    func submit() async throws{
        self.loading = true
        
        if (self.isOnboarder == false){
            let editableDirectorEmail = self.activeDirector?.email.lowercased()
            let editableDirectorPhone = self.activeDirector?.phone.lowercased().filter("01234567890".contains)
            
            //MARK: Here we should check for email & phone is unique
            let email = self.email.lowercased()
            let phone = self.phone.lowercased().filter("01234567890".contains)
            let clone = self.Store.onboarding.directors.firstIndex(where: { director in
                return (editableDirectorEmail != email && director.email.lowercased() == email) || (editableDirectorPhone != phone && director.phone.lowercased().filter("01234567890".contains) == phone)
            })
            if (clone != nil){
                throw ApplicationError(title: "Unable to add director", message: "Director should have unique email adress and phone")
            }
            let isOwner = (email == self.Store.user.email?.lowercased() || phone == self.Store.user.phone?.lowercased().filter("01234567890".contains))
            if (isOwner){
                throw ApplicationError(title: "Unable to add director", message: "Director should have unique email adress and phone")
            }
            
            if (self.activeDirector != nil){
                let index = self.Store.onboarding.business.directors.firstIndex(where: {director in
                    return director.email.lowercased() == self.Store.onboarding.business.activeDirectorEmail.lowercased()
                })
                if (index != nil){
                    self.Store.onboarding.business.directors[index!] = .init(
                        firstName: self.firstName,
                        lastName: self.lastName,
                        middleName: self.middleName,
                        email: self.email,
                        phone: self.phone,
                        id: self.activeDirector!.id
                    )
                }
            }else{
                self.Store.onboarding.business.directors.append(.init(
                    firstName: self.firstName,
                    lastName: self.lastName,
                    middleName: self.middleName,
                    email: self.email,
                    phone: self.phone,
                    id: ""
                ))
            }
        }
        self.loading = false
        self.Router.goTo(BusinessDirectorsView(), routingType: .backward)
    }
    
    func remove() async throws{
        //Try to remove director
        if (self.activeDirector != nil && self.activeDirector!.id.isEmpty){
            let index = self.Store.onboarding.business.directors.firstIndex(where: {director in
                return director.email.lowercased() == self.activeDirector!.email.lowercased()
            })
            if (index != nil){
                self.Store.onboarding.business.directors.remove(at: index!)
            }
        }
        self.Router.goTo(BusinessDirectorsView(), routingType: .backward)
    }
    
    private var emailValid: Bool{
        return self.email.isEmail()
    }
    
    private var phoneValid: Bool{
        return self.phone.isPhone()
    }
    
    var body: some View {
        GeometryReader{ geometry in
            ScrollView{
                VStack(spacing: 0){
                    HStack(spacing:0){
                        Text(self.activeDirector == nil ? LocalizedStringKey("Add Directors") : LocalizedStringKey("Update Directors"))
                            .foregroundColor(Color.get(.Text))
                            .font(.body.bold())
                        Spacer()
                        if (self.activeDirector != nil && self.activeDirector!.id.isEmpty){
                            Button(LocalizedStringKey("Remove")){
                                Task{
                                    do{
                                        try await self.remove()
                                    }catch(let error){
                                        self.loading = false
                                        self.Error.handle(error)
                                    }
                                }
                            }
                            .foregroundColor(Color.get(.Danger))
                            .disabled(self.loading)
                        }else{
                            Button(LocalizedStringKey("Cancel")){
                                self.Router.goTo(BusinessDirectorsView(), routingType: .backward)
                            }
                            .foregroundColor(Whitelabel.Color(.Primary))
                            .disabled(self.loading)
                        }
                    }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 20)
                    VStack(spacing:24){
                        CustomField(value: self.$firstName, placeholder: "First Name", type: .text)
                            .disabled(self.isOnboarder || self.loading)
                        CustomField(value: self.$lastName, placeholder: "Last Name", type: .text)
                            .disabled(self.isOnboarder || self.loading)
                        CustomField(value: self.$middleName, placeholder: "Middle Name", type: .text)
                            .disabled(self.isOnboarder || self.loading)
                        CustomField(value: self.$email, placeholder: "Email", type: .email)
                            .disabled(self.isOnboarder || self.loading)
                        CustomField(value: self.$phone, placeholder: "Phone", type: .phone)
                            .disabled(self.isOnboarder || self.loading)
                    }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 24)
                    Spacer()
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
                            Text(LocalizedStringKey(self.activeDirector == nil ? "Add a director" : "Update Director"))
                        }
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(self.loading || self.firstName.isEmpty || self.lastName.isEmpty || self.email.isEmpty || self.phone.isEmpty || !self.emailValid || !self.phoneValid)
                        .buttonStyle(.primary())
                        .padding(.horizontal, 16)
                        .loader(self.$loading)
                }
                    .frame(
                        maxWidth: .infinity,
                        minHeight: geometry.size.height - geometry.safeAreaInsets.bottom
                    )
                    .onAppear{
                        if (self.activeDirector != nil){
                            self.firstName = self.activeDirector!.firstName
                            self.lastName = self.activeDirector!.lastName
                            self.middleName = self.activeDirector!.middleName
                            self.email = self.activeDirector!.email
                            self.phone = self.activeDirector!.phone
                        }
                    }
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationTitle("")
        .background(Color.get(.Background))
    }
}

struct BusinessAddDirectorsView_Previews: PreviewProvider {
    static var store: ApplicationStore {
        var store = ApplicationStore()
        return store
    }
    
    static var previews: some View {
        BusinessAddDirectorsView()
            .environmentObject(self.store)
    }
}
