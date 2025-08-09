//
//  PayeesView.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 02.01.2024.
//

import Foundation
import SwiftUI
import CoreData

extension PayeesView{
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
    
    func getContacts(page: Int = 1) async throws -> ContactsService.GetCustomersResponse?{
        if (self.loading){
            return nil;
        }
        
        if (page == 1){
            self.Store.contacts.list = []
        }
        guard self.customer != nil else{
            throw ApplicationError(title: "No customer", message: "Customer doesnt passed")
        }
        
        self.loading = true
        let response = try await services.contacts.getCustomerContacts(
            self.customer.id ?? "",
            page: page,
            size: self.pageSize,
            currency: self.currency ?? "",
            query: self.query.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed)
        )
        
        self.Store.contacts.list.append(contentsOf: response.data)
        self.total = response.total
        self.page = response.pageNumber
        self.loading = false
        
        return response
    }
    
    func handleSearch(){
        Task{
            if (self.task != nil && self.task?.isCancelled == false){
                self.task?.cancel()
            }
            let task = Task.detached(priority: .background){
                try await Task.sleep(nanoseconds: userDefaultInputLagTimeNanoSeconds)
                return try await self.getContacts(page: 1)
            }
            self.task = task
            
            do{
                _ = try await task.value
            }catch(let error){
                if (error as? CancellationError != nil){
                    
                }else{
                    self.Error.handle(error)
                }
                self.loading = false
            }
        }
    }
    
    func selectContact(_ contact: Contact){
        self.Router.goTo(
            CreatePaymentView(
                customer: self.customer,
                account: self.account,
                payee: contact,
                fetch: self.callback,
                attachments: self.attachments                
            ),
            routingType: .backward)
    }
    
    var contacts: [Binding<[Contact]>.Element] {
        return self.$Store.contacts.list.filter({ _ in
            return true
        })
    }
    
    func contactActionsHandler(_ contact: Contact){
        self.selectedContactId = contact.contactId!
        self.popupActions = true
    }
    
    /// Delete customer contact
    /// - Parameters:
    /// - contactId<String> - Source contact id
    func deleteContact(_ contactId: String) async throws{
        self.loading = true
        self.deleteWarning = false
        
        self.contactDeleteOTPResult = nil
        let initiate = try await services.contacts.initiateDeleteCustomerContacts(self.customer.id ?? "", contactId: contactId)
        self.contactDeleteOperationId = initiate.operationId
        self.contactDeleteOTP = true
        
        Task{
            while(self.contactDeleteOTPResult == nil){
                try? await Task.sleep(nanoseconds: 1_000_000_000)
            }
            self.contactDeleteOTP = false
            switch(self.contactDeleteOTPResult){
                case .confirmed(let operationId, let sessionId, let type):
                    do{
                        let isSuccess = try await services.contacts.finalizeContactOperation(self.customer.id ?? "", operationId: operationId, sessionId: sessionId, confirmationType: type)
                        if (isSuccess){
                            self.loading = false
                            //Manually remove item from store
                            let index = self.Store.contacts.list.firstIndex(where: {contact in
                                return contact.id == contactId
                            })
                            if (index != nil){
                                self.Store.contacts.list.remove(at: index!)
                            }
                            return;
                        }
                        
                        throw ApplicationError(title: "Delete contact", message: "Failed to delete contact, please try again")
                    }catch(let error){
                        self.loading = false
                        self.Error.handle(error)
                    }
                break
            default:
                throw ApplicationError(title: "", message: "Operation rejected")
            }
        }
        self.loading = false
    }
    
    /// Make contact copy and move it to anoter customer
    /// - Parameters:
    /// - destination<KycpService.CustomersResponse.Customer> - Destination customer
    /// - contactId<String?> - Source contact id
    func copyContact(_ destination: CoreCustomer, contactId: String?) async throws{
        self.loading = true
        self.destinationAccountPopup = false
        
        //Make contact copy
        guard var contact = self.contacts.first(where: {$0.wrappedValue.contactId == contactId})?.wrappedValue else{
            throw ApplicationError(title: "", message: "Unable to copy contact. Please try again")
        }
        contact.contactId = nil
        
        self.contactCopyOTPResult = nil
        let initiate = try await services.contacts.initiateCreateCustomerContact(destination.id ?? "", contact: contact)
        self.contactCopyOperationId = initiate.operationId
        self.contactCopyOTP = true
        
        Task{
            while(self.contactCopyOTPResult == nil){
                try? await Task.sleep(nanoseconds: 1_000_000_000)
            }
            self.contactCopyOTP = false
            switch(self.contactCopyOTPResult){
                case .confirmed(let operationId,let sessionId,let type):
                    do{
                        let isSuccess = try await services.contacts.finalizeContactOperation(destination.id ?? "", operationId: operationId, sessionId: sessionId, confirmationType: type)
                        if (isSuccess){
                            self.loading = false
                            return;
                        }
                        throw ApplicationError(title: "", message: "Failed to copy payee. Please try again")
                    }catch(let error){
                        self.loading = false
                        self.Error.handle(error)
                    }
                break
            default:
                throw ApplicationError(title: "", message: "Operation rejected")
            }
        }
        self.loading = false
    }
    
    var selectedContact: Contact?{
        if (self.selectedContactId != nil){
            return self.contacts.first(where: { contact in
                return contact.wrappedValue.contactId == self.selectedContactId
            })?.wrappedValue
        }
        return nil
    }
}

