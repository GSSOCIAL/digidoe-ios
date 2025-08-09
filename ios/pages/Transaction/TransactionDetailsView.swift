//
//  DetailsView.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 28.09.2023.
//

import Foundation
import SwiftUI
import LinkPresentation

/**Getters*/
extension TransactionDetailsView{
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
    var transactionAmount: Array<Substring> {
        return String(Double(self.transaction!.amount.value)).formatAsPrice(self.transaction!.amount.currencyCode.uppercased()).split(separator: ".")
    }
    var transactionFee: Array<Substring> {
        return String(self.transaction?.feeAmount?.value ?? 0).formatAsPrice(self.transaction!.amount.currencyCode.uppercased()).split(separator: ".")
    }
}

/**Methods*/
extension TransactionDetailsView{
    func exportStatement() async throws{
        try await self.shareTransaction()
    }
    
    func getTransaction() async throws{
        self.loading = true

        let response = try await services.transactions.getTransaction(
            self.account.customer?.id ?? "",
            accountId: self.account.id ?? "",
            transactionId: self.transactionRef.transactionId
        )
        self.transaction = response.value
        
        if (response.value.hasAttachments){
            let documents = try await services.transactionCases.getDocuments(
                customerId: self.account.customer?.id ?? "",
                transactionId: self.transactionRef.transactionId
            )
            self.documents = []
            documents.value.forEach{ document in
                self.documents.append(document)
            }
        }
        
        self.loading = false
    }
    func prepareExport(){
        Task{
            do{
                let content = try await services.transactions.getTransactionReport(
                    self.account.customer?.id ?? "",
                    accountId: self.account.id ?? "",
                    transactionId: self.transactionRef.transactionId
                )
                self.exportSheetContent = content
            }
        }
    }
    
    func shareTransaction(){
        Task{
            self.exportLoading = true
            do{
                if (self.exportSheetContent == nil){
                    let content = try await services.transactions.getTransactionReport(
                        self.account.customer?.id ?? "",
                        accountId: self.account.id ?? "",
                        transactionId: self.transactionRef.transactionId
                    )
                    
                    self.exportSheetContent = content
                }
                self.exportSheet = true
                self.exportLoading = false
            }catch(let error){
                self.exportLoading = false
                self.Error.handle(error)
            }
        }
    }
    
    func downloadDocument(_ attachment: TransactionCasesService.NoteDocument){
        self.exportLoading = true
        //Ask for document
        Task{
            do{
                let content = try await services.transactionCases.getDocument(
                    customerId: self.account.customer?.id ?? "",
                    documentId: attachment.id
                )
                let applicationTemporaryDirectoryURL = FileManager.default.temporaryDirectory
                let sharePreviewURL = applicationTemporaryDirectoryURL.appendingPathComponent(attachment.externalFileName)
                try content.write(to: sharePreviewURL)
                /*
                 self.exportDocumentContent = MyActivityItemSource(
                    title: attachment.externalFileName,
                    subtitle: sharePreviewURL,
                    data: content,
                    filetype: attachment.mimeType
                )
                 */
                self.exportDocumentContent = content
                self.exportDocumentSheet = true
                self.exportLoading = false
            }catch(let error){
                self.loading = false
                self.Error.handle(error)
            }
        }
    }
}
/**Views*/
extension TransactionDetailsView{
    var transactionStatus: some View{
        ZStack{
            if (self.transaction != nil){
                switch(self.transaction!.currentState){
                case .completed:
                    Text("Completed")
                        .foregroundColor(Color.get(.Active))
                case .failed:
                    Text("Failed")
                        .foregroundColor(Color.get(.Danger))
                case .pending:
                    Text("Pending")
                        .foregroundColor(Color.get(.LightGray))
                default:
                    Text(self.transaction?.currentState.rawValue ?? "")
                }
            }
        }
    }
    
