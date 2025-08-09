//
//  CustomerLockedState.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 11.12.2023.
//

import Foundation
import SwiftUI

struct CustomerLockedView: View, RouterPage {
    @EnvironmentObject var Store: ApplicationStore
    @EnvironmentObject var Error: ErrorHandlingService
    @EnvironmentObject var Router: RoutingController
    
    @State private var loading: Bool = false
    
    func signout() async throws{
        self.loading = true
        try await self.Store.logout()
        self.loading = false
        self.Router.home()
    }
    
    var body: some View {
        GeometryReader{ geometry in
            ZStack{
                Image("pat8")
                    .ignoresSafeArea()
                    .zIndex(2)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .blur(radius: 20)
                ScrollView{
                    VStack(alignment:.center){
                        Spacer()
                        ZStack{
                            Image(Whitelabel.Image(.logo))
                                .resizable()
                                .scaledToFit()
                        }
                            .frame(
                                width: 150,
                                height: 50
                            )
                        .padding(.bottom,50)
                        VStack(alignment:.center,spacing:10){
                            HStack(alignment: .center){
                                Text("Account is inactive")
                                    .multilineTextAlignment(.center)
                                    .foregroundColor(Color.get(.Text))
                            }
                            .font(.title.bold())
                        }
                        .padding(.horizontal, 16)
                        Spacer()
                        Button("Logout"){
                            Task{
                                do{
                                    try await self.signout()
                                }catch(let error){
                                    self.loading = false
                                    self.Error.handle(error)
                                }
                            }
                        }.buttonStyle(.secondaryDanger())
                    }
                    .frame(
                        maxWidth: .infinity,
                        minHeight: geometry.size.height - geometry.safeAreaInsets.bottom
                    )
                }
                .zIndex(3)
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationTitle("")
        .background(Color.get(.Background))
    }
}

struct CustomerLockedView_Previews: PreviewProvider {
    static var store: ApplicationStore {
        var store = ApplicationStore()
        return store
    }
    
    static var previews: some View {
        CustomerLockedView()
            .environmentObject(self.store)
    }
}
