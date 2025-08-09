//
//  RelatedDocumentsView.swift
//  DigiDoe Business Banking
//
//  Created by Михайло Картмазов on 21.01.2025.
//

import Foundation
import SwiftUI

extension RelatedDocumentsView{
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

extension RelatedDocumentsView{
    func removeAttachment(_ attachment: FileAttachment){
        let index = self.attachments.firstIndex(where: { $0.id == attachment.id})
        self.attachments.remove(at: index!)
    }
    
    func upload() async throws{
        do{
            self.loading = true
            self.errorMessage = nil
            var ids: Array<String> = []
            
            for attachment in self.attachments{
                self.processing = attachment.key
                let result = try await services.transactionCases.fileUpload(
                    attachment,
                    customerId: self.customerId,
                    documentType: .noteDocument
                )
                //MOVE upload to other array
                ids.append(result.value.id)
                let index = self.attachments.firstIndex(where: {$0.key == attachment.key})
                if (index != nil){
                    self.attachments.remove(at: index!)
                }
            }
            
            let link = try await services.transactionCases.addNotes(
                customerId: self.customerId,
                transactionId: self.transaction.id,
                documentIds: ids
            )
            //After upload link with transactions
            self.loading = false
            self.processing = ""
            self.Router.back()
        }catch let error{
            if let error = error as? KycpService.ApiError{
                let message: String? = error.errors.first(where: {$0.code == "ValidationError"})?.description
                if (message != nil){
                    self.loading = false
                    self.processing = ""
                    self.errorMessage = message
                    return;
                }
            }
            throw error
        }
    }
    
    func processPhoto(image: UIImage){
        Task{
            do{
                if let data = image.jpegData(compressionQuality: 0.7){
                    let attachment = FileAttachment(data: data)
                    attachment.fileType = .jpg
                    attachment.fileName = "Scanned.jpg"
                    attachment.key = randomString(length: 6)
                    self.attachments.append(attachment)
                }else{
                    throw ApplicationError(title: "Unable to take photo", message: "")
                }
            }catch let error{
                self.Error.handle(error)
            }
        }
    }
}

struct RelatedDocumentsView: View, RouterPage {
    @EnvironmentObject var Store: ApplicationStore
    @EnvironmentObject var Error: ErrorHandlingService
    @EnvironmentObject var Router: RoutingController
    
    @State private var loading: Bool = false
    @State private var scrollOffset : Double = 0
    @State private var selectDocument: Bool = false
    @State private var fileSelection: Bool = false
    
    @State private var attachments: Array<FileAttachment> = []
    @State private var uploaded: Array<String> = []
    @State private var processing: String = ""
    
    @State public var customerId: String
    @State public var transaction: TransactionsService.CustomerTransactionModelResult.CustomerTransactionModel
    @State public var documents: Array<TransactionCasesService.NoteDocument> = []
    
    @State private var errorMessage: String? = nil
    @State private var takePhoto: Bool = false
    
