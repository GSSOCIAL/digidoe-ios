//
//  CreatePerson.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 22.11.2023.
//

import Foundation
import SwiftUI

extension CreatePersonView{
    func submit() async throws{
        self.loading = true
        //MARK: On this step create person & continue
        if (self.Store.user.person == nil || self.Store.user.person!.id.isEmpty){
            let response = try await services.kycp.createPerson(Person.CreatePersonRequest(
                email: self.Store.user.email ?? "",
                phone: self.Store.user.phone ?? ""
            ))
            self.Store.user.person = response
        }
        
        self.loading = false
        self.Router.goTo(OCRScanView())
    }
    
    var genders: [Option]{
        return self.Store.onboarding.genders.map({
            return .init(
                id: String($0.id),
                label: $0.name
            )
        })
    }
    
    var countries: [Option]{
        return self.Store.onboarding.countries.map({
            return .init(
                id: String($0.id),
                label: $0.name
            )
        })
    }
}

extension CreatePersonView{
    var header: some View{
        HStack{
            Button{
                
            } label:{
                ZStack{
                    Image("arrow-left")
                        .foregroundColor(Color.get(.PaleBlack))
                }
                .frame(width: 24, height: 24)
            }
            Spacer()
            ZStack{
                
            }
        }
        .padding(.horizontal,16)
        .padding(.vertical, 12)
        .overlay(
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
            }
        )
    }
}

struct CreatePersonView: View, RouterPage {
    
    @EnvironmentObject var Store: ApplicationStore
    @EnvironmentObject var Error: ErrorHandlingService
    @EnvironmentObject var Router: RoutingController
    
    @State private var loading: Bool = false
    
    var body: some View {
        GeometryReader{ geometry in
            ScrollView{
                VStack(spacing: 0){
                    self.header
                    VStack(alignment: .center, spacing:24){
                        HStack{
                            VStack(alignment: .leading){
                                Text("Verify Your Identity")
                                    .font(.title2.bold())
                                    .foregroundColor(Color.get(.Text))
                                Text("Your information is encrypted and securely handled.")
                                    .foregroundColor(Color.get(.LightGray))
                            }
                            Spacer()
                        }
                        VStack(alignment: .center){
                            Image("id-verification-vector")
                        }
                            .padding(.bottom, 12)
                        VStack(alignment: .leading, spacing: 20){
                            HStack(alignment: .top, spacing: 20){
                                ZStack{
                                    Image("id_card")
                                }
                                .frame(width: 24, height: 24)
                                VStack(alignment: .leading){
                                    Text("To get started, please have one of the following documents ready:")
                                        .foregroundColor(Color.get(.Text))
                                        .font(.body.weight(.medium))
                                    HStack(spacing: 10){
                                        ZStack{}
                                            .frame(width: 4, height: 4)
                                            .background(Color.get(.LightGray))
                                            .clipShape(Circle())
                                        Text("Passport")
                                            .foregroundColor(Color.get(.LightGray))
                                        Spacer()
                                    }
                                    HStack(spacing: 10){
                                        ZStack{}
                                            .frame(width: 4, height: 4)
                                            .background(Color.get(.LightGray))
                                            .clipShape(Circle())
                                        Text("Driver’s licence")
                                            .foregroundColor(Color.get(.LightGray))
                                        Spacer()
                                    }
                                }
                                Spacer()
                            }
                            HStack(alignment: .top, spacing: 20){
                                ZStack{
                                    Image("camera 1")
                                }
                                .frame(width: 24, height: 24)
                                VStack(alignment: .leading){
                                    Group{
                                        Text("Make sure your ")
                                        + Text("camera")
                                            .foregroundColor(Color.get(.Text))
                                        + Text(" is unobstructed and working, and that you’re in a ")
                                        + Text("well-lit area")
                                            .foregroundColor(Color.get(.Text))
                                        + Text(".")
                                    }
                                        .foregroundColor(Color.get(.LightGray))
                                        .font(.body.weight(.medium))
                                }
                                Spacer()
                            }
                            HStack(alignment: .top, spacing: 20){
                                ZStack{
                                    Image("user_circle")
                                }
                                .frame(width: 24, height: 24)
                                VStack(alignment: .leading){
                                    Group{
                                        Text("Click ")
                                        + Text("Continue")
                                            .foregroundColor(Color.get(.Text))
                                        + Text(" to begin scanning your ID.")
                                    }
                                        .foregroundColor(Color.get(.LightGray))
                                        .font(.body.weight(.medium))
                                }
                                Spacer()
                            }
                        }
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
        .background(Color.get(.Background))
    }
}

struct CreatePersonView_Previews: PreviewProvider {
    static var store: ApplicationStore {
        var store = ApplicationStore()
        return store
    }
    
    static var previews: some View {
        CreatePersonView()
            .environmentObject(self.store)
    }
}