    var relatedDocuments: some View{
        VStack(spacing: 12){
            Divider()
                .foregroundColor(Color.get(.Divider))
            VStack{
                HStack{
                    Text("Related Documents")
                        .foregroundColor(Color.get(.Text))
                        .font(.body)
                    Spacer()
                }
                VStack(spacing: 8){
                    ForEach(self.documents, id: \.id){ attachment in
                        Button{
                            self.downloadDocument(attachment)
                        } label:{
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
                                ZStack{
                                    Image("document-download")
                                        .resizable()
                                        .foregroundColor(Whitelabel.Color(.Primary))
                                }
                                .frame(width: 18, height: 18)
                            }
                            .padding(6)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.get(.BackgroundInput))
                                    .foregroundColor(Color.clear)
                                    .background(.clear)
                            )
                        }
                            .disabled(self.exportLoading)
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }
    
    var standingOrder: some View{
        Button{
            self.Router.goTo(
                StandingOrderDetailsView(
                    customerId: self.account.customer?.id ?? "",
                    account: self.account,
                    orderId: self.transaction?.paymentOrder?.id ?? ""
                )
            )
        } label:{
            HStack(alignment: .center, spacing: 5){
                ZStack{
                    Image("standing")
                        .foregroundColor(Color.get(.Text))
                }
                .frame(width: 20, height: 20)
                Group{
                    Text(self.transaction?.paymentOrder?.standingOrder?.description ?? "–")
                        .foregroundColor(Color.get(.Text))
                }
                .font(.subheadline.bold())
                Spacer()
                ZStack{
                    Image("arrow-next")
                        .foregroundColor(Color.get(.LightGray))
                }
                .frame(width: 24, height: 24)
            }
            .padding(12)
            .background(Whitelabel.Color(.Primary).opacity(0.08))
            .clipShape(
                RoundedRectangle(cornerRadius: 16)
            )
            .padding(.horizontal, 16)
        }
    }
}

struct TransactionDetailsView: View, RouterPage {
    @EnvironmentObject var Store: ApplicationStore
    @EnvironmentObject var Error: ErrorHandlingService
    @EnvironmentObject var Router: RoutingController
    
    @State private var loading: Bool = false
    @State private var exportLoading: Bool = false
    @State private var scrollOffset : Double = 0
    
    @State private var exportSheet:Bool = false
    @State private var transaction: TransactionsService.CustomerTransactionModelResult.CustomerTransactionModel?
    @State private var exportSheetContent: Data? = nil
    
    @State public var account: CoreAccount
    @State public var transactionRef: Transaction
    @State private var documents: Array<TransactionCasesService.NoteDocument> = []
    @State private var exportDocumentSheet: Bool = false
    @State private var exportDocumentTitle: String = "Download document"
    @State private var exportDocumentContent: Data? = nil//UIActivityItemSource? = nil
    