    var body: some View {
        ApplicationNavigatorContainerView{
            GeometryReader{ geometry in
                ZStack{
                    ScrollView{
                        VStack(spacing: 0){
                            VStack(spacing:0){
                                Header(back:{
                                    self.Router.back()
                                }, title: "Related documents")
                            }
                            .offset(
                                y: self.scrollOffset < 0 ? self.scrollOffset : 0
                            )
                            
                            VStack(spacing:12){
                                VStack(spacing:12){
                                    VStack(spacing: 8){
                                        ForEach(self.documents, id: \.id){ attachment in
                                            HStack(spacing: 8){
                                                ZStack{
                                                    Text(mimeTypeForFileExtension(attachment.mimeType  ?? ""))
                                                        .font(.caption)
                                                        .foregroundColor(Color.get(.Pending))
                                                }
                                                .frame(width: 48,height: 48)
                                                .background(Color.get(.Pending).opacity(0.14))
                                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                                VStack{
                                                    Text(attachment.externalFileName ?? "")
                                                        .font(.subheadline.weight(.medium))
                                                        .foregroundColor(Color.get(.Text))
                                                        .multilineTextAlignment(.leading)
                                                }
                                                Spacer()
                                            }
                                            .padding(6)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(Color.get(.BackgroundInput))
                                                    .foregroundColor(Color.clear)
                                                    .background(.clear)
                                            )
                                            .padding(.horizontal, 16)
                                        }
                                        
                                        ForEach(self.attachments, id: \.key){ attachment in
                                            HStack(spacing: 8){
                                                ZStack{
                                                    Text((attachment.fileType?.rawValue  ?? "").uppercased())
                                                        .font(.caption)
                                                        .foregroundColor(Color.get(.Pending))
                                                }
                                                .frame(width: 48,height: 48)
                                                .background(Color.get(.Pending).opacity(0.14))
                                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                                VStack{
                                                    Text(attachment.fileName ?? "")
                                                        .font(.subheadline.weight(.medium))
                                                        .foregroundColor(Color.get(.Text))
                                                        .multilineTextAlignment(.leading)
                                                }
                                                Spacer()
                                                if (self.processing == attachment.key){
                                                    ZStack{
                                                        Loader(size: .small)
                                                    }
                                                }else{
                                                    Button{
                                                        self.removeAttachment(attachment)
                                                    } label:{
                                                        ZStack{
                                                            Image("trash")
                                                                .foregroundColor(Color.get(.Danger))
                                                        }
                                                        .frame(width: 24, height: 24)
                                                    }
                                                    .disabled(self.loading)
                                                }
                                            }
                                            .padding(6)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(Color.get(.BackgroundInput))
                                                    .foregroundColor(Color.clear)
                                                    .background(.clear)
                                            )
                                            .padding(.horizontal, 16)
                                        }
                                        
                                        if (self.errorMessage != nil){
                                            HStack{
                                                Text(self.errorMessage!)
                                                    .font(.subheadline.bold())
                                                    .foregroundColor(Color.get(.Danger))
                                            }
                                        }
                                    }
                                }
                                VStack{
                                    Button{
                                        self.selectDocument = true
                                    } label:{
                                        HStack{
                                            Spacer()
                                            ZStack{
                                                Image("add")
                                                    .resizable()
                                                    .scaledToFit()
                                                    .foregroundColor(.black)
                                            }
                                            .frame(width: 18, height: 18)
                                            Text("Add documents")
                                                .font(.subheadline.bold())
                                            Spacer()
                                        }
                                    }
                                    .buttonStyle(.secondary())
                                    .disabled(self.loading)
                                    .fixedSize(
                                        horizontal: false,
                                        vertical: true
                                    )
                                    HStack{
                                        Text("Image or PDF, up to 20 Mb")
                                        Spacer()
                                        Text("Optional")
                                    }
                                    .font(.subheadline.bold())
                                    .foregroundColor(Color.get(.LightGray))
                                }
                                .padding(.horizontal, 16)
                            }
                            Spacer()
                            
                            VStack{
                                Button{
                                    Task{
                                        do{
                                            try await self.upload()
                                        }catch(let error){
                                            self.loading = false
                                            self.processing = ""
                                            self.Error.handle(error)
                                        }
                                    }
                                } label:{
                                    HStack{
                                        Spacer()
                                        Text("Confirm")
                                        Spacer()
                                    }
                                }
                                .buttonStyle(.primary())
                                .disabled(self.loading)
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 12)
                            
                            //MARK: Media importer
                            MediaUploaderContainer(
                                isPresented: self.$fileSelection,
                                onImport: { url in
                                    var attachment = FileAttachment(url: url);
                                    attachment.key = randomString(length: 6)
                                    
                                    self.attachments.append(attachment)
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
                    }
                    .coordinateSpace(name: "scroll")
                    //MARK: - Popups
                    
                    //MARK: File Uploader
                    PresentationSheet(isPresented: self.$selectDocument){
                        HStack(spacing: 20){
                            Button{
                                self.selectDocument = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1){
                                    self.takePhoto = true
                                }
                            } label:{
                                HStack{
                                    Text(LocalizedStringKey("Take a photo"))
                                }
                            }
                            .buttonStyle(.action(image:"scan"))
                            Button{
                                self.selectDocument = false
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
                    
                    //MARK: Camera
                    if (self.takePhoto){
                        CameraPickerView(
                            onDismiss: {
                                self.takePhoto = false
                            },
                            onImagePicked: { image in
                                self.processPhoto(image: image)
                            }
                        )
                        .ignoresSafeArea(.all)
                        .edgesIgnoringSafeArea(.all)
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationTitle("")
        .background(Color.get(.Background))
    }
}
