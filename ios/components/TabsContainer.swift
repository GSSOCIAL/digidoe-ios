//
//  TabsContainer.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 11.10.2023.
//

import Foundation
import SwiftUI
import Combine

struct OffsetPageTabView<Content: View>: UIViewRepresentable{
    public let content: () -> Content
    @Binding public var offset: CGFloat
    @Binding public var selection: Int
    
    init(selection: Binding<Int>, offset: Binding<CGFloat>, @ViewBuilder content: @escaping ()->Content){
        self.content = content
        self._offset = offset
        self._selection = selection
    }
    
    func makeCoordinator() -> Coordinator {
        return OffsetPageTabView.Coordinator(hostingController: UIHostingController(rootView: self.content()), parent: self)
    }
    
    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        let hostview = context.coordinator.hostingController
        hostview.view.translatesAutoresizingMaskIntoConstraints = false
        
        let constaints = [
            hostview.view.topAnchor.constraint(equalTo: scrollView.topAnchor),
            hostview.view.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            hostview.view.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            hostview.view.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            //MARK: If use vertical padding - comment
            hostview.view.heightAnchor.constraint(equalTo: scrollView.heightAnchor)
        ]
        
        scrollView.addSubview(hostview.view)
        scrollView.addConstraints(constaints)
        
        //Hide indicators
        scrollView.isPagingEnabled = true
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        
        //Add delegate
        scrollView.delegate = context.coordinator
        
        return scrollView
    }
    
    func updateUIView(_ uiView: UIScrollView, context: Context) {
        context.coordinator.hostingController.rootView = self.content()
        
        let currentOffset = uiView.contentOffset.x
        if (currentOffset != self.offset){
            uiView.setContentOffset(.init(x: offset, y: 0), animated: true)
        }
    }
    
    class Coordinator: NSObject, UIScrollViewDelegate{
        var parent: OffsetPageTabView
        var hostingController: UIHostingController<Content>
                
        init(hostingController: UIHostingController<Content>, parent: OffsetPageTabView) {
            self.hostingController = hostingController
            self.parent = parent
        }
        
        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            let offset = scrollView.contentOffset.x
            
            let maxSize = scrollView.contentSize.width
            let currentSelection = (offset / maxSize).rounded()
            //parent.selection = Int(currentSelection)
            
            parent.offset = offset
        }
    }
}

struct TabsContainer<Content: View>: View{
    //MARK: Inherit form tabs header
    @Binding public var selectedTab: Int
    @State private var directTab: Int = 0
    @State private var offset: CGFloat = 0
    @State private var tabInProgress: Bool = false
    public let content: () -> Content
    
    init(selectedTab: Binding<Int>,@ViewBuilder content: @escaping ()->Content) {
        self._selectedTab = selectedTab
        self.content = content
    }
    
    var body: some View{
        ZStack{
            OffsetPageTabView(selection: self.$directTab, offset: self.$offset){
                HStack(spacing:0){
                    self.content()
                }
                .overlay(
                    GeometryReader{ proxy in
                        Color.clear.preference(key: TabPreferenceKey.self,value: proxy.frame(in:.global))
                    }
                )
            }
            .onPreferenceChange(TabPreferenceKey.self){ proxy in
                let minX = -proxy.minX
                let screenWidth = getScreenBounds().width
                
                let activeTab: Int = Int((minX / screenWidth).rounded())
                if (self.tabInProgress == false){
                    self.directTab = activeTab
                    self.selectedTab = activeTab
                }else if(activeTab == self.selectedTab){
                    self.tabInProgress = false
                }
            }
            .onChange(of: self.selectedTab){ _ in
                if (self.selectedTab != self.directTab){
                    self.directTab = self.selectedTab
                    self.offset = CGFloat(self.selectedTab) * getScreenBounds().width
                    self.tabInProgress = true
                }
            }
        }
    }
}

struct CustomTabContainerViewPreview: View{
    var tabs: [Tab] {
        return [
            .init(title: "Tab 1", id: 1),
            .init(title: "Tab 2", id: 2),
            .init(title: "Tab 3", id: 3),
            .init(title: "Tab 4", id: 4),
        ]
    }
    @State private var selection: Int = 0
    @State private var list: [String] = ["prepared"]
    
    func loadList(){
        DispatchQueue.main.asyncAfter(deadline: .now()+1, execute: {
            self.list = ["data loaded a a a a a a a a a a a a a a a a a a a a a"]
        })
    }
    
    var body: some View{
        VStack{
            Tabs(tabs: self.tabs, selectedTab: $selection, style: .selector)
            TabsContainer(selectedTab: $selection){
                ForEach(Array(self.tabs.enumerated()), id: \.1.id){ (index, tab) in
                    ForEach(Array(self.list.enumerated()), id: \.1.self) { (sIndex,content) in
                        Text(content)
                            .pageView()
                    }
                }
            }
        }.onAppear{
            self.loadList()
        }
    }
}

struct CustomTabContainerView_Previews: PreviewProvider {
    static var previews: some View {
        CustomTabContainerViewPreview()
    }
}

struct TabPreferenceKey: PreferenceKey{
    static var defaultValue: CGRect = .init()
    
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}
