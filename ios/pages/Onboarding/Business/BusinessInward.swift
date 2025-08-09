//
//  BusinessInward.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 29.11.2023.
//

import Foundation
import SwiftUI

struct BusinessInwardTransactionsView: View, RouterPage{
    @EnvironmentObject var Store: ApplicationStore
    @EnvironmentObject var Error: ErrorHandlingService
    @EnvironmentObject var Router: RoutingController
    
    @State private var loading: Bool = false
    
    func submit(_ id : String) async throws{
        self.loading = true
        /*
        guard self.Store.onboarding.application != nil else{
            throw ServiceError(title: "Application not found", message: "Application not found. Please try again")
        }
        let businessEntityId = self.Store.onboarding.application?.getBusinessId()
        guard businessEntityId != nil else{
            throw ServiceError(title: "Entity not found", message: "Couldnt find Your Entity")
        }
        
        let fields = [
            "": ""
        ]
        let _ = try await services.kycp.updateEntity(fields, application: self.Store.onboarding.application, entityId: businessEntityId)
        
        //self.Store.onboarding.business.usage = ""
        self.loading = false
        self.Router.goTo(BusinessCompanySizeView())
         */
    }
    
    var options: [Option]{
        return self.Store.onboarding.corporateServices.map({
            return .init(id: String($0.id), label: $0.name)
        })
    }
    
    var body: some View {
        GeometryReader{ geometry in
            ScrollView{
                VStack(spacing: 0){
                    Header(back:{
                        self.Router.goTo(BusinessDepositView(), routingType: .backward)
                    }, title: "")
                    .padding(.bottom, 16)
                    TitleView(title: LocalizedStringKey("Volume of inward transactions by count per month"), description: LocalizedStringKey("Give your best estimate"))
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

struct BusinessInwardTransactionsView_Previews: PreviewProvider {
    static var store: ApplicationStore {
        var store = ApplicationStore()
        return store
    }
    
    static var previews: some View {
        BusinessInwardTransactionsView()
            .environmentObject(self.store)
    }
}

