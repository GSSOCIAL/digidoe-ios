//
//  OpenAccountView.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 09.01.2024.
//

import Foundation
import SwiftUI

struct OpenAccountView: View, RouterPage{
    @EnvironmentObject var Store: ApplicationStore
    @EnvironmentObject var Error: ErrorHandlingService
    @EnvironmentObject var Router: RoutingController
    
    @State private var selectedTab: Int = 0
    @State private var openAccountCurrency: String = ""
    @State private var selectedCurrency: String = ""
    @State private var selectedBusinessCurrency: String = ""
    @State private var businessParentCustomer: String = ""
    
    @State private var loading: Bool = false
    
    var tabs: [Tab]{
        var tabs: [Tab] = []
        tabs.append(.init(icon: Image("user"), title: "Individual", id: 0))
        tabs.append(.init(icon: Image("building-4"), title: "Business", id: 1))
        return tabs
    }
    
    var individualAccounts: Array<KycpService.CustomersResponse.Customer>{
        return self.Store.user.customers.filter({ customer in
            return customer.type == .individual && customer.state == .active
        })
    }
    
    var businessAccounts: Array<KycpService.CustomersResponse.Customer> {
        return self.Store.user.customers.filter({ customer in
            return customer.type == .business && customer.state == .active
        })
    }
    
    var businessCustomers: Array<Option>{
        var options: Array<Option> = self.businessAccounts.filter({account in
            return account.state == .active
        }).map({ account in
            return Option(
                id: account.id,
                label: account.name
            )
        })
        options.insert(Option(
            id: "0",
            label: "Open new business"
        ), at: 0)
        
        return options
    }
    
    var currencies: [Option]{
        return [
            Option(id: "gbp", label: "GBP account"),
            Option(id: "eur", label: "EURO account"),
        ]
    }
    
    func process() async throws{
        self.loading = true
        //Individual
        if(self.selectedTab == 0){
            //MARK: No individual customer - switch to KYC
            if (self.individualAccounts.isEmpty){
                //MARK: Prepend - remove active customer & switch to KYB
                self.Store.user.previousCustomerId = self.Store.user.customerId
                self.Store.user.customerId = nil
                self.Router.goTo(CurrencyIndividualSelectView())
                return
            }else{
                try await services.accounts.openCustomerAccount(self.individualAccounts.first!.id, currency: self.selectedCurrency)
                self.Router.back()
            }
        }else if(self.selectedTab == 1){
            //MARK: Create new business - KYB
            if (self.businessParentCustomer == "0"){
                //MARK: Prepend - remove active customer & switch to KYB
                self.Store.user.previousCustomerId = self.Store.user.customerId
                self.Store.user.customerId = nil
                self.Router.goTo(CountryOfIncorporationView())
                return
            }else{
                try await services.accounts.openCustomerAccount(self.businessParentCustomer, currency: self.selectedBusinessCurrency)
                self.Router.back()
            }
        }
        self.loading = false
    }
    
    var body: some View {
        ApplicationNavigatorContainerView{
            GeometryReader{ geometry in
                ScrollView{
                    VStack(spacing:0){
                        Header(back:{
                            self.Router.back()
                        }, title: "Opening new account")
                            .padding(.horizontal, 16)
                        VStack(spacing:24){
                            ZStack{
                                Image("card")
                                    .resizable()
                                    .scaledToFit()
                            }
                                .frame(maxHeight: 160)
                                .padding(.horizontal, 16)
                            VStack(spacing:8){
                                Text("Select account type")
                                    .font(.body.bold())
                                    .foregroundColor(Color.get(.MiddleGray, scheme: .light))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Tabs(tabs: tabs, selectedTab: $selectedTab)
                            }
                                .padding(.horizontal, 16)
                            TabsContainer(selectedTab: self.$selectedTab){
                                VStack{
                                    //MARK: Check for individuals, if no - show msg to create new one
                                    if (self.individualAccounts.isEmpty){
                                        Text("You don't have an individual customer, click next to open one.")
                                            .font(.subheadline)
                                            .foregroundColor(Color.get(.MiddleGray))
                                    }else{
                                        VStack(spacing:8){
                                            Text("Select currency")
                                                .font(.body.bold())
                                                .foregroundColor(Color.get(.MiddleGray, scheme: .light))
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                            RadioGroup(items: self.currencies, value: self.$selectedCurrency)
                                        }
                                    }
                                    Spacer()
                                }
                                    .tag(0)
                                    .padding(.horizontal, 16)
                                    .pageView()
                                
                                VStack{
                                    VStack(spacing:8){
                                        CustomField(value: self.$businessParentCustomer, placeholder: "Select your Business", type: .select, options: self.businessCustomers)
                                            .disabled(self.businessAccounts.isEmpty)
                                        if (self.businessParentCustomer != "0"){
                                            VStack(spacing:8){
                                                Text("Select currency")
                                                    .font(.body.bold())
                                                    .foregroundColor(Color.get(.MiddleGray, scheme: .light))
                                                    .frame(maxWidth: .infinity, alignment: .leading)
                                                RadioGroup(items: self.currencies, value: self.$selectedBusinessCurrency)
                                            }
                                                .padding(.top, 10)
                                        }
                                        if (self.businessAccounts.isEmpty){
                                            Text("You don't have any business customers, click next to open one.")
                                                .font(.subheadline)
                                                .foregroundColor(Color.get(.MiddleGray))
                                        }
                                    }
                                    Spacer()
                                }
                                    .tag(1)
                                    .padding(.horizontal, 16)
                                    .pageView()
                                    .onAppear{
                                        self.businessParentCustomer = "0"
                                    }
                            }
                        }
                        .padding(.top, 20)
                        Spacer()
                        Button{
                            Task{
                                do{
                                    try await self.process()
                                }catch(let error){
                                    self.loading = false
                                    self.Error.handle(error)
                                }
                            }
                        } label:{
                            HStack{
                                Spacer()
                                Text("Next")
                                Spacer()
                            }
                        }
                        .buttonStyle(.primary())
                        .loader(self.$loading)
                        .disabled(self.selectedTab == 0 ? (self.individualAccounts.isEmpty ? false : self.selectedCurrency.isEmpty) : (self.businessParentCustomer.isEmpty ? true : ( self.businessParentCustomer != "0" ? self.selectedBusinessCurrency.isEmpty : false)))
                        .padding(.horizontal, 16)
                    }
                    .frame(
                        maxWidth: .infinity,
                        minHeight: geometry.size.height - geometry.safeAreaInsets.bottom
                    )
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationTitle("")
    }
}

struct OpenAccountView_Previews: PreviewProvider {
    static var previews: some View {
        ContentViewContainerPreview{
            OpenAccountView()
        }
    }
}
