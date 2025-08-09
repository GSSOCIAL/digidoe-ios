//
//  BusinessMoneySend.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 29.11.2023.
//

import Foundation
import SwiftUI

struct BusinessMoneySendView: View, RouterPage {
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
            "GENaveragetransactionvalue": id
        ]
        
        let _ = try await self.Store.onboarding.application.updateEntity(fields, entityId: entity!.id)
        self.loading = false
        self.Router.goTo(self.Store.onboarding.currentFlowPage)
    }
    
    var options: [Option]{
        return self.Store.onboarding.paymentsPerMonth.map({
            return .init(id: String($0.id), label: $0.name)
        })
    }
    
    var body: some View {
        GeometryReader{ geometry in
            ScrollView{
                VStack(spacing: 0){
                    Header(back:{
                        self.Router.goTo(BusinessTurnoverView(), routingType: .backward)
                    }, title: "")
                        .padding(.bottom, 16)
                    TitleView(title: LocalizedStringKey("How much money will be sent out from your account each month?"), description: LocalizedStringKey("Give your best estimate"))
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

struct BusinessMoneySendView_Previews: PreviewProvider {
    static var store: ApplicationStore {
        var store = ApplicationStore()
        return store
    }
    
    static var previews: some View {
        BusinessMoneySendView()
            .environmentObject(self.store)
    }
}



