//
//  EditAccountDetailsView.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 11.01.2024.
//

import Foundation
import SwiftUI
import CoreData

extension EditAccountDetailsView{
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
}

extension EditAccountDetailsView{
    func submit() async throws{
        self.loading = true
        
        let response = try await services.accounts.updateAccountTitle(
            self.account.customer?.id ?? "",
            accountId: self.account.id ?? "",
            title: self.title
        )
        if (response){
            //Refresh title
            self.account.setValue(self.title, forKey: "title")
            try self.viewContext.save()
            
            self.Router.back()
        }else{
            throw ApplicationError(title: "", message: "Failed to update account details")
        }
        self.loading = false
    }
}

struct EditAccountDetailsView: View, RouterPage{
    @EnvironmentObject var Store: ApplicationStore
    @EnvironmentObject var Error: ErrorHandlingService
    @EnvironmentObject var Router: RoutingController
    @EnvironmentObject var manager: DataController
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var loading: Bool = false
    @State private var scrollOffset : Double = 0
    
    @State private var title: String = ""
    @State public var account: CoreAccount
    
    var body: some View {
        ApplicationNavigatorContainerView{
            GeometryReader{ geometry in
                ScrollView{
                    VStack(spacing: 0){
                        VStack(spacing:0){
                            Header(back:{
                                self.Router.back()
                            }, title: "Editing the account")
                        }
                        .offset(
                            y: self.scrollOffset < 0 ? self.scrollOffset : 0
                        )
                        
                        if (self.loading){
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
                        }
                        
                        VStack(spacing:12){
                            CustomField(
                                value: self.$title,
                                placeholder: "Title of account",
                                maxLength: 35
                            )
                                .disabled(self.loading)
                                .padding(.horizontal, 16)
                            VStack(spacing: 12){
                                if (self.account != nil){
                                    
                                    VStack(spacing:2){
                                        Text("Account holder name")
                                            .foregroundColor(Color.get(.LightGray))
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        Text(self.account.ownerName ?? "–")
                                            .foregroundColor(Color.get(.Text))
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                    VStack(spacing:2){
                                        Text("Type of account")
                                            .foregroundColor(Color.get(.LightGray))
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        Text("Individual")
                                            .foregroundColor(Color.get(.Text))
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                     
                                    if (self.account.baseCurrencyCode?.lowercased() == "gbp"){
                                        
                                        VStack(spacing:2){
                                            Text("Account Number")
                                                .foregroundColor(Color.get(.LightGray))
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                            Text(self.account.identification?.accountNumber ?? "-")
                                                .foregroundColor(Color.get(.Text))
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                        }
                                        VStack(spacing:2){
                                            Text("Sort Code")
                                                .foregroundColor(Color.get(.LightGray))
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                            Text(self.account.identification?.sortCode ?? "-")
                                                .foregroundColor(Color.get(.Text))
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                        }
                                         
                                    }else if (self.account.baseCurrencyCode?.lowercased() == "eur"){
                                        VStack(spacing:2){
                                            Text("IBAN")
                                                .foregroundColor(Color.get(.LightGray))
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                            Text(self.account.identification?.iban ?? "-")
                                                .foregroundColor(Color.get(.Text))
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                        }
                                    }
                                }
                            }
                                .font(.subheadline)
                                .padding(.horizontal, 16)
                        }
                        .padding(.vertical, 16)
                        .offset(
                            y: self.loading && self.scrollOffset > -100 ? Swift.abs(100 - self.scrollOffset) : 0
                        )
                        .onAppear{
                            Task{
                                do{
                                    self.title = self.account.title ?? ""
                                }catch(let error){
                                    self.loading = false
                                    self.Error.handle(error)
                                }
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
                        } label:{
                            HStack{
                                Spacer()
                                Text("Save")
                                Spacer()
                            }
                        }
                        .buttonStyle(.primary())
                        .loader(self.$loading)
                        .disabled(self.loading || self.title.isEmpty)
                        .padding(.horizontal, 16)
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
                                //try await self.getDetails()
                            }catch(let error){
                                self.loading = false
                                self.Error.handle(error)
                            }
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
