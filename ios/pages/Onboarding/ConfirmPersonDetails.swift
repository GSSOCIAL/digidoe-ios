//
//  ConfirmPersonDetails.swift
//  DigiDoe Business Banking
//
//  Created by Михайло Картмазов on 30.04.2025.
//
import Foundation
import SwiftUI
import Combine

//Please enter your country only, do not enter a state or city.

extension ConfirmPersonDetailsView{
    func submit() async throws{
        self.loading = true
        
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
        
        var outputEdited = false
        if (self.ocrResult?.firstName?.value.isEmpty == false && self.firstName != self.ocrResult?.firstName?.value){
            outputEdited = true
        } else if(self.ocrResult?.lastName?.value.isEmpty == false && self.lastName != self.ocrResult?.lastName?.value){
            outputEdited = true
        } else if(self.ocrResult?.middleName?.value.isEmpty == false && self.middleName != self.ocrResult?.middleName?.value){
            outputEdited = true
        } else if(self.ocrResult?.placeOfBirth?.value.isEmpty == false && self.country != self.ocrResult?.placeOfBirth?.value){
            outputEdited = true
        } else if(self.ocrResult?.gender?.value.isEmpty == false && self.gender != self.ocrResult?.gender?.value){
            outputEdited = true
        }else if(self.ocrResult?.dateOfBirth?.value.isEmpty == false && self.ocrResult?.dateOfBirth != nil && self.dateOfBirth != String(self.ocrResult!.dateOfBirth!.value.split(separator: "T")[0])){
            outputEdited = true
        }else if(self.ocrResult?.dateOfExpiration?.value.isEmpty == false && self.ocrResult?.dateOfExpiration != nil && self.idExpiryDate != String(self.ocrResult!.dateOfExpiration!.value.split(separator: "T")[0])){
            outputEdited = true
        }
        
        //Pass request
        let request = Person.CreatePersonRequest(
            givenName: self.firstName,
            surname: self.lastName,
            middleName: self.middleName,
            dateOfBirth: self.dateOfBirth,
            countryOfBirthExtId: self.country,
            email: self.Store.user.email ?? "",
            phone: self.Store.user.phone ?? "",
            genderExtId: self.gender,
            prepopulatedOCRResults: KycpService.OCRDecodeResponse.OCRDecodeResult(
                dateOfBirth: self.ocrResult?.dateOfBirth?.id ?? nil,
                dateOfExpiration: self.ocrResult?.dateOfExpiration?.id ?? nil,
                dateOfIssue: self.ocrResult?.dateOfIssue?.id ?? nil,
                documentType: self.ocrResult?.documentType?.id ?? nil,
                firstName: self.ocrResult?.firstName?.id ?? nil,
                gender: self.ocrResult?.gender?.id ?? nil,
                id: self.ocrResult?.id?.id ?? nil,
                lastName: self.ocrResult?.lastName?.id ?? nil,
                middleName: self.ocrResult?.middleName?.id ?? nil,
                nationality: self.ocrResult?.nationality?.id ?? nil,
                placeOfBirth: self.ocrResult?.placeOfBirth?.id ?? nil
            ),
            ocrOutputEdited: outputEdited
        )
        let response = try await services.kycp.updatePerson(request)
        self.Store.user.person = response
        self.Store.user.person!.edited = outputEdited
        self.Store.onboarding.customerEmail = self.Store.user.email
        
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
    
    var stateForSelectedCountryExists: Bool{
        return isStateForCountryExists(self.country)
    }
    
    var documentDateNotExpired: Bool{
        let date = self.idExpiryDate.asDate()
        if (date == nil){
            return false
        }
        if (Date().add(.month, value: 6) > date!){
            return false
        }
        return true
    }
    
    var countryExists: Bool{
        let index = self.countries.firstIndex(where: {$0.id == self.country})
        return index != nil
    }
    
    var dateOfBirthdayValid: Bool{
        let date = self.dateOfBirth.asDate()
        if (date == nil){
            return false
        }
        let diff = Date() - date!
        let months = diff.month ?? 0
        if months < (18*12){
            return false
        }
        return true
    }
    
    struct PersonAddress: Codable{
        public var country: String
        public var state: String
        public var city: String
        public var firstLine: String
        public var secondLine: String
        public var postcode: String
    }
}

extension ConfirmPersonDetailsView{
    var dateOfBirthValidationRule: ValidationRule{
        return ValidationRule(
            id: "dateOfBirth",
            validate: { value in
                let date = value.asDate()
                if (date == nil){
                    return false
                }
                let diff = Date() - date!
                let months = diff.month ?? 0
                if months < (18*12){
                    return false
                }
                return true
            }
        )
    }
    var dateOfExpiryValidationRule: ValidationRule{
        return ValidationRule(
            id: "dateOfExpiry",
            validate: { value in
                let date = self.idExpiryDate.asDate()
                if (date == nil){
                    return false
                }
                if (Date().add(.month, value: 6) > date!){
                    return false
                }
                return true
            }
        )
    }
    var countryOfBirthValidationRule: ValidationRule{
        return ValidationRule(
            id: "countryOfBirth",
            validate: { value in
                let index = self.countries.firstIndex(where: {$0.id == value})
                return index != nil
            }
        )
    }
    var genderValidationRule: ValidationRule{
        return ValidationRule(
            id: "gender",
            validate: { value in
                let index = self.genders.firstIndex(where: {$0.id == value})
                return index != nil
            }
        )
    }
}

struct ConfirmPersonDetailsView: View, RouterPage {
    @EnvironmentObject var Store: ApplicationStore
    @EnvironmentObject var Error: ErrorHandlingService
    @EnvironmentObject var Router: RoutingController
    
