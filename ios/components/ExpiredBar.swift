//
//  ExpiredBar.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 19.09.2024.
//

import Foundation
import Combine
import SwiftUI

struct ExpiredBar: View{
    @Binding public var timeout: Int
    
    @State private var ticked: Int = 0
    @State private var timer: Publishers.Autoconnect<Timer.TimerPublisher>?
    
    private var fill: Binding<Color>{
        Binding(
            get: {
                if (self.ticked <= self.timeout / 2){
                    return Color.get(.Active)
                }
                return Color.get(.Danger)
            },
            set: {_ in}
        )
    }
    var body: some View{
        VStack(spacing: 4){
            HStack{
                Text("Rate expires in: ")
                    .font(.caption.weight(.regular))
                + Text(String(self.timeout - self.ticked).toTime())
                    .font(.caption.weight(.bold))
                    .foregroundColor(self.fill.wrappedValue)
                Spacer()
            }
                .foregroundColor(Color.get(.Text))
            ZStack{
                    if (self.timer != nil){
                        EmptyView()
                            .onReceive(self.timer!, perform: { _ in
                                if (self.ticked < self.timeout){
                                    withAnimation(.interpolatingSpring(duration: 0.4)){
                                        self.ticked += 1
                                    }
                                }else{
                                    self.timer = nil
                                }
                            })
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 7, maxHeight: 7)
                .background(Color.get(.CardSecondary))
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .scale(x: max((1 - Double(self.ticked) / Double(self.timeout)),0), anchor: .leading)
                        .foregroundColor(self.fill.wrappedValue)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                )
        }
        .onAppear{
            self.timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
        }
        .onChange(of: self.timeout){ _ in
            if (self.timeout <= 0){
                self.ticked = 0
                self.timeout = 0
                self.timer = nil
            }
        }
    }
}

struct ExpiredBar_Preview: View{
    @State private var timeout: Int = 10
    var body: some View{
        ExpiredBar(
            timeout: self.$timeout
        )
            .padding()
    }
}

struct ExpiredBar_Previews: PreviewProvider {
    static var previews: some View {
        VStack{
            ExpiredBar_Preview()
            Spacer()
        }
    }
}
