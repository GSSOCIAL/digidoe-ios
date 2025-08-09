//
//  ProfileDetailsView.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 28.09.2023.
//

import Foundation
import SwiftUI

struct ProfileMenuView: View, RouterPage {
    @EnvironmentObject var Store: ApplicationStore
    @EnvironmentObject var Error: ErrorHandlingService
    @EnvironmentObject var Router: RoutingController
    
    @State private var scrollOffset : Double = 0
    
    @State private var loading: Bool = false
    @State private var inviteSheet:Bool = false
    
    var customerFullName: String{
        if (self.Store.user.person != nil){
            return [self.Store.user.person?.givenName ?? "", self.Store.user.person?.surname ?? ""].joined(separator: " ")
        }
        return ""
    }
    
    var phone: String{
        var formatted = self.Store.user.person?.phone ?? ""
        
        if(formatted.isEmpty){
            return "-"
        }
        
        var startOffset: Int = 0
        var endOffset: Int = 0
        var maskLength: Int = 4
        
        if (formatted.count > 8){
            startOffset = -6
            endOffset = 2
        }else if(formatted.count > 5){
            startOffset = -4
            endOffset = 2
            maskLength = 2
        }else if(formatted.count > 3){
            startOffset = -2
            endOffset = 1
            maskLength = 1
        }else{
            startOffset = -1
            endOffset = 1
            maskLength = 1
        }
        
        let mask: String = (0...maskLength).map({ _ in return "*" }).joined(separator: "")
        let last = String(formatted.suffix(endOffset))
        
        formatted = [formatted.substring(to: formatted.index(formatted.endIndex, offsetBy: startOffset)),mask,last].joined(separator: "")
        return formatted
    }
    
    var profileNavigationItems: some View{
        VStack(alignment: .leading, spacing:0){
            /*
            Button{
                
            } label:{
                Navigator.navigate(Navigator.pages.Account.open){
                    HStack{
                        Text("Add Account")
                        Spacer()
                    }
                }
            }
            .buttonStyle(.next(image: "money"))
            .frame(maxWidth: .infinity)
            */
            Button{
                self.Router.goTo(SupportView())
            } label:{
                HStack{
                    Text("Support")
                    Spacer()
                }
            }
                .buttonStyle(.next(image:"message"))
                .frame(maxWidth: .infinity)
            
            Button{
                self.Router.goTo(SettingsView())
            } label:{
                HStack{
                    Text("Settings & Information")
                    Spacer()
                }
            }
                .buttonStyle(.next(image:"cog"))
                .frame(maxWidth: .infinity)
            
            Button{
                self.inviteSheet = true
            } label:{
                Text("Invite friends to \(Whitelabel.BrandName())")
            }
            .buttonStyle(.next(image: "Business - Liner"))
            .frame(maxWidth: .infinity)
            
            Divider()
                .overlay(Color.get(.Divider))
            
            Button{
                Task{
                    do{
                        try await self.Store.logout()
                        self.Router.home()
                    }
                }
            } label:{
                HStack{
                    Text("Log out")
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.danger(image: "logout"))
        }
    }
    
    var body: some View {
        ApplicationNavigatorContainerView{
            GeometryReader{ geometry in
                ScrollView{
                    VStack(spacing: 0){
                        Header(back:{
                            self.Router.back()
                        }, title: "Profile", scheme: .light)
                            .transformEffect(.init(translationX: 0, y: scrollOffset * 0.3))
                        VStack(spacing: 0){
                            HStack(spacing:12){
                                ZStack{
                                    if (self.Store.user.person != nil){
                                        Text([self.Store.user.person!.givenName, self.Store.user.person!.surname].map({ el in
                                            return String(el?.prefix(1) ?? "")
                                        }).joined(separator: ""))
                                        .font(.subheadline.bold())
                                        .foregroundColor(Color.get(.Pending))
                                        .multilineTextAlignment(.center)
                                    }
                                }
                                .frame(width: 64, height: 64)
                                .background(Color.get(.Section))
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(Color.black, style: .init(lineWidth: 1))
                                        .opacity(0.24)
                                )
                                Button{
                                    self.Router.goTo(ProfileDetailsView())
                                } label:{
                                    VStack(alignment:.leading){
                                        Text(self.customerFullName)
                                            .font(.body.bold())
                                            .foregroundColor(Color.get(.Text))
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        Text(self.phone)
                                            .foregroundColor(Color.get(.LightGray))
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        Text("See Details")
                                            .foregroundColor(Whitelabel.Color(.Primary))
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                            }
                                .padding(16)
                                .background(Color.get(.Section))
                                .clipShape(
                                    RoundedRectangle(cornerRadius: 16)
                                )
                                .padding(16)
                                self.profileNavigationItems
                                Spacer()
                        }
                            .padding(.bottom, geometry.safeAreaInsets.bottom)
                            .frame(maxWidth: .infinity)
                            .background(Color.get(.Background))
                            .clipShape(
                                RoundedRectangle(cornerRadius: 16)
                            )
                            .padding(.top, 10)
                    }
                        .frame(
                            maxWidth: .infinity,
                            minHeight: geometry.size.height - geometry.safeAreaInsets.bottom
                        )
                        .background(GeometryReader {
                            Color.clear.preference(key: ViewOffsetKey.self, value: -$0.frame(in: .named("scroll")).origin.y)
                        })
                        .onPreferenceChange(ViewOffsetKey.self) { position in
                            self.scrollOffset = position
                        }
                }
                    .coordinateSpace(name: "scroll")
            }
            .background(
                ZStack{
                    LinearGradient(colors: [Whitelabel.Color(.Primary),Whitelabel.Color(.Secondary)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    RadialGradient(colors: [Whitelabel.Color(.Secondary),Color.clear], center: .top, startRadius: 0, endRadius: 180)
                        .transformEffect(.init(translationX: 0 + scrollOffset / 1.3, y: 0))
                        .opacity(0.6)
                }.ignoresSafeArea()
            )
            .overlay(
                Rectangle()
                    .foregroundColor(Color.get(.Background))
                    .frame(maxWidth: .infinity, maxHeight: 20 + self.scrollOffset)
                ,alignment: .bottom
            )
            .sheet(isPresented:self.$inviteSheet){
                ShareSheet(
                    activityItems: ["\(self.customerFullName) has invited you to join \(Whitelabel.BrandName()). Please click on this link to registered with \(Whitelabel.BrandName()): \(Enviroment.shareUrl)"],
                    callback: { activityType,completed,returnedItems,error in
                        self.inviteSheet = false
                    }
                )
            }
        }
        .environmentObject(self.Store)
        .environmentObject(self.Error)
        .navigationBarBackButtonHidden(true)
        .navigationTitle("")
        .edgesIgnoringSafeArea(.bottom)
    }
}

struct ProfileMenuView_Previews: PreviewProvider {
    static var previews: some View {
        ContentViewContainerPreview{
            ProfileMenuView()
        }
    }
}