    @State public var ocrResult: KycpService.OCRDecodeResponse.OCRDecodeResultExtended? = nil
    
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var middleName: String = ""
    
    @State private var dateOfBirth: String = ""
    @State private var idExpiryDate: String = ""
    
    @State private var country: String = ""
    @State private var gender: String = ""
    
    @State private var loading: Bool = false
    
    private var regex: String{
        return "[^a-zA-Z0-9-' ]"
    }
    
    var body: some View {
        GeometryReader{ geometry in
            ScrollView{
                VStack(spacing: 0){
                    self.header
                    VStack(spacing:20){
                        CustomField(value: self.$firstName, placeholder: "First Name")
                            .onReceive(Just(self.firstName), perform:{ _ in
                                let value = self.firstName.replacingOccurrences(of: self.regex, with: "", options: .regularExpression)
                                self.firstName = value
                            })
                            .disabled(self.loading)
                        CustomField(value: self.$lastName, placeholder: "Last Name")
                            .onReceive(Just(self.lastName), perform:{ _ in
                                let value = self.lastName.replacingOccurrences(of: self.regex, with: "", options: .regularExpression)
                                self.lastName = value
                            })
                            .disabled(self.loading)
                        VStack(spacing: 8){
                            CustomField(value: self.$middleName, placeholder: "Middle Name")
                                .onReceive(Just(self.middleName), perform:{ _ in
                                    let value = self.middleName.replacingOccurrences(of: self.regex, with: "", options: .regularExpression)
                                    self.middleName = value
                                })
                                .disabled(self.loading)
                            HStack{
                                Text("Optional")
                                    .font(.caption.italic())
                                    .foregroundColor(Color.get(.LightGray))
                                    .padding(.horizontal, 15)
                                Spacer()
                            }
                        }
                        VStack(spacing:20){
                            VStack(spacing:0){
                                CustomField(value: self.$dateOfBirth, placeholder: "Date of Birth", type: .date, validationRules: [self.dateOfBirthValidationRule])
                                    .disabled(self.loading)
                                if (!self.dateOfBirthdayValid){
                                    HStack(spacing: 8){
                                        ZStack{
                                            Image("info-circle")
                                                .resizable()
                                                .scaledToFit()
                                                .foregroundColor(Color.get(.Danger))
                                        }
                                        .frame(width: 18, height: 18)
                                        Text("You must be 18 years or older to use this service. Check the date on your ID document or contact support.")
                                            .multilineTextAlignment(.leading)
                                            .font(.caption)
                                            .foregroundColor(Color.get(.Danger))
                                        Spacer()
                                    }
                                    .padding(.top, 16)
                                }
                            }
                            VStack(spacing:0){
                                CustomField(value: self.$idExpiryDate, placeholder: "Date of expiry", type: .date, dateRangeThrough: nil, validationRules: [self.dateOfExpiryValidationRule])
                                    .disabled(self.loading)
                                if (!self.documentDateNotExpired){
                                    HStack(spacing: 8){
                                        ZStack{
                                            Image("info-circle")
                                                .resizable()
                                                .scaledToFit()
                                                .foregroundColor(Color.get(.Danger))
                                        }
                                        .frame(width: 18, height: 18)
                                        Text("Your ID document must remain valid for at least 6 months from today.")
                                            .multilineTextAlignment(.leading)
                                            .font(.caption)
                                            .foregroundColor(Color.get(.Danger))
                                        Spacer()
                                    }
                                    .padding(.top, 16)
                                }
                            }
                        }
                        HStack{
                            Text("Place of birth")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(Color.get(.MiddleGray))
                            Spacer()
                        }
                        .padding(.top, 18)
                        VStack(spacing:0){
                            CustomField(value: self.$country, placeholder: "Country", type: .select, options: self.countries, searchable: true, validationRules: [self.countryOfBirthValidationRule])
                                .disabled(self.loading)
                            if (!self.countryExists){
                                HStack(spacing: 8){
                                    ZStack{
                                        Image("info-circle")
                                            .resizable()
                                            .scaledToFit()
                                            .foregroundColor(Color.get(.Danger))
                                    }
                                    .frame(width: 18, height: 18)
                                    Text("Only enter your country name")
                                        .multilineTextAlignment(.leading)
                                        .font(.caption)
                                        .foregroundColor(Color.get(.Danger))
                                    Spacer()
                                }
                                .padding(.top, 16)
                            }
                        }
                        CustomField(value: self.$gender, placeholder: "Gender", type: .select, options: self.genders, validationRules: [self.genderValidationRule])
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
                    .disabled(self.loading || self.firstName.isEmpty || self.lastName.isEmpty || self.dateOfBirth.isEmpty || self.gender.isEmpty || self.country.isEmpty || !self.documentDateNotExpired)
                        .buttonStyle(.primary())
                        .padding(.horizontal, 16)
                        .loader(self.$loading)
                }
                .frame(
                    maxWidth: .infinity,
                    minHeight: geometry.size.height - geometry.safeAreaInsets.bottom
                )
                .onAppear{
                    self.firstName = self.ocrResult?.firstName?.value ?? ""
                    self.firstName = self.firstName.replacingOccurrences(of: self.regex, with: "", options: .regularExpression)
                    
                    self.lastName = self.ocrResult?.lastName?.value ?? ""
                    self.lastName = self.lastName.replacingOccurrences(of: self.regex, with: "", options: .regularExpression)
                    
                    self.middleName = self.ocrResult?.middleName?.value ?? ""
                    self.middleName = self.middleName.replacingOccurrences(of: self.regex, with: "", options: .regularExpression)
                    
                    if (self.ocrResult?.dateOfBirth != nil){
                        self.dateOfBirth = String(self.ocrResult!.dateOfBirth!.value.split(separator: "T")[0])
                    }
                    if (self.ocrResult?.dateOfExpiration != nil){
                        self.idExpiryDate = String(self.ocrResult!.dateOfExpiration!.value.split(separator: "T")[0])
                    }
                    
                    self.gender = self.ocrResult?.gender?.value ?? ""
                    self.country = self.ocrResult?.placeOfBirth?.value ?? ""
                    
                    //MARK: Map genders to get option id
                    if (self.ocrResult?.gender?.value != nil){
                        let gender = self.ocrResult!.gender!.value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                        
                        let option = self.genders.first(where: {
                            if ($0.label.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == gender){
                                return true
                            }
                            return false
                        })
                        if(option != nil){
                            self.gender = option!.id
                            self.ocrResult!.gender!.value = option!.id
                        }
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationTitle("")
        .background(Color.get(.Background))
    }
}

extension ConfirmPersonDetailsView{
    var header: some View{
        HStack{
            Button{
                self.Router.stack.removeLast()
                self.Router.goTo(CreatePersonView(), routingType: .backward)
            } label:{
                ZStack{
                    Image("arrow-left")
                        .foregroundColor(Color.get(.PaleBlack))
                }
                .frame(width: 24, height: 24)
            }
            Spacer()
            ZStack{
                
            }
        }
        .padding(.horizontal,16)
        .padding(.vertical, 12)
        .overlay(
            VStack{
                ZStack{
                    Image(Whitelabel.Image(.logo))
                        .resizable()
                        .scaledToFit()
                }
                    .frame(
                        width: 150,
                        height: 50
                    )
            }
        )
    }
}

struct ConfirmPersonDetailsViewPreviews: PreviewProvider {
    static var store: ApplicationStore {
        var store = ApplicationStore()
        return store
    }
    
    static var previews: some View {
        ConfirmPersonDetailsView()
            .environmentObject(self.store)
    }
}
