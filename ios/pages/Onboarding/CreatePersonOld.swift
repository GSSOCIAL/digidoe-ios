//
//  CreatePerson.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 22.11.2023.
//

import Foundation
import SwiftUI
/*
extension CreatePersonView{
    func submit() async throws{
        self.loading = true
        //MARK: Check that age gt 18
        let birthday = self.dateOfBirth.asDate()
        if (birthday == nil){
            throw ApplicationError(title: "Application error", message: "Failed to process date of birth")
        }
        let diff = Date() - birthday!
        let months = diff.month ?? 0
        if months < (18*12){
            //MARK: Age not passed - show message & close application
            throw ApplicationError(title: "Age not passed", message: "You must be 18 or older")
        }
        
        self.Store.onboarding.person.givenName = self.firstName
        self.Store.onboarding.person.surName = self.lastName
        self.Store.onboarding.person.middleName = self.middleName
        self.Store.onboarding.person.dateOfBirth = self.dateOfBirth
        self.Store.onboarding.person.countryOfBirthExt = self.country
        self.Store.onboarding.person.email = self.Store.user.email ?? ""
        self.Store.onboarding.person.phone = self.Store.user.phone ?? ""
        self.Store.onboarding.person.genderExt = self.gender
        
        self.loading = false
        self.Router.goTo(CreatePersonAddressView())
    }
    
    var genders: [Option]{
        return self.Store.onboarding.genders.map({
            return .init(
                id: String($0.id),
                label: $0.name
            )
        })
    }
    
    var countries: [Option]{
        return self.Store.onboarding.countries.map({
            return .init(
                id: String($0.id),
                label: $0.name
            )
        })
    }
}

extension CreatePersonView{
    var header: some View{
        ZStack{
            
        }
            .frame(maxWidth: .infinity, maxHeight: 50)
            .padding(.bottom, 16)
    }
}

struct CreatePersonView: View, RouterPage {
    @EnvironmentObject var Store: ApplicationStore
    @EnvironmentObject var Error: ErrorHandlingService
    @EnvironmentObject var Router: RoutingController
    
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var middleName: String = ""
    @State private var dateOfBirth: String = ""
    @State private var country: String = ""
    @State private var gender: String = ""
    
    @State private var loading: Bool = false
    
    var body: some View {
        GeometryReader{ geometry in
            ScrollView{
                VStack(spacing: 0){
                    self.header
                    TitleView(
                        title: LocalizedStringKey("Personal Details"),
                        description: LocalizedStringKey("As stated on your official ID. We will need your name to verify your identity")
                    )
                        .padding(.horizontal, 16)
                    VStack(spacing:24){
                        CustomField(value: self.$firstName, placeholder: "First Name")
                            .id(UUID())
                            .disabled(self.loading)
                        CustomField(value: self.$lastName, placeholder: "Last Name")
                            .id(UUID())
                            .disabled(self.loading)
                        CustomField(value: self.$middleName, placeholder: "Middle Name")
                            .disabled(self.loading)
                        CustomField(value: self.$dateOfBirth, placeholder: "Date of Birth", type: .date)
                            .disabled(self.loading)
                        CustomField(value: self.$country, placeholder: "Country of Birth", type: .select, options: self.countries, searchable: true)
                            .disabled(self.loading)
                        CustomField(value: self.$gender, placeholder: "Gender", type: .select, options: self.genders)
                            .disabled(self.loading)
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
                            Text(LocalizedStringKey("Continue"))
                        }
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(self.loading || self.firstName.isEmpty || self.lastName.isEmpty || self.country.isEmpty || self.gender.isEmpty)
                        .buttonStyle(.primary())
                        .padding(.horizontal, 16)
                        .loader(self.$loading)
                }
                .frame(
                    maxWidth: .infinity,
                    minHeight: geometry.size.height - geometry.safeAreaInsets.bottom
                )
                .onAppear{
                    self.firstName = self.Store.user.person?.givenName ?? ""
                    self.lastName = self.Store.user.person?.surname ?? ""
                    self.middleName = self.Store.user.person?.middleName ?? ""
                    self.dateOfBirth = self.Store.user.person?.dateOfBirth ?? ""
                    self.country = self.Store.user.person?.countryOfBirth ?? ""
                    self.gender = self.Store.user.person?.gender ?? ""
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationTitle("")
        .background(Color.get(.Background))
    }
}

struct CreatePersonView_Previews: PreviewProvider {
    static var store: ApplicationStore {
        var store = ApplicationStore()
        return store
    }
    
    static var previews: some View {
        CreatePersonView()
            .environmentObject(self.store)
    }
}

*/
