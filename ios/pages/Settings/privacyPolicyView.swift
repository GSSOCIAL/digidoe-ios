//
//  privacyPolicyView.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 10.01.2024.
//

import Foundation
import SwiftUI

extension PrivacyPolicyView{
    private var loaderOffset: Double{
        if (self.loading){
            return 50 + self.scrollOffset
        }
        
        if (self.scrollOffset > 0){
            return 0
        }else if(self.scrollOffset < -100){
            return 50 + self.scrollOffset
        }
        
        return 0 + self.scrollOffset / 2
    }
}

struct PrivacyPolicyView: View, RouterPage {
    @EnvironmentObject var Store: ApplicationStore
    @EnvironmentObject var Error: ErrorHandlingService
    @EnvironmentObject var Router: RoutingController
    
    @State private var loading: Bool = false
    @State private var scrollOffset : Double = 0
    @State private var data: TermsService.TermsConditionsResponse?
    
    func getPrivacyPolicy() async throws{
        if (self.loading){
            return;
        }
        self.loading = true
        let response = try await services.terms.getPrivacyPolicy()
        #if DEBUG
        if Enviroment.useMockData == true{
            DispatchQueue.main.asyncAfter(deadline: .now()+5){
                self.data = response
                self.loading = false
            }
        }else{
            self.data = response
            self.loading = false
        }
        #else
        self.data = response
        self.loading = false
        #endif
    }
    
    var body: some View {
        ApplicationNavigatorContainerView{
            GeometryReader{ geometry in
                ScrollView{
                    VStack(spacing: 0){
                        
                        VStack(spacing:0){
                            Header(back:{
                                self.Router.back()
                            }, title: "Privacy policy")
                        }
                            .offset(
                                y: self.scrollOffset < 0 ? self.scrollOffset : 0
                            )
                         
                        //MARK: Loader
                        HStack{
                            Spacer()
                            Loader(size:.small)
                                .offset(y: self.loaderOffset)
                                .opacity(self.loading ? 1 : self.scrollOffset > -10 ? 0 : -self.scrollOffset / 100)
                            Spacer()
                        }
                        .frame(
                            maxWidth: .infinity,
                            maxHeight: 0
                        )
                        .zIndex(3)
                        .offset(y: 0)
                         
                        //MARK: Content
                        VStack(spacing:0){
                            if (self.data != nil){
                                JsonRenderer(data: self.data!.Body)
                            }
                        }
                        .padding(.horizontal, 16)
                        .offset(
                            y: self.loading && self.scrollOffset > -100 ? Swift.abs(Double(100) - self.scrollOffset) : 0
                        )
                        Spacer()
                    }
                    .background(GeometryReader {
                        Color.clear.preference(key: RefreshViewOffsetKey.self, value: -$0.frame(in: .named("scroll")).origin.y)
                    })
                    .onPreferenceChange(RefreshViewOffsetKey.self) { position in
                        self.scrollOffset = position
                    }
                    .frame(
                        maxWidth: .infinity,
                        minHeight: geometry.size.height - geometry.safeAreaInsets.bottom
                    )
                    .onAppear{
                        Task{
                            do{
                                try await self.getPrivacyPolicy()
                            }catch(let error){
                                self.loading = false
                                self.Error.handle(error)
                            }
                        }
                    }
                }
                    .coordinateSpace(name: "scroll")
                    .onChange(of: scrollOffset){ _ in
                        if (!self.loading && self.scrollOffset <= -100){
                            Task{
                                do{
                                    try await self.getPrivacyPolicy()
                                }catch(let error){
                                    self.loading = false
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

struct PrivacyPolicyView_Previews: PreviewProvider {
    static var previews: some View {
        ContentViewContainerPreview{
            PrivacyPolicyView()
        }
    }
}
