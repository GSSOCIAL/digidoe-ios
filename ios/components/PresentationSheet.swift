//
//  PresentationSheet.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 20.02.2024.
//

import Foundation
import UIKit
import SwiftUI

struct PresentationSheet<Content:View>: View{
    @Binding var isPresented: Bool
    public let content: () -> Content
    
    init(isPresented: Binding<Bool>,@ViewBuilder content: @escaping ()->Content) {
        self._isPresented = isPresented
        self.content = content
    }
    
    var body: some View{
        ZStack(alignment:.bottom){
            if (isPresented){
                Color.get(.PopupOverlay)
                    .ignoresSafeArea()
                    .onTapGesture {
                        self.isPresented = false
                    }
                self.modal
                    .transition(.move(edge: .bottom))
            }
        }
        //.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .ignoresSafeArea()
        .animation(.easeInOut(duration: 0.2))
    }
    
    var modal: some View{
        ZStack{
            self.content()
        }
        .frame(minHeight: 100)
        .frame(maxWidth: .infinity)
        .background(
            ZStack{
                RoundedRectangle(cornerRadius: 16)
                Rectangle()
                    .frame(height: 30)
            }
                .foregroundColor(Color.get(.Background))
        )
    }
}

struct PresentationSheetPreview: View{
    @State private var sheetA: Bool = false
    @State private var sheetB: Bool = false
    @State private var sheetC: Bool = false
    
    @State private var dynamic: Bool = false
    
    var body: some View{
        //Actually bottom sheet
        ZStack{
            VStack{
                Button("Open"){
                    self.sheetA = true
                }
            }
            PresentationSheet(isPresented: self.$sheetA){
                VStack{
                    Button("replace"){
                        self.dynamic = !self.dynamic
                    }
                    Text(self.dynamic ? "1" : "0")
                    Button("A > B"){
                        self.sheetB = true
                    }
                }
            }
            PresentationSheet(isPresented: self.$sheetB){
                VStack{
                    Button("replace"){
                        self.dynamic = !self.dynamic
                    }
                    Text(self.dynamic ? "1" : "0")
                    Button("A > B"){
                        self.sheetC = true
                    }
                }
            }
            PresentationSheet(isPresented: self.$sheetC){
                VStack{
                    Button("replace"){
                        self.dynamic = !self.dynamic
                    }
                    Text(self.dynamic ? "1" : "0")
                    Button("Close"){
                        self.sheetC = false
                    }
                }
            }
        }
    }
}

struct PresentationSheet_Previews: PreviewProvider{
    static var previews: some View{
        PresentationSheetPreview()
    }
}
