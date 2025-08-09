//
//  BusinessRegulated.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 29.11.2023.
//

import Foundation
import SwiftUI

struct BusinessRegulatedView: View, RouterPage {
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
            "GENregulatedbusiness": id
        ]
        
        let _ = try await self.Store.onboarding.application.updateEntity(fields, entityId: entity!.id)
        self.loading = false
        
        if(self.Store.onboarding.regulatedPositiveOption != nil && String(self.Store.onboarding.regulatedPositiveOption!.id) == id){
            self.Router.goTo(BusinessRegulatoryView())
            return;
        }
        self.Router.goTo(self.Store.onboarding.currentFlowPage)
    }
    
    var options: [Option]{
        return self.Store.onboarding.regulatedOptions.map({
            return .init(id: String($0.id), label: $0.name)
        })
    }
    
    var body: some View {
        GeometryReader{ geometry in
            ScrollView{
                VStack(spacing: 0){
                    Header(back:{
                        let entity = self.Store.onboarding.businessEntity
                        if (entity != nil && entity!.has("GENnatureofbusiness")){
                            let option = entity!.at("GENnatureofbusiness")
                            if (option != nil){
                                if (BusinessNatureView.isOtherSelected(option!)){
                                    self.Router.goTo(BusinessDescriptionView(), routingType: .backward)
                                }
                            }
                        }
                        self.Router.goTo(BusinessNatureView(), routingType: .backward)
                    }, title: "")
                        .padding(.bottom, 16)
                    TitleView(
                        title: LocalizedStringKey("Is your business regulated?"),
                        description: LocalizedStringKey("Please tell us whether your operate under the supervision of a regulatory body")
                    )
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

struct BusinessRegulatedView_Previews: PreviewProvider {
    static var store: ApplicationStore {
        var store = ApplicationStore()
        return store
    }
    
    static var previews: some View {
        BusinessRegulatedView()
            .environmentObject(self.store)
    }
}
