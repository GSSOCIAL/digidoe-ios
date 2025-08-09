//
//  AboutAppView.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 30.09.2023.
//

import Foundation
import SwiftUI

struct AboutAppView: View, RouterPage{
    @EnvironmentObject var Store: ApplicationStore
    @EnvironmentObject var Error: ErrorHandlingService
    @EnvironmentObject var Router: RoutingController
    
    let service: AppVersion = AppVersion()
    @State var appHasUpdate = false
    
    var body: some View {
        ApplicationNavigatorContainerView{
            GeometryReader{ geometry in
                ScrollView{
                    VStack(spacing: 0){
                        Header(back:{
                            self.Router.back()
                        }, title: "About App")
                            .padding(.bottom, 16)
                        Spacer()
                        VStack{
                            ZStack{
                                Image(Whitelabel.Image(.logo))
                                    .resizable()
                                    .scaledToFit()
                            }
                                .frame(
                                    width: 150,
                                    height: 50
                                )
                            Group{
                                Text("Version \(self.service.current)")
                                    .padding(.top,20)
                                    .padding(.bottom,1)
                                    .font(.body)
                                    .foregroundColor(Color.get(.Text))
                                Text("Build \(self.service.build)")
                                    .font(.caption)
                                    .foregroundColor(Color.get(.LightGray))
                            }
                        }
                        .padding(.horizontal, 16)
                        Spacer()
                        BottomSheetContainer(isPresented: self.$appHasUpdate){
                            VStack{
                                Text("New version available")
                                    .font(.title.bold())
                                    .foregroundColor(Color.get(.Text, scheme: .light))
                                    .padding(.bottom,5)
                                    .frame(maxWidth: .infinity,alignment: .leading)
                                Text("New version available on the AppStore. Please, update the app")
                                    .font(.subheadline)
                                    .foregroundColor(Color.get(.LightGray, scheme: .light))
                                    .padding(.bottom,20)
                                    .frame(maxWidth: .infinity,alignment: .leading)
                                HStack(spacing:10){
                                    Button{
                                        self.appHasUpdate = false
                                    } label:{
                                        HStack{
                                            Spacer()
                                            Text("Later")
                                            Spacer()
                                        }
                                    }
                                    .buttonStyle(.secondary())
                                    Button{
                                        self.appHasUpdate = false
                                        
                                        let url = URL(string: Enviroment.appUrl)
                                        UIApplication.shared.open(url!)
                                    } label:{
                                        HStack{
                                            Spacer()
                                            Text("Update")
                                            Spacer()
                                        }
                                    }
                                    .buttonStyle(.primary())
                                }
                            }
                            .padding(20)
                            .padding(.top,10)
                            .onAppear{
                                let tapticFeedback = UINotificationFeedbackGenerator()
                                tapticFeedback.notificationOccurred(.error)
                            }
                        }
                    }
                    .frame(
                        maxWidth: .infinity,
                        minHeight: geometry.size.height - geometry.safeAreaInsets.bottom
                    )
                    .onAppear{
                        Task{
                            do{
                                var hasUpdates = try await self.service.hasUpdates()
                                if hasUpdates == true{
                                    self.appHasUpdate = true
                                }
                            }catch(let error){
                                self.Error.handle(error)
                            }
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

struct AboutAppView_Previews: PreviewProvider {
    static var previews: some View {
        ContentViewContainerPreview{
            AboutAppView()
        }
    }
}
