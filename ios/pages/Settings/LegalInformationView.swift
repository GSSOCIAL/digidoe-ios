//
//  LegalInformationView.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 30.09.2023.
//

import Foundation
import SwiftUI

struct LegalInformationView: View, RouterPage {
    @EnvironmentObject var Store: ApplicationStore
    @EnvironmentObject var Error: ErrorHandlingService
    @EnvironmentObject var Router: RoutingController
    
    var body: some View {
        ApplicationNavigatorContainerView{
            GeometryReader{ geometry in
                ScrollView{
                    VStack(spacing: 0){
                        Header(back:{
                            self.Router.back()
                        }, title: "Legal Information")
                        .padding(.bottom, 16)
                        VStack(spacing:0){
                            Button{
                                self.Router.goTo(PrivacyPolicyView())
                            } label:{
                                HStack{
                                    Text("Privacy policy")
                                    Spacer()
                                }
                            }
                                .buttonStyle(.next(image:"Content, Edit - Liner"))
                                .frame(maxWidth: .infinity)
                            
                            Divider()
                                .overlay(Color("Divider"))
                            
                            Button{
                                self.Router.goTo(TermsConditionsView())
                            } label:{
                                HStack{
                                    Text("Terms & condition")
                                    Spacer()
                                }
                            }
                                .buttonStyle(.next(image:"info"))
                                .frame(maxWidth: .infinity)
                        }
                        .padding(.top, 16)
                        Spacer()
                    }
                    .frame(
                        maxWidth: .infinity,
                        minHeight: geometry.size.height - geometry.safeAreaInsets.bottom
                    )
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationTitle("")
        .background(Color.get(.Background))
    }
}

struct LegalInformationView_Previews: PreviewProvider {
    static var previews: some View {
        ContentViewContainerPreview{
            LegalInformationView()
        }
    }
}
