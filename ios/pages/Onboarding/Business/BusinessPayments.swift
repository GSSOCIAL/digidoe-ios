//
//  BusinessPayments.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 29.11.2023.
//

import Foundation
import SwiftUI

struct BusinessPaymentsView: View, RouterPage {
    @EnvironmentObject var Store: ApplicationStore
    @EnvironmentObject var Error: ErrorHandlingService
    @EnvironmentObject var Router: RoutingController
    
    @State private var loading: Bool = false
    
    func submit(_ id: String) async throws{
        self.loading = true
        
        let entity = self.Store.onboarding.businessEntity
        
        if (entity == nil){
            throw ServiceError(title: "Entity not found", message: "Couldnt find Your Entity")
        }
        
        let fields:[String:Any] = [
            "GENaveragetransactionvolumes": id
        ]
        
        let _ = try await self.Store.onboarding.application.updateEntity(fields, entityId: entity!.id)
        self.loading = false
        self.Router.goTo(self.Store.onboarding.currentFlowPage)
    }
    
    var options: [Option]{
        return self.Store.onboarding.averageTransactions.map({
            return .init(
                id: String($0.id),
                label: $0.name
            )
        })
    }
    
    var body: some View {
        GeometryReader{ geometry in
            ScrollView{
                VStack(spacing: 0){
                    Header(back:{
                        self.Router.goTo(BusinessMoneySendView(), routingType: .backward)
                    }, title: "")
                    .padding(.bottom, 16)
                    TitleView(title: LocalizedStringKey("How many payments will you send each month?"), description: LocalizedStringKey("Give us your best estimate. This number doesn’t have to have precise"))
                        .padding(.horizontal, 16)
                    VStack{
                        ForEach(self.options, id: \.id){ option in
                            Button(LocalizedStringKey(option.label)){
                                Task{
                                    do{
                                        try await self.submit(option.id)
                                    }catch(let error){
                                        self.loading = false
                                        self.Error.handle(error)
                                    }
                                }
                            }
                            .disabled(self.loading)
                            .buttonStyle(.secondaryNext())
                        }
                    }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 24)
                    Spacer()
                }
                .frame(
                    maxWidth: .infinity,
                    minHeight: geometry.size.height - geometry.safeAreaInsets.bottom
                )
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationTitle("")
        .background(Color.get(.Background))
    }
}

struct BusinessPaymentsView_Previews: PreviewProvider {
    static var store: ApplicationStore {
        var store = ApplicationStore()
        return store
    }
    
    static var previews: some View {
        BusinessPaymentsView()
            .environmentObject(self.store)
    }
}
