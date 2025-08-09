//
//  BusinessRegulatorory.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 29.11.2023.
//

import Foundation
import SwiftUI

struct BusinessRegulatoryView: View, RouterPage{
    @EnvironmentObject var Store: ApplicationStore
    @EnvironmentObject var Error: ErrorHandlingService
    @EnvironmentObject var Router: RoutingController
    
    @State private var loading: Bool = false
    @State private var regulatorName: String = ""
    @State private var regulatorReference: String = ""
    
    func submit() async throws{
        self.loading = true
        
        let entity = self.Store.onboarding.businessEntity
        
        if (entity == nil){
            throw ServiceError(title: "Entity not found", message: "Couldnt find Your Entity")
        }
        
        let fields = [
            "GENregulator": self.regulatorName,
            "GENregulatorrefencenumber": self.regulatorReference
        ]
        
        let _ = try await self.Store.onboarding.application.updateEntity(fields, entityId: entity!.id)
        self.loading = false
        self.Router.goTo(self.Store.onboarding.currentFlowPage)
    }
    
    var body: some View {
        GeometryReader{ geometry in
            ScrollView{
                VStack(spacing: 0){
                    Header(back:{
                        self.Router.goTo(BusinessRegulatedView(), routingType: .backward)
                    }, title: "")
                        .padding(.bottom, 16)
                    TitleView(title: LocalizedStringKey("Regulatory body details"), description: LocalizedStringKey("Please tell us whether your operate under the supervision of a regulatory body"))
                        .padding(.horizontal, 16)
                    VStack(spacing:24){
                        CustomField(value: self.$regulatorName, placeholder: "Regulatory body name", type: .text)
                            .disabled(self.loading)
                        CustomField(value: self.$regulatorReference, placeholder: "Referance number", type: .text)
                            .disabled(self.loading)
                    }
                        .padding(.horizontal, 16)
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
                        .disabled(self.loading || self.regulatorName.isEmpty || self.regulatorReference.isEmpty)
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
                    if (businessEntity != nil){
                        if(businessEntity!.has("GENregulator")){
                            self.regulatorName = businessEntity!.at("GENregulator")!
                        }
                        if(businessEntity!.has("GENregulatorrefencenumber")){
                            self.regulatorReference = businessEntity!.at("GENregulatorrefencenumber")!
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

struct BusinessRegulatoryView_Previews: PreviewProvider {
    static var store: ApplicationStore {
        var store = ApplicationStore()
        return store
    }
    
    static var previews: some View {
        BusinessRegulatoryView()
            .environmentObject(self.store)
    }
}
