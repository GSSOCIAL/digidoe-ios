//
//  UploadIdentityView.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 17.11.2023.
//

import Foundation
import SwiftUI

extension UploadIdentityView{
    struct DocumentType{
        public var id: KycpService.DocType
        public var key: String
        public var label: String
        public var image: String
        public var description: String
    }
    
    static public var documentTypes: Array<DocumentType>{
        return IdentityDocumentTypes
    }
    
    var selectedDocumentType: DocumentType?{
        return UploadIdentityView.documentTypes.first(where: {$0.key == self.documentType})
    }
}

struct UploadIdentityView: View, RouterPage{
    @EnvironmentObject var Store: ApplicationStore
    @EnvironmentObject var Error: ErrorHandlingService
    @EnvironmentObject var Router: RoutingController
    
    @State private var loading: Bool = false
    
    @State private var showDocumentType: Bool = false
    @State private var methodSelection: Bool = false
    @State private var documentType: String? = nil
    @State private var fileSelection: Bool = false
    
    func submit() async throws{
        self.loading = true
        do{
            self.loading = false
            self.Store.onboarding.proofOfIdentityDocumentType = self.documentType ?? ""
            self.Router.goTo(VerifyPersonalIdentityView(), routingType: .backward)
        }catch(let error){
            self.loading = false
            throw error
        }
    }
    
    private var attachments: [FileAttachment]{
        self.Store.onboarding.proofOfIdentitiesUploaded
    }
    
    var body: some View {
        GeometryReader{ geometry in
            ZStack{
                ScrollView{
                    VStack(spacing: 0){
                        Header(back:{
                            self.Router.goTo(VerifyPersonalIdentityView(), routingType: .backward)
                        }, title: "")
                            .padding(.bottom, 16)
                        TitleView(title: LocalizedStringKey("Proof your identity"), description: LocalizedStringKey("Please be assured that all your data is encrypted and secure"))
                            .padding(.horizontal, 16)
                        HStack{
                            Text(LocalizedStringKey("We will be allowed Only:"))
                                .font(.subheadline)
                                .foregroundColor(Color.get(.LightGray))
                            Button("JPG"){}
                                .buttonStyle(.tag(style:.success))
                            Button("PDF"){}
                                .buttonStyle(.tag(style:.pending))
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        if (self.selectedDocumentType == nil){
                            Button(LocalizedStringKey("Select type of document")){
                                self.showDocumentType = true
                            }
                            .buttonStyle(.next(image:"document 1", outline: true))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .disabled(self.loading)
                        }else{
                            Button{
                                self.showDocumentType = true
                            } label: {
                                Text(LocalizedStringKey(self.selectedDocumentType!.label))
                            }
                            .buttonStyle(.detailed(image:self.selectedDocumentType!.image, description: self.selectedDocumentType!.description))
                            .disabled(self.loading)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            
                            Button(LocalizedStringKey("Select a file")){
                                self.methodSelection = true
                            }
                            .buttonStyle(.dashed(image:"export 1"))
                            .disabled(self.loading)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                        }
                        
                        //Show list
                        VStack(spacing:12){
                            ForEach(self.attachments, id:\.key){ file in
                                Attachment(name: file.fileName!, type: file.fileType, documentType: file.documentType)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        
                        //MARK: File Uploader
                        MediaUploaderContainer(
                            isPresented: self.$fileSelection,
                            onImport: { url in
                                var attachment = FileAttachment(url: url);
                                let type = UploadIdentityView.documentTypes.first(where: {$0.key == self.documentType})
                                attachment.key = randomString(length: 6)
                                attachment.documentType = type
                                
                                self.Store.onboarding.proofOfIdentitiesUploaded.append(attachment)
                                DispatchQueue.main.async {
                                    self.fileSelection = false
                                }
                            },
                            onError: { error in
                                DispatchQueue.main.async {
                                    self.fileSelection = false
                                }
                                self.Error.handle(error)
                            }
                        )
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
                        .disabled(self.loading || self.attachments.isEmpty)
                        .buttonStyle(.primary())
                        .padding(.horizontal, 16)
                        .loader(self.$loading)
                    }
                    .frame(
                        maxWidth: .infinity,
                        minHeight: geometry.size.height - geometry.safeAreaInsets.bottom
                    )
                    .onAppear{
                        self.documentType = self.Store.onboarding.proofOfIdentityDocumentType
                    }
                    .onChange(of: self.documentType, perform: { _ in
                        self.Store.onboarding.proofOfIdentityDocumentType = self.documentType ?? ""
                    })
                }
                //MARK: Popup
                //MARK: Document type container
                PresentationSheet(isPresented: self.$showDocumentType){
                    VStack(spacing: 20){
                        Text(LocalizedStringKey("Select type of document"))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .font(.body.bold())
                        VStack(spacing: 16){
                            ForEach(UploadIdentityView.documentTypes, id: \.key){ type in
                                Button{
                                    self.showDocumentType = false
                                    self.documentType = type.key
                                } label: {
                                    Text(LocalizedStringKey(type.label))
                                }
                                .buttonStyle(.detailed(image:type.image, description: type.description))
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top,10)
                    .padding(.horizontal,10)
                    .padding(.bottom, geometry.safeAreaInsets.bottom)
                }
                
                //MARK: Upload identity container
                PresentationSheet(isPresented: self.$methodSelection){
                    HStack(spacing: 20){
                        Button{
                            self.methodSelection = false
                            self.Router.goTo(ScanIdentityView())
                        } label:{
                            HStack{
                                Text(LocalizedStringKey("Scan your identity"))
                            }
                        }
                        .buttonStyle(.action(image:"scan"))
                        Button{
                            self.methodSelection = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1){
                                self.fileSelection = true
                            }
                        } label:{
                            HStack{
                                Text(LocalizedStringKey("Select from files"))
                            }
                        }
                        .buttonStyle(.action(image:"folder-add"))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top,10)
                    .padding(.horizontal,10)
                    .padding(.bottom, geometry.safeAreaInsets.bottom)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationTitle("")
        .background(Color.get(.Background))
    }
}

struct UploadIdentityView_Previews: PreviewProvider {
    static var store: ApplicationStore {
        var store = ApplicationStore()
        return store
    }
    
    static var previews: some View {
        UploadIdentityView()
            .environmentObject(self.store)
    }
}
