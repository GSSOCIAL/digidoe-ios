//
//  IdentityView.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 17.11.2023.
//

import Foundation
import SwiftUI

struct IdentityView: View,RouterPage {
    @EnvironmentObject var Store: ApplicationStore
    @EnvironmentObject var Error: ErrorHandlingService
    @EnvironmentObject var Router: RoutingController
    @EnvironmentObject var notificationManager: NotificationManager
    @EnvironmentObject var identity: AuthenticationService
    
    @State private var step: Int = 0
    @State private var userLoginStatus: Int = 0
    @State private var userLoginErrorPopup: Bool = false
    @GestureState var offset: CGFloat = 0
    
    @State var currentWindow: UIWindow?
    
    @State private var createPerson: Bool = false
    @State private var selectType: Bool = false
    @State private var processAuthentification: Bool = false
    
    func slide(title: String, description: String) -> some View{
        return VStack(spacing:0){
            HStack{
                ZStack{
                    Image(Whitelabel.Image(.logo))
                        .resizable()
                        .scaledToFit()
                }
                .frame(
                    width: 110,
                    height: 36
                )
                Spacer()
            }
            .padding(16)
            Spacer()
            VStack(alignment:.leading, spacing: 10){
                Text(LocalizedStringKey(title))
                    .foregroundColor(Color.get(.Text))
                    .font(.title.bold())
                    .padding(.horizontal, 16)
                    .frame(alignment: .topLeading)
                
                Text(LocalizedStringKey(description))
                    .foregroundColor(Color.get(.Text))
                    .padding(.horizontal, 16)
                    .frame(alignment: .topLeading)
                    .padding(.bottom,50)
            }
            .frame(maxHeight: 300, alignment: .topLeading)
        }
    }
    
