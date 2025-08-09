//
//  MainView.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 26.09.2023.
//

import Foundation
import SwiftUI
import CoreData

extension MainView{
    private var loaderOffset: Double{
        if (self.loading){
            return 50 + self.scrollOffset
        }
        
        if (self.scrollOffset > 0){
            return 0
        }else if(self.scrollOffset < -100){
            return 50 + self.scrollOffset
        }
        
        return 0 + self.scrollOffset / 2
    }
    
    private var availableCurrencies: [Option] {
        return [
            Option(id: "gbp", label: "GBP account"),
            Option(id: "eur", label: "EURO account")
        ]
    }
}

extension MainView{
    func fetchCustomers() async throws{
        //Store customers
        let customers = try await services.kycp.getCustomers()
        self.viewContext.refreshAllObjects()
        
        //Remove all entities and update with new one
        customers.customers.forEach({ customer in
            Task{
                //Check if customer alredy registred
                let request = CoreCustomer.fetchRequest()
                request.predicate = NSPredicate(format: "id == %@", customer.id)
                let results = try self.viewContext.fetch(request)
                
                if (results.isEmpty){
                    let coreCustomer = CoreCustomer(context: self.viewContext)
                    coreCustomer.setValue(customer.id, forKey:"id")
                    coreCustomer.setValue(customer.name, forKey:"name")
                    coreCustomer.setValue(customer.type.rawValue.lowercased(), forKey:"type")
                    coreCustomer.setValue(customer.state.rawValue.lowercased(), forKey:"state")
                }else{
                    results.forEach{
                        $0.setValue(customer.id, forKey:"id")
                        $0.setValue(customer.name, forKey:"name")
                        $0.setValue(customer.type.rawValue.lowercased(), forKey:"type")
                        $0.setValue(customer.state.rawValue.lowercased(), forKey:"state")
                    }
                }
            }
        })
    }
    
    func getAccounts() async throws{
        if (self.loading){
            return;
        }
        
        self.loading = true
        try await self.fetchCustomers()
        try self.viewContext.save()
        self.loading = false
    }
    
    func fetchAccounts() async throws{
        if (self.loading){
            return
        }
        self.loading = true
        //Look for individual customer
        
        for customer in self.individuals{
            
            //Retrieve individual accounts
            if let accounts = try await services.accounts.getCustomerAccounts(customer.id ?? "") as? AccountsService.AccountsGetResponse{
                accounts.value.data.forEach{ account in
                    Task{
                        //Check if account exists
                        let accountsRequest = CoreAccount.fetchRequest()
                        accountsRequest.predicate = NSPredicate(format: "id == %@", account.id)
                        let response = try self.viewContext.fetch(accountsRequest)
                        
                        if (response.isEmpty){
                            
                            let coreAccount = CoreAccount(context: self.viewContext)
                            coreAccount.fetchFromAccount(account: account)
                            //TODO coreAccount.customer = customer
                            customer.addToAccounts(coreAccount)
                        }else{
                            response.forEach({
                                $0.fetchFromAccount(account: account)
                                //TODO $0.customer = customer
                                customer.addToAccounts($0)
                            })
                        }
                    }
                }
            }
        }
        try self.viewContext.save()
        self.uid += 1;
        self.loading = false
    }
}

struct MainView: View, RouterPage {
    @EnvironmentObject var Store: ApplicationStore
    @EnvironmentObject var Error: ErrorHandlingService
    @EnvironmentObject var Router: RoutingController
    @EnvironmentObject var activityController: ApplicationActivityController
    @EnvironmentObject var manager: DataController
    
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var selectedTab: Int = 0
    @State private var loading: Bool = false
    @State private var scrollOffset : Double = 0
    @State private var openAccountPopup: Bool = false
    @State private var uid: Int = 1
    
    @FetchRequest(
        sortDescriptors:[
            SortDescriptor(\.state),
            SortDescriptor(\.name)
        ],
        predicate: NSPredicate(format: "lowercase:(type) == 'individual' AND lowercase:(state) == 'active'")
    ) var individuals: FetchedResults<CoreCustomer>
    @FetchRequest(
        sortDescriptors:[
            SortDescriptor(\.state),
            SortDescriptor(\.name)
        ],
        predicate: NSPredicate(format: "lowercase:(type) == 'business' AND lowercase:(state) != 'inactive'")
    ) var companies: FetchedResults<CoreCustomer>
    @FetchRequest(
        sortDescriptors: [
            SortDescriptor(\.sortOrder),
        ],
        predicate: NSPredicate(format: "lowercase:(customer.type) == 'individual' AND lowercase:(customer.state) == 'active'")
    ) var individualAccounts: FetchedResults<CoreAccount>
    
