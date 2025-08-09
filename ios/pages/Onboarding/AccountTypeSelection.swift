//
//  AccountTypeSelection.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 19.11.2023.
//

import Foundation
import SwiftUI

struct AccountTypeSelectionView: View, RouterPage {
    @EnvironmentObject var Store: ApplicationStore
    @EnvironmentObject var Error: ErrorHandlingService
    @EnvironmentObject var Router: RoutingController
    
    var body: some View {
        GeometryReader{ geometry in
            ScrollView{
                VStack(spacing: 0){
                    VStack(spacing:0){
                        HStack(alignment:.center){
                            Image(Whitelabel.Image(.logo))
                                .resizable()
                                .scaledToFit()
                        }
                        .frame(
                            width: 150,
                            height: 50
                        )
                        .padding(.bottom,20)
                        Image("signup")
                            .resizable()
                            .scaledToFit()
                            .padding(.bottom,20)
                    }
                    .padding(.top, 50)
                    VStack(alignment:.leading, spacing: 0){
                        VStack(alignment: .leading, spacing: 10){
                            Text(LocalizedStringKey("Welcome to \(Whitelabel.BrandName())"))
                                .font(.title.bold())
                                .frame(maxWidth: .infinity,alignment: .topLeading)
                                .foregroundColor(Color.get(.Text))
                                .padding(.bottom,0)
                            Text(LocalizedStringKey("Everything you need to run your business in one place"))
                                .frame(maxWidth: .infinity, alignment: .topLeading)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                                .foregroundColor(Color.get(.LightGray))
                                .padding(0)
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 12)
                        VStack(alignment: .leading, spacing: 12){
                            Button{
                                self.Router.goTo(CountryOfIncorporationView())
                            } label: {
                                HStack{
                                    Text(LocalizedStringKey("Create a company account"))
                                }
                            }
                            .buttonStyle(.detailed(image:"briefcase", description:"Get your company on \(Whitelabel.BrandName())"))
                            Button{
                                self.Router.goTo(CurrencyIndividualSelectView())
                            } label: {
                                HStack{
                                    Text(LocalizedStringKey("Create an Individual account"))
                                }
                            }
                            .buttonStyle(.detailed(image:"user", description:"Get your freelance activity on \(Whitelabel.BrandName())"))
                        }
                        .padding(.horizontal, 16)
                    }
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

struct AccountTypeSelectionView_Previews: PreviewProvider {
    static var store: ApplicationStore {
        var store = ApplicationStore()
        return store
    }
    
    static var previews: some View {
        AccountTypeSelectionView()
            .environmentObject(self.store)
    }
}
