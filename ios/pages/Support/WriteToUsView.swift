//
//  WriteToUsView.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 30.09.2023.
//

import Foundation
import SwiftUI

struct WriteToUsView: View, RouterPage {
    @EnvironmentObject var Store: ApplicationStore
    @EnvironmentObject var Error: ErrorHandlingService
    @EnvironmentObject var Router: RoutingController
    
    @State private var message: String = ""
    @State private var loading: Bool = false
    
    func submit() async throws{
        self.loading = true
        //try await services.feedback.sendFeedback(title:"IOS Report",description:self.message,customerId:self.user.customer!.id)
        self.loading = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1){
            self.Router.back()
        }
    }
    
    var body: some View {
        ApplicationNavigatorContainerView{
            GeometryReader{ geometry in
                ScrollView{
                    VStack(spacing: 0){
                        Header(back:{
                            self.Router.back()
                        }, title: "Write to us")
                        VStack{
                            Text("Please describe your problem as much as possible")
                                .font(.subheadline) //or CAPTION
                                .foregroundColor(Color.get(.LightGray))
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 16)
                            CustomField(value: self.$message, placeholder: "", type: .textarea)
                                .padding(.horizontal, 16)
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
                                    Text(LocalizedStringKey("Submit"))
                                }
                                    .frame(maxWidth: .infinity)
                            }
                                .disabled(self.loading || self.message.isEmpty)
                                .buttonStyle(.primary())
                                .padding(.horizontal, 16)
                        }
                        .padding(.top, 10)
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

struct WriteToUsView_Previews: PreviewProvider {
    static var previews: some View {
        ContentViewContainerPreview{
            WriteToUsView()
        }
    }
}

