//
//  ContentView.swift
//  DigiDoe FinVue
//
//  Created by Михайло Картмазов on 08.08.2025.
//

import SwiftUI
import AudioToolbox
import LocalAuthentication
import CoreData

extension ContentView{
    enum TrustedDeviceResult{
        case success
        case revoke
        case dismiss
    }
    enum PinCodeStep{
        case setup
        case confirm
        case enter
    }
    enum PinCodeSetupResult{
        case sucess
        case failed
    }
}

//Trusted
extension ContentView{
    /**
     User dismiss this device as trusted
     */
    func dismissTrustedDevice(){
        self.trustedDevicePopup = false
        self.trustedDeviceFailed = false
        self.trustedDeviceResult = .dismiss
    }
    
    /**
     User mark this device as trusted
     */
    func markAsTrustedDevice(){
        self.trustedDevicePopup = false
        
        Task{
            do{
                //Check for permissions first
                try await self.notificationManager.getAuthStatus()
                if (!self.notificationManager.hasPermission){
                    self.trustedDeviceFailed = true
                    return;
                }
                guard self.Store.deviceData.deviceId != nil else{
                    throw ApplicationError(title: "", message: "Unable to mark device as trusted. Please try again")
                }
                try await services.profiles.trust(self.Store.deviceData.deviceId!)
                self.trustedDeviceResult = .success
            }catch(let error){
                self.trustedDeviceResult = .dismiss
                self.Error.handle(error)
            }
        }
    }
    
    ///Revoke trusted
    func revoke() async throws{
        self.trustedDeviceResult = .revoke
        self.Store.showTrustedNotificationsDisabled = false
        guard self.Store.deviceData.deviceId != nil else{
            throw ApplicationError(title: "", message: "Unable to revoke device, device id not specified")
        }
        let update = try await services.profiles.untrust(self.Store.deviceData.deviceId!)
        try await self.Store.logout()
        self.Router.home()
    }
}

