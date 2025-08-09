//
//  InfiniteScrollView.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 05.08.2024.
//

import Foundation
import SwiftUI

struct InfiniteScrollView<Content: View>: View {
    @State public var tolerance: Int = 0
    @State public var onScrollEnd: ()->Void
    @ViewBuilder var content: () -> Content
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView(.vertical) {
                content()
                .background(
                    ScrollViewHelper(
                        tolerance: self.tolerance,
                        onScrollEnd: self.onScrollEnd
                    )
                )
            }
        }
    }
}

fileprivate struct ScrollViewHelper: UIViewRepresentable {
    @State public var tolerance: Int = 0
    @State public var onScrollEnd: () -> Void
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(
            tolerance: self.tolerance,
            onList: self.onScrollEnd
        )
    }
    
    func makeUIView(context: Context) -> some UIView {
        return .init()
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) {
            if let scrollview = uiView.superview?.superview?.superview as? UIScrollView,
               !context.coordinator.isAdded {
                scrollview.delegate = context.coordinator
                context.coordinator.isAdded = true
            }
        }
    }
    
    class Coordinator: NSObject, UIScrollViewDelegate {
        public var tolerance: Int = 0
        public var onList: ()->Void
        ///Tells us whether the delegate is added or not
        var isAdded: Bool = false
        
        init(tolerance: Int = 0, onList: @escaping ()->Void){
            self.tolerance = tolerance
            self.onList = onList
        }
        
        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            let height = scrollView.contentSize.height
            let screen = UIScreen.main.bounds.height
            let y = scrollView.contentOffset.y + CGFloat(self.tolerance)
            
            if (y > (height - screen)){
                self.onList()
            }
        }
    }
}

struct InfiniteScrollViewParent_Previews: View{
    @State private var items: [String] = []
    @State private var loading = false
    @State private var loaded = false
    
    func load(){
        if (self.loading || self.loaded){
            return
        }
        self.loading = true
        var i = 0;
        while(i<10){
            self.items.append("item")
            i+=1
        }
        self.loading = false
        if (self.items.count > 30){
            self.loaded = true
        }
    }
    
    var body: some View{
        VStack{
            InfiniteScrollView(onScrollEnd: {
                self.load()
            }){
                ZStack{
                    VStack{
                        ForEach(Array(self.items.enumerated()),id:\.offset){ index, el in
                            Rectangle()
                                .frame(width: .infinity, height: 80)
                                .foregroundColor(index < 10 ? Color.red : index < 20 ? Color.orange : index < 30 ? Color.yellow : Color.green)
                        }
                    }
                    Text("\(self.items.count)")
                        .foregroundColor(Color.white)
                        .background(Color.black.opacity(0.4))
                }
            }
            .onAppear{
                self.load()
            }
            Text("3211")
        }
    }
}

struct InfiniteScrollView_Previews: PreviewProvider {
    static var previews: some View {
        InfiniteScrollViewParent_Previews()
    }
}