struct PayeesView: View, RouterPage {
    @EnvironmentObject var Store: ApplicationStore
    @EnvironmentObject var Error: ErrorHandlingService
    @EnvironmentObject var Router: RoutingController
    
    @State private var popupActions: Bool = false
    @State private var deleteWarning: Bool = false
    @State private var selectedContactId: String? = ""
    @State private var destinationAccountPopup: Bool = false
    
    @State private var loading: Bool = false
    @State private var scrollOffset : Double = 0
    let columns = Array(repeating: GridItem(.flexible(),spacing: 10), count: 1)
    
    @State private var query: String = ""
    @State private var queryResponder: Bool = false
    @State private var task: Task<ContactsService.GetCustomersResponse?, any Error>?
    @State private var page:Int = 1
    @State private var pageSize:Int = 20
    @State private var total:Int = 0
    
    @State public var customer: CoreCustomer
    @State public var account: CoreAccount? = nil
    @State public var currency: String? = ""
    
    //OTP For Contact actions
    @State private var contactCopyOTP: Bool = false
    @State private var contactCopyOperationId: String = ""
    @State private var contactCopyOTPResult: OTPView.OTPOperationResult? = nil
    
    @State private var contactDeleteOTP: Bool = false
    @State private var contactDeleteOperationId: String = ""
    @State private var contactDeleteOTPResult: OTPView.OTPOperationResult? = nil
    
    //Attachments
    @Binding public var attachments: Array<FileAttachment>
    
    //Callback
    @State public var callback: RouterPageCallback? = nil
    
    @FetchRequest(
        sortDescriptors:[SortDescriptor(\.type), SortDescriptor(\.name)],
        predicate: NSPredicate(format: "lowercase:(state) == 'active'")
    ) var customers: FetchedResults<CoreCustomer>
    
