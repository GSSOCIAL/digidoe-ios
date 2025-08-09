//
//  BusinessType.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 29.11.2023.
//

import Foundation
import SwiftUI

struct BusinessTypeView: View, RouterPage {
    @EnvironmentObject var Store: ApplicationStore
    @EnvironmentObject var Error: ErrorHandlingService
    @EnvironmentObject var Router: RoutingController
    
    @State private var loading: Bool = false
    @State private var value: String = ""
    
    func submit() async throws{
        self.loading = true
        
        let entity = self.Store.onboarding.businessEntity
        
        if (entity == nil){
            throw ServiceError(title: "Entity not found", message: "Couldnt find Your Entity")
        }
        
        let fields:[String:Any] = [
            "GENstructure": self.value
        ]
        
        let _ = try await self.Store.onboarding.application.updateEntity(fields, entityId: entity!.id)
        self.loading = false
        self.Router.goTo(self.Store.onboarding.currentFlowPage)
    }
    
    var options: [Option]{
        return self.Store.onboarding.companyStructure.map({
            return .init(id: String($0.id), label: $0.name)
        })
    }
    
    var body: some View {
        GeometryReader{ geometry in
            ScrollView{
                VStack(spacing: 0){
                    Header(back:{
                        self.Router.goTo(BusinessCompanySizeView(), routingType: .backward)
                    }, title: "")
                        .padding(.bottom, 16)
                    TitleView(title: LocalizedStringKey("Type of business"), description: LocalizedStringKey("Please select complex if any of your shareholders is a legal entity or your business operates as a holding company or you have any legal entities as subsidiaries"))
                        .padding(.horizontal, 16)
                    RadioGroup(items: self.options, value: self.$value)
                        .padding(.horizontal, 16)
                        .disabled(self.loading)
                        .padding(.vertical, 24)
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
                    .disabled(self.loading || self.value.isEmpty)
                        .buttonStyle(.primary())
                        .padding(.horizontal, 16)
                        .loader(self.$loading)
                }
                .frame(
                    maxWidth: .infinity,
                    minHeight: geometry.size.height - geometry.safeAreaInsets.bottom
                )
                .onAppear{
                    let businessEntity = self.Store.onboarding.businessEntity
                    if (businessEntity != nil && businessEntity!.has("GENstructure")){
                        self.value = businessEntity!.at("GENstructure")!
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationTitle("")
        .background(Color.get(.Background))
    }
}

struct BusinessTypeView_Previews: PreviewProvider {
    static var store: ApplicationStore {
        var store = ApplicationStore()
        return store
    }
    
    static var previews: some View {
        BusinessTypeView()
            .environmentObject(self.store)
    }
}