    let columns = Array(repeating: GridItem(.flexible(),spacing: 10), count: 1)
    var tabs: [Tab]{
        var tabs: [Tab] = []
        tabs.append(.init(icon: Image("user"), title: "Individual", id: 0))
        tabs.append(.init(icon: Image("building-4"), title: "Business", id: 1))
        return tabs
    }
    
    func processCompany(_ company: CoreCustomer) async throws{
        switch(company.state?.lowercased()){
            case "new":
                self.Store.user.customerId = company.id ?? ""
                return
            break;
            case "active":
                self.Router.goTo(AccountBusinessList(
                    company: company
                ))
                return;
            default:
            break;
        }
    }
    
    var header: some View{
        HStack{
            //MARK: Profile picture
            Button{
                self.Router.goTo(ProfileMenuView())
            } label: {
                ZStack{
                    if (self.Store.user.person != nil){
                        Text([self.Store.user.person!.givenName, self.Store.user.person!.surname].map({ el in
                            return String(el?.prefix(1) ?? "")
                        }).joined(separator: ""))
                        .font(.caption)
                        .foregroundColor(Color.get(.Pending))
                    }
                }
                .frame(width: 34, height: 34)
                .background(Color.get(.Section))
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color.black, style: .init(lineWidth: 1))
                        .opacity(0.24)
                )
            }
            Spacer()
            Text("Accounts")
                .foregroundColor(Color.get(.Text))
                .font(.subheadline.bold())
            Spacer()
            ZStack{
                Button(action:{
                    self.Router.goTo(ContactsView())
                }, label: {
                    Image("people")
                        .foregroundColor(Color("MiddleGray"))
                })
            }
            .frame(width: 34, height: 34)
        }
    }
    
    var individualList: some View{
        VStack(spacing:0){
            if (self.individualAccounts.isEmpty){
                VStack(alignment:.center,spacing: 0){
                    Spacer()
                    ZStack{
                        Image("no-records")
                    }
                    .frame(width: 220, height: 160)
                    Text("No Accounts")
                        .font(.title2)
                        .foregroundColor(Color.get(.LightGray))
                        .padding(.vertical, 24)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            }else{
                VStack(spacing:0){
                    ForEach(self.individualAccounts, id: \.id){ account in
                        Button{
                            self.Router.goTo(
                                AccountMainView(account: account)
                            )
                            /*
                             self.Store.user.customerId = self.Store.user.customers.first(where: {$0.type == .individual && $0.state == .active})?.id
                            self.Store.selectedAccountId = $account.id
                            self.Router.goTo(AccountMainView())
                             */
                        } label: {
                            CoreAccountCard(
                                style: .list,
                                account: account
                            )
                                .id("\(account.id)-\(self.uid)")
                                .shadow(
                                    color: Color.black.opacity( 0.2),
                                    radius: 7, x: 0, y: -4
                                )
                        }
                    }
                }
            }
        }
    }
    
    var businessList: some View{
        VStack(spacing:0){
            if (self.companies.isEmpty){
                VStack(alignment:.center,spacing: 0){
                    Spacer()
                    ZStack{
                        Image("no-records")
                    }
                    .frame(width: 220, height: 160)
                    Text("No Accounts")
                        .font(.title2)
                        .foregroundColor(Color.get(.LightGray))
                        .padding(.vertical, 24)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            }else{
                VStack(spacing:10){
                    ForEach(self.companies){ company in
                        Button{
                            Task{
                                do{
                                    try await self.processCompany(company)
                                }catch let(error){
                                    self.loading = false
                                    self.Error.handle(error)
                                }
                            }
                        } label: {
                            CustomerCard(
                                style: .list,
                                customer: company
                            )
                        }
                        .disabled(self.loading)
                    }
                }
            }
        }
    }
    
    var body: some View {
        ApplicationNavigatorContainerView{
            GeometryReader{ geometry in
                ScrollView{
                    VStack(spacing:0){
                        VStack(spacing:0){
                            header
                                .padding(.horizontal, 16)
                            Tabs(tabs: tabs, selectedTab: $selectedTab)
                                .padding(.horizontal, 16)
                                .padding(.top, 10)
                        }
                        .offset(
                            y: self.scrollOffset < 0 ? self.scrollOffset : 0
                        )
                        
                        HStack{
                            Spacer()
                            Loader(size:.small)
                                .offset(y: self.loaderOffset)
                                .opacity(self.loading ? 1 : self.scrollOffset > -10 ? 0 : -self.scrollOffset / 100)
                            Spacer()
                        }
                        .frame(
                            maxWidth: .infinity,
                            maxHeight: 0
                        )
                        .zIndex(3)
                        .offset(y: 0)
                        
                        VStack(spacing:0){
                            if (self.selectedTab == 0){
                                individualList
                                    .padding(.horizontal, 16)
                            }else if(self.selectedTab == 1){
                                businessList
                                    .padding(.horizontal, 16)
                            }
                        }
                        .padding(.top, 45)
                        .offset(
                            y: self.loading && self.scrollOffset > -100 ? Swift.abs(Double(100) - self.scrollOffset) : 0
                        )
                        .onAppear{
                            Task{
                                do{
                                    self.activityController.registerActivity()
                                    try await self.fetchCustomers()
                                }catch(let error){
                                    self.loading = false
                                    self.Error.handle(error)
                                }
                            }
                        }
                        .task(id: self.individuals.count){
                            Task{
                                do{
                                    try await self.fetchAccounts()
                                }catch(let error){
                                    self.loading = false
                                    self.Error.handle(error)
                                }
                            }
                        }
                        Spacer()
                    }
                    .background(GeometryReader {
                        Color.clear.preference(key: RefreshViewOffsetKey.self, value: -$0.frame(in: .named("scroll")).origin.y)
                    })
                    .onPreferenceChange(RefreshViewOffsetKey.self) { position in
                        self.scrollOffset = position
                    }
                    .frame(
                        maxWidth: .infinity,
                        minHeight: geometry.size.height - geometry.safeAreaInsets.bottom
                    )
                }
                .coordinateSpace(name: "scroll")
                .onChange(of: scrollOffset){ _ in
                    if (!self.loading && self.scrollOffset <= -100){
                        Task{
                            do{
                                try await self.fetchAccounts()
                            }catch(let error){
                                self.loading = false
                                self.Error.handle(error)
                            }
                        }
                    }
                }
                .overlay(
                    ZStack{
                        if (self.selectedTab == 1){
                            VStack{
                                HStack{
                                    Spacer()
                                    Button{
                                        self.Router.goTo(AccountApprovalsView())
                                    } label: {
                                        VStack(alignment: .center, spacing:5){
                                            ZStack{
                                                Image("clipboard-text")
                                                    .resizable()
                                                    .scaledToFit()
                                                    .foregroundColor(Whitelabel.Color(.Primary))
                                            }
                                            .frame(width: 24, height: 24)
                                            Text(LocalizedStringKey("Approvals"))
                                                .font(.caption2.weight(.medium))
                                                .foregroundColor(Whitelabel.Color(.Primary))
                                        }
                                    }
                                    .disabled(self.loading)
                                    .padding(.horizontal, 16)
                                    .loader(self.$loading)
                                    Spacer()
                                }
                            }
                            .ignoresSafeArea()
                            .padding(.vertical, 12)
                            .padding(.bottom, geometry.safeAreaInsets.bottom * 2 + 22)
                            .background(Color.get(.Background))
                            .compositingGroup()
                            .cornerRadius(16, corners: [.topLeft, .topRight])
                            .offset(y: geometry.safeAreaInsets.bottom)
                            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: -4)
                        }
                    }
                    , alignment: .bottom)
            }
        }
        .edgesIgnoringSafeArea(.bottom)
        .navigationBarBackButtonHidden(true)
        .navigationTitle("")
    }
}

/*
 .font(.body) = 16px
 .font(title2) = 20px
 .font(subheadline) = 14px
 .font(caption) = 12px
 .font(caption2) = 10px
*/
