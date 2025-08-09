//
//  Router.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 21.03.2024.
//

import Foundation
import SwiftUI

struct RouterView<Main>: View where Main: View{
    @EnvironmentObject private var controller: RoutingController
    
    private let transitionsCell: (backward: AnyTransition, forward: AnyTransition)
    private var transitions: AnyTransition {
        controller.routingType == .forward ? transitionsCell.forward : transitionsCell.backward
    }
    
    let content: Main
    
    public init(
        duration: Double,
        transition: RoutingController.RoutingTransition = .default,
        @ViewBuilder content: () -> Main)
    {
        self.init(
            easing: Animation.easeOut(duration: duration),
            transition: transition,
            content: content
        )
    }

    public init(
        easing: Animation = Animation.easeOut(duration: 0.4),
        transition: RoutingController.RoutingTransition = .default,
        @ViewBuilder content: () -> Main)
    {
        self.content = content()
        
        switch transition {
        case .single(let ani):
            self.transitionsCell = (ani, ani)
        case .double(let first, let second):
            self.transitionsCell = (first, second)
        case .none:
            self.transitionsCell = (.identity, .identity)
        default:
            self.transitionsCell = RoutingController.RoutingTransition.transitions
        }
    }
    
    var body: some View{
        ZStack{
            if (self.controller.current == nil){
                self.content
                    .transition(self.transitions)
                    .environmentObject(self.controller)
            }else{
                self.controller.current!.view
                    .transition(self.transitions)
                    .environmentObject(self.controller)
            }
        }.frame(maxWidth: .infinity)
    }
}

#if DEBUG
struct RouterViewPreviewsHomePage: View, RouterPage{
    @EnvironmentObject var Router: RoutingController
    
    var body: some View{
        GeometryReader{ geometry in
            ZStack{
                ScrollView{
                    VStack{
                        HStack{
                            Spacer()
                            Text("Home")
                            Spacer()
                        }
                            .padding(16)
                        ZStack{
                            Image("success-splash")
                        }
                        Text("Lorem ipsum")
                            .foregroundColor(Color.gray)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(16)
                        VStack{
                            Button{
                                self.Router.goTo(RouterViewPreviewsContactsPage())
                            } label: {
                                HStack{
                                    Text("Contacts")
                                    Spacer()
                                }
                            }
                            .padding(.vertical, 10)
                            Button{
                                self.Router.goTo(RouterViewPreviewsLeadsPage())
                            } label: {
                                HStack{
                                    Text("Leads")
                                    Spacer()
                                }
                            }
                            .padding(.vertical, 10)
                        }
                        .padding(16)
                        Spacer()
                    }
                }
                //MARK: Popup
            }
        }
    }
}

struct RouterViewPreviewsContactsPage: View, RouterPage{
    @EnvironmentObject var Router: RoutingController
    
    var body: some View{
        GeometryReader{ geometry in
            ZStack{
                ScrollView{
                    VStack{
                        HStack{
                            Button{
                                self.Router.back()
                            } label: {
                                Text("Back")
                            }
                            Spacer()
                            Text("Contacts")
                            Spacer()
                        }
                        .padding(16)
                        ZStack{
                            Image("success-splash")
                        }
                        Text("Lorem ipsum")
                            .foregroundColor(Color.gray)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(16)
                        VStack{
                            
                        }
                        .padding(16)
                        Spacer()
                    }
                }
                //MARK: Popup
            }
        }
    }
}

struct RouterViewPreviewsLeadsPage: View, RouterPage{
    @EnvironmentObject var Router: RoutingController
    
    var body: some View{
        GeometryReader{ geometry in
            ZStack{
                ScrollView{
                    VStack{
                        HStack{
                            Button{
                                self.Router.back()
                            } label: {
                                Text("Back")
                            }
                            Spacer()
                            Text("Leads")
                            Spacer()
                        }
                        .padding(16)
                        VStack{
                            
                        }
                        .padding(16)
                        Spacer()
                    }
                }
                //MARK: Popup
            }
        }
    }
}

struct RouterViewPreviews: View{
    @StateObject private var controller: RoutingController = RoutingController(Animation.interactiveSpring(duration:0.4))
    
    var body: some View{
        GeometryReader{ primaryGeometry in
            ZStack{
                VStack(spacing:0){
                    RouterView{
                        RouterViewPreviewsHomePage()
                    }
                    .environmentObject(self.controller)
                }
            }
        }
    }
}

struct RouterView_Previews: PreviewProvider {
    static var previews: some View {
        RouterViewPreviews()
    }
}
#endif
