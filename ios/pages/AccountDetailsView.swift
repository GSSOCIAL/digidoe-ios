//
//  DetailsView.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 27.09.2023.
//

import Foundation
import SwiftUI

extension AccountDetailsView{
    private var loaderOffset: Double{
        if (self.loading){
            return 50 + self.scrollOffset
        }
        
        if (self.scrollOffset > 0){
            return 0
        }else if(self.scrollOffset < -100){
            return 50 + self.scrollOffset
        }
        
        return 0 + self.scrollOffset / 2
    }
    
    private var contentBlocks: Array<DetailsContentBlock>{
        var output: Array<DetailsContentBlock> = []
        
        if (self.account != nil){
            if (self.account.baseCurrencyCode?.lowercased() == "gbp"){
                output.append(DetailsContentBlock(
                    title: "Payment instructions to accept transfers in the GBP",
                    rows: [
                        .init(label: "Beneficiary’s Bank", content: self.account.bankName ?? "–"),
                        .init(label: "Beneficiary’s Name", content: self.account.ownerName ?? "–"),
                        .init(label: "Account Number", content: String(self.account.identification?.accountNumber ?? "-")),
                        .init(label: "Sort Code", content: String(self.account.identification?.sortCode ?? "-")),
                        .init(label: "Currency of Settlement", content: self.account.baseCurrencyCode?.uppercased() ?? "-")
                    ]
                ))
                output.append(DetailsContentBlock(
                    title: "Payment instructions for International transfers",
                    rows: [
                        .init(label: "Beneficiary’s Bank", content: self.account.bankName ?? "–"),
                        .init(label: "Beneficiary’s Name", content: self.account.ownerName ?? "-"),
                        .init(label: "Beneficiary IBAN", content: self.account.identification?.iban ?? "-"),
                        .init(label: "Beneficiary BIC/SWIFT", content: "CLRBGB22XXX"),
                        .init(label: "Account Number", content: String(self.account.identification?.accountNumber ?? "-")),
                        .init(label: "Sort Code", content: String(self.account.identification?.sortCode ?? "-")),
                        .init(label: "Currency of Settlement", content: self.account.baseCurrencyCode?.uppercased() ?? "-")
                    ]
                ))
            }else if (self.account.baseCurrencyCode?.lowercased() == "eur"){
                output.append(DetailsContentBlock(
                    title: "Payment instructions for transfers from \(Whitelabel.BrandName())'s customers",
                    rows: [
                        .init(label: "Beneficiary’s Name", content: self.account.ownerName ?? "-"),
                        .init(label: "Wallet number", content: String(self.account.identification?.accountNumber ?? "-"))
                    ]
                ))
                output.append(DetailsContentBlock(
                    title: "Credentials for transfers from other financial institutions",
                    rows: [
                        .init(label: "Beneficiary’s Name", content: self.account.ownerName ?? "-"),
                        .init(label: "IBAN", content: "GB49IFXS23229083164543"),
                        .init(label: "SWIFT", content: "IFXSGB2L"),
                        .init(label: "Mandatory reference", content: "87177-CJW-\(self.account.identification?.accountNumber ?? "")")
                    ]
                ))
            }else if (self.account.baseCurrencyCode?.lowercased() == "usd"){
                output.append(DetailsContentBlock(
                    title: "Payment instructions for transfers from \(Whitelabel.BrandName())'s customers",
                    rows: [
                        .init(label: "Beneficiary’s Name", content: self.account.ownerName ?? "-"),
                        .init(label: "Wallet number", content: String(self.account.identification?.accountNumber ?? "-"))
                    ]
                ))
                output.append(DetailsContentBlock(
                    title: "Credentials for transfers from other financial institutions",
                    rows: [
                        .init(label: "Beneficiary’s Name", content: self.account.ownerName ?? "-"),
                        .init(label: "IBAN", content: "GB49IFXS23229083164543"),
                        .init(label: "SWIFT", content: "IFXSGB2L"),
                        .init(label: "Mandatory reference", content: "87177-CJW-\(self.account.identification?.accountNumber ?? "")")
                    ]
                ))
            }
        }
        
        return output;
    }
    
    struct DetailsContentBlock{
        public var title: String
        public var rows: Array<AccountDetailRow>
    }
    
    struct AccountDetailRow{
        public var label: String
        public var content: String
    }
}

struct AccountDetailsView: View, RouterPage {
    @EnvironmentObject var Store: ApplicationStore
    @EnvironmentObject var Error: ErrorHandlingService
    @EnvironmentObject var Router: RoutingController
    
    @State private var loading: Bool = false
    @State private var scrollOffset : Double = 0
    @State private var export : Bool = false
    
    @State public var account: CoreAccount
    
