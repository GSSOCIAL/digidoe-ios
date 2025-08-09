//
//  Loader.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 18.11.2023.
//

import Foundation
import SwiftUI

extension Loader{
    enum LoaderSize{
        case small
        case normal
        case large
    }
}

struct Loader: View {
    enum LoaderStyle{
        case primary
        case light
        case dark
        case auto
        case gray
    }
    @State public var size: LoaderSize = .normal
    @State public var style: LoaderStyle = .primary
    @State private var isAnimating : Bool = false
    @State private var from : CGFloat = 0
    @State private var to : CGFloat = 0
    
    private var lineWidth: Double{
        switch (self.size){
        case .normal:
            return 9
        case .large:
            return 20
        case .small:
            return 5
        }
    }
    
    private var frameSize: Double{
        switch (self.size){
        case .normal:
            return 60
        case .large:
            return 60
        case .small:
            return 30
        }
    }
    
    private var loaderFill: Color{
        switch(self.style){
        case .light:
            return Color.white
        case .gray:
            return Color.get(.CardSecondary)
        default:
            return Whitelabel.Color(.Primary)
        }
    }
    
    public var body: some View {
        ZStack{
            Circle()
                .stroke(
                    self.loaderFill.opacity(0.5),
                    lineWidth: self.lineWidth
                )
            Circle()
                .trim(
                    from: self.from,
                    to: self.to
                )
                .stroke(
                    self.loaderFill,
                    style: StrokeStyle(
                        lineWidth: self.lineWidth,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .onChange(of: self.isAnimating){ _ in
                    self.from = 0
                    self.to = 0
                    self.isAnimating = false
                    
                    withAnimation(
                        Animation
                            .timingCurve(0.15, 0.15, 0.25, 1, duration: 1)
                    ){
                        self.from = 0
                        self.to = 1
                    }
                    withAnimation(
                        Animation
                            .timingCurve(0.15, 0.15, 0.25, 1, duration: 1)
                            .delay(1)
                    ){
                        self.from = 1
                        self.to = 1
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        self.isAnimating = true
                    }
                }
                .onAppear{
                    self.isAnimating = true
                }
        }
        .frame(width:self.frameSize,height:self.frameSize)
    }
}

struct Loader_Previews: PreviewProvider {
    static var previews: some View {
        Loader()
    }
}
