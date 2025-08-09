//
//  BottomSheet.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 11.10.2023.
//

import Foundation
import SwiftUI
import Combine


struct BottomSheetModifier<Body:View>: ViewModifier {
    @Binding var isPresented: Bool
    let content: () -> Body
    
    @State private var offset: Double = 100
    
    var grip: some View{
        Rectangle()
            .frame(maxWidth: 90, maxHeight: 6)
            .background(Color.gray)
            .foregroundColor(Color.gray)
            .clipShape(Capsule())
    }
    
    func overlay(reader: GeometryProxy) -> some View{
        return Rectangle()
            .foregroundColor(Color.white)
            .frame(maxWidth:.infinity,maxHeight: reader.safeAreaInsets.bottom + 15)
            .offset(y: reader.safeAreaInsets.bottom)
    }
    
    func body(content: Content) -> some View {
        Group{
            GeometryReader{ reader in
                ZStack(alignment:.bottom){
                    Color.black
                        .opacity(0.4)
                        .ignoresSafeArea(.all)
                        .onTapGesture {
                            self.isPresented = false
                        }
                    Group{
                        self.overlay(reader:reader)
                        VStack{
                            self.content()
                        }
                        .foregroundColor(Color.black)
                        .frame(maxWidth: .infinity)
                        .padding(5)
                        .padding(.bottom,20)
                        .background(Color.white)
                        .cornerRadius(15)
                        .zIndex(2)
                    }
                    .offset(y:self.offset)
                }.onAppear{
                    self.offset = 0
                }
                .animation(.easeInOut(duration:0.6), value: self.offset)
            }
        }
    }
}

extension BottomSheetContainer{
    func present() -> UIViewController{
        let topMostController = topMostController()
        let someView = modifier(BottomSheetModifier(isPresented: $isPresented, content: content))
        let viewController = UIHostingController(rootView: someView)
        viewController.view?.backgroundColor = .clear
        viewController.modalPresentationStyle = .overFullScreen
        topMostController.present(viewController, animated: true)
        self.state.controller = viewController
        return viewController
    }
}

class BottomSheetState: ObservableObject{
    @Published var visible: Bool = false
    var controller: UIViewController?
}

struct BottomSheetContainer<Content:View>: View{
    @Binding var isPresented: Bool
    let content: () -> Content
    @StateObject var state: BottomSheetState = BottomSheetState()
    
    func onPresentChanged(){
        if self.isPresented{
            DispatchQueue.main.async{
                self.state.controller = self.present()
            }
        }else{
            DispatchQueue.main.async{
                self.state.controller?.dismiss(animated: false)
            }
        }
    }
    
    var body: some View{
        return ZStack{
            ZStack{
                self.content()
            }
            .hidden()
            .frame(maxHeight: .zero)
            .opacity(0)
            EmptyView().onChange(of: self.isPresented){ change in
                onPresentChanged()
            }
        }
    }
}
