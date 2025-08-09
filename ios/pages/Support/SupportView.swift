//
//  SupportView.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 30.09.2023.
//

import Foundation
import SwiftUI

struct SupportView: View, RouterPage {
    @EnvironmentObject var Store: ApplicationStore
    @EnvironmentObject var Error: ErrorHandlingService
    @EnvironmentObject var Router: RoutingController
    
    func appFeedback(){
        do{
            let email = Enviroment.feedbackEmail
            if let url = URL(string: "mailto:\(email)") {
                UIApplication.shared.open(url)
            }else{
                throw ApplicationError(title:"Failed to send email", message:"Failed to open URL")
            }
        }catch let error{
            self.Error.handle(error)
        }
    }
    
    var body: some View {
        ApplicationNavigatorContainerView{
            GeometryReader{ geometry in
                ScrollView{
                    VStack(spacing: 0){
                        Header(back:{
                            self.Router.back()
                        }, title: "Support")
                        .padding(.bottom, 16)
                        Text("How can we help?")
                            .font(.title2.bold())
                            .foregroundColor(Color.get(.Text))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 16)
                        VStack(spacing:0){
                            /*
                            //MARK: No feedback api service available
                            Button{
                                
                            } label:{
                                Navigator.navigate(Navigator.pages.Support.writeToUs){
                                    HStack{
                                        Text("Write to us")
                                        Spacer()
                                    }
                                }
                            }
                            .buttonStyle(.next())
                            .frame(maxWidth: .infinity)
                            .disabled(true)
                            
                            Divider()
                                .overlay(Color("Divider"))
                             */
                            
                            Button{
                                ReviewHandler.requestReview()
                            } label:{
                                HStack{
                                    Text("Rate us")
                                    Spacer()
                                }
                            }
                            .buttonStyle(.next())
                            .frame(maxWidth: .infinity)
                            
                            Divider()
                                .overlay(Color("Divider"))
                            Button{
                                self.appFeedback()
                            } label:{
                                HStack{
                                    Text("Provide app feedback")
                                    Spacer()
                                }
                            }
                            .buttonStyle(.next())
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

struct SupportView_Previews: PreviewProvider {
    static var previews: some View {
        ContentViewContainerPreview{
            SupportView()
        }
    }
}
