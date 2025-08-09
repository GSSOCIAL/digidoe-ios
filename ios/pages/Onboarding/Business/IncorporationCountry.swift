//
//  IncorporationCountry.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 22.11.2023.
//

import Foundation
import SwiftUI

struct CountryOfIncorporationView: View, RouterPage {
    @EnvironmentObject var Store: ApplicationStore
    @EnvironmentObject var Error: ErrorHandlingService
    @EnvironmentObject var Router: RoutingController
    
    @State private var loading: Bool = false
    @State private var country: String = ""
    
    @State private var name: String = ""
    @State private var number: String = ""
    @State private var date: String = ""
    
    @State private var task: Task<[KycpService.Company], any Error>?
    @State private var pageSize: Int = 50
    @State private var pageNumber: Int = 0
    
    @State private var companies: [KycpService.Company] = []
    
    func submit() async throws{
        self.loading = true
        self.Store.onboarding.business.registredAddress.country = self.country
        self.Store.onboarding.business.legalName = self.name
        self.Store.onboarding.business.registrationNumber = self.number
        self.Store.onboarding.business.incorporationDate = self.date.asDate("")?.asBackendString() ?? ""
        if (self.Store.onboarding.business.incorporationDate.isEmpty){
            throw ApplicationError(title: "Unable to process company data", message: "Unable to process company data")
        }
        self.loading = false
        self.Router.goTo(BusinessAddressView())
    }
    
    var countries: [Option]{
        return self.Store.onboarding.countries.map({
            return .init(id: String($0.id), label: $0.name)
        })
    }
    
    var isBusinessInCompanyHouse: Bool{
        return self.Store.onboarding.isCountryIsUK(self.country)
    }
    
    /**
        Trigger
     */
    func handleSearchCompany(_ name: String){
        Task{
            self.task?.cancel()
            if name.count > 0{
                let task = Task.detached{
                    try await Task.sleep(nanoseconds: userDefaultInputLagTimeNanoSeconds)
                    return try await services.kycp.searchCompany(name, pageSize: self.pageSize, pageNumber: self.pageNumber)
                }
                self.task = task
                do{
                    self.companies = try await task.value
                }catch(_){
                    //Just ignore errors here, cause it break future errors render
                }
            }
        }
    }
    
    func renderCompanyHouseResult(option: Option, selected: String) -> any View{
        return 
        HStack(alignment:.center, spacing: 10){
            Text(option.label)
                .frame(maxWidth: .infinity, alignment: .leading)
                .font(.subheadline)
                .foregroundStyle(Color("Text"))
            Spacer()
            Text(option.id)
                .font(.caption)
                .foregroundStyle(Color("LightGray"))
        }
        .multilineTextAlignment(.leading)
        .padding(.horizontal, 15)
        .padding(.vertical, 10)
    }
    
    func onCompanySelect(_ option: Option){
        //MARK: Just store company information
        self.name = option.label
        self.date = option.props["incorporationDate"] ?? ""
        self.number = option.props["companyNumber"] ?? ""
    }
    
    var companiesSearchResults: [Option]{
        return self.companies.map({ company in
            return .init(
                id: String(company.companyNumber),
                label: company.title,
                props: [
                    "companyNumber": company.companyNumber,
                    "description": company.description ?? "",
                    "incorporationDate": company.dateOfCreation,
                ]
            )
        })
    }
    
    var body: some View {
        GeometryReader{ geometry in
            ScrollView{
                VStack(spacing: 0){
                    ZStack{
                        
                    }
                    .frame(maxWidth: .infinity, maxHeight: 50)
                    .padding(.bottom, 16)
                    TitleView(
                        title: LocalizedStringKey("Choose your country of incorporation"),
                        description: LocalizedStringKey("Please enter country of incorporation")
                    )
                        .padding(.horizontal, 16)
                    CustomField(value: self.$country, placeholder: "Country of incorporation", type: .select, options: self.countries, searchable: true)
                        .padding(.horizontal, 16)
                        .padding(.vertical,12)
                        .disabled(self.loading)
                    if (self.country.isEmpty){
                        Button{
                            
                        } label:{
                            Text(LocalizedStringKey("Please select the country where your business was originally registered, as it appears in your registration documents"))
                        }
                        .buttonStyle(.notification(style: .info))
                        .padding(.horizontal, 16)
                        .padding(.vertical,6)
                        .disabled(true)
                    }else{
                        if(self.isBusinessInCompanyHouse){
                            //MARK: For UK
                            TitleView(title: LocalizedStringKey("Search legal name of your business"), description: LocalizedStringKey("Please provide your company information"))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                            //MARK: Searchable field
                            CustomField(value: self.$number, placeholder: "Business Legal Name", type: .search, options: self.companiesSearchResults, onQueryChanged: self.handleSearchCompany, buildItem: self.renderCompanyHouseResult, onItemSelect: self.onCompanySelect)
                                .padding(.horizontal, 16)
                                .padding(.vertical,12)
                                .disabled(self.loading)
                        }else{
                            //MARK: No-UK company
                            TitleView(title: LocalizedStringKey("Enter business details"), description: LocalizedStringKey("Please provide your company information"))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                            VStack(spacing:12){
                                CustomField(value: self.$name, placeholder: "Legal Name")
                                    .disabled(self.loading)
                                CustomField(value: self.$number, placeholder: "Registration number")
                                    .disabled(self.loading)
                                Text(LocalizedStringKey("Usually it looks like 1234559, G323232 or LP1341312"))
                                    .font(.caption.weight(.medium))
                                    .foregroundColor(Color("LightGray"))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                CustomField(value: self.$date, placeholder: "Date of incorporation", type: .date)
                                    .disabled(self.loading)
                            }
                            .padding(.horizontal, 16)
                        }
                    }
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
                        .disabled(self.loading || self.country.isEmpty || self.name.isEmpty || self.number.isEmpty || self.date.isEmpty)
                        .buttonStyle(.primary())
                        .padding(.horizontal, 16)
                        .loader(self.$loading)
                }
                .frame(
                    maxWidth: .infinity,
                    minHeight: geometry.size.height - geometry.safeAreaInsets.bottom
                )
                .onChange(of: self.isBusinessInCompanyHouse){ option in
                    self.name = ""
                    self.number = ""
                    self.date = ""
                }
                .onAppear{
                    self.country = self.Store.onboarding.business.registredAddress.country
                    self.name = self.Store.onboarding.business.legalName
                    self.number = self.Store.onboarding.business.registrationNumber
                    self.date = self.Store.onboarding.business.incorporationDate
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationTitle("")
        .background(Color.get(.Background))
    }
}

struct CountryOfIncorporationView_Previews: PreviewProvider {
    static var store: ApplicationStore {
        var store = ApplicationStore()
        return store
    }
    
    static var previews: some View {
        CountryOfIncorporationView()
            .environmentObject(self.store)
    }
}
