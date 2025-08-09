//
//  isEMICompay.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 22.11.2023.
//

import Foundation
import SwiftUI

struct EMICompanyView: View, RouterPage {
    @EnvironmentObject var Store: ApplicationStore
    @EnvironmentObject var Error: ErrorHandlingService
    @EnvironmentObject var Router: RoutingController
    
    @State private var loading: Bool = false
    @State private var value: String = ""
    
    func submit() async throws{
        self.loading = true
        do{
            self.loading = false
            self.Router.goTo(BusinessCurrencyView())
        }catch(let error){
            self.loading = false
            throw error
        }
    }
    
    var body: some View {
        GeometryReader{ geometry in
            ScrollView{
                    VStack(spacing: 0){
                        Header(back:{
                            self.Router.back()
                        }, title: "")
                        .padding(.bottom, 16)
                        TitleView(title: LocalizedStringKey("Are you planning to utilize your accounts to function as an Electronic Money Institution (EMI)?"), description: LocalizedStringKey("If so, we can arrange specialized EMI accounts for your ease."))
                            .padding(.horizontal, 16)
                        RadioGroup(items: [], value: self.$value)
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
                            .disabled(self.loading)
                            .buttonStyle(.primary())
                            .padding(.horizontal, 16)
                            .loader(self.$loading)
                    }
                    .frame(
                        maxWidth: .infinity,
                        minHeight: geometry.size.height - geometry.safeAreaInsets.bottom
                    )
                }
        }
        .navigationBarBackButtonHidden(true)
        .navigationTitle("")
    }
}

struct EMICompanyView_Previews: PreviewProvider {
    static var store: ApplicationStore {
        var store = ApplicationStore()
        return store
    }
    
    static var previews: some View {
        EMICompanyView()
            .environmentObject(self.store)
    }
}
