//
//  BusinessCountryOfOperation.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 29.11.2023.
//

import Foundation
import SwiftUI

struct BusinessCountryOfOperationView: View, RouterPage {
    @EnvironmentObject var Store: ApplicationStore
    @EnvironmentObject var Error: ErrorHandlingService
    @EnvironmentObject var Router: RoutingController
    
    @State private var loading: Bool = false
    @State private var value: Array<String> = []
    
    func submit() async throws{
        self.loading = true
        
        let entity = self.Store.onboarding.businessEntity
        
        if (entity == nil){
            throw ServiceError(title: "Entity not found", message: "Couldnt find Your Entity")
        }
        
        let fields:[String:Any] = [
            "GENcountriesofbusiness": self.value
        ]
        
        let _ = try await self.Store.onboarding.application.updateEntity(fields, entityId: entity!.id)
        self.loading = false
        self.Router.goTo(self.Store.onboarding.currentFlowPage)
    }
    
    var countries: [Option]{
        return self.Store.onboarding.countries.map({
            return .init(id: String($0.id), label: $0.name)
        })
    }
    
    var body: some View {
        GeometryReader{ geometry in
            ScrollView{
                VStack(spacing: 0){
                    Header(back:{
                        self.Router.goTo(BusinessCompanyTypeView(), routingType: .backward)
                    }, title: "")
                    .padding(.bottom, 16)
                    ZStack{
                        Image("globeSplash")
                            .frame(maxWidth: .infinity)
                        Image("globeWithMark")
                            .frame(maxWidth: .infinity)
                    }
                    .padding(.bottom,20)
                    TitleView(
                        title: LocalizedStringKey("Countries of operation or physical presence"),
                        description: LocalizedStringKey("Please select the country where your business operates from")
                    )
                        .padding(.horizontal, 16)
                    CountrySelector(value: self.$value, options: self.countries)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 24)
                        .disabled(self.loading)
                    VStack(spacing:24){
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
                        if (businessEntity != nil && businessEntity!.has("GENcountriesofbusiness")){
                            self.value = businessEntity!.atArray("GENcountriesofbusiness")!
                        }
                    }
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationTitle("")
        .background(Color.get(.Background))
    }
}

struct BusinessCountryOfOperationView_Previews: PreviewProvider {
    static var store: ApplicationStore {
        var store = ApplicationStore()
        return store
    }
    
    static var previews: some View {
        BusinessCountryOfOperationView()
            .environmentObject(self.store)
    }
}