    var signSlide: some View{
        ZStack{
            Image("pat8")
                .ignoresSafeArea()
                .zIndex(2)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .blur(radius: 20)
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
                        Text("Welcome to")
                            .foregroundColor(Color.get(.Text))
                        Text(Whitelabel.BrandName())
                            .foregroundColor(
                                Whitelabel.Color(.Primary)
                            )
                    }
                    .font(.title.bold())
                    Text("Our Finance Solutions as a service offers a centralised entry for financial service providers.")
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .foregroundColor(Color.get(.LightGray))
                }
                Spacer()
                if currentWindow != nil{
                    ZStack{
                        ZStack{
                            switch(self.identity.state){
                            case .authenticating, .accessCodeReceived, .authenticated:
                                ZStack{
                                    Loader(size: .small)
                                }
                            default:
                                Button{
                                    self.Store.processLoginURL = nil
                                    self.Store.processLogin = true
                                } label:{
                                    HStack{
                                        Spacer()
                                        Text(LocalizedStringKey("Get Started"))
                                        Spacer()
                                    }
                                }
                                .buttonStyle(.primary())
                                .padding(.horizontal, 16)
                            }
                        }
                        .opacity(self.Store.user.loading ? 0 : 1)
                        Loader(size: .small)
                        .opacity(self.Store.user.loading ? 1 : 0)
                    }
                    .onAppear{
                        self.Store.loggedIn = false
                        /*
                        //MARK: Pass actions
                        self.identity.onLogout = {
                            
                        }
                        self.identity.onThrow = { error in
                            self.Error.handle(error)
                        }
                         */
                        
                        //Check for active session
                        if (self.Store.user.user_id == nil){
                            Task{
                                do{
                                    try await self.Store.user.load()
                                }catch(let error){
                                    self.Error.handle(error)
                                }
                            }
                        }
                        
                        //Check if application should be processed to login
                        if (self.Store.processLogin){
                            DispatchQueue.main.asyncAfter(deadline:.now()+0.2){
                                Task{
                                    self.Store.processLogin = false
                                    do{
                                        try await self.identity.login(self.Store.processLoginURL)
                                    }catch(let error){
                                        self.Error.handle(error)
                                    }
                                }
                            }
                        }
                    }
                    .onChange(of: self.Store.processLogin){ _  in
                        if (self.Store.processLogin){
                            DispatchQueue.main.asyncAfter(deadline:.now()+0.2){
                                Task{
                                    self.Store.processLogin = false
                                    do{
                                        try await self.identity.login(self.Store.processLoginURL)
                                    }catch(let error){
                                        self.Error.handle(error)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .onAppear{
                self.currentWindow = UIApplication.shared.windows.first
            }
            .onChange(of: self.Store.user.user_id, perform: { _ in
                Task{
                    do{
                        self.step = 4
                    }
                }
            })
            .padding()
        }
    }
    
    var slider: some View{
        ZStack{
            HStack(alignment:.center){
                ForEach(0..<4){ index in
                    Circle()
                        .foregroundColor( index == self.step ? Color.clear : Color.gray)
                        .frame(width: 10)
                        .overlay(
                            Circle()
                                .strokeBorder(
                                    Whitelabel.Color(.Primary),
                                    lineWidth:2
                                )
                                .scaleEffect( index == self.step ? 1 : 0)
                        )
                        .animation(.easeInOut(duration: 0.3))
                }
            }
            .frame(maxWidth: .infinity,maxHeight: 20)
            
            HStack(alignment:.center){
                if self.step == 0{
                    Button(LocalizedStringKey("Skip")){
                        self.step = 4
                    }
                    .padding(10)
                    .foregroundColor(Color.get(.Text))
                    
                }else{
                    Button{
                        self.step -= 1
                    } label: {
                        ZStack{
                            Image("arrow-l")
                        }
                        .frame(width: 30, height: 30)
                    }
                        .buttonStyle(.secondary())
                }
                Spacer()
                Button{
                    self.step += 1
                } label:{
                    ZStack{
                        Image("arrow-r")
                    }
                    .frame(width: 30, height: 30)
                }
                    .buttonStyle(.primary())
                
            }
            .padding(.horizontal,16)
            .padding(.vertical,10)
        }
    }
    
    var body: some View{
        ZStack{
            GeometryReader{ proxy in
                let width = proxy.size.width
                ZStack(){
                    HStack(spacing:0){
                        VStack(alignment:.leading){
                            ZStack{
                                self.slide(
                                    title: "FCA Authorised Electronic Money Institution",
                                    description: "Save big on money and time. Operate either through our EMI licence or explore the possibility of your own branded application."
                                )
                                    .zIndex(3)
                                Image("pic1")
                                    .ignoresSafeArea()
                                    .zIndex(2)
                            }.zIndex(1)
                        }
                        .frame(width: width)
                        
                        VStack(alignment:.leading){
                            ZStack{
                                self.slide(
                                    title:"Easy API Integration",
                                    description: "Our scalable APIs empower you to offer digital bank accounts with an array of engaging features."
                                )
                                    .zIndex(3)
                                ZStack{
                                    Image("pic2")
                                    ZStack{
                                        Image(Whitelabel.Image(.logoSmall))
                                            .resizable()
                                            .scaledToFit()
                                    }
                                    .frame(
                                        width: 57,
                                        height: 57
                                    )
                                    .offset(
                                        x: -8,
                                        y: 14
                                    )
                                }
                                    .ignoresSafeArea()
                                    .zIndex(2)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                                    .offset(y:100)
                            }
                        }
                        .frame(width: width)
                        
                        VStack(alignment:.leading){
                            ZStack{
                                self.slide(
                                    title:"Go Global With Cross-Border Payments & Foreign Exchange",
                                    description: "Put payments at the heart of your platform with access to UK, EU and US payment schemes."
                                )
                                    .zIndex(3)
                                Image("pic3")
                                    .ignoresSafeArea()
                                    .zIndex(2)
                                    .offset(y: -100)
                            }
                        }
                        .frame(width: width)
                        
                        VStack(alignment:.leading){
                            ZStack{
                                self.slide(
                                    title:"AI-Driven AML and Transaction Monitoring",
                                    description: "Supercharge your KYB/KYC and compliance processes with our integrated state-of-the-art solution."
                                )
                                    .zIndex(3)
                                Image("pic4")
                                    .ignoresSafeArea()
                                    .zIndex(2)
                                    .offset(y: -50)
                            }
                        }
                        .frame(width: width)
                        
                        //MARK: Sign in page
                        self.signSlide
                            .frame(width: width)
                    }
                    .offset(x: (CGFloat(self.step) * -width) + (self.step == 0 ? (self.offset > 0 ? 0 : self.offset) : (self.step == 4 ? (self.offset < 0 ? 0 : self.offset) : self.offset)))

                    //MARK: Popup
                }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .animation(.easeInOut, value: offset == 0)
                    .background(
                        Color.get(.Background)
                    )
                    .gesture(
                        DragGesture()
                            .updating(self.$offset, body: { value, out, _ in
                                out = value.translation.width
                            })
                            .onEnded({ value in
                                let offsetX = value.translation.width
                                let progress = -offsetX / width
                                let roundIndex = progress.rounded()
                                
                                self.step = max(min(self.step + Int(roundIndex), 4), 0)
                            })
                    )
                    .overlay(
                        self.slider
                            .frame(maxWidth: width)
                            .opacity(self.step == 4 ? 0 : 1),
                        alignment: .bottomLeading
                    )
            }
        }
            .navigationBarBackButtonHidden(true)
            .navigationTitle("")
    }
}

struct IdentityView_Previews: PreviewProvider {
    static var store: ApplicationStore {
        var store = ApplicationStore()
        return store
    }
    
    static var error: ErrorHandlingService {
        var error = ErrorHandlingService()
        return error
    }
    
    static var previews: some View {
        IdentityView()
            .environmentObject(self.store)
            .environmentObject(self.error)
    }
}
