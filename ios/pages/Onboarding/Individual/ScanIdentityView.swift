//
//  ScanIdentityView.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 17.11.2023.
//

import Foundation
import SwiftUI

struct ScanIdentityView: View, RouterPage{
    @EnvironmentObject var Store: ApplicationStore
    @EnvironmentObject var Error: ErrorHandlingService
    @EnvironmentObject var Router: RoutingController
    
    @StateObject var cameraModel: cameraModelService = cameraModelService()
    
    @State private var loading: Bool = false
    
    var body: some View{
        ZStack(alignment: .leading){
            GeometryReader{ geometry in
                ZStack{
                    AVCamera()
                        .zIndex(1)
                        .edgesIgnoringSafeArea(.all)
                        .ignoresSafeArea()
                        .environmentObject(self.cameraModel)
                        .overlay(
                            Text(LocalizedStringKey("Take your identity"))
                                .foregroundColor(Color.white)
                                .font(.title.bold())
                                .offset(y: geometry.safeAreaInsets.top + 60)
                            , alignment: .top
                        )
                        .onChange(of: self.cameraModel.photo){ photo in
                            if (photo != nil){
                                let jpg = UIImage(data:photo!.originalData)!.jpegData(compressionQuality: 0.7)
                                let attachment = FileAttachment(data: jpg!)
                                attachment.fileType = .jpg
                                attachment.fileName = "ScannedIdentity.jpg"
                                let type = UploadIdentityView.documentTypes.first(where: {$0.key == self.Store.onboarding.proofOfIdentityDocumentType})
                                attachment.documentType = type
                                attachment.key = randomString(length: 6)
                                self.Store.onboarding.proofOfIdentitiesUploaded.append(attachment)
                                self.Router.goTo(UploadIdentityView(), routingType: .backward)
                            }
                        }
                }
                    .overlay(
                        ZStack{
                        }
                            .frame(maxWidth:.infinity, maxHeight: .infinity)
                            .zIndex(2)
                            .overlay(
                                Header(back:{
                                    self.Router.goTo(UploadIdentityView(), routingType: .backward)
                                }, title: "")
                                .padding(.bottom, 16)
                                , alignment: .top
                            )
                            .overlay(
                                HStack(alignment:.center,spacing:60){
                                    Spacer()
                                    Button(""){
                                        self.cameraModel.takePhoto()
                                    }
                                    .buttonStyle(.shutter())
                                    .offset(y: (geometry.safeAreaInsets.bottom + 30) * -1)
                                    Spacer()
                                }
                                ,alignment: .bottom
                            )
                            .overlay(
                                HStack(alignment: .center){
                                    Spacer()
                                    Button(""){
                                        self.cameraModel.flipCamera()
                                    }
                                    .buttonStyle(.camera(image:"refresh-2"))
                                    .offset(y: (geometry.safeAreaInsets.bottom + 24 + 16) * -1)
                                    .padding(.trailing, 30)
                                }
                                ,alignment: .bottom
                            )
                        )
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationTitle("")
        .background(Color("Background"))
    }
}

struct ScanIdentityView_Previews: PreviewProvider {
    static var store: ApplicationStore {
        var store = ApplicationStore()
        return store
    }
    
    static var previews: some View {
        ScanIdentityView()
            .environmentObject(self.store)
    }
}
