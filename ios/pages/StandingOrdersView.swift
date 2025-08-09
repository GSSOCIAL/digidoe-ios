//
//  StandingOrdersView.swift
//  DigiDoe Business Banking
//
//  Created by Михайло Картмазов on 29.06.2025.
//

import Foundation
import SwiftUI

//MARK: - Structs
extension StandingOrdersView{
    struct SortedOrders{
        var state: StandingOrderDto.StandingOrderState
        var list: Array<PaymentOrderExtendedDto>
    }
}

//MARK: - Methods
extension StandingOrdersView{
    func getOrders() async throws{
        if (self.loading){
            return
        }
        self.loading = true
        
        let response = try await services.standingOrders.getList(
            self.account.customer?.id ?? "",
            accountId: self.account.id ?? "",
            state: StandingOrderDto.StandingOrderState.allCases.first(where: {$0.rawValue.lowercased() == self.state.lowercased()})
        )
        self.orders = self.sortOrders(response.value.data!)
        self.loading = false
    }
    
    func sortOrders(_ orders: Array<PaymentOrderExtendedDto>) -> Array<SortedOrders>{
        var output: Array<SortedOrders> = []
        
        //Loop through each order and sort by status
        StandingOrderDto.StandingOrderState.allCases.forEach{ state in
            //Find related orders
            let ordersForState: Array<PaymentOrderExtendedDto> = orders.filter{
                $0.standingOrder?.state == state
            }
            if (ordersForState.isEmpty == false){
                output.append(.init(
                    state: state,
                    list: ordersForState
                ))
            }
        }
        
        return output.sorted(by: {a,b in
            if (a.state == .active && b.state != .active){
                return false
            }
            if (a.state == .completed && b.state != .completed){
                return false
            }
            if (a.state == .cancelled && b.state != .cancelled){
                return false
            }
            
            return true
        })
    }
    func scheduleNewOrder(){
        self.Router.goTo(
            CreatePaymentView(
                customer: self.account.customer!,
                account: self.account,
                isScheduleOrder: true
            )
        )
    }
}

//MARK: - Getters
extension StandingOrdersView{
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
    private var stateList: Array<Option>{
        var list: Array<Option> = [
            .init(id: "", label: "All")
        ]
        list.append(contentsOf: StandingOrderDto.StandingOrderState.allCases.map({
            return .init(
                id: $0.rawValue,
                label: $0.label
            )
        }))
        return list
    }
}

//MARK: - Views
extension StandingOrdersView{
    func renderGroup(group: SortedOrders) -> some View{
        ZStack{
            VStack(spacing:0){
                ForEach(group.list, id:\.id){ order in
                    Button{
                        self.Router.goTo(
                            StandingOrderDetailsView(
                                customerId: self.account.customer?.id ?? "",
                                account: self.account,
                                orderId: order.id
                            )
                        )
                    } label: {
                        StandingOrderCard(
                            order: order
                        )
                    }
                    if (order.id != group.list.last(where: {$0.id == order.id})?.id){
                        Divider().overlay(Color.get(.LightGray))
                    }
                }
            }
        }
    }
    var bottom: some View{
        HStack{
            HStack{
                Button{
                    self.scheduleNewOrder()
                } label:{
                    HStack{
                        Spacer()
                        HStack(alignment: .center, spacing: 12){
                            ZStack{
                                Image("add")
                                    .foregroundColor(Color.white)
                            }.frame(width: 16, height: 16)
                            Text("Schedule new transfer")
                        }
                        Spacer()
                    }
                }
                .buttonStyle(.primary())
            }
        }
    }
}

struct StandingOrdersView: View, RouterPage {
    @EnvironmentObject var Store: ApplicationStore
    @EnvironmentObject var Error: ErrorHandlingService
    @EnvironmentObject var Router: RoutingController
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var loading: Bool = false
    @State private var scrollOffset: Double = 0
    @State private var orders: Array<SortedOrders> = []
    
    @State public var account: CoreAccount
    @State private var accountUid: Int = 1
    @State private var state: String = ""
    
    var body: some View {
        ApplicationNavigatorContainerView{
            GeometryReader{ geometry in
                ZStack{
                    ScrollView{
                        VStack(spacing: 0){
                            VStack(spacing: 0){
                                Header(back:{
                                    self.Router.back()
                                }, title: "Standing orders")
                                
                                CoreAccountCard(
                                    account: self.account
                                )
                                .id(self.accountUid)
                                    .padding(.horizontal, 16)
                                
                                Text("Standing orders")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal,16)
                                    .padding(.vertical, 16)
                                    .font(.title2.bold())
                                    .foregroundColor(Color("Text"))
                                
                                VStack{
                                    CustomField(
                                        value: self.$state,
                                        placeholder: "All",
                                        type: .select,
                                        options: self.stateList
                                    )
                                    .onChange(of: self.state){ _ in
                                        Task{
                                            do{
                                                try await self.getOrders()
                                            }catch(let error){
                                                self.loading = false
                                                self.Error.handle(error)
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.bottom, 16)
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
                            VStack(spacing: 0) {
                                VStack(spacing: 0){
                                    ForEach(Array(self.orders.enumerated()), id: \.1.state.rawValue){ (index, group) in
                                        VStack(spacing: 0){
                                            ZStack{
                                                Text(group.state.group)
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
                                            VStack(spacing: 0){
                                                self.renderGroup(group: group)
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal, 16)
                            }
                            .padding(.bottom, geometry.safeAreaInsets.bottom + 90)
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
                                    try await self.getOrders()
                                }catch(let error){
                                    self.loading = false
                                    self.Error.handle(error)
                                }
                            }
                        }
                    }
                    .overlay(
                        self.bottom
                            .frame(maxWidth: .infinity)
                            .padding(.bottom, geometry.safeAreaInsets.bottom)
                            .padding(.vertical,16)
                            .padding(.horizontal,24)
                            .background(Color("Background"))
                            .clipShape(
                                RoundedRectangle(cornerRadius: 16)
                            )
                            .shadow(color: Color.black.opacity(0.2), radius: 6, x: 0, y: -6)
                        , alignment: .bottom
                    )
                    .edgesIgnoringSafeArea(.bottom)
                    
                    //MARK: Popups
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationTitle("")
        .background(Color.get(.Background))
        .onAppear{
            Task{
                do{
                    try await self.getOrders()
                }catch(let error){
                    print(error)
                    self.loading = false
                    self.Error.handle(error)
                }
            }
        }
    }
}
