//
//  JsonRenderer.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 10.01.2024.
//

import Foundation
import SwiftUI

struct JsonRenderer: View {
    @State public var data: String
    @State private var context: Array<TermsService.TermsConditionsResponse.Node> = []
    
    func decodeContext() async throws{
        var body: String = self.data
        body = body.replacingOccurrences(of:"'", with: "\"")
        self.context = try JSONDecoder().decode(Array<TermsService.TermsConditionsResponse.Node>.self,from: body.data(using: .utf8)!)
    }
    
    var nodes: some View{
        ForEach(self.context.indices, id:\.self){ index in
            let node = self.context[index] as TermsService.TermsConditionsResponse.Node
            
            if (node.tag == "text"){
                Text(node.content)
                    .font(.body)
                    .padding(.bottom, 5)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            if (node.tag == "title2"){
                Text(node.content)
                    .font(.body.bold())
                    .padding(.top, 10)
                    .padding(.bottom, 5)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
    
    var body: some View{
        VStack(spacing:0){
            if (!self.data.isEmpty){
                if (!self.context.isEmpty){
                    self.nodes
                        //.fixedSize()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }else{
                    Text("Failed to decode data")
                        .font(.callout)
                        .foregroundColor(Color.get(.LightGray))
                }
            }else{
                Loader(size: .small)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onChange(of: self.data){ _ in
            Task{
                do{
                    try await self.decodeContext()
                }catch(let error){
                    print(error)
                }
            }
        }
        .onAppear{
            Task{
                do{
                    try await self.decodeContext()
                }catch(let error){
                    print(error)
                }
            }
        }
    }
}

struct JsonRendererView_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView{
            JsonRenderer(data: "[{'tag':'text','content':'These Terms & Conditions apply to your DigiDoe account. Please read them carefully. You can download a copy of these Terms &amp; Conditions at any time from within your online account portal. Log in via our website www.digidoe.com. In these Terms &amp; Conditions: «Distributor» means DigiDoe Ltd. that may distribute the account to you on our behalf. «You» means the named account, holder being the authorised user of the DigiDoe account. «We», «us» or «our» means DigiDoe Ltd or the Distributor acting on our behalf.'},{'tag':'text','content':'If you have any questions, you can contact Customer Services by:'},{'tag':'text','content':'A. Telephone: +44 (0) 203 865 6467 (standard geographic rates apply);'},{'tag':'text','content':'B. Online: Log in to your DigiDoe account at www.digidoe.com and click on Contact Us to send us a secure message;'},{'tag':'text','content':'C. Mobile App: click on Contact Us in your mobile app and send us a message;'},{'tag':'text','content':'D. Post: DigiDoe Ltd, 167 Turners Hill, Cheshunt, Waltham Cross, Hertfordshire, EN8 9BH.Your DigiDoe account is issued by DigiDoe Ltd, 167 Turners Hill, Cheshunt, Waltham Cross, Hertfordshire, EN8 9BH, DigiDoe Ltd. that may by the Financial Conduct Authority under the Electronic Money Regulations 2011 (registered number 901043) as an Authorised Electronic Money Institution. Your DigiDoe account may be distributed by a third party on our behalf.'},{'tag':'heading','content':'WHAT IS A DIGIDOE ACCOUNT?'},{'tag':'text','content':'A DigiDoe Account is an electronic money account, from which you can make and receive payments. You can use your account to make transfers to other accounts, set up standing orders, and make direct debit payments. You can only spend money that you have paid into your account, so before making transfers you need to make sure there are enough funds in the account. Monies in the DigiDoe account are not bank deposits and do not earn interest.'},{'tag':'heading','content':'WHO CAN APPLY FOR A DIGIDOE ACCOUNT?'},{'tag':'text','content':'You must be at least 18 years old and a UK or EEA resident to be issued with a DigiDoe account. You must provide \\na copy of your passport or driving license, proof of your residential address, email address, and a mobile phone number to open an account, so that we can communicate with you. There is a maximum limit of 10 accounts allowed to be opened at each residential address.'},{'tag':'heading','content':'HOW CAN I APPLY FOR THE DIGIDOE ACCOUNT?'},{'tag':'text','content':'You can apply on our website www.digidoe.com, or via DigiDoe App that you can download from Google Play or Apple\\nStore. Before we open an account for you, we may require evidence of your identity and residential address. We\\nmay also need to carry out checks on your identity electronically.'}]")
                .padding()
        }
    }
}
