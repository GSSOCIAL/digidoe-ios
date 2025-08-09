//
//  TagCloudView.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 25.07.2024.
//

import Foundation
import SwiftUI

struct TagCloudView: View {
    @Binding public var tags: [Tag]
    @State private var totalHeight
              = CGFloat.zero       // << variant for ScrollView/List
        //    = CGFloat.infinity   // << variant for VStack
    public var onClick: (String) -> Void = { _ in }
    
    struct Tag{
        public var key: String
        public var label: String
    }
    
    var body: some View {
        VStack {
            GeometryReader { geometry in
                self.generateContent(in: geometry)
            }
        }
        .frame(height: totalHeight)// << variant for ScrollView/List
        //.frame(maxHeight: totalHeight) // << variant for VStack
    }
    
    private func generateContent(in g: GeometryProxy) -> some View {
        var width = CGFloat.zero
        var height = CGFloat.zero

        return ZStack(alignment: .topLeading) {
            ForEach(self.tags, id: \.key) { tag in
                self.item(for: tag)
                    .padding([.horizontal, .vertical], 4)
                    .alignmentGuide(.leading, computeValue: { d in
                        if (abs(width - d.width) > g.size.width){
                            width = 0
                            height -= d.height
                        }
                        let result = width
                        if tag.key == self.tags.last!.key {
                            width = 0 //last item
                        } else {
                            width -= d.width
                        }
                        return result
                    })
                    .alignmentGuide(.top, computeValue: {d in
                        let result = height
                        if tag.key == self.tags.last!.key {
                            height = 0 // last item
                        }
                        return result
                    })
                }
            }
            .background(viewHeightReader($totalHeight))
    }

    private func item(for tag: Tag) -> some View {
        Button{
            self.onClick(tag.key)
        } label: {
            Text(tag.label)
        }.buttonStyle(.removableTag(style: .primary))
    }

    private func viewHeightReader(_ binding: Binding<CGFloat>) -> some View {
        return GeometryReader { geometry -> Color in
            let rect = geometry.frame(in: .local)
            DispatchQueue.main.async {
                binding.wrappedValue = rect.size.height
            }
            return .clear
        }
    }
}

struct TagCloudView_Previews: PreviewProvider {
    static var previews: some View {
        VStack{
            
        }
    }
}
