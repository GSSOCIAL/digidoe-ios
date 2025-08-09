//
//  BusinessLargestSingle.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 29.11.2023.
//

import Foundation
import SwiftUI

struct BusinessLargestSinglePaymentView: View, RouterPage {
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
            "GENsinglelargestpayment": self.value.replacingOccurrences(of: ",", with: "")
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
                        self.Router.goTo(BusinessPaymentsView(), routingType: .backward)
                    }, title: "")
                        .padding(.bottom, 16)
                    TitleView(title: LocalizedStringKey("What is the single largest payment value that you expect each month?"), description: LocalizedStringKey("Give us  your best estimate. This number doesn’t have to be precise"))
                        .padding(.horizontal, 16)
                    CustomField(value: self.$value, placeholder: "Maximum single payment", type: .price)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 24)
                        .disabled(self.loading)
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
                    if (businessEntity != nil && businessEntity!.has("GENsinglelargestpayment")){
                        self.value = businessEntity!.at("GENsinglelargestpayment")!
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationTitle("")
        .background(Color.get(.Background))
    }
}

struct BusinessLargestSinglePaymentView_Previews: PreviewProvider {
    static var store: ApplicationStore {
        var store = ApplicationStore()
        return store
    }
    
    static var previews: some View {
        BusinessLargestSinglePaymentView()
            .environmentObject(self.store)
    }
}

