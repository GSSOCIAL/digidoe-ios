//
//  ProfileDetailsView.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 29.09.2023.
//

import Foundation
import SwiftUI

struct ProfileDetailsView: View, RouterPage {
    @EnvironmentObject var Store: ApplicationStore
    @EnvironmentObject var Error: ErrorHandlingService
    @EnvironmentObject var Router: RoutingController
    
    @State private var uploadAvatarPopup: Bool = false
    @State private var fileSelection: Bool = false
    @State private var avatarLoading: Bool = false
    @State private var avatar: Data?
    
    func createImage(_ value: Data) -> Image {
        #if canImport(UIKit)
            let songArtwork: UIImage = UIImage(data: value) ?? UIImage()
            return Image(uiImage: songArtwork)
        #elseif canImport(AppKit)
            let songArtwork: NSImage = NSImage(data: value) ?? NSImage()
            return Image(nsImage: songArtwork)
        #else
            return Image("")
        #endif
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
    
    var body: some View {
        ApplicationNavigatorContainerView{
            GeometryReader{ geometry in
                ScrollView{
                    VStack(spacing: 0){
                        Header(back:{
                            self.Router.back()
                        }, title: "Profile Details", actions: {
                            /*
                            Button{
                                
                            } label: {
                                Navigator.navigate(Navigator.pages.Profile.menu){
                                    ZStack{
                                        Image("edit")
                                            .foregroundColor(Color.get(.DisabledText))
                                    }
                                    .frame(width: 24, height: 24)
                                }
                            }
                                .disabled(true)
                             */
                        })
                        HStack{
                            //MARK: Upload Avatar
                            Button{
                                self.uploadAvatarPopup = true
                            } label:{
                                ZStack{
                                    if self.avatar != nil{
                                        self.createImage(self.avatar!)
                                            .resizable()
                                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                                            .clipShape(Circle())
                                    }else if (self.Store.user.person != nil){
                                        Text([self.Store.user.person!.givenName, self.Store.user.person!.surname].map({ el in
                                            return String(el?.prefix(1) ?? "")
                                        }).joined(separator: ""))
                                        .font(.title3.bold())
                                        .foregroundColor(Color.get(.Pending))
                                        .multilineTextAlignment(.center)
                                    }
                                }
                                .frame(width:95,height:95)
                                .background(Color.get(.Section))
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(Color.black, style: .init(lineWidth: 1))
                                        .opacity(0.24)
                                )
                                .overlay(
                                    /*
                                    ZStack{
                                        Image("camera")
                                            .foregroundColor(Color.white)
                                    }
                                        .frame(width:30,height: 30)
                                        .background(Color.get(.Primary))
                                        .clipShape(Circle())
                                        .overlay(
                                            Circle()
                                                .stroke(Color.get(.Background), style: .init(lineWidth: 3))
                                        )
                                        .opacity(0)
                                     */
                                    EmptyView()
                                    , alignment: .bottomTrailing
                                )
                            }
                            .disabled(true)
                            .padding(.trailing, 12)
                            
                            VStack(alignment:.leading, spacing: 2){
                                Text([self.Store.user.person?.givenName ?? "", self.Store.user.person?.surname ?? ""].joined(separator: " "))
                                    .font(.title2.bold())
                                    .foregroundColor(Color.get(.Text))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Text(self.phone)
                                    .foregroundColor(Whitelabel.Color(.Primary))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .padding(.horizontal,16)
                        .padding(.bottom, 24)
                        VStack(spacing:10){
                            VStack(alignment: .leading, spacing: 4){
                                Text("Full Name")
                                    .foregroundColor(Color.get(.LightGray))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Text([self.Store.user.person?.givenName ?? "", self.Store.user.person?.surname ?? ""].joined(separator: " "))
                                    .font(.body.bold())
                                    .foregroundColor(Color.get(.Text))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            VStack(alignment: .leading, spacing: 4){
                                Text("Account phone number")
                                    .foregroundColor(Color.get(.LightGray))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Text(self.phone)
                                    .font(.body.bold())
                                    .foregroundColor(Color.get(.Text))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            VStack(alignment: .leading, spacing: 4){
                                Text("Account email")
                                    .foregroundColor(Color.get(.LightGray))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Text(self.Store.user.person?.email ?? "-")
                                    .font(.body.bold())
                                    .foregroundColor(Color.get(.Text))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                            .padding(.horizontal, 16)
                            .sheet(isPresented: self.$fileSelection){
                                ImagePickerView(
                                    isPresented: self.$fileSelection,
                                    onImport: { url in
                                        
                                    }
                                )
                            }
                        Spacer()
                        //MARK: Avatar uploader
                        BottomSheetContainer(isPresented: self.$uploadAvatarPopup){
                            HStack(spacing: 20){
                                Button{
                                    self.uploadAvatarPopup = false
                                    self.fileSelection = false
                                } label:{
                                    HStack{
                                        Text(LocalizedStringKey("Take photo"))
                                    }
                                }
                                .buttonStyle(.action(image:"scan", scheme: .light))
                                Button{
                                    self.uploadAvatarPopup = false
                                    DispatchQueue.main.asyncAfter(deadline:.now()+0.1){
                                        self.fileSelection = true
                                    }
                                } label:{
                                    HStack{
                                        Text(LocalizedStringKey("Select from files"))
                                    }
                                }
                                .buttonStyle(.action(image:"folder-add", scheme: .light))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top,10)
                            .padding(.horizontal,10)
                        }
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
        .edgesIgnoringSafeArea(.bottom)
        .background(Color.get(.Background))
    }
}

struct ProfileDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        ContentViewContainerPreview{
            ProfileDetailsView()
        }
    }
}

