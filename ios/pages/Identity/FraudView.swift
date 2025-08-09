
//
//  OTPView.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 10.03.2024.
//

import Foundation
import SwiftUI
import UIKit
import Combine

extension FraudView{
    enum FraudOperationResult{
        case confirmed
        case rejected
    }
}

struct FraudView: View {
    @EnvironmentObject var Store: ApplicationStore
    @EnvironmentObject var Error: ErrorHandlingService
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    struct FraudWarning{
        var id: String = ""
        var alert: String = ""
    }
    
    ///Called when OTP passed
    public var onVerify: ()->Void = {}
    
    ///Called when OTP failed or rejected
    public var onCancel: ()->Void = {}
    public var onClose: ()->Void = {}
    @Binding var alerts: [String:String]
    
    @State private var loading: Bool = false
    @State private var scrollOffset : Double = 0
    
    private var warnings: Array<FraudWarning> {
        return self.alerts.map({
            return .init(
                id: $0.key,
                alert: $0.value
            )
        })
    }
    
    @State private var result: FraudOperationResult? = nil
    @State private var checked: Array<String> = []
    
    @State private var confirmation: Bool = false
    
    var hasResult: Binding<Bool>{
        Binding(
            get: {
                return self.result != nil
            }, set: { _ in }
        )
    }
    
    func handleClick(_ alertId: String){
        let index = self.checked.firstIndex(of: alertId)
        if (index == nil){
            self.checked.append(alertId)
        }else{
            self.checked.remove(at: index!)
        }
    }
    
