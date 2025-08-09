//
//  DevicesListView.swift
//  DigiDoe Business Banking
//
//  Created by Настя Оксенюк on 28.02.2024.
//

import Foundation
import SwiftUI

extension DevicesListView{
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
}

struct DevicesListView: View, RouterPage {
    @EnvironmentObject var Store: ApplicationStore
    @EnvironmentObject var Error: ErrorHandlingService
    @EnvironmentObject var Router: RoutingController
    
    @State private var loading: Bool = false
    @State private var revokeLoading: Bool = false
    @State private var scrollOffset : Double = 0
    @State private var devices: Array<ProfileService.DeviceRegisterResultResult.DeviceRegisterResult.DeviceInfoDto> = [
        .init(id: "1", createdUtc: "2024-02-28T11:56:04.030Z", isTrusted: true, deviceType: .Mobile),
        .init(id: "2", createdUtc: "2024-02-28T11:56:04.030Z", updatedUtc: "2024-03-28T11:56:04.030Z", isTrusted: false, deviceType: .Browser)
    ]
    @State private var popupDevice: ProfileService.DeviceRegisterResultResult.DeviceRegisterResult.DeviceInfoDto = .init(id: "", createdUtc: "", isTrusted: false, deviceType: .Undefined)
    @State private var showDeviceDetails: Bool = false

    func getDevices() async throws{
        self.loading = true
        let devices = try await services.profiles.getDevices()
        self.devices = devices.value
        self.loading = false
    }
    
    func revokeDevice() async throws{
        self.revokeLoading = true
        guard self.popupDevice.deviceId != nil else{
            throw ApplicationError(title: "", message: "Unable to revoke device, device id not specified")
        }
        let update = try await services.profiles.untrust(self.popupDevice.deviceId!)
        
        //Update device model
        let index = self.devices.firstIndex(where: {$0.id == self.popupDevice.id})
        if (index != nil){
            self.devices[index!] = update.value
        }
        //Logout
        try await self.Store.logout()
        
        self.revokeLoading = false
        self.Router.home()
    }
    