    var body: some View {
        ApplicationNavigatorContainerView{
            GeometryReader{ geometry in
                ScrollView{
                    VStack(spacing: 0){
                        VStack(spacing:0){
                            Header(back:{
                                self.Router.back()
                            }, title: "Transaction details")
                            /*{
                                HStack{
                                    Button{
                                        self.shareTransaction()
                                    } label:{
                                        HStack{
                                            ZStack{
                                                Image("share")
                                                    .resizable()
                                                    .scaledToFit()
                                            }
                                            .frame(width: 24, height: 24)
                                        }
                                        .foregroundColor(Color.get(.Primary))
                                    }
                                    .disabled(self.exportLoading)
                                }
                            }
                            */
                            HStack{
                                ZStack{
                                    if (self.transaction != nil){
                                        Image("send")
                                            .renderingMode(.template)
                                            .foregroundColor(Color.get(.MiddleGray))
                                            .scaleEffect(x:self.transaction!.amount.value > 0 ? -1 : 1, y:self.transaction!.amount.value > 0 ? -1 : 1)
                                    }else{
                                        Image("send")
                                            .renderingMode(.template)
                                            .foregroundColor(Color.get(.MiddleGray))
                                    }
                                }
                                .frame(width: 52, height: 52)
                                .background(Color("SectionDivider"))
                                .clipShape(
                                    RoundedRectangle(cornerRadius: 16)
                                )
                                .padding(.trailing,16)
                                
                                VStack(alignment: .leading, spacing: 6){
                                    Group{
                                        if (self.transaction != nil){
                                            Text("\(self.transactionAmount[0]).")
                                            + Text(self.transactionAmount[1])
                                                .font(.subheadline)
                                        }else{
                                            Text("0.")
                                            + Text("00")
                                                .font(.subheadline)
                                        }
                                    }
                                    .font(.title2.bold())
                                    .foregroundColor(Color.get(.Text))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    HStack{
                                        Text(self.transaction?.createdUtc.asDate()?.asString("yyyy-MM-dd HH:mm") ?? "0000-00-00")
                                            .foregroundColor(Color("PaleBlack"))
                                        if (self.transaction != nil){
                                            ZStack{
                                                
                                            }
                                            .frame(width: 6, height: 6)
                                            .background(Color.get(.MiddleGray))
                                            .clipShape(Circle())
                                        }
                                        self.transactionStatus
                                    }
                                }
                            }
                            .padding(.horizontal,16)
                        }
                        .offset(
                            y: self.scrollOffset < 0 ? self.scrollOffset : 0
                        )
                        
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
                        
                        VStack(spacing:0){
                            if (self.transaction != nil){
                                VStack(spacing:12){
                                    if (self.transactionRef.hasStandingOrder && self.transaction?.remitter?.accountId == self.account.id){
                                        self.standingOrder
                                    }
                                    VStack(alignment: .leading, spacing:8){
                                        Text("Sender Details")
                                            .font(.body.bold())
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        Rectangle()
                                            .frame(height: 1)
                                            .foregroundColor(Color("SectionDivider"))
                                        //MARK: - Sender body
                                        VStack(spacing:8){
                                            HStack(alignment: .top, spacing:0){
                                                Text("Name")
                                                    .frame(maxWidth: 130, alignment: .leading)
                                                    .font(.subheadline.bold())
                                                    .foregroundColor(Color.get(.LightGray))
                                                Text(self.transaction?.remitter?.partyDetails?.name ?? "-")
                                                    .frame(maxWidth: .infinity, alignment: .trailing)
                                                    .font(.subheadline.bold())
                                                    .foregroundColor(Color.get(.MiddleGray))
                                            }
                                            AccountIdentification(self.transaction?.remitter, currency: self.transaction?.amount.currencyCode)
                                        }
                                    }
                                    .padding(12)
                                    .background(Color.get(.Section))
                                    .clipShape(
                                        RoundedRectangle(cornerRadius: 16)
                                    )
                                    .padding(.horizontal, 16)
                                    
                                    VStack(alignment: .leading, spacing:8){
                                        Text("Recipient Details")
                                            .font(.body.bold())
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        Rectangle()
                                            .frame(height: 1)
                                            .foregroundColor(Color("SectionDivider"))
                                        //MARK: - Recipient body
                                        VStack(spacing:8){
                                            HStack(alignment: .top, spacing:0){
                                                Text("Name")
                                                    .frame(maxWidth: 130, alignment: .leading)
                                                    .font(.subheadline.bold())
                                                    .foregroundColor(Color.get(.LightGray))
                                                Text(self.transaction?.beneficiary?.partyDetails?.name ?? "-")
                                                    .frame(maxWidth: .infinity, alignment: .trailing)
                                                    .font(.subheadline.bold())
                                                    .foregroundColor(Color.get(.MiddleGray))
                                            }
                                            AccountIdentification(self.transaction?.beneficiary, currency: self.transaction?.amount.currencyCode)
                                        }
                                    }
                                    .padding(12)
                                    .background(Color.get(.Section))
                                    .clipShape(
                                        RoundedRectangle(cornerRadius: 16)
                                    )
                                    .padding(.horizontal, 16)
                                    
                                    VStack(alignment: .leading, spacing:8){
                                        Text("Amount")
                                            .font(.body.bold())
                                            .frame(maxWidth: 130, alignment: .leading)
                                        Rectangle()
                                            .frame(height: 1)
                                            .foregroundColor(Color("SectionDivider"))
                                        //MARK: - Amount body
                                        VStack(spacing:8){
                                            HStack(alignment: .top, spacing:0){
                                                Text("Transferred")
                                                    .frame(maxWidth: 130, alignment: .leading)
                                                    .font(.subheadline.bold())
                                                    .foregroundColor(Color.get(.LightGray))
                                                HStack{
                                                    Spacer()
                                                    Text("\(self.transactionAmount[0]).")
                                                    + Text(self.transactionAmount[1])
                                                        .font(.caption)
                                                }
                                                .font(.subheadline.bold())
                                                .foregroundColor(Color.get(.MiddleGray))
                                            }
                                            HStack(alignment: .top, spacing:0){
                                                Text("Fee")
                                                    .frame(maxWidth: 130, alignment: .leading)
                                                    .font(.subheadline.bold())
                                                    .foregroundColor(Color.get(.LightGray))
                                                HStack{
                                                    Spacer()
                                                    Text("\(self.transactionFee[0]).")
                                                    + Text(self.transactionFee[1])
                                                        .font(.caption)
                                                }
                                                .font(.subheadline.bold())
                                                .foregroundColor(Color.get(.MiddleGray))
                                            }
                                            /*
                                             HStack(alignment: .top, spacing:0){
                                             Text("Balance")
                                             .frame(maxWidth: 130, alignment: .leading)
                                             .font(.subheadline.bold())
                                             .foregroundColor(Color.get(.LightGray))
                                             Text(String(self.transaction?.balance ?? 0).formatAsPrice(currencyChars[self.transaction!.amount.currencyCode.lowercased()] ?? ""))
                                             .frame(maxWidth: .infinity, alignment: .trailing)
                                             .font(.subheadline.bold())
                                             .foregroundColor(Color.get(.MiddleGray))
                                             }
                                             */
                                            HStack(alignment: .top, spacing:0){
                                                Text("Reference")
                                                    .frame(maxWidth: 130, alignment: .leading)
                                                    .font(.subheadline.bold())
                                                    .foregroundColor(Color.get(.LightGray))
                                                Text(self.transaction?.reference ?? "")
                                                    .frame(maxWidth: .infinity, alignment: .trailing)
                                                    .font(.subheadline.bold())
                                                    .foregroundColor(Color.get(.MiddleGray))
                                                    .fixedSize(horizontal: false, vertical: true)
                                                //.lineLimit(0)
                                            }
                                            HStack(alignment: .top, spacing:0){
                                                Text("Statement")
                                                    .frame(maxWidth: 130, alignment: .leading)
                                                    .font(.subheadline.bold())
                                                    .foregroundColor(Color.get(.LightGray))
                                                Button{
                                                    Task{
                                                        do{
                                                            try await self.exportStatement()
                                                        }catch let error{
                                                            self.Error.handle(error)
                                                        }
                                                    }
                                                } label:{
                                                    HStack(alignment: .center, spacing: 4){
                                                        Spacer()
                                                        ZStack{
                                                            Image("Content, Edit - Liner")
                                                                .foregroundColor(Color.get(.Pending))
                                                        }
                                                        .frame(width:18, height: 18)
                                                        Text("Download")
                                                            .font(.subheadline.bold())
                                                            .foregroundColor(Color.get(.Pending))
                                                            .fixedSize(horizontal: false, vertical: true)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    .padding(12)
                                    .background(Color.get(.Section))
                                    .clipShape(
                                        RoundedRectangle(cornerRadius: 16)
                                    )
                                    .padding(.horizontal, 16)
                                }
                                
                            }
                        }
                        .padding(.top,20)
                        .offset(
                            y: self.loading && self.scrollOffset > -100 ? Swift.abs(100 - self.scrollOffset) : 0
                        )
                        .onAppear{
                            Task{
                                do{
                                    try await self.getTransaction()
                                }catch(let error){
                                    self.loading = false
                                    self.Error.handle(error)
                                }
                            }
                        }
                        .onAppear{
                            self.prepareExport()
                        }
                        
                        if (!self.documents.isEmpty){
                            self.relatedDocuments
                                .padding(.top, 12)
                        }
                        Spacer()
                        if (self.transaction != nil){
                            VStack{
                                Button{
                                    self.Router.goTo(RelatedDocumentsView(
                                        customerId: self.account.customer?.id ?? "",
                                        transaction: self.transaction!,
                                        documents: self.documents
                                    ))
                                } label:{
                                    HStack{
                                        Spacer()
                                        ZStack{
                                            Image("add")
                                                .resizable()
                                                .scaledToFit()
                                                .foregroundColor(.black)
                                        }
                                        .frame(width: 18)
                                        Text("Add documents")
                                            .font(.subheadline.bold())
                                        Spacer()
                                    }
                                }
                                .buttonStyle(.secondary())
                                .disabled(self.loading || self.exportLoading)
                                HStack{
                                    Text("Image or PDF, up to 20 Mb")
                                    Spacer()
                                    Text("Optional")
                                }
                                .font(.subheadline.bold())
                                .foregroundColor(Color.get(.LightGray))
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 12)
                        }
                        
                        /*
                        Button{
                            self.shareTransaction()
                        } label: {
                            HStack{
                                Spacer()
                                VStack{
                                    ZStack{
                                        Image("export 1")
                                    }
                                    .frame(width: 24, height: 24)
                                    Text("Share receipt")
                                }
                                Spacer()
                            }
                        }
                        .buttonStyle(.secondary())
                        .disabled(self.exportLoading)
                        .loader(self.$exportLoading)
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                         */
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
                .onChange(of: scrollOffset){ _ in
                    if (!self.loading && self.scrollOffset <= -100){
                        Task{
                            do{
                                try await self.getTransaction()
                            }catch(let error){
                                self.loading = false
                                self.Error.handle(error)
                            }
                        }
                    }
                }
                .sheet(isPresented:self.$exportSheet){
                    ShareSheet(
                        activityItems: [self.exportSheetContent],
                        callback: { activityType,completed,returnedItems,error in
                            self.exportSheet = false
                        }
                    )
                }
                .sheet(isPresented:self.$exportDocumentSheet){
                    ShareSheet(
                        activityItems: [
                            self.exportDocumentContent
                        ],
                        callback: { activityType,completed,returnedItems,error in
                            self.exportDocumentSheet = false
                        }
                    )
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationTitle("")
        .background(Color.get(.Background))
    }
}
