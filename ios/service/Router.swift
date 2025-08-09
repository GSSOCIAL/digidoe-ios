//
//  Router.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 26.09.2023.
//

import Foundation
import SwiftUI

protocol ApplicationRouterPage{
    associatedtype view: View
    var screen: view { get }
}

struct Navigator{
    enum pages{
        enum System: ApplicationRouterPage{
            case main
            case customerLocked
            
            var screen: some View{
                var screen: any View = EmptyView()
                
                switch(self){
                case .main:
                    screen = MainView()
                case .customerLocked:
                    screen = CustomerLockedView()
                }
                
                return AnyView(screen)
            }
        }
        
        enum Account: ApplicationRouterPage{
            case open
            
            var screen: some View{
                var screen: any View = EmptyView()
                
                switch(self){
                case .open:
                    screen = OpenAccountView()
                }
                
                return AnyView(screen)
            }
        }
        
        enum Profile: ApplicationRouterPage{
            case details
            case menu
            
            var screen: some View{
                var screen: any View = EmptyView()
                
                switch(self){
                case .details:
                    screen = ProfileDetailsView()
                case .menu:
                    screen = ProfileMenuView()
                }
                
                return AnyView(screen)
            }
        }
        
        enum Support: ApplicationRouterPage{
            case settings
            case writeToUs
            
            var screen: some View{
                var screen: any View = EmptyView()
                
                switch(self){
                case .settings:
                    screen = SupportView()
                case .writeToUs:
                    screen = WriteToUsView()
                }
                
                return AnyView(screen)
            }
        }
        
        enum Settings: ApplicationRouterPage{
            case settings
            case security
            case aboutApp
            case legalInformation
            case termsConditions
            case privacyPolicy
            case changePinCode
            case deviceList
            
            var screen: some View{
                var screen: any View = EmptyView()
                
                switch(self){
                case .settings:
                    screen = SettingsView()
                case .security:
                    screen = SecurityView()
                case .legalInformation:
                    screen = LegalInformationView()
                case .aboutApp:
                    screen = AboutAppView()
                case .changePinCode:
                    screen = ChangePinCodeView()
                case .termsConditions:
                    screen = TermsConditionsView()
                case .privacyPolicy:
                    screen = PrivacyPolicyView()
                case .deviceList:
                    screen = DevicesListView()
                }
                
                return AnyView(screen)
            }
        }
        
        enum Identity: ApplicationRouterPage{
            case welcome
            
            var screen: some View{
                var screen: any View = EmptyView()
                
                switch(self){
                case .welcome:
                    screen = IdentityView()
                }
                
                return AnyView(screen)
            }
        }
        
        enum Onboarding{
            enum Base: ApplicationRouterPage{
                case accountType
                case createPerson
                case personAddress
                case applicationInReview
                
                var screen: some View{
                    var screen: any View = EmptyView()
                    
                    switch(self){
                    case .accountType:
                        screen = AccountTypeSelectionView()
                    case .createPerson:
                        screen = CreatePersonView()
                    case .personAddress:
                        screen = CreatePersonAddressView()
                    case .applicationInReview:
                        screen = ApplicationInReviewView()
                    }
                    
                    return AnyView(screen)
                }
            }
            
            enum Individual: ApplicationRouterPage{
                case selectCurrency
                case verifyIdentity
                case takeSelfie
                case scanIdentity
                case uploadIdentity
                case proofOfAddress
                case scanProofOfAddress
                case personalAddress
                case confirmDetails
                
                var screen: some View{
                    var screen: any View = EmptyView()
                    
                    switch(self){
                    case .selectCurrency:
                        screen = CurrencyIndividualSelectView()
                    case .verifyIdentity:
                        screen = VerifyPersonalIdentityView()
                    case .takeSelfie:
                        screen = TakeSelfieView()
                    case .scanIdentity:
                        screen = ScanIdentityView()
                    case .uploadIdentity:
                        screen = UploadIdentityView()
                    case .personalAddress:
                        screen = PersonalAddressView()
                    case .confirmDetails:
                        screen = ConfirmIndividualView()
                    case .proofOfAddress:
                        screen = ProofOfAddressView()
                    case .scanProofOfAddress:
                        screen = ScanProofOfAddressView()
                    }
                    
                    return AnyView(screen)
                }
            }
            
