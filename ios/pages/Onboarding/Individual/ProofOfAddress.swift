//
//  ProofOfAddress.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 20.11.2023.
//

import Foundation
import SwiftUI

extension ProofOfAddressView{
    static var documentTypes: Array<UploadIdentityView.DocumentType>{
        return ProofOfAddressDocumentTypes
    }
    
    var selectedDocumentType: UploadIdentityView.DocumentType?{
        return ProofOfAddressView.documentTypes.first(where: {$0.key == self.documentType})
    }
}

struct ProofOfAddressView: View, RouterPage {
    @EnvironmentObject var Store: ApplicationStore
    @EnvironmentObject var Error: ErrorHandlingService
    @EnvironmentObject var Router: RoutingController
    
    @State private var loading: Bool = false
    @State private var showDocumentType: Bool = false
    @State private var documentType: String? = nil
    @State private var fileSelection: Bool = false
    @State private var uploadFile: Bool = false
    
    var proofOfAddressLoaded: Binding<Bool>{
        Binding(
            get: {
                #if targetEnvironment(simulator) && DEBUG
                    return true
                #else
                    return !self.Store.onboarding.proofOfAddressUploaded.isEmpty
                #endif
            },
            set: { value in
                
            })
    }
    
    private var attachments: [FileAttachment]{
        return self.Store.onboarding.proofOfAddressUploaded
    }
    
    func submit() async throws{
        self.loading = true
        
        let individualEntity = self.Store.onboarding.individualEntity
        if (individualEntity == nil || self.Store.onboarding.application.isApplicationExists == false){
            throw ServiceError(title: "Entity not found", message: "Couldnt find Your Entity")
        }
        var fields:[String:Int] = [:]
        
        #if targetEnvironment(simulator) && DEBUG
            fields["GENresadddocnumber"] = 1
        #else
            //MARK: Upload address here
            if self.Store.onboarding.proofOfAddressUploaded.count > 0{
                var i = 0
                var identities = self.Store.onboarding.proofOfAddressUploaded.filter({ item in return !item.uploaded })
                while(i<identities.count){
                    let _ = try await services.kycp.uploadDocument(identities[i], applicationId: self.Store.onboarding.application.id!, entityId: individualEntity!.id, entityTypeId: KycpService.entityType.individual, title: identities[i].documentType!.label, type: identities[i].documentType!.id)
                    i += 1
                }
                fields["GENresadddocnumber"] = self.Store.onboarding.proofOfAddressUploaded.count
            }
        #endif
        let _ = try await self.Store.onboarding.application.updateEntity(fields, entityId: individualEntity!.id)
        self.loading = false
        self.Router.goTo(self.Store.onboarding.currentFlowPage)
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
                        TitleView(
                            title: LocalizedStringKey("Proof of address"),
                            description: LocalizedStringKey("Utility bill or bank statement")
                        )
                            .padding(.horizontal, 16)
                        if (self.selectedDocumentType == nil){
                            Button(LocalizedStringKey("Select type of document")){
                                self.showDocumentType = true
                            }.buttonStyle(.next(image:"document 1", outline: true))
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
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .disabled(self.loading)
                            
                            Button(LocalizedStringKey("Select a file")){
                                self.uploadFile = true
                            }
                            .buttonStyle(.dashed(image:"export 1"))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .disabled(self.loading)
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
                                DispatchQueue.main.async {
                                    self.fileSelection = false
                                }
                                var attachment = FileAttachment(url: url);
                                let type = ProofOfAddressView.documentTypes.first(where: {$0.key == self.documentType})
                                attachment.key = randomString(length: 6)
                                attachment.documentType = type
                                
                                self.Store.onboarding.proofOfAddressUploaded.append(attachment)
                            },
                            onError: { error in
                                DispatchQueue.main.async {
                                    self.fileSelection = false
                                }
                                self.Error.handle(error)
                            },
                            scheme: .light
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
                        .disabled((self.loading || !self.proofOfAddressLoaded.wrappedValue))
                        .buttonStyle(.primary())
                        .padding(.horizontal, 16)
                        .loader(self.$loading)
                    }
                    .frame(
                        maxWidth: .infinity,
                        minHeight: geometry.size.height - geometry.safeAreaInsets.bottom
                    )
                    .onAppear{
                        self.documentType = self.Store.onboarding.proofOfAddressDocumentType
                    }
                    .onChange(of: self.documentType, perform: { _ in
                        self.Store.onboarding.proofOfAddressDocumentType = self.documentType ?? ""
                            //self.Store.onboarding.proofOfAddressUploaded = []
                    })
                }
                
                //MARK: Popups
                PresentationSheet(isPresented: self.$showDocumentType){
                    VStack(spacing: 20){
                        Text(LocalizedStringKey("Select type of document"))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .font(.body.bold())
                        VStack(spacing: 16){
                            ForEach(ProofOfAddressView.documentTypes, id: \.key){ type in
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
                PresentationSheet(isPresented: self.$uploadFile){
                    HStack(spacing: 20){
                        Button{
                            self.uploadFile = false
                            self.Router.goTo(ScanProofOfAddressView())
                        } label:{
                            HStack{
                                Text(LocalizedStringKey("Take a picture"))
                            }
                        }
                        .buttonStyle(.action(image:"scan"))
                        Button{
                            self.uploadFile = false
                            DispatchQueue.main.asyncAfter(deadline: .now()+1){
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

struct ProofOfAddressView_Previews: PreviewProvider {
    static var store: ApplicationStore {
        var store = ApplicationStore()
        return store
    }
    
    static var error: ErrorHandlingService {
        var error = ErrorHandlingService()
        return error
    }
    
    static var previews: some View {
        ProofOfAddressView()
            .environmentObject(self.store)
            .environmentObject(self.error)
    }
}