    var devicesList: some View{
        VStack(spacing: 0) {
            //MARK: Display list of devices
            ForEach(Array(self.devices.sorted(by: { (a,b) in
                if (a.isTrusted && b.isTrusted){
                    return (a.updatedUtc ?? a.createdUtc).asDate()! > (b.updatedUtc ?? b.createdUtc).asDate()!
                }
                return a.isTrusted ? true : ( (a.updatedUtc ?? a.createdUtc).asDate()! > (b.updatedUtc ?? b.createdUtc).asDate()!)
            }).enumerated()), id: \.1.id){ (index, device) in
                Button{
                    self.popupDevice = device
                    DispatchQueue.main.asyncAfter(deadline: .now()+0.1, execute: {
                        self.showDeviceDetails = true
                    })
                } label: {
                    HStack{
                        ZStack{
                            Image(device.deviceType == .Mobile ? "mobile" : "monitor")
                                .foregroundColor(Color.white)
                        }
                            .frame(width: 40, height: 40)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .foregroundColor(Whitelabel.Color(.Primary))
                            )
                        VStack(spacing: 2){
                            Text(device.platform ?? "-")
                                .font(.body.bold())
                                .foregroundColor(Color.get(.MiddleGray))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .multilineTextAlignment(.leading)
                            Text((device.updatedUtc ?? device.createdUtc).asDate()?.asStringDateTime() ?? "-")
                                .font(.subheadline)
                                .foregroundColor(Color.get(.MiddleGray))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .multilineTextAlignment(.leading)
                            if (device.isTrusted == true){
                                Text("Trusted")
                                    .font(.subheadline)
                                    .foregroundColor(Color.get(.Active))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .multilineTextAlignment(.leading)
                            }
                        }
                        Spacer()
                    }
                }
                .buttonStyle(.next())
                .disabled(self.loading || self.revokeLoading)
                if (index < devices.count - 1){
                    Divider().overlay(Color.get(.Divider))
                }
            }
            Spacer()
        }
    }
    
    var body: some View{
        ApplicationNavigatorContainerView{
            GeometryReader{ geometry in
                ZStack{
                    ScrollView{
                        VStack(spacing: 0){
                            //MARK: Header
                            VStack(spacing: 0){
                                Header(back:{
                                    self.Router.back()
                                }, title: "Devices")
                                
                                ZStack{
                                    Image("devices")
                                        .resizable()
                                        .scaledToFit()
                                        .foregroundColor(Color.get(.LightGray))
                                }
                                    .frame(width: 90)
                                    .padding(16)
                                Text("List of active devices")
                                    .font(.subheadline)
                                    .foregroundColor(Color.get(.LightGray))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 0)
                            }
                                .offset(
                                    y: self.scrollOffset < 0 ? self.scrollOffset : 0
                                )
                            //MARK: Loader
                            HStack{
                                Spacer()
                                Loader(size:.small)
                                    .offset(y: self.loaderOffset)
                                    .opacity(self.loading ? 1 : self.scrollOffset > -10 ? 0 : -self.scrollOffset / 100)
                                Spacer()
                            }
                            .frame(
                                maxWidth: .infinity,
                                maxHeight: 0
                            )
                            .zIndex(3)
                            .offset(y: 0)
                            
                            //MARK: Content
                            self.devicesList
                                .offset(
                                    y: self.loading && self.scrollOffset > -100 ? Swift.abs(100 - self.scrollOffset) : 0
                                )
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
                        .onAppear{
                            Task{
                                do{
                                    try await self.getDevices()
                                }catch(let error){
                                    self.loading = false
                                    self.Error.handle(error)
                                }
                            }
                        }
                    }
                        .coordinateSpace(name: "scroll")
                        .onChange(of: scrollOffset){ _ in
                            if (!self.loading && self.scrollOffset <= -100){
                                Task{
                                    do{
                                        try await self.getDevices()
                                    }catch(let error){
                                        self.loading = false
                                        self.Error.handle(error)
                                    }
                                }
                            }
                        }
                    
                    if (!self.popupDevice.id.isEmpty){
                        //MARK: Modals
                        PresentationSheet(isPresented: self.$showDeviceDetails){
                            VStack(spacing:24){
                                ZStack{
                                    Image(self.popupDevice.deviceType == .Mobile ? "mobile" : "monitor")
                                        .foregroundColor(Color.white)
                                }
                                .frame(width: 64, height: 64)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .foregroundColor(Whitelabel.Color(.Primary))
                                )
                                VStack(spacing:6){
                                    Text(self.popupDevice.platform ?? "-")
                                        .font(.title2.bold())
                                        .foregroundColor(Color.get(.MiddleGray))
                                        .multilineTextAlignment(.center)
                                    if (self.popupDevice.isTrusted){
                                        Text("Trusted")
                                            .font(.subheadline)
                                            .foregroundColor(Color.get(.Active))
                                            .multilineTextAlignment(.center)
                                    }
                                }
                                
                                VStack(spacing:12){
                                    if (self.popupDevice.firstIpAddress != nil || self.popupDevice.lastIpAddress != nil){
                                        HStack(spacing:16){
                                            Text("IP address")
                                                .font(.subheadline)
                                                .foregroundColor(Color.get(.LightGray))
                                            //.frame(maxWidth: .infinity, alignment: .leading)
                                                .multilineTextAlignment(.leading)
                                            Text(self.popupDevice.lastIpAddress ?? self.popupDevice.firstIpAddress ?? "-")
                                                .font(.subheadline.bold())
                                                .foregroundColor(Color.get(.MiddleGray))
                                                .frame(maxWidth: .infinity, alignment: .trailing)
                                                .multilineTextAlignment(.trailing)
                                        }
                                    }
                                    HStack(spacing:16){
                                        Text("Last activity")
                                            .font(.subheadline)
                                            .foregroundColor(Color.get(.LightGray))
                                        //.frame(alignment: .leading)
                                            .multilineTextAlignment(.leading)
                                        Text((self.popupDevice.updatedUtc ?? self.popupDevice.createdUtc).asDate()?.asStringDateTime() ?? "-")
                                            .font(.subheadline.bold())
                                            .foregroundColor(Color.get(.MiddleGray))
                                            .frame(maxWidth: .infinity, alignment: .trailing)
                                            .multilineTextAlignment(.trailing)
                                    }
                                }
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .foregroundColor(Color.get(.Section))
                                )
                                
                                VStack(spacing:12){
                                    if (self.popupDevice.isTrusted){
                                        Button{
                                            Task{
                                                do{
                                                    try await self.revokeDevice()
                                                    self.showDeviceDetails = false
                                                }catch(let error){
                                                    self.revokeLoading = false
                                                    self.loading = false
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
                                        .buttonStyle(.secondaryDanger())
                                        .disabled(self.revokeLoading)
                                        .loader(self.$revokeLoading)
                                    }
                                }
                            }
                            .padding(16)
                            .padding(.bottom, geometry.safeAreaInsets.bottom)
                        }
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationTitle("")
        .background(Color.get(.Background))
    }
}

struct DevicesListView_Previews: PreviewProvider {
    static var previews: some View {
        ContentViewContainerPreview{
            DevicesListView()
        }
    }
}
