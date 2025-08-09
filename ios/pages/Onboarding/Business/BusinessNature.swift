//
//  BusinessNature.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 29.11.2023.
//

import Foundation
import SwiftUI

struct BusinessNatureView: View, RouterPage {
    @EnvironmentObject var Store: ApplicationStore
    @EnvironmentObject var Error: ErrorHandlingService
    @EnvironmentObject var Router: RoutingController
    
    @State private var loading: Bool = false
    @State private var query: String = ""
    
    func submit(_ id: String) async throws{
        self.loading = true
        
        let entity = self.Store.onboarding.businessEntity
        
        if (entity == nil){
            throw ServiceError(title: "Entity not found", message: "Couldnt find Your Entity")
        }
        
        let fields:[String:Any] = [
            "GENnatureofbusiness": id
        ]
        
        let _ = try await self.Store.onboarding.application.updateEntity(fields, entityId: entity!.id)
        self.loading = false
        if (BusinessNatureView.isOtherSelected(id)){
            self.Router.goTo(BusinessDescriptionView())
            return;
        }
        self.Router.goTo(self.Store.onboarding.currentFlowPage)
    }
    
    static func isOtherSelected(_ id: String) ->Bool{
        return id == "39706" || id == "39708"
    }
    
    var options: [Option]{
        if (self.query.isEmpty){
            return self.Store.onboarding.businessCategories.map({
                return .init(id: String($0.id), label: $0.name)
            })
        }
        return self.Store.onboarding.businessCategories.map({
            return .init(id: String($0.id), label: $0.name)
        }).filter({ option in
            return option.label.lowercased().contains(self.query.lowercased())
        })
    }
    
    var body: some View {
        GeometryReader{ geometry in
            ScrollView{
                VStack(spacing: 0){
                    Header(back:{
                        self.Router.goTo(BusinessUsageView(), routingType: .backward)
                    }, title: "")
                        .padding(.bottom, 16)
                    TitleView(title: LocalizedStringKey("Nature of business"), description: LocalizedStringKey("Choose a category so we can verify your business faster"))
                        .padding(.horizontal, 16)
                        .padding(.bottom, 12)
                    SearchField(query: self.$query)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
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

struct BusinessNatureView_Previews: PreviewProvider {
    static var store: ApplicationStore {
        var store = ApplicationStore()
        store.onboarding.businessCategories = [
            .init(externalRef: "0", id: 1, name: "Option 1"),
            .init(externalRef: "0", id: 2, name: "Option 2"),
            .init(externalRef: "0", id: 3, name: "Option 3")
        ]
        return store
    }
    
    static var previews: some View {
        BusinessNatureView()
            .environmentObject(self.store)
    }
}