    var contactActions: some View{
        VStack(alignment: .leading, spacing:0){
            if (self.selectedContact != nil && self.selectedContactId != nil){
                Button{
                    self.popupActions = false
                    self.deleteWarning = true
                } label:{
                    HStack{
                        Text("Delete the payee")
                        Spacer()
                    }
                }
                .buttonStyle(.danger(image: "delete"))
                .frame(maxWidth: .infinity)
                
                if (isContactDetailsMissing(self.selectedContact!) == false){
                    Divider().overlay(Color.get(.Divider))
                    
                    //MARK: Missing design
                    Button{
                        self.popupActions = false
                        self.destinationAccountPopup = true
                    } label:{
                        HStack{
                            Text("Copy payee to...")
                            Spacer()
                        }
                    }
                    .buttonStyle(.plain(image: "copy"))
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }
    
    var body: some View {
        ApplicationNavigatorContainerView{
            GeometryReader{ geometry in
                ZStack{
                    InfiniteScrollView(
                        tolerance: 100,
                        onScrollEnd: {
                            if (self.contacts.isEmpty || self.loading || self.contacts.count >= self.total){
                                return
                            }
                            Task{
                                do{
                                    let _ = try await self.getContacts(page: self.page + 1)
                                }catch(let error){
                                    self.loading = false
                                    self.Error.handle(error)
                                }
                            }
                        }
                    ){
                        VStack(spacing: 0){
                            VStack(spacing: 12){
                                Header(back:{
                                    self.Router.stack.removeLast()
                                    self.Router.goTo(
                                        CreatePaymentView(
                                            customer: self.customer,
                                            account: self.account,
                                            fetch: self.callback,
                                            attachments: self.attachments
                                        ),
                                        routingType: .backward
                                    )
                                }, title: "Payees"){
                                    HStack{
                                        Button{
                                            self.Router.goTo(
                                                CreatePayeeView(
                                                    customer: self.customer,
                                                    callback: self.callback,
                                                    attachments: self.$attachments
                                                )
                                            )
                                        } label:{
                                            HStack{
                                                ZStack{
                                                    Image("add")
                                                        .resizable()
                                                        .scaledToFit()
                                                }
                                                .frame(width: 18)
                                                Text("Add")
                                                    .font(.subheadline.bold())
                                            }
                                            .foregroundColor(Whitelabel.Color(.Primary))
                                        }
                                    }
                                }
                                CustomField(
                                    value: self.$query,
                                    responder: self.queryResponder,
                                    placeholder: "Search",
                                    type: .text
                                )
                                    .padding(.horizontal, 16)
                                    .onChange(of: self.query, perform: { _ in
                                        self.handleSearch()
                                    })
                            }
                            .padding(.bottom, 16)
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
                            
                            LazyVGrid(columns: self.columns){
                                ForEach(Array(self.contacts.enumerated()),id:\.1.id){ (index, $contact) in
                                    if (isContactDetailsMissing($contact.wrappedValue)){
                                        Button{
                                            self.selectedContactId = $contact.wrappedValue.contactId
                                            //Here store contact & open edit page
                                            self.Router.goTo(CreatePayeeView(
                                                customer: self.customer,
                                                selectedContact: self.selectedContact,
                                                callback: self.callback,
                                                attachments: self.$attachments
                                            ))
                                        } label: {
                                            ContactCard(
                                                style: .list,
                                                contact: $contact.wrappedValue,
                                                actionsHandler: self.contactActionsHandler
                                            )
                                        }
                                    }else{
                                        ContactCard(
                                            style: .list,
                                            contact: $contact.wrappedValue,
                                            handler: self.selectContact,
                                            actionsHandler: self.contactActionsHandler
                                        )
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .offset(
                                y: self.loading && self.scrollOffset > -100 ? Swift.abs(100 - self.scrollOffset) : 0
                            )
                            .onAppear{
                                Task{
                                    do{
                                        try await self.getContacts()
                                    }catch(let error){
                                        self.loading = false
                                        self.Error.handle(error)
                                    }
                                }
                            }
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
                    }
                    .coordinateSpace(name: "scroll")
                    .onChange(of: scrollOffset){ _ in
                        if (!self.loading && self.scrollOffset <= -100){
                            Task{
                                do{
                                    try await self.getContacts()
                                }catch(let error){
                                    self.loading = false
                                    self.Error.handle(error)
                                }
                            }
                        }
                    }
                    
                    //MARK: - Popup
                    if (self.selectedContact != nil){
                        PresentationSheet(isPresented: self.$popupActions){
                            VStack(spacing:0){
                                if (self.selectedContact != nil){
                                    ContactCard(style: .initial, contact: self.selectedContact!)
                                        .padding(16)
                                        .background(
                                            ZStack{
                                                RoundedRectangle(cornerRadius: 16)
                                                    .overlay(
                                                        Rectangle()
                                                            .frame(height:30)
                                                            .foregroundColor(Color.get(.Section))
                                                        , alignment: .bottom
                                                    )
                                            }
                                                .foregroundColor(Color.get(.Section))
                                        )
                                    self.contactActions
                                }
                            }
                            .padding(.bottom, geometry.safeAreaInsets.bottom)
                        }
                        
                        PresentationSheet(isPresented: self.$deleteWarning){
                            VStack{
                                Image("ask-splash")
                                VStack(alignment: .center, spacing: 2){
                                    Text("Do you want to delete payee’s account?")
                                        .font(.body.bold())
                                        .foregroundColor(Color.get(.Text))
                                        .multilineTextAlignment(.center)
                                    Text("Associated SO’s will be cancelled.")
                                        .font(.body.bold())
                                        .foregroundColor(Color.get(.Text))
                                        .multilineTextAlignment(.center)
                                }
                                .padding(.vertical,26)
                                HStack{
                                    Button{
                                        self.deleteWarning = false
                                    } label:{
                                        HStack{
                                            Spacer()
                                            Text(LocalizedStringKey("Cancel"))
                                            Spacer()
                                        }
                                    }
                                    .buttonStyle(.secondary())
                                    if (self.selectedContactId != nil){
                                        Spacer()
                                        Button{
                                            Task{
                                                do{
                                                    self.deleteWarning = false
                                                    try await self.deleteContact(self.selectedContactId!)
                                                }catch(let error){
                                                    self.Error.handle(error)
                                                }
                                            }
                                        } label:{
                                            HStack{
                                                Spacer()
                                                Text(LocalizedStringKey("Confirm"))
                                                Spacer()
                                            }
                                        }
                                        .buttonStyle(.primary())
                                    }
                                }
                            }
                            .padding(.bottom, geometry.safeAreaInsets.bottom)
                            .padding(20)
                            .padding(.top,10)
                        }
                        
                        PresentationSheet(isPresented: self.$destinationAccountPopup){
                            VStack{
                                ScrollView{
                                    VStack(spacing: 12){
                                        Text("Select customer")
                                            .font(.title2.bold())
                                            .foregroundColor(Color.get(.Text))
                                            .frame(maxWidth:.infinity, alignment: .leading)
                                            .multilineTextAlignment(.leading)
                                        VStack(spacing: 8){
                                            ForEach(self.customers, id: \.id){ customer in
                                                Button{
                                                    Task{
                                                        do{
                                                            try await self.copyContact(
                                                                customer,
                                                                contactId: self.selectedContactId
                                                            )
                                                        }catch(let error){
                                                            self.destinationAccountPopup = false
                                                            self.loading = false
                                                            self.Error.handle(error)
                                                        }
                                                    }
                                                } label:{
                                                    CustomerCard(
                                                        style: .list,
                                                        customer: customer
                                                    )
                                                }
                                                .disabled(self.loading)
                                            }
                                        }
                                    }
                                }
                                .frame(maxHeight: geometry.size.height - (geometry.safeAreaInsets.bottom + 100))
                            }
                            .padding(.bottom, geometry.safeAreaInsets.bottom)
                            .padding(20)
                            .padding(.top,10)
                        }
                    }
                }
            }
            .otp(isPresented: self.$contactCopyOTP, operationId: self.$contactCopyOperationId, result: self.$contactCopyOTPResult)
            .otp(isPresented: self.$contactDeleteOTP, operationId: self.$contactDeleteOperationId, result: self.$contactDeleteOTPResult)
        }
        .navigationBarBackButtonHidden(true)
        .navigationTitle("")
        .background(Color.get(.Background))
    }
}