            enum Business: ApplicationRouterPage{
                case countryOfIncorportion
                case isEMICompany
                case businessCurrency
                case businessAddress
                case roleSelection
                case companyType
                case directors
                case addDirector
                case countryOfOperation
                case operatingAddress
                case businessUsage
                case businessNature
                
                case description
                case regulator
                case regulatory
                case sell
                case customers
                case turnover
                case moneyOut
                case paymentsPerMonth
                case singleLargestPayment
                case internationalPayments
                case deposit
                case inwardTransactions
                case size
                case type
                case confirmation
                
                var screen: some View{
                    var screen: any View = EmptyView()
                    
                    switch(self){
                    case .countryOfIncorportion:
                        screen = CountryOfIncorporationView()
                    case .isEMICompany:
                        screen = EMICompanyView()
                    case .businessCurrency:
                        screen = BusinessCurrencyView()
                    case .businessAddress:
                        screen = BusinessAddressView()
                    case .roleSelection:
                        screen = BusinessCompanyRoleView()
                    case .companyType:
                        screen = BusinessCompanyTypeView()
                    case .directors:
                        screen = BusinessDirectorsView()
                    case .countryOfOperation:
                        screen = BusinessCountryOfOperationView()
                    case .operatingAddress:
                        screen = BusinessOperatingAddressView()
                    case .businessUsage:
                        screen = BusinessUsageView()
                    case .businessNature:
                        screen = BusinessNatureView()
                    case .description:
                        screen = BusinessDescriptionView()
                    case .regulator:
                        screen = BusinessRegulatedView()
                    case .regulatory:
                        screen = BusinessRegulatoryView()
                    case .sell:
                        screen = BusinessSellView()
                    case .customers:
                        screen = BusinessCustomersView()
                    case .turnover:
                        screen = BusinessTurnoverView()
                    case .moneyOut:
                        screen = BusinessMoneySendView()
                    case .paymentsPerMonth:
                        screen = BusinessPaymentsView()
                    case .singleLargestPayment:
                        screen = BusinessLargestSinglePaymentView()
                    case .internationalPayments:
                        screen = BusinessInternationalView()
                    case .deposit:
                        screen = BusinessDepositView()
                    case .inwardTransactions:
                        screen = BusinessInwardTransactionsView()
                    case .size:
                        screen = BusinessCompanySizeView()
                    case .type:
                        screen = BusinessTypeView()
                    case .confirmation:
                        screen = BusinessConfirmationView()
                    case .addDirector:
                        screen = BusinessAddDirectorsView()
                    }
                    
                    return AnyView(screen)
                }
            }
        }
    }
    
    /*
    static func navigate<T: View>(_ route: any ApplicationRouterPage, content: () -> T) -> AnyView{
        return AnyView(NavigationLink(
            destination: AnyView(route.screen)
        ){
            content()
        })
    }
    
    static func navigate<T: View>(_ view: some View, content: () -> T) -> AnyView{
        return AnyView(NavigationLink(
            destination: view
        ){
            content()
        })
    }
    
    
    static func navigate(_ route: any ApplicationRouterPage, isPresented: Binding<Bool>) -> AnyView{
        return AnyView(
            NavigationLink(
                destination: AnyView(route.screen),
                isActive: isPresented
            ){
                Text("")
            })
    }
    
    static func navigate(_ view: some View, isPresented: Binding<Bool>) -> AnyView{
        return AnyView(
            NavigationLink(
                destination: view,
                isActive: isPresented
            ){
                Text("")
            })
    }
     */
}
