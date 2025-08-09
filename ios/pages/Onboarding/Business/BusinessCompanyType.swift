//
//  BusinessCompanyType.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 28.11.2023.
//

import Foundation
import SwiftUI

struct BusinessCompanyTypeView: View, RouterPage{
    @EnvironmentObject var Store: ApplicationStore
    @EnvironmentObject var Error: ErrorHandlingService
    @EnvironmentObject var Router: RoutingController
    
    @State private var loading: Bool = false
    @State private var companyType: String = ""
    
    func submit() async throws{
        self.loading = true
        
        let entity = self.Store.onboarding.businessEntity
        
        if (entity == nil){
            throw ServiceError(title: "Entity not found", message: "Couldnt find Your Entity")
        }
        
        let fields:[String:String] = [
            "GENcompanytype": self.companyType
        ]
        
        let _ = try await self.Store.onboarding.application.updateEntity(fields, entityId: entity!.id)
        self.loading = false
        self.Router.goTo(self.Store.onboarding.currentFlowPage)
    }
    
    var types: [Option]{
        return self.Store.onboarding.companyTypes.map({
            return .init(id: String($0.id), label: $0.name)
        })
    }
    
    var body: some View {
        GeometryReader{ geometry in
            ScrollView{
                    VStack(spacing: 0){
                        ZStack{
                            
                        }
                            .frame(maxWidth: .infinity, maxHeight: 50)
                            .padding(.bottom, 16)
                        Image("welcomeCompanyImage")
                            .edgesIgnoringSafeArea([.leading])
                            .offset(x: -25)
                        TitleView(
                            title: LocalizedStringKey("Select type of your company"),
                            description: LocalizedStringKey("Please select the type of business or company"))
                            .padding(.horizontal, 16)
                        VStack(spacing:24){
                            CustomField(value: self.$companyType, placeholder: "Type of Company", type: .select, options: self.types, searchable: true)
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
                            .disabled(self.loading || self.companyType.isEmpty)
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
                        if (businessEntity != nil && businessEntity!.has("GENcompanytype")){
                            self.companyType = businessEntity!.at("GENcompanytype")!
                        }
                    }
                }
        }
        .navigationBarBackButtonHidden(true)
        .navigationTitle("")
        .background(Color.get(.Background))
        .background(
            ZStack{
                Image("pat6")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
            }.ignoresSafeArea(.all), alignment: .top
        )
    }
}

struct BusinessCompanyTypeView_Previews: PreviewProvider {
    static var store: ApplicationStore {
        var store = ApplicationStore()
        return store
    }
    
    static var previews: some View {
        BusinessCompanyTypeView()
            .environmentObject(self.store)
    }
}