    func collectExportData() -> String{
        return self.contentBlocks.map({ block in
            var subContent: [String] = block.rows.map({ sub in
                return "\(sub.label) : \(sub.content)"
            })
            return "\(block.title):\n\(subContent.joined(separator: "\n"))"
        }).joined(separator: "\n\n")
    }
    
    var body: some View {
        ApplicationNavigatorContainerView{
            GeometryReader{ geometry in
                ScrollView{
                    VStack(spacing: 0){
                        VStack(spacing:0){
                            Header(back:{
                                self.Router.back()
                            }, title: "Account details"){
                                HStack{
                                    Button{
                                        self.export = true
                                    } label:{
                                        ZStack{
                                            Image("export")
                                                .resizable()
                                                .scaledToFit()
                                                .foregroundColor(Whitelabel.Color(.Primary))
                                        }
                                        .frame(width: 24, height: 24)
                                    }
                                }
                            }
                            if (self.account != nil){
                                Button{
                                    self.Router.goTo(
                                        EditAccountDetailsView(
                                            account: self.account
                                        )
                                    )
                                } label: {
                                    CoreAccountCard(
                                        account: self.account,
                                        editable: true
                                    )
                                }
                                .padding(.horizontal, 16)
                            }
                        }
                        .offset(
                            y: self.scrollOffset < 0 ? self.scrollOffset : 0
                        )
                        
                        VStack(spacing:12){
                            //MARK: Section block
                            ForEach(self.contentBlocks, id:\.title){ block in
                                AccountDetailsBlock(
                                    title: block.title,
                                    rows: block.rows
                                )
                                .padding(.horizontal, 16)
                            }
                        }
                        .padding(.vertical, 12)
                        .offset(
                            y: self.loading && self.scrollOffset > -100 ? Swift.abs(100 - self.scrollOffset) : 0
                        )
                        Spacer()
                    }
                    .background(GeometryReader {
                        Color.clear.preference(key: RefreshViewOffsetKey.self, value: -$0.frame(in: .named("scroll")).origin.y)
                    })
                    .onPreferenceChange(RefreshViewOffsetKey.self) { position in
                        self.scrollOffset = position
                    }
                    .frame(
                        maxWidth: .infinity,
                        minHeight: geometry.size.height - geometry.safeAreaInsets.bottom
                    )
                }
                .coordinateSpace(name: "scroll")
                .sheet(isPresented:self.$export){
                    ShareSheet(
                        activityItems: [self.collectExportData()],
                        callback: { activityType,completed,returnedItems,error in
                            self.export = false
                        }
                    )
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationTitle("")
        .background(Color.get(.Background))
    }
}

struct AccountDetailsBlock: View{
    @State public var title: String
    @State public var rows: Array<AccountDetailsView.AccountDetailRow>
    
    @State private var copied: Bool = false
    
    var body: some View{
        VStack(spacing:0){
            ZStack{
                Text("Copied to clipboard")
                    .font(.subheadline)
                    .foregroundColor(Color.white)
                    .padding(5)
            }
            .frame(maxWidth: .infinity)
            .background(Color.get(.Active))
            .offset(
                y: self.copied ? 0 : -30
            )
            .animation(.easeInOut(duration: 0.1))
            .frame(height: self.copied ? 30 : 0)
            
            VStack(spacing: 12){
                HStack(spacing:12){
                    Text(title)
                        .font(.subheadline.bold())
                        .foregroundColor(Color.get(.Text))
                    Spacer()
                    Button{
                        var content = rows.map({ item in
                            return "\(item.label): \(item.content)"
                        })
                        content.insert(title, at: 0)
                        UIPasteboard.general.string = content.joined(separator: "\n")
                        
                        self.copied = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3){
                            self.copied = false
                        }
                    } label:{
                        ZStack{
                            Image("copy")
                                .resizable()
                                .scaledToFit()
                                .foregroundColor(Whitelabel.Color(.Primary))
                        }
                        .frame(width: 24, height: 24)
                    }
                }
                
                Divider()
                    .overlay(Color.get(.MiddleGray))
                
                VStack(spacing: 12){
                    ForEach(rows, id: \.label){ row in
                        Button{
                            UIPasteboard.general.string = row.content ?? ""
                        } label: {
                            VStack(alignment: .leading, spacing: 2){
                                Text(row.label)
                                    .foregroundColor(Color.get(.LightGray))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .multilineTextAlignment(.leading)
                                Text(row.content ?? "-")
                                    .fontWeight(.bold)
                                    .foregroundColor(Color.get(.MiddleGray))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .multilineTextAlignment(.leading)
                            }
                        }
                    }
                }
                .font(.subheadline)
            }
            .padding(12)
        }
        .frame(maxWidth: .infinity)
        .background(Color.get(.Section))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
