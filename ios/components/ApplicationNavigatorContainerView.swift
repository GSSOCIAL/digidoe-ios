//
//  ApplicationNavigatorContainerView.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 12.12.2023.
//

import Foundation
import SwiftUI

struct ApplicationNavigatorContainerView<Content:View>: View{
    @EnvironmentObject var Store: ApplicationStore
    @EnvironmentObject var Error: ErrorHandlingService
    
    @Binding public var logout: Bool
    let content: () -> Content
    
    func callLogout() async throws{
        try await self.Store.logout()
    }
    
    init(logout: Binding<Bool> = .constant(false),@ViewBuilder content: @escaping ()->Content){
        self._logout = logout
        self.content = content
    }
    
    var body: some View{
        ZStack{
            content()
        }.onChange(of: self.logout){ _ in
            if (self.logout == true){
                Task{
                    do{
                        try await self.callLogout()
                    }catch(let error){
                        self.Error.handle(error)
                    }
                }
            }
        }
        .background(Color.get(.Background))
    }
}
