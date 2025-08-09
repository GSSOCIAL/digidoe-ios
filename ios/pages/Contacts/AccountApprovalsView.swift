 //
 //  AccountApprovalsView.swift
 //  DigiDoe Business Banking
 //
 //  Created by Настя Оксенюк on 20.07.2024.
 //

 import Foundation
 import SwiftUI

 extension AccountApprovalsView{
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
     
     fileprivate var customers: Array<Option> {
         return self.Store.user.customers.filter({customer in
             return customer.state == .active && customer.type == .business
         }).map({ customer in
             return Option(
                 id: customer.id,
                 label: customer.name
             )
         })
     }
     
     fileprivate var approvalsMonths: [AccountMainView.TransactionMonth] {
         var output: [AccountMainView.TransactionMonth] = []
         
         let date = Date()
         var i = 0
         
         let formatter = DateFormatter()
         formatter.dateFormat = "MM"
         let yearFormatter = DateFormatter()
         yearFormatter.dateFormat = "yyyy"
         let currentYear = Int(yearFormatter.string(from: date))
         
         while (i<6) {
             let d = date.add(.month, value: i * -1)
             let monthIndex = Int(formatter.string(from: d)) ?? 0
             let monthYear = Int(yearFormatter.string(from: d)) ?? 0;
             
             output.insert(.init(
                 id: i,
                 date: d,
                 title: "\(months[monthIndex-1])\(monthYear != currentYear ? " \(monthYear)" : "")"
             ),at:0)
             i+=1
         }
         
         return output
     }
     
     fileprivate var approvalsMonthsTabs: [Tab] {
         //MARK: Show last 6 months
         var output: [Tab] = []
         
         let _ = self.approvalsMonths.map({ el in
             output.append(Tab(
                 title: el.title,
                 id: el.id
             ))
         })
         output.append(Tab(title: "Pending approval", id: 6))
         return output
     }
     
     fileprivate struct SortedList{
         let date: String
         let ts: Double
         let label: String
         var list: [ListApprovalFlow]
     }
     
     func getApprovals() async throws{
         if (self.loading){
             return;
         }
         
         self.approvals = []
         
         if (self.selectedCustomerId.isEmpty && !Enviroment.isPreview){
             return;
         }
         
         self.loading = true
         
         var from: String? = nil
         var to: String? = nil
         var state: ListApprovalFlow.ListApprovalFlowState? = nil
         //If filters applied - use it
         if (self.from.isEmpty == false){
             from = self.from
         }
         if (self.to.isEmpty == false){
             to = self.to
         }
         if (self.selectedMonth < 6 && (from == nil || from!.isEmpty) && (to == nil || to!.isEmpty)){
             let month = self.approvalsMonths.first(where: { el in
                 return el.id == 5 - self.selectedMonth
             })
             if (month != nil){
                 from = month!.date.startOfMonth().asStringDate()
                 to = month!.date.add(.month, value: 1).startOfMonth().asStringDate()
             }
         }
         if (self.state.isEmpty == false){
             switch(self.state.lowercased()){
             case ListApprovalFlow.ListApprovalFlowState.processing.rawValue.lowercased():
                 state = .processing
             case ListApprovalFlow.ListApprovalFlowState.approved.rawValue.lowercased():
                 state = .approved
             case ListApprovalFlow.ListApprovalFlowState.rejected.rawValue.lowercased():
                 state = .rejected
             default:
                 break
             }
         }else{
             if (self.selectedMonth == 6 && self.from.isEmpty && self.to.isEmpty){
                 state = .processing
             }
         }
         
         let response = try await services.mls.getFlows(self.selectedCustomerId, state: state, startDate: from, endDate: to, pageNumber: self.page, pageSize: self.pageSize)
         if (response.value?.data != nil){
             self.approvals = self.sortApprovals(response.value!.data)
         }
         
         self.loading = false
     }
     
     fileprivate func sortApprovals(_ list: [ListApprovalFlow]) -> [SortedList]{
         var output: [SortedList] = []
         if (list != nil){
             //MAP transactions and push by days
             let today = Date()
             let todayFormatter = DateFormatter()
             todayFormatter.dateFormat = "yyyy-MM-dd"
             let todayString = todayFormatter.string(from: today)
             
             let _ = list.map(({ item in
                 let frm = DateFormatter()
                 frm.locale = Locale(identifier: "en_US_POSIX")
                 frm.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
                 let itemDate = frm.date(from: item.createdUtc)
                 if (itemDate != nil){
                     let dateString = todayFormatter.string(from: itemDate!)
                     //Search for index in output
                     let index = output.firstIndex(where: {$0.date == dateString})
                     
                     if (index == nil){
                         output.append(.init(
                             date: dateString,
                             ts: 0,
                             label: dateString,
                             list: [item]
                         ))
                     }else{
                         output[index!].list.append(item)
                     }
                 }
             }))
         }
         
         return output.sorted(by: {a,b in
             let formatter = DateFormatter()
             formatter.dateFormat = "yyyy-MM-dd"
             
             let dateA = formatter.date(from: a.date)
             let dateB = formatter.date(from: b.date)
             if (dateA != nil && dateB != nil){
                 return dateA! > dateB!
             }
             return false
         });
     }
     
     fileprivate func renderGroup(group: SortedList) -> some View{
         ZStack{
             VStack(spacing:0){
                 ForEach(group.list, id:\.id){ item in
                     Button{
                         self.Router.goTo(AccountApprovalFlowDetailsView(flowId: item.id))
                     } label: {
                         ApprovalCard(item: item)
                     }
                     if (item.id != group.list.last(where: {$0.id == item.id})?.id){
                         Divider().overlay(Color.get(.LightGray))
                     }
                 }
             }
         }
     }
     
     var statuses: [Option]{
         return [
             .init(
                 id: "",
                 label: "All"
             ),
             .init(
                 id: ListApprovalFlow.ListApprovalFlowState.processing.rawValue,
                 label: "Processing"
             ),
             .init(
                 id: ListApprovalFlow.ListApprovalFlowState.approved.rawValue,
                 label: "Approved"
             ),
             .init(
                 id: ListApprovalFlow.ListApprovalFlowState.rejected.rawValue,
                 label: "Rejected"
             ),
         ]
     }
     
     func applyFilters(){
         Task{
             do{
                 self.showFilters = false
                 try await self.getApprovals()
             }catch(let error){
                 self.Error.handle(error)
             }
         }
     }
     
     var appliedFilters: Binding<[TagCloudView.Tag]>{
         Binding(
             get:{
                 var output: [TagCloudView.Tag] = []
                 if (self.from.isEmpty == false){
                     output.append(.init(
                         key: "from", label: "From \(self.from)"
                     ))
                 }
                 if (self.to.isEmpty == false){
                     output.append(.init(
                         key: "to", label: "To \(self.to)"
                     ))
                 }
                 if (self.state.isEmpty == false){
                     switch(self.state.lowercased()){
                     case ListApprovalFlow.ListApprovalFlowState.approved.rawValue.lowercased():
                         output.append(.init(
                             key: "state", label: "Approved"
                         ))
                     case ListApprovalFlow.ListApprovalFlowState.rejected.rawValue.lowercased():
                         output.append(.init(
                             key: "state", label: "Rejected"
                         ))
                     case ListApprovalFlow.ListApprovalFlowState.processing.rawValue.lowercased():
                         output.append(.init(
                             key: "state", label: "Processing"
                         ))
                     default: break
                     }
                 }
                 return output
             },
             set: { value in
             }
         )
     }
 }

 struct AccountApprovalsView: View, RouterPage{
     @EnvironmentObject var Store: ApplicationStore
     @EnvironmentObject var Error: ErrorHandlingService
     @EnvironmentObject var Router: RoutingController
     
     @State private var scrollOffset : Double = 0
     @State private var filtersScrollOffset : Double = 0
     let columns = Array(repeating: GridItem(.flexible(),spacing: 12), count: 1)
     @State private var loading: Bool = false
     
     @State private var selectedCustomerId: String = ""
     @State private var selectedMonth: Int = 0
     
     @State private var approvals: [SortedList] = []
     @State private var showFilters: Bool = false
     @State private var from: String = ""
     @State private var to: String = ""
     @State private var state: String = ""
     @State private var fromBefore: String = ""
     @State private var toBefore: String = ""
     @State private var stateBefore: String = ""
     
     @State private var page: Int = 1
     @State private var pageSize: Int = -1
     @State private var total: Int = 0
     
     var filters: some View{
         GeometryReader{ geometry in
             ZStack{
                 ScrollView{
                     VStack(spacing:0){
                         VStack(spacing:0){
                             //MARK: Header
                             ZStack{
                                 HStack{
                                     Spacer()
                                     Button{
                                         self.from = self.fromBefore
                                         self.to = self.toBefore
                                         self.state = self.stateBefore
                                         self.showFilters = false
                                     } label:{
                                         ZStack{
                                             Image("cross")
                                                 .resizable()
                                                 .scaledToFit()
                                                 .foregroundColor(Color.get(.Text))
                                             
                                         }
                                             .frame(width: 24, height: 24)
                                     }
                                 }
                                 Text("Filter").foregroundColor(Color.get(.Text))
                                     .font(.subheadline.bold())
                                     .multilineTextAlignment(.center)
                             }
                             .padding(.horizontal, 16)
                             .padding(.vertical, 12)
                             //MARK: End of header
                         }
                         .offset(
                             y: self.filtersScrollOffset < 0 ? self.filtersScrollOffset : 0
                         )
                         VStack(spacing: 18){
                             CustomField(value: self.$from, placeholder: "From", type: .date)
                             CustomField(value: self.$to, placeholder: "To", type: .date)
                             CustomField(value: self.$state, placeholder: "Status", type: .select, options: self.statuses, searchable: true)
                         }
                         .frame(maxWidth: .infinity)
                         .padding(.horizontal, 16)
                         .offset(
                             y: self.loading && self.filtersScrollOffset > -100 ? Swift.abs(100 - self.filtersScrollOffset) : 0
                         )
                         Spacer()
                         HStack(spacing: 17){
                             Button{
                                 self.from = ""
                                 self.to = ""
                                 self.state = ""
                             } label: {
                                 HStack{
                                     Spacer()
                                     Text("Clear")
                                     Spacer()
                                 }
                             }
                             .buttonStyle(.plain())
                             Button{
                                 self.applyFilters()
                             } label: {
                                 HStack{
                                     Spacer()
                                     Text("Apply")
                                     Spacer()
                                 }
                             }
                             .buttonStyle(.primary())
                         }
                         .padding(.horizontal, 16)
                     }
                     .background(GeometryReader {
                         Color.clear.preference(key: RefreshViewOffsetKey.self, value: -$0.frame(in: .named("filtersScroll")).origin.y)
                     })
                     .onPreferenceChange(RefreshViewOffsetKey.self) { position in
                         self.filtersScrollOffset = position
                     }
                     .frame(
                         maxWidth: .infinity,
                         minHeight: geometry.size.height - geometry.safeAreaInsets.bottom
                     )
                 }
                     .coordinateSpace(name: "filtersScroll")
                     .onChange(of: scrollOffset){ _ in
                         if (!self.loading && self.scrollOffset <= -100){
                             Task{
                                 do{
                                     try await self.getApprovals()
                                 }catch(let error){
                                     self.loading = false
                                     self.Error.handle(error)
                                 }
                             }
                         }
                     }
             }
             .background(Color.get(.Background))
             .onAppear{
                 if (self.from.isEmpty){
                     DispatchQueue.main.async{
                         self.from = ""
                     }
                 }
                 if (self.to.isEmpty){
                     DispatchQueue.main.async{
                         self.to = ""
                     }
                 }
             }
         }
     }
     
     var body: some View {
         ApplicationNavigatorContainerView{
             GeometryReader{ geometry in
                 ZStack{
                     ScrollView{
                         VStack(spacing:0){
                             VStack(spacing:0){
                                 Header(back:{
                                     self.Router.back()
                                 }, title: "Approvals"){
                                     HStack{
                                         Button{
                                             self.showFilters = true
                                         } label: {
                                             ZStack{
                                                 Image("filter")
                                                     .resizable()
                                                     .scaledToFit()
                                                     .foregroundColor(self.appliedFilters.isEmpty ?  Color.get(.Text) : Whitelabel.Color(.Primary))
                                             }
                                             .frame(width: 24, height: 24)
                                             .padding(8)
                                             .background(self.appliedFilters.isEmpty ?  Color.get(.Background) : Whitelabel.Color(.Primary).opacity(0.2))
                                             .clipShape(RoundedRectangle(cornerRadius: 10))
                                         }
                                         .onChange(of: self.showFilters){ _ in
                                             self.fromBefore = self.from
                                             self.toBefore = self.to
                                             self.stateBefore = self.state
                                         }
                                     }
                                 }
                                 //MARK: Filters
                                 if (self.appliedFilters.isEmpty == false){
                                     TagCloudView(tags: self.appliedFilters, onClick: { property in
                                         switch(property.lowercased()){
                                         case "from":
                                             self.from = ""
                                         case "to":
                                             self.to = ""
                                         default:
                                             self.state = ""
                                         }
                                         self.applyFilters()
                                     })
                                         .padding(.horizontal, 16)
                                 }
                                 //MARK: Tabs
                                 Tabs(tabs: approvalsMonthsTabs, selectedTab: $selectedMonth, style: .selector)
                                     .padding(.bottom, 12)
                                     .padding(.horizontal, 16)
                                     .frame(height: 60)
                                     .onChange(of: self.selectedMonth){ change in
                                         if (self.selectedMonth < 6){
                                             self.from = ""
                                             self.to = ""
                                         }else{
                                             self.state = ""
                                         }
                                         Task{
                                             do{
                                                 try await self.getApprovals()
                                             }catch(let error){
                                                 self.loading = false
                                                 self.Error.handle(error)
                                             }
                                         }
                                     }
                                 //MARK: Customer selector
                                 CustomField(value: self.$selectedCustomerId, placeholder: "Customer", type: .select, options: self.customers, overrideSelect: false)
                                     .disabled(self.loading)
                                     .padding(.horizontal, 16)
                                     .onChange(of: self.selectedCustomerId){ customer in
                                         if (self.selectedCustomerId.isEmpty == false){
                                             Task{
                                                 do{
                                                     try await self.getApprovals()
                                                 }catch(let error){
                                                     self.loading = false
                                                     self.Error.handle(error)
                                                 }
                                             }
                                         }
                                     }
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
                             
                             VStack{
                                 LazyVGrid(columns: self.columns){
                                     ForEach(Array(self.approvals.enumerated()), id: \.1.date){ (index,group) in
                                         //MARK: Group
                                         VStack(spacing:0){
                                             ZStack{
                                                 Text(group.label)
                                                     .frame(maxWidth: .infinity, alignment: .leading)
                                                     .padding(.horizontal,16)
                                                     .padding(.vertical,2)
                                                     .font(.caption.weight(.medium))
                                                     .background(Color("Container"))
                                                     .foregroundColor(Color.get(.LightGray))
                                                     .clipShape(RoundedRectangle(cornerRadius: 16))
                                                     .background(
                                                         VStack(spacing:0){
                                                             if (index > 0){
                                                                 Color.get(.Section)
                                                             }else{
                                                                 Color.get(.Background)
                                                             }
                                                             Color.get(.Section)
                                                         }
                                                     )
                                             }
                                             VStack(spacing:0){
                                                 self.renderGroup(group: group)
                                             }
                                         }
                                     }
                                 }
                                 .padding(.top, 12)
                             }
                             .frame(maxWidth: .infinity)
                             .padding(.horizontal, 16)
                             .offset(
                                 y: self.loading && self.scrollOffset > -100 ? Swift.abs(100 - self.scrollOffset) : 0
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
                     }
                         .coordinateSpace(name: "scroll")
                         .onChange(of: scrollOffset){ _ in
                             if (!self.loading && self.scrollOffset <= -100){
                                 Task{
                                     do{
                                         try await self.getApprovals()
                                     }catch(let error){
                                         self.loading = false
                                         self.Error.handle(error)
                                     }
                                 }
                             }
                         }
                         .onAppear{
                             Task{
                                 do{
                                     DispatchQueue.main.asyncAfter(deadline: .now() + 0.1){
                                         self.selectedCustomerId = self.customers.first?.id ?? ""
                                         self.selectedMonth = 6
                                     }
                                 }catch(let error){
                                     self.loading = false
                                     self.Error.handle(error)
                                 }
                             }
                         }
                     //MARK: Popups
                     if (self.showFilters){
                         self.filters
                     }
                     //MARK: Filters end
                 }
             }
         }
         .navigationBarBackButtonHidden(true)
         .navigationTitle("")
     }
 }

 struct AccountApprovalsViewParent_Previews: View{
     @EnvironmentObject var Store: ApplicationStore
     
     var body: some View{
         ZStack{
             if (self.Store.user.customers.isEmpty == false){
                 AccountApprovalsView()
                     .environmentObject(self.Store)
             }
         }.onAppear{
             if Enviroment.isPreview{
                 self.Store.user.customers = [
                     .init(
                         id: "0",
                         name: "Individual Preview",
                         type: .individual,
                         state: .active
                     ),
                     .init(
                         id: "1",
                         name: "Business Preview",
                         type: .business,
                         state: .active
                     )
                 ]
             }
         }
     }
 }

 struct AccountApprovalsView_Previews: PreviewProvider {
     static var previews: some View {
         ContentViewContainerPreview{
             AccountApprovalsViewParent_Previews()
         }
     }
 }