    var body: some View {
        ApplicationNavigatorContainerView{
            GeometryReader{ geometry in
                ZStack{
                    ScrollView{
                        VStack(spacing: 24){
                            ZStack{
                                Image("danger")
                            }
                            .frame(
                                width: 80,
                                height: 80
                            )
                            .padding(.top, 12)
                            VStack(spacing: 12){
                                Text("Stop! Think Before You Pay!")
                                    .font(.body.bold())
                                    .foregroundColor(Color.get(.Text))
                                Text("The easiest way for fraudsters to get their hands on your money is to simply get you to send it to them!")
                                    .multilineTextAlignment(.center)
                                    .font(.body)
                                    .foregroundColor(Color.get(.Text))
                            }
                            .padding(.horizontal, 16)
                            VStack(spacing: 12){
                                ForEach(self.warnings, id: \.id){ warning in
                                    let index = self.checked.firstIndex(of: warning.id)
                                    Button{
                                        handleClick(warning.id)
                                    } label: {
                                        let checked = Binding<Bool>(get: {
                                            return index != nil
                                        }, set: { value in
                                            handleClick(warning.id)
                                        })
                                        
                                        HStack(spacing:10){
                                            Checkbox(checked: checked)
                                                .disabled(self.loading)
                                            Text(warning.alert)
                                                .foregroundColor(!self.loading ? Color.get(.Text) : Color.get(.DisabledText))
                                                .font(.body)
                                                .multilineTextAlignment(.leading)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                            Spacer()
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            VStack(spacing: 12){
                                Text("By choosing to continue, you agree that you have read our warning and choose to proceed, taking full responsibility for the payment. You confirm that you have conducted adequate due diligence to protect yourself from fraud and are confident in the legitimacy of the transaction.")
                                    .font(.subheadline)
                                    .foregroundColor(Color.get(.PaleBlack))
                                HStack{
                                    Text("Take some time to reconsider.")
                                        .multilineTextAlignment(.leading)
                                        .font(.subheadline.bold())
                                        .foregroundColor(Color.get(.PaleBlack))
                                    Spacer()
                                }
                            }
                            .padding(16)
                            .background(Color.get(.Section))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .padding(.horizontal, 16)
                            Spacer()
                            VStack(spacing: 12){
                                Button{
                                    self.confirmation = true
                                } label:{
                                    HStack{
                                        Spacer()
                                        Text("Agreee and Continue")
                                        Spacer()
                                    }
                                }
                                .buttonStyle(.secondary())
                                .disabled(self.loading || (self.checked.count != self.warnings.count))
                                Button{
                                    self.result = .rejected
                                    self.onCancel()
                                } label:{
                                    HStack{
                                        Spacer()
                                        Text("Stop Payment")
                                        Spacer()
                                    }
                                }
                                .buttonStyle(.primary())
                                .disabled(self.loading)
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 16)
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
                    //MARK: Popups
                    PresentationSheet(isPresented: self.$confirmation){
                        VStack{
                            Image("danger")
                            VStack(alignment: .center, spacing: 12){
                                Text("Last Chance to Think Again! Doubt means Do not")
                                    .font(.title2.bold())
                                    .foregroundColor(Color.get(.MiddleGray))
                                    .multilineTextAlignment(.center)
                                Text("Once you proceed, the payment will be processed as requested.")
                                    .font(.body)
                                    .foregroundColor(Color.get(.Text))
                                    .multilineTextAlignment(.center)
                                Text("You understand that we may not be able to assist you in recovering your funds if they are sent to a fraudster’s account and accept full responsibility for the payment.")
                                    .font(.body.bold())
                                    .foregroundColor(Color.get(.Text))
                                    .multilineTextAlignment(.center)
                                Text("If you are in any way unsure, please stop immediately.")
                                    .font(.body)
                                    .foregroundColor(Color.get(.Text))
                                    .multilineTextAlignment(.center)
                            }
                                .padding(.bottom,20)
                            HStack(spacing:12){
                                Button{
                                    self.confirmation = false
                                    self.result = .confirmed
                                    self.onVerify()
                                } label:{
                                    HStack{
                                        Spacer()
                                        Text("Process Payment")
                                        Spacer()
                                    }
                                }
                                .buttonStyle(.secondary())
                                Button{
                                    self.confirmation = false
                                } label:{
                                    HStack{
                                        Spacer()
                                        Text("Stop Payment")
                                        Spacer()
                                    }
                                }
                                .buttonStyle(.primary())
                            }
                        }
                        .padding(.bottom, geometry.safeAreaInsets.bottom)
                        .padding(20)
                        .padding(.top,10)
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationTitle("")
        .background(Color.get(.Background))
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to:nil, from:nil, for:nil)
        }
    }
}

struct FraudViewModifider: ViewModifier{
    @Binding public var isPresented: Bool
    
    @State public var onVerify: ()->Void = {}
    @State public var onReject: ()->Void = {}
    
    @Binding public var operationResult: FraudView.FraudOperationResult?
    @Binding public var alerts: [String:String]
    
    init(
        isPresented: Binding<Bool>,
        onVerify: @escaping ()->Void,
        onReject: @escaping ()->Void,
        alerts: Binding<[String:String]>
    ){
        self._isPresented = isPresented
        self.onVerify = onVerify
        self.onReject = onReject
        self._operationResult = .constant(.rejected)
        self._alerts = alerts
    }
    
    init(
        isPresented: Binding<Bool>,
        operationResult: Binding<FraudView.FraudOperationResult?>,
        alerts: Binding<[String:String]>
    ){
        self._isPresented = isPresented
        self._operationResult = operationResult
        self._alerts = alerts
    }
    
    //MARK: - Methods
    
    /// Called when OTP operation confirmed
    func operationConfirmed(){
        self.operationResult = .confirmed
        self.onVerify()
        self.isPresented = false
    }
    
    /// Called when OTP operation rejected
    func operationRejected(){
        self.operationResult = .rejected
        self.onReject()
        self.isPresented = false
    }
    
    func body(content: Content) -> some View{
        ZStack{
            content
            if (self.isPresented){
                FraudView(
                    onVerify: self.operationConfirmed,
                    onCancel: self.operationRejected,
                    alerts: self.$alerts
                )
            }
        }
    }
}

extension View{
    /// Create OTP Confirmation screen
    ///
    /// - Parameter isPresented: Determite if OTP confirmation should be shown
    /// - Parameter operationId: Operation identifier
    ///
    /// - Returns: A view with OTP support
    func fraud(
        isPresented: Binding<Bool>,
        onVerify: @escaping ()->Void,
        onReject: @escaping ()->Void,
        alerts: Binding<[String:String]>
    ) -> some View{
        modifier(FraudViewModifider(
            isPresented: isPresented,
            onVerify: onVerify,
            onReject: onReject,
            alerts: alerts
        ))
    }
    
    func fraud(
        isPresented: Binding<Bool>,
        result: Binding<FraudView.FraudOperationResult?>,
        alerts: Binding<[String:String]>
    ) -> some View{
        modifier(FraudViewModifider(
            isPresented: isPresented,
            operationResult: result,
            alerts: alerts
        ))
    }
}

struct FraudViewParent: View{
    @EnvironmentObject var Store: ApplicationStore
    @EnvironmentObject var Error: ErrorHandlingService
    
    //OTP
    @State private var verifyFraud: Bool = true
    @State private var fraudResult: FraudView.FraudOperationResult? = nil
    @State private var alerts: [String:String] = [:]
    
    func process(){
        self.fraudResult = nil
        self.verifyFraud = true
        Task{
            while(self.fraudResult == nil){
                try? await Task.sleep(nanoseconds: 1_000_000_000)
            }
            self.verifyFraud = false
            switch(self.fraudResult){
            case .confirmed:
                break;
            case .rejected:
                break;
            default:
                break;
            }
        }
    }
    
    var body: some View{
        VStack{
            Button("Action"){
                self.process()
            }
        }
        .fraud(
            isPresented: self.$verifyFraud,
            result: self.$fraudResult,
            alerts: self.$alerts
        )
    }
}


struct FraudView_Previews: PreviewProvider {
    static var store: ApplicationStore {
        var store = ApplicationStore()
        return store
    }
    
    static var error: ErrorHandlingService {
        var error = ErrorHandlingService()
        return error
    }
    
    static var previews: some View {
        FraudViewParent()
            .environmentObject(self.store)
            .environmentObject(self.error)
    }
}
