//
//  AccountManagementView.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 20.07.2024.
//

import Foundation
import SwiftUI

/// MARK: Getters
extension AccountManagementView{
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
    
    enum AccountManagementSelectedUser{
        case none
        case any(String, String, String)
    }
    
    private var isUserSelected: Binding<Bool>{
        Binding(
            get:{
                switch(self.selectedUser){
                case .none:
                    return false
                default:
                    return true
                }
            },
            set:{ value in
                if (value == false){
                    self.selectedUser = .none
                }
            }
        )
    }
}

struct AccountManagementView: View, RouterPage{
    @EnvironmentObject var Store: ApplicationStore
    @EnvironmentObject var Error: ErrorHandlingService
    @EnvironmentObject var Router: RoutingController
    
    @State private var scrollOffset : Double = 0
    let columns = Array(repeating: GridItem(.flexible(),spacing: 12), count: 1)
    @State private var loading: Bool = false
    @State private var limitLoading: Bool = false
    @State private var query: String = ""
    
    @State public var account: CoreAccount
    
    @State private var selectedUser: AccountManagementView.AccountManagementSelectedUser = .none
    @State private var transactionLimit: String = ""
    @State private var dailyLimit: String = ""
    
    @State private var users: Array<AccountsService.AccountLimitSimpleDtoPaginationResponseResult.AccountLimitSimpleDtoAccountLimitSimpleDto> = []
    
    func getLimits() async throws{
        self.loading = true
        let response = try await services.accounts.getAccountLimits(self.account.customer?.id ?? "", accountId: self.account.id ?? "")
        self.users = response.value.data
        self.loading = false
    }
    
    func updateLimit() async throws{
        self.limitLoading = true
        
        let perTransaction = Double(self.transactionLimit.replacingOccurrences(of: ",", with: "")) ?? 0
        var perDay = Double(self.dailyLimit.replacingOccurrences(of: ",", with: "")) ?? 0
        
        if (perTransaction > perDay){
            throw ApplicationError(title: "", message: "Limit per transaction should be less that limit per day")
        }
        switch(self.selectedUser){
        case .any(_, _, var id):
            let response = try await services.accounts.updateAccountLimits(
                self.account.customer?.id ?? "",
                accountId: self.account.id ?? "",
                accountLimitId: id,
                dailyLimit: perDay,
                perTransactionLimit: perTransaction
            )
            let index = self.users.firstIndex(where: {$0.id == response.value.id})
            if (index != nil){
                self.users[index!] = response.value
            }
        default:
            break
        }
        self.limitLoading = false
        self.selectedUser = .none
    }
    
    var body: some View {
        ApplicationNavigatorContainerView{
            GeometryReader{ geometry in
                ZStack{
                    ScrollView{
                        VStack(spacing:0){
                            VStack(spacing:0){
                                Header(back:{
                                    self.Router.back()
                                }, title: "Users with access to the account")
                                    .padding(.horizontal, 16)
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
                            
                            LazyVGrid(columns: self.columns){
                                ForEach(Array(self.users.enumerated()),id:\.1.id){ (index, user) in
                                    Button{
                                        self.selectedUser = .any(user.userId, user.userName ?? "", user.id)
                                        self.transactionLimit = String(user.perTransactionLimit).preparePrice()
                                        self.dailyLimit = String(user.dailyLimit).preparePrice()
                                    } label: {
                                        HStack{
                                            ZStack{
                                                Text((user.userName ?? "").asInitials())
                                                    .foregroundColor(Color.get(.LightGray))
                                                    .font(.subheadline.weight(.medium))
                                            }
                                                .frame(width: 38, height: 38)
                                                .background(Color.get(.CardSecondary))
                                                .clipShape(RoundedRectangle(cornerRadius: 4))
                                            
                                            VStack(alignment: .leading, spacing: 3){
                                                Text(user.userName ?? "")
                                                    .foregroundColor(Color.get(.MiddleGray))
                                                Text("Daily Limit: ")
                                                + Text(String(user.dailyLimit).formatAsPrice(self.account.baseCurrencyCode?.uppercased() ?? "")).foregroundColor(Color.get(.MiddleGray))
                                                Text("Transaction Limit: ")
                                                + Text(String(user.perTransactionLimit).formatAsPrice(self.account.baseCurrencyCode?.uppercased() ?? "")).foregroundColor(Color.get(.MiddleGray))
                                            }
                                                .foregroundColor(Color.get(.LightGray))
                                                .font(.subheadline.weight(.medium))
                                        }
                                    }
                                    .buttonStyle(.secondaryNext())
                                    .padding(.horizontal, 16)
                                }
                            }
                            .padding(.top, 12)
                            .offset(
                                y: self.loading && self.scrollOffset > -100 ? Swift.abs(100 - self.scrollOffset) : 0
                            )
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
                                        try await self.getLimits()
                                    }catch(let error){
                                        self.loading = false
                                        self.Error.handle(error)
                                    }
                                }
                            }
                        }
                        .onAppear{
                            Task{
                                do{
                                    try await self.getLimits()
                                }catch(let error){
                                    self.loading = false
                                    self.Error.handle(error)
                                }
                            }
                        }
                    
                    //MARK: Popups
                    PresentationSheet(isPresented: self.isUserSelected){
                        VStack{
                            switch(self.selectedUser){
                            case .any(_, let userName,_):
                                VStack(spacing: 12){
                                    Text("Set limit for \(userName)")
                                        .font(.title2.bold())
                                        .foregroundColor(Color.get(.Text))
                                        .frame(maxWidth:.infinity, alignment: .leading)
                                        .multilineTextAlignment(.leading)
                                    CustomField(value: self.$transactionLimit, placeholder: "Limit per transaction", type: .price)
                                        .disabled(self.loading || self.limitLoading)
                                    CustomField(value: self.$dailyLimit, placeholder: "Limit per day", type: .price)
                                        .disabled(self.loading || self.limitLoading)
                                    HStack(spacing: 12){
                                        Button{
                                            self.selectedUser = .none
                                        } label:{
                                            HStack{
                                                Spacer()
                                                Text("Cancel")
                                                Spacer()
                                            }
                                        }
                                        .buttonStyle(.secondary())
                                        .disabled(self.loading || self.limitLoading)
                                        
                                        Button{
                                            Task{
                                                do{
                                                    try await self.updateLimit()
                                                }catch (let error){
                                                    self.limitLoading = false
                                                    self.Error.handle(error)
                                                }
                                            }
                                        } label:{
                                            HStack{
                                                Spacer()
                                                Text("Confirm")
                                                Spacer()
                                            }
                                        }
                                        .buttonStyle(.primary())
                                        .disabled(self.loading || self.limitLoading)
                                    }
                                    .padding(.top, 12)
                                }
                            default:
                                ZStack{}
                            }
                        }
                        .padding(.bottom, geometry.safeAreaInsets.bottom)
                        .padding(20)
                        .padding(.top,10)
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationTitle("")
    }
}
