//
//  ApllicationInReview.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 11.12.2023.
//

import Foundation
import SwiftUI

struct ApplicationInReviewView: View, RouterPage {
    @EnvironmentObject var Store: ApplicationStore
    @EnvironmentObject var Error: ErrorHandlingService
    @EnvironmentObject var Router: RoutingController
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var loading: Bool = false
    @State private var refreshing: Bool = false
    @State private var offset: Double = 0
    
    func signout() async throws{
        try await self.Store.logout()
        self.Router.home()
    }
    
    func refreshState(){
        Task{
            self.refreshing = true
            do{
                //MARK: Refresh customer state
                let customers = try await services.kycp.getCustomers()
                self.viewContext.refreshAllObjects()
                
                customers.customers.forEach({customer in
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
                /*
                let _ = try await self.Store.user.loadCustomers()
                //Check current customer id
                let customer = self.Store.user.customers.first(where: {$0.id == self.Store.user.customerId})
                
                if (customer != nil){
                    switch(customer!.state){
                    case .active:
                        //Go to appllication
                        self.refreshing = false
                        self.Router.goTo(MainView())
                        break;
                    case .inactive:
                        self.refreshing = false
                        self.Router.goTo(CustomerLockedView())
                        break;
                    default:
                        break;
                    }
                }
                self.refreshing = false
                 */
            }catch(let error){
                self.refreshing = false
                self.Error.handle(error)
            }
        }
    }
    
    var body: some View {
        GeometryReader{ geometry in
            ZStack{
                Image("pat8")
                    .ignoresSafeArea()
                    .zIndex(2)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .blur(radius: 20)
                RefreshableScrollView(refresh:self.refreshState, refreshing: self.$refreshing, scrollOffset: self.$offset){
                    VStack(alignment:.center){
                        Spacer()
                        ZStack{
                            Image(Whitelabel.Image(.logo))
                                .resizable()
                                .scaledToFit()
                                .offset(y: -self.offset * 0.1)
                        }
                            .frame(
                                width: 150,
                                height: 50
                            )
                            .padding(.bottom,24)
                        
                        ZStack{
                            Image("pendingApplication")
                                .resizable()
                                .scaledToFit()
                                .offset(y: -self.offset * 0.3)
                        }
                        .frame(maxHeight: 140)
                        .padding(.bottom,24)
                        
                        VStack(alignment:.center,spacing:10){
                            HStack(alignment: .center){
                                Text("Your application has been successfully submitted and being reviewed")
                                    .multilineTextAlignment(.center)
                                    .foregroundColor(Color.get(.Text))
                                    .offset(y: -self.offset * 0.6)
                            }
                            .font(.title.bold())
                            /*
                            Text("Your application has been successfully submitted and being reviewed")
                                .font(.subheadline)
                                .multilineTextAlignment(.center)
                                .foregroundColor(Color.get(.LightGray))
                                .offset(y: -self.offset * 0.6)
                             */
                        }
                        .padding(.horizontal, 16)
                        Spacer()
                        Button{
                            Task{
                                do{
                                    try await self.signout()
                                }catch(let error){
                                    self.loading = false
                                    self.Error.handle(error)
                                }
                            }
                        } label: {
                            Text("Logout")
                                .padding(.horizontal, 50)
                        }
                            .buttonStyle(.secondaryDanger())
                            .offset(y: -self.offset * 0.6)
                    }
                    .frame(
                        maxWidth: .infinity,
                        minHeight: geometry.size.height - geometry.safeAreaInsets.bottom
                    )
                }
                .zIndex(3)
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationTitle("")
        .background(Color.get(.Background))
    }
}