struct ContentView: View {
    @EnvironmentObject var Store: ApplicationStore
    @EnvironmentObject var notificationManager: NotificationManager
    @EnvironmentObject var Error: ErrorHandlingService
    @EnvironmentObject var Router: RoutingController
    @EnvironmentObject var NotificationHandler: NotificationHandler
    @EnvironmentObject var identity: AuthenticationService
    @EnvironmentObject var activityController: ApplicationActivityController
    @EnvironmentObject var maintenanceController: MaintenanceController
    @EnvironmentObject var scheduler: SchedulerController
    @EnvironmentObject var manager: DataController
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.openURL) var openURL
    
    @State private var deviceName: String = ""
    @State private var trustedDevicePopup: Bool = false
    @State private var trustedDeviceNoNotifications: Bool = false
    @State private var errorViewHeight: CGFloat = 0
    @State private var logout: Bool = false
    @State public var confirmOperationPopup: Bool = false
    @State private var lockoutEnabled: Bool = false
    @State private var notificationHeight: CGFloat = 0
    @State private var applicationReady: Bool = false
    
    let service: AppVersion = AppVersion()
    @State var appHasUpdate = false
    @State var appHasUpdateRequired = false
    @State var trustedDeviceFailed: Bool = false
    @State var trustedDeviceResult: TrustedDeviceResult? = nil
    @State var pinCodeStep: PinCodeStep? = nil
    @State var pinCodeSetupResult: PinCodeSetupResult? = nil
    let pinService: pin = pin()
    @State private var retry: Int = 0
    @State private var code: String = ""
    @State private var newpin: String = ""
    @State private var confirmationpin: String = ""
    
    @State private var maintenance: Bool = false
    @State private var maintenanceTitle: String = ""
    @State private var maintenanceBody: String = ""
    
    @Environment(\.scenePhase) var scenePhase
    
    func processWithCode(){
        Task{
            //MARK: Setup or enter pincode
            if (!self.pinService.hasPin){
                self.pinCodeStep = .setup
            }else{
                self.pinCodeStep = .enter
                Task{
                    if Biometrics.isEnabled(){
                        let context = LAContext()
                        var error: NSError?
                        
                        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
                            let reason = "Login to \(Whitelabel.BrandName())"
                            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authenticationError in
                                if success {
                                    self.pinCodeSetupResult = .sucess
                                }
                            }
                        }
                    }
                }
            }
            
            while(self.pinCodeSetupResult == nil){
                try? await Task.sleep(nanoseconds: 1_000_000_000)
            }
            
            if (self.pinCodeSetupResult! == .sucess){
                self.identity.state = .initialized
                Task.detached(priority: .background){
                    let codes = try await services.dictionarise.getCopCodes()
                    //Remove all entities and update with new one
                    
                    await self.viewContext.refreshAllObjects()
                    let fetchRequest: NSFetchRequest<NSFetchRequestResult> = CoreReasonCodeLookupDto.fetchRequest()
                    let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
                    _ = try? self.viewContext.execute(batchDeleteRequest)
                    
                    codes.value.forEach({ code in
                        let reasonCodeLookup = CoreReasonCodeLookupDto(context: self.viewContext)
                        reasonCodeLookup.reasonCode = code.reasonCode
                        reasonCodeLookup.header = code.header
                        reasonCodeLookup.reasonDescription = code.description
                    })
                    try self.viewContext.save()
                }
                self.Router.goTo(MainView())
                return
            }
            
            //MARK: Logout
            self.identity.state = .initialized
            self.pinCodeStep = nil
            try await self.failedPin()
            return
        }
    }
    
    func failedPin() async throws{
        do{
            try await self.Store.logout()
        }catch(_){
            
        }
        self.pinCodeSetupResult = .failed
        self.pinCodeStep = nil
        self.Router.home()
    }
    
    func vibrate(){
        let tapticFeedback = UINotificationFeedbackGenerator()
        tapticFeedback.notificationOccurred(.error)
    }
    
    func processOnboarding(){
        Task{
            //Load lists
            if (self.Store.onboarding.companySizes.isEmpty){
                try await self.Store.onboarding.loadCountries()
                try await self.Store.onboarding.loadGenders()
                try await self.Store.onboarding.loadCorporateServices()
                try await self.Store.onboarding.loadCurrencies()
                try await self.Store.onboarding.loadCompanyTypes()
                try await self.Store.onboarding.loadMailingAddressDifferentOptions()
                try await self.Store.onboarding.loadBusinessCategories()
                try await self.Store.onboarding.loadCompanyStructure()
                try await self.Store.onboarding.loadRegulatoryOptions()
                try await self.Store.onboarding.loadServiceUsage()
                try await self.Store.onboarding.loadSellOptions()
                try await self.Store.onboarding.loadCustomerOptions()
                try await self.Store.onboarding.loadTurnoverOptions()
                try await self.Store.onboarding.loadVolumeBands()
                try await self.Store.onboarding.loadCompanySize()
            }
            
            self.Store.onboarding.customerEmail = self.Store.user.email
            
            if (self.Store.user.customerId != nil){
                let application = try await services.kycp.getApplication(self.Store.user.customerId!)
                if (application != nil){
                    self.Store.onboarding.application.parse(application)
                    self.Store.applicationLoaded()
                }
            }
            
            //If person not prefilled
            
            if self.Store.user.person == nil || (self.Store.user.person?.id == nil || self.Store.user.person!.id.isEmpty){
                self.identity.state = .initialized
                self.Router.goTo(CreatePersonView())
                return
            }
            
            if self.Store.user.person != nil && (self.Store.user.person?.address?.city == nil || self.Store.user.person?.address?.city?.isEmpty == true){
                self.identity.state = .initialized
                self.Router.goTo(CreatePersonAddressView())
                return
            }
            
            self.identity.state = .initialized
            self.Router.goTo(self.Store.onboarding.currentFlowPage)
        }
    }
    
    var body: some View {
        GeometryReader{ primaryGeometry in
            ZStack{
                VStack(spacing:0){
                    RouterView{
                        if (self.applicationReady && !self.maintenance){
                            IdentityView()
                        }
                    }
                    .environmentObject(self.Router)
                    .environmentObject(self.Store)
                    .environmentObject(self.Error)
                    .environmentObject(self.identity)
                    .environmentObject(self.manager)
                    .onAppear{
                        Task{
                            do{
                                //Ask for notifications
                                try await self.notificationManager.requestAuthorization()
                            }catch(let error){
                                self.Error.handle(error)
                            }
                        }
                    }
                }
                
                //MARK: - Popups
                BottomSheetContainer(isPresented: self.$appHasUpdate){
                    VStack(spacing: 16){
                        VStack(alignment: .center){
                            ZStack{
                                Image("danger")
                                    .resizable()
                                    .scaledToFit()
                            }
                            .frame(width: 92, height: 92, alignment: .center)
                        }
                        VStack(alignment: .center, spacing: 8){
                            Text("Update available")
                                .font(.title2.bold())
                                .foregroundColor(Color.get(.Text, scheme: .light))
                                .multilineTextAlignment(.center)
                            Text("A new version of the application is available. Please update your app as soon as possible")
                                .font(.subheadline)
                                .foregroundColor(Color.get(.LightGray, scheme: .light))
                                .multilineTextAlignment(.center)
                        }
                        HStack(spacing:10){
                            Button{
                                self.appHasUpdate = false
                            } label:{
                                HStack{
                                    Spacer()
                                    Text("Remind me later")
                                    Spacer()
                                }
                            }
                            .buttonStyle(.secondary())
                            .disabled(self.appHasUpdateRequired)
                            Button{
                                self.appHasUpdate = false
                                
                                let url = URL(string: Enviroment.appUrl)
                                UIApplication.shared.open(url!)
                            } label:{
                                HStack{
                                    Spacer()
                                    Text("Update now")
                                    Spacer()
                                }
                            }
                            .buttonStyle(.primary())
                        }
                    }
                    .padding(20)
                    .padding(.top,10)
                    .onAppear{
                        let tapticFeedback = UINotificationFeedbackGenerator()
                        tapticFeedback.notificationOccurred(.error)
                        
                    }
                }
                
                PresentationSheet(isPresented: self.$trustedDevicePopup){
                    VStack(spacing: 24){
                        ZStack{
                            Image("graphics-1")
                        }
                        .frame(width: 80, height: 80)
                        VStack(spacing: 4){
                            Text("Do you want to make \(deviceName) a trusted device?")
                                .font(.body.bold())
                                .foregroundColor(Color.get(.Text))
                        }
                        HStack(spacing: 16){
                            Button{
                                self.dismissTrustedDevice()
                            } label:{
                                HStack{
                                    Spacer()
                                    Text("No")
                                    Spacer()
                                }
                            }
                            .buttonStyle(.secondary())
                            
                            Button{
                                self.markAsTrustedDevice()
                            } label:{
                                HStack{
                                    Spacer()
                                    Text("Yes")
                                    Spacer()
                                }
                            }
                            .buttonStyle(.primary())
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 24)
                    .padding(.bottom, primaryGeometry.safeAreaInsets.bottom)
                }
                
                PresentationSheet(isPresented: self.$trustedDeviceFailed){
                    VStack(spacing:24){
                        ZStack{
                            Image("close-circle")
                        }
                        .frame(width: 80, height: 80)
                        VStack(spacing: 6){
                            Text("Error")
                                .font(.body.bold())
                                .foregroundColor(Color.get(.Text))
                            Text("Sorry, to set device as trusted, you must allow us to send you notifications. Please enable notifications for our application in device's settings and try again.")
                                .multilineTextAlignment(.center)
                                .font(.caption)
                                .foregroundColor(Color.get(.LightGray))
                        }
                        HStack(spacing: 16){
                            Button{
                                self.dismissTrustedDevice()
                            } label:{
                                HStack{
                                    Spacer()
                                    Text("Ok")
                                    Spacer()
                                }
                            }
                            .buttonStyle(.secondary())
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 24)
                    .padding(.bottom, primaryGeometry.safeAreaInsets.bottom)
                }
                
                PresentationSheet(isPresented: self.$trustedDeviceNoNotifications){
                    VStack(spacing:24){
                        ZStack{
                            Image("close-circle")
                        }
                        .frame(width: 80, height: 80)
                        VStack(spacing: 6){
                            Text("Error")
                                .font(.body.bold())
                                .foregroundColor(Color.get(.Text))
                            Text("Apologies, but we've detected that you haven't allowed sending notifications. Thus, this device can't be set as trusted. Please enable it in settings or revoke trust and login again.")
                                .multilineTextAlignment(.center)
                                .font(.caption)
                                .foregroundColor(Color.get(.LightGray))
                        }
                        HStack(spacing: 16){
                            Button{
                                if let appSettings = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(appSettings) {
                                    UIApplication.shared.open(appSettings)
                                }
                            } label:{
                                HStack{
                                    Spacer()
                                    Text("Settings")
                                    Spacer()
                                }
                            }
                            .buttonStyle(.secondary())
                            Spacer()
                            Button{
                                Task{
                                    do{
                                        try await self.revoke()
                                    }catch(let error){
                                        self.trustedDeviceResult = .revoke
                                        self.Error.handle(error)
                                    }
                                }
                            } label:{
                                HStack{
                                    Spacer()
                                    Text("Revoke")
                                    Spacer()
                                }
                            }
                            .buttonStyle(.secondary())
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 24)
                    .padding(.bottom, primaryGeometry.safeAreaInsets.bottom)
                }
                
                //MARK: - Overlays
                if(self.confirmOperationPopup){
                    ConfirmOperation(notification: self.Store.notification, onClose: {
                        self.confirmOperationPopup = false
                    })
                    .environmentObject(self.Error)
                    .environmentObject(self.Store)
                    .environmentObject(self.Router)
                }
                
                //MARK: - Lockout
                if(self.lockoutEnabled){
                    LockoutView(onVerify:{
                        self.lockoutEnabled = false
                        self.activityController.registerActivity()
                        self.Router.goTo(MainView())
                    }, onCancel: {
                        Task{
                            do{
                                try await self.Store.logout()
                                self.Router.home()
                            }catch(_){
                                
                            }
                        }
                    })
                }
                
                //MARK: - Pincode
                if(self.pinCodeSetupResult == nil && self.pinCodeStep != nil){
                    ZStack{
                        if (self.pinCodeStep == .setup){
                            VStack{
                                HStack(spacing:0){
                                    Spacer()
                                    Button{
                                        Task{
                                            do{
                                                try await self.failedPin()
                                            }catch(let error){
                                                self.pinCodeSetupResult = .failed
                                                self.Error.handle(error)
                                            }
                                        }
                                    } label:{
                                        ZStack{
                                            Image("cross")
                                                .resizable()
                                                .scaledToFit()
                                                .foregroundColor(Color.get(.Text))
                                        }.frame(width: 24, height: 24)
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 16)
                                
                                VStack(spacing:12){
                                    VStack(spacing:8){
                                        Text("Enter PIN")
                                            .font(.title2.bold())
                                            .foregroundColor(Color.get(.Text))
                                        Text("Please setup pincode")
                                            .font(.body)
                                            .foregroundColor(Color.get(.Text))
                                    }
                                    .padding(.bottom, 24)
                                    
                                    PassCode(passcode:self.$newpin, onEnter:{ code in
                                        self.retry = 0
                                        self.pinCodeStep = .confirm
                                    })
                                }
                                .padding(.vertical, 24)
                                Spacer()
                            }
                        }
                        else if (self.pinCodeStep == .confirm){
                            VStack{
                                HStack(spacing:0){
                                    Spacer()
                                    Button{
                                        Task{
                                            self.retry = 0
                                            self.pinCodeStep = .setup
                                            self.newpin = ""
                                            self.confirmationpin = ""
                                        }
                                    } label:{
                                        ZStack{
                                            Image("cross")
                                                .resizable()
                                                .scaledToFit()
                                                .foregroundColor(Color.get(.Text))
                                        }.frame(width: 24, height: 24)
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 16)
                                
                                VStack(spacing:12){
                                    VStack(spacing:8){
                                        Text("Enter PIN")
                                            .font(.title2.bold())
                                            .foregroundColor(Color.get(.Text))
                                        Text("Confirm pincode")
                                            .font(.body)
                                            .foregroundColor(Color.get(.Text))
                                    }
                                    .padding(.bottom, 24)
                                }
                                
                                PassCode(passcode:self.$confirmationpin, onEnter:{ code in
                                    Task{
                                        do{
                                            if code == self.newpin{
                                                self.pinService.set(self.confirmationpin)
                                                self.pinCodeSetupResult = .sucess
                                            }else{
                                                self.vibrate()
                                                self.retry += 1
                                                self.confirmationpin = ""
                                                
                                                if self.retry >= 4{
                                                    self.newpin = ""
                                                    self.confirmationpin = ""
                                                    self.pinCodeStep = .setup
                                                    return;
                                                }
                                                
                                                throw ApplicationError(title: "", message: "Wrong pin! You have \(4 - self.retry) attempts")
                                            }
                                        }catch(let error){
                                            self.Error.handle(error)
                                        }
                                    }
                                })
                                .padding(.vertical, 24)
                                
                                Spacer()
                            }
                        }
                        else if (self.pinCodeStep == .enter){
                            VStack{
                                HStack(spacing:0){
                                    Spacer()
                                    Button{
                                        Task{
                                            do{
                                                try await self.failedPin()
                                            }catch(let error){
                                                self.pinCodeSetupResult = .failed
                                                self.Error.handle(error)
                                            }
                                        }
                                    } label:{
                                        ZStack{
                                            Image("cross")
                                                .resizable()
                                                .scaledToFit()
                                                .foregroundColor(Color.get(.Text))
                                        }.frame(width: 24, height: 24)
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 16)
                                
                                VStack(spacing:12){
                                    VStack(spacing:8){
                                        Text("Enter PIN")
                                            .font(.title2.bold())
                                            .foregroundColor(Color.get(.Text))
                                        Text("Please enter your PIN to confirm person")
                                            .font(.body)
                                            .foregroundColor(Color.get(.Text))
                                    }
                                    .padding(.bottom, 24)
                                    
                                    PassCode(passcode:self.$code, onEnter:{ code in
                                        Task{
                                            do{
                                                if self.pinService.verify(code){
                                                    self.pinCodeSetupResult = .sucess
                                                }else{
                                                    self.vibrate()
                                                    self.retry += 1
                                                    self.code = ""
                                                    if self.retry >= 4{
                                                        self.code = ""
                                                        do{
                                                            try await self.failedPin()
                                                        }catch(let error){
                                                            self.pinCodeSetupResult = .failed
                                                            self.Error.handle(error)
                                                        }
                                                        return;
                                                    }
                                                    
                                                    throw ApplicationError(title: "", message: "Wrong pin! You have \(4 - self.retry) attempts")
                                                }
                                            }catch(let error){
                                                self.Error.handle(error)
                                            }
                                        }
                                    })
                                }
                                .padding(.vertical, 24)
                                Spacer()
                            }
                        }
                    }
                    .background(Color.get(.Background))
                }
                
                if (self.appHasUpdateRequired){
                    ZStack{
                        Image("pat8")
                            .ignoresSafeArea()
                            .zIndex(2)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                            .blur(radius: 20)
                        VStack(alignment:.center){
                            Spacer()
                            ZStack{
                                Image(Whitelabel.Image(.logo))
                                    .resizable()
                                    .scaledToFit()
                            }
                                .frame(
                                    width: 150,
                                    height: 50
                                )
                            .padding(.bottom,32)
                            VStack(alignment:.center,spacing:12){
                                HStack(alignment: .center){
                                    Text("Update available")
                                        .font(.title.bold())
                                        .foregroundColor(Color.get(.Text))
                                }
                                .font(.title.bold())
                                Text("A new version of the application is available. Please update your app now to continue using \(Whitelabel.BrandName()) platform")
                                    .font(.body)
                                    .multilineTextAlignment(.center)
                                    .foregroundColor(Color.get(.LightGray))
                            }
                            .padding(.horizontal, 16)
                            Spacer()
                            ZStack{
                                Button{
                                    Task{
                                        do{
                                            try await self.maintenanceController.checkMaintenance()
                                        }catch(let error){
                                            
                                        }
                                    }
                                    let url = URL(string: Enviroment.appUrl)
                                    UIApplication.shared.open(url!)
                                } label:{
                                    HStack{
                                        Text(LocalizedStringKey("Update now"))
                                    }
                                }
                                .buttonStyle(.primary())
                                .padding(.horizontal, 16)
                            }
                            .padding(.bottom, 40)
                        }
                    }
                    .background(Color.get(.Background))
                }
                if (self.maintenance){
                    ZStack{
                        VStack(spacing: 16){
                            Spacer()
                            ZStack{
                                Image("ufo")
                                ZStack{
                                    Image(Whitelabel.Image(.logoSmall))
                                        .resizable()
                                        .scaledToFit()
                                }
                                .frame(
                                    width: 68,
                                    height: 68
                                )
                                .offset(
                                    x: 6,
                                    y: 24
                                )
                                .rotationEffect(.degrees(17))
                            }
                            VStack(alignment: .center, spacing: 6){
                                Text(self.maintenanceTitle)
                                    .multilineTextAlignment(.center)
                                    .font(.body.bold())
                                    .foregroundColor(Color.get(.Text))
                                Text(self.maintenanceBody)
                                    .multilineTextAlignment(.center)
                                    .font(.caption)
                                    .foregroundColor(Color.get(.LightGray))
                            }
                            Spacer()
                            Button{
                                Task{
                                    do{
                                        try await self.maintenanceController.checkMaintenance()
                                    }catch(let error){
                                        
                                    }
                                }
                            } label:{
                                HStack{
                                    Spacer()
                                    Text("Try again")
                                    Spacer()
                                }
                            }
                            .buttonStyle(.primary())
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)
                    }
                    .background(Color.get(.Background))
                }
            }
            .offset(y: notificationHeight)
            .padding(.top, self.errorViewHeight > 0 ?  self.errorViewHeight + primaryGeometry.safeAreaInsets.top : 0)
            .alert(isPresented: self.$Error.hasMessageError, content: displayAlert(error: self.$Error.error.wrappedValue))
            .onAppear{
                Task{
                    do{
                        //Ask for application version
                        try await self.maintenanceController.checkMaintenance()
                        self.applicationReady = true
                    }catch(let error){
                        self.applicationReady = true
                    }
                }
            }
            .onAppear{
                Task{
                    do{
                        if (self.Store.deviceData.isTrusted){
                            try await self.notificationManager.getAuthStatus()
                            if (self.notificationManager.hasPermission){
                                self.Store.showTrustedNotificationsDisabled = false
                            }else{
                                self.Store.showTrustedNotificationsDisabled = true
                            }
                        }
                        let service = DeviceDataService()
                        self.deviceName = service.deviceName
                    }catch(let error){
                        self.Error.handle(error)
                    }
                }
            }
            //MARK: - Popups
            .onChange(of: self.Store.showTrustedDevicePopup){ changes in
                self.trustedDevicePopup = self.Store.showTrustedDevicePopup
            }
            .onReceive(self.Store.$showTrustedNotificationsDisabled){ change in
                self.trustedDeviceNoNotifications = change
            }
            .onChange(of: self.trustedDevicePopup){ changes in
                self.Store.showTrustedDevicePopup = self.trustedDevicePopup
            }
            //MARK: - React to authentification state
            .onReceive(NotificationCenter.default.publisher(for: .AuthenticationStateChange), perform: { notification in
                let state : AuthenticationService.AuthenticateState = notification.userInfo?["state"] as! AuthenticationService.AuthenticateState
                
                Task{
                    do{
                        switch(state){
                        //Error received during authorization
                        case .error(let error):
                            self.Error.handle(error)
                            break;
                        //Login successed
                        case .accessCodeReceived(let code):
                            //Remove manually entities
                            let customers = try self.viewContext.fetch(CoreCustomer.fetchRequest())
                            for customer in customers{
                                self.viewContext.delete(customer)
                            }
                            let accounts = try self.viewContext.fetch(CoreAccount.fetchRequest())
                            for account in accounts{
                                self.viewContext.delete(account)
                            }
                            let identifications = try self.viewContext.fetch(CoreAccountIdentification.fetchRequest())
                            for identification in identifications{
                                self.viewContext.delete(identification)
                            }
                            let amounts = try self.viewContext.fetch(CoreAmount.fetchRequest())
                            for amount in amounts{
                                self.viewContext.delete(amount)
                            }
                            let reasons = try self.viewContext.fetch(CoreReasonCodeLookupDto.fetchRequest())
                            for reason in reasons{
                                self.viewContext.delete(reason)
                            }
                            self.viewContext.refreshAllObjects()
                            try await self.identity.processAccessCode(code)
                            break;
                        case .authenticated:
                            //MARK: Start flow. Logged in
                            try await self.Store.user.load()
                            break;
                        default:
                            break;
                        }
                    }catch(let error){
                        self.Error.handle(error)
                    }
                }
            })
            //MARK: - Deeplink login
            .onReceive(NotificationCenter.default.publisher(for: .DeepLinkLogin), perform: { notification in
                guard var authUrl = notification.userInfo?["url"] as? URL else{
                    return;
                }
                
                DispatchQueue.main.asyncAfter(deadline:.now()+0.2){
                    Task{
                        self.Store.processLogin = false
                        self.Router.home()
                        do{
                            try await self.identity.login(authUrl)
                        }catch(let error){
                            self.Error.handle(error)
                        }
                    }
                }
            })
            //MARK: - Maintence warning
            .onReceive(NotificationCenter.default.publisher(for: .Maintenance), perform: { notification in
                guard var isMaintenance = notification.userInfo?["maintenance"] as? Bool else{
                    return;
                }
                guard var title = notification.userInfo?["title"] as? String else{
                    return;
                }
                guard var description = notification.userInfo?["description"] as? String else{
                    return;
                }
                if (isMaintenance){
                    self.maintenance = true;
                    self.maintenanceTitle = title;
                    self.maintenanceBody = description;
                }else{
                    self.maintenance = false;
                }
            })
            .onReceive(NotificationCenter.default.publisher(for: .ScheduleMaintenanceCheck), perform: { notification in
                Task{
                    do{
                        try await self.maintenanceController.registerScenePhase()
                        try await self.maintenanceController.checkMaintenance()
                    }
                }
            })
            .onReceive(NotificationCenter.default.publisher(for: .AppVersion), perform: { notification in
                guard var isRequired = notification.userInfo?["required"] as? Bool else{
                    return;
                }
                guard var outdated = notification.userInfo?["outdated"] as? Bool else{
                    return;
                }
                self.appHasUpdate = false
                self.appHasUpdateRequired = false
                if (outdated && !self.maintenance){
                    if (isRequired){
                        self.appHasUpdateRequired = true
                    }else{
                        self.appHasUpdate = true
                    }
                }
            })
            //MARK: - Check if token expire
            .onReceive(self.Error.$hasError){ _ in
                if let error = self.Error.error as? AuthenticationService.RefreskTokenError{
                    //Clean session & push to logout page
                    Task{
                        do{
                            try await self.Store.logout()
                            self.Router.home()
                        }
                    }
                }
            }
            //MARK: - User loaded / changed
            .onChange(of: self.Store.user.user_id, perform: { _ in
                Task{
                    do{
                        self.trustedDeviceFailed = false
                        self.trustedDeviceResult = nil
                        self.pinCodeStep = nil
                        self.retry = 0
                        self.code = ""
                        self.newpin = ""
                        self.confirmationpin = ""
                        self.pinCodeSetupResult = nil
                        //User exists & logged in
                        if (self.Store.user.user_id != nil){
                            //Check if account required?
                            if (self.Store.user.accountNotRequested == true){
                                self.identity.state = .initialized
                                openURL(URL(string: Enviroment.platformUrl)!)
                                throw ApplicationError(title: "", message: "Please, continue authentication via web")
                            }else{
                                self.identity.state = .authenticating
                                
                                //MARK: Load & prepare user information
                                let _ = try await self.Store.user.loadCustomers()
                                let _ = try await self.Store.user.loadPerson()
                                
                                //MARK: Active customer
                                if (self.Store.user.customers.first(where: {$0.state == .active}) != nil){
                                    self.Store.user.customerId = self.Store.user.customers.first(where: {$0.state == .active})?.id
                                    return
                                }
                                
                                
                                if (self.Store.user.customers.isEmpty == true || self.Store.user.customers.first(where: {$0.state == .new}) != nil){
                                    if (self.Store.user.customers.isEmpty){
                                        self.processOnboarding()
                                        return
                                    }
                                    self.Store.user.customerId = self.Store.user.customers.first(where: {$0.state == .new})?.id
                                    return
                                }
                                
                                //MARK: Customer await for review
                                if  (self.Store.user.customers.first(where: {$0.state == .review}) != nil){
                                    self.Store.user.customerId = self.Store.user.customers.first(where: {$0.state == .review})?.id
                                    return
                                }
                                
                                if  (self.Store.user.customers.first(where: {$0.state == .approvedForExternal}) != nil){
                                    self.Store.user.customerId = self.Store.user.customers.first(where: {$0.state == .approvedForExternal})?.id
                                    return
                                }
                                if  (self.Store.user.customers.first(where: {$0.state == .rejected}) != nil){
                                    self.Store.user.customerId = self.Store.user.customers.first(where: {$0.state == .rejected})?.id
                                    return
                                }
                                
                                //MARK: Customer blocked
                                if  (self.Store.user.customers.first(where: {$0.state == .inactive}) != nil){
                                    self.Store.user.customerId = self.Store.user.customers.first(where: {$0.state == .inactive})?.id
                                    return
                                }
                            }
                        }
                    }catch(let error){
                        self.identity.state = .initialized
                        self.Error.handle(error)
                    }
                }
            })
            //MARK: - Customer changed
            .onChange(of: self.Store.user.customerId, perform: { _ in
                      
                Task{
                    do{
                        let customer = self.Store.user.customers.first(where: {$0.id == self.Store.user.customerId})
                        if (customer != nil){
                            //App
                            if (customer!.state == .active){
                                if (self.Store.deviceData.deviceId == nil || self.Store.deviceData.deviceId!.isEmpty){
                                    //MARK: On this step - ask for pin, device data, etc
                                    let process = try await self.identity.processDevice()
                                    self.Store.deviceData.deviceId = process.value.deviceInfo.deviceId
                                    self.Store.deviceData.isTrusted = process.value.deviceInfo.isTrusted
                                    
                                    //MARK: If device not trusted - ask to make it trust
                                    if (process.value.deviceInfo.isTrusted == false){
                                        self.Store.showTrustedDevicePopup = true
                                    }else{
                                        if (!self.notificationManager.hasPermission){
                                            self.identity.state = .initialized
                                            self.Store.showTrustedNotificationsDisabled = true
                                        }else{
                                            self.trustedDeviceResult = .success
                                        }
                                    }
                                    Task{
                                        while(self.trustedDeviceResult == nil){
                                            try? await Task.sleep(nanoseconds: 1_000_000_000)
                                        }
                                        if (self.trustedDeviceResult != .revoke){
                                            self.processWithCode()
                                        }
                                    }
                                }
                            }
                            //Onboarding
                            if(customer!.state == .new){
                                //Check if CURRENT screen non onboarding
                                if (!self.Store.onboarding.processing){
                                    self.processOnboarding()
                                }
                                return
                            }
                            //Under review
                            if (customer!.state == .review){
                                self.identity.state = .initialized
                                self.Router.goTo(ApplicationInReviewView())
                                return
                            }
                            if (customer!.state == .approvedForExternal){
                                self.identity.state = .initialized
                                self.Router.goTo(ApplicationInReviewView())
                                return
                            }
                            if (customer!.state == .rejected){
                                self.identity.state = .initialized
                                self.Router.goTo(ApplicationInReviewView())
                                return
                            }
                            //Blocked
                            if (customer!.state == .inactive){
                                self.identity.state = .initialized
                                self.Router.goTo(CustomerLockedView())
                                return
                            }
                        }
                    }catch(let error){
                        self.identity.state = .initialized
                        self.Error.handle(error)
                    }
                }
            })
            //MARK: - Capture last activity time
            .onReceive(NotificationCenter.default.publisher(for: .Activity), perform: { _ in
                if (self.Store.user.user_id == nil){
                    return;
                }
                if (self.Store.user.customers.first(where: {$0.state == .active}) == nil){
                    return;
                }
                if (self.pinCodeSetupResult != .sucess){
                    return;
                }
                self.activityController.registerActivity()
            })
            .onReceive(NotificationCenter.default.publisher(for: .Logout), perform: { _ in
                self.lockoutEnabled = false
                /*
                 DispatchQueue.main.asyncAfter(deadline: .now()+0.2){
                    self.Router.home()
                }
                //self.Router.home()
                 */
            })
            //MARK: - React for application state change
            .onChange(of: scenePhase) { newPhase in
                if newPhase == .active {
                    Task{
                        do{
                            try await self.maintenanceController.registerScenePhase()
                            try await self.maintenanceController.checkMaintenance()
                        }
                    }
                    if (self.Store.deviceData.isTrusted){
                        Task{
                            do{
                                try await self.notificationManager.getAuthStatus()
                                if (self.notificationManager.hasPermission){
                                    self.Store.showTrustedNotificationsDisabled = false
                                }else{
                                    self.Store.showTrustedNotificationsDisabled = true
                                }
                            }
                        }
                    }
                }
            }
            //MARK: - Called when application in "inactive" mode
            .onReceive(NotificationCenter.default.publisher(for: .Inactive), perform: { _ in
                if (self.Store.user.user_id == nil){
                    return;
                }
                if (self.Store.user.customers.first(where: {$0.state == .active}) == nil){
                    return;
                }
                if (self.pinCodeSetupResult != .sucess){
                    return;
                }
                self.lockoutEnabled = true
            })
            //MARK: - Display confirmation notification
            .onReceive(self.Store.$notification){ _ in
                if (self.Store.notification == nil){
                    return;
                }
                if (self.Store.user.user_id == nil){
                    return;
                }
                if (self.Store.user.customers.first(where: {$0.state == .active}) == nil){
                    return;
                }
                if (self.pinCodeSetupResult != .sucess){
                    return;
                }
                
                //Check for notification callback type
                if (self.Store.notification?.action == .router){
                    switch(self.Store.notification?.type){
                    case .UpcomingSOPayment:
                        let data = self.Store.notification as! UpcomingSOPaymentNotification
                        Task{
                            do{
                                let customers = try await services.kycp.getCustomers()
                                let customer = customers.customers.first(where: {$0.id == data.customerId})
                                let account = try await services.accounts.getCustomerAccount(
                                    data.customerId,
                                    accountId: data.accountId
                                )
                                if (account.value != nil){
                                    let coreAccount = CoreAccount(context: self.viewContext)
                                    coreAccount.fetchFromAccount(account: account.value!)
                                    let coreCustomer = CoreCustomer(context: self.viewContext)
                                    coreCustomer.setValue(customer!.id, forKey:"id")
                                    coreCustomer.setValue(customer!.name, forKey:"name")
                                    coreCustomer.setValue(customer!.type.rawValue.lowercased(), forKey:"type")
                                    coreCustomer.setValue(customer!.state.rawValue.lowercased(), forKey:"state")
                                    coreCustomer.addToAccounts(coreAccount)
                                    self.Router.goTo(
                                        AccountMainView(
                                            account: coreAccount
                                       )
                                       .environmentObject(self.Error)
                                       .environmentObject(self.Store)
                                       .environmentObject(self.Router)
                                   )
                                }
                            }catch let error{
                                self.Error.handle(error)
                            }
                        }
                        break;
                    case .FailedSOInsufficientFunds:
                        let data = self.Store.notification as! FailedSOInsufficientFundsNotification
                        Task{
                            do{
                                let customers = try await services.kycp.getCustomers()
                                let customer = customers.customers.first(where: {$0.id == data.customerId})
                                let account = try await services.accounts.getCustomerAccount(
                                    data.customerId,
                                    accountId: data.accountId
                                )
                                if (account.value != nil){
                                    let coreAccount = CoreAccount(context: self.viewContext)
                                    coreAccount.fetchFromAccount(account: account.value!)
                                    let coreCustomer = CoreCustomer(context: self.viewContext)
                                    coreCustomer.setValue(customer!.id, forKey:"id")
                                    coreCustomer.setValue(customer!.name, forKey:"name")
                                    coreCustomer.setValue(customer!.type.rawValue.lowercased(), forKey:"type")
                                    coreCustomer.setValue(customer!.state.rawValue.lowercased(), forKey:"state")
                                    coreCustomer.addToAccounts(coreAccount)
                                    self.Router.goTo(
                                        AccountMainView(
                                            account: coreAccount
                                       )
                                       .environmentObject(self.Error)
                                       .environmentObject(self.Store)
                                       .environmentObject(self.Router)
                                   )
                                }
                            }catch let error{
                                self.Error.handle(error)
                            }
                        }
                        break;
                    case .NewSOCreated:
                        let data = self.Store.notification as! NewSOCreatedNotification
                        self.Router.goTo(
                            StandingOrderDetailsView(
                                customerId: data.customerId,
                                accountId: data.accountId,
                                orderId: data.orderId
                            )
                            .environmentObject(self.Error)
                            .environmentObject(self.Store)
                            .environmentObject(self.Router)
                        )
                        break;
                    case .FailedSOTechnIssue:
                        let data = self.Store.notification as! FailedSOTechnIssueNotification
                        self.Router.goTo(
                            StandingOrderDetailsView(
                                customerId: data.customerId,
                                accountId: data.accountId,
                                orderId: data.orderId
                            )
                            .environmentObject(self.Error)
                            .environmentObject(self.Store)
                            .environmentObject(self.Router)
                        )
                        break;
                    case .FailedSOAccountClosed:
                        let data = self.Store.notification as! FailedSOAccountClosedNotification
                        self.Router.goTo(
                            StandingOrderDetailsView(
                                customerId: data.customerId,
                                accountId: data.accountId,
                                orderId: data.orderId
                            )
                            .environmentObject(self.Error)
                            .environmentObject(self.Store)
                            .environmentObject(self.Router)
                        )
                        break;
                    case .StaleSOPushForCreator:
                        let data = self.Store.notification as! StaleSOPushForCreatorNotification
                        self.Router.goTo(
                            StandingOrderDetailsView(
                                customerId: data.customerId,
                                accountId: data.accountId,
                                orderId: data.orderId
                            )
                            .environmentObject(self.Error)
                            .environmentObject(self.Store)
                            .environmentObject(self.Router)
                        )
                        break;
                    case .OperationWaitingApproval:
                        let data = self.Store.notification as! OperationWaitingApprovalNotification
                        self.Router.goTo(
                            AccountApprovalFlowDetailsView(
                                flowId: data.flowId
                            )
                            .environmentObject(self.Error)
                            .environmentObject(self.Store)
                            .environmentObject(self.Router)
                        )
                        break;
                    default:
                        break;
                    }
                    return
                }
                
                if (self.confirmOperationPopup){
                    self.confirmOperationPopup = false
                    DispatchQueue.main.asyncAfter(deadline: .now()+0.1) {
                        self.confirmOperationPopup = true
                    }
                    return
                }
                self.confirmOperationPopup = true
            }
            //MARK: -
            .onChange(of: self.pinCodeSetupResult){ _ in
                if (self.Store.notification == nil){
                    return;
                }
                if (self.Store.user.user_id == nil){
                    return;
                }
                if (self.Store.user.customers.first(where: {$0.state == .active}) == nil){
                    return;
                }
                if (self.pinCodeSetupResult != .sucess){
                    return;
                }
                if (self.confirmOperationPopup){
                    self.confirmOperationPopup = false
                    DispatchQueue.main.asyncAfter(deadline: .now()+0.1) {
                        self.confirmOperationPopup = true
                    }
                    return
                }
                self.confirmOperationPopup = true
            }
        }
        .overlay(
            ZStack{
                //MARK: Application global errors (warning block on top)
                if (self.Error.hasError && ((self.Error.error as? ApplicationError) != nil)){
                    Text(LocalizedStringKey(self.Error.message))
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                        .frame(maxWidth: .infinity)
                        .zIndex(10)
                        .foregroundColor(Color.white)
                        .padding(.vertical, 16)
                        .padding(.horizontal, 16)
                        .background(
                            GeometryReader{ notification in
                                Color.clear
                                    .preference(
                                        key: NotificationHeightPreference.self,
                                        value: notification.size.height
                                    )
                            }
                        )
                        .background(Color("Danger"))
                        .onAppear{
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: {
                                self.Error.error = nil
                            })
                        }
                }
            }
                .frame(maxWidth: .infinity)
                .onPreferenceChange(NotificationHeightPreference.self) { value in
                  DispatchQueue.main.async {
                     self.notificationHeight = value
                  }
                }
            , alignment: .top)
    }
}

struct NotificationHeightPreference: PreferenceKey {
   static var defaultValue: CGFloat { 0 }
   
   static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
      value = nextValue()
   }
}

struct ContentViewContainerPreview<Content:View>: View{
    @StateObject var Store = ApplicationStore()
    @StateObject var Error = ErrorHandlingService()
    
    let content: () -> Content
    
    var body: some View{
        GeometryReader{ primaryGeometry in
            ZStack{
                VStack(spacing:0){
                    NavigationView{
                        self.content()
                        .environmentObject(self.Store)
                        .environmentObject(self.Error)
                    }
                    .navigationViewStyle(.stack)
                    .environmentObject(self.Store)
                    .environmentObject(self.Error)
                }
            }
        }
        .onAppear{
            EnviromentOverrideUseMockData = true
            Task{
                do{
                    let _ = try await self.Store.user.loadPerson()
                    let _ = try await self.Store.user.loadCustomers()
                    self.Store.user.customerId = self.Store.user.customers.first?.id
                }catch(let error){
                    
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var store: ApplicationStore {
        var store = ApplicationStore()
        return store
    }
    
    static var previews: some View {
        ContentView()
            .environmentObject(self.store)
    }
}

/*
 
 .font(.body) = 16px
 .font(title2) = 20px
 .font(subheadline) = 14px
 .font(caption) = 12px
 .font(caption2) = 10px
 */

private struct ErrorViewHeightPreference: PreferenceKey {
  static var defaultValue: CGFloat = 0

  static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
    value = max(value, nextValue())
  }
}
