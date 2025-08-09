//
//  MaintenseService.swift
//  DigiDoe Business Banking
//
//  Created by Михайло Картмазов on 28.03.2025.
//

import Foundation
import Combine

class MaintenanceController: ObservableObject{
    private var task: DispatchWorkItem? = nil
    
    func registerScenePhase() async throws{
        self.task?.cancel()
        self.task = nil
        
        self.task = DispatchWorkItem{
            //Check for activity
            NotificationCenter.default.post(name: .ScheduleMaintenanceCheck, object: nil)
        }
        
        let calendar = Calendar.current
        
        let minutes = calendar.component(.minute, from: Date())
        let seconds = calendar.component(.second, from: Date())
        let current = seconds + (minutes*60)
        
        //Repeat scheduler time, in seconds. (check each minute - 60, each 5 minute - 60 * 5, etc)
        let repeatInterval: Int = 30 * 60
        //Difference between current time & scheduled
        var difference: Int = 0;
        
        difference = current % repeatInterval
        //For case when difference == 0 (e.x 0, 30, 60)
        if (difference == 0){
            difference = 1
        }
        
        let offset: Double = (Double(repeatInterval) - Double(difference))
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + offset, execute: self.task!)
    }
    
    func checkMaintenance() async throws{
        let result = try await services.maintenance.getMaintenance()
        NotificationCenter.default.post(
            name: .Maintenance,
            object: nil,
            userInfo: [
                "maintenance": result.maintenance,
                "title": result.msgTitle,
                "description": result.msgBody
            ]
        )
        //MARK: Compare app versions
        let service = AppVersion()
        NotificationCenter.default.post(
            name: .AppVersion,
            object: nil,
            userInfo: [
                "outdated":service.isOutdatedWith(version: result.iOS_ver),
                "version": result.iOS_ver,
                "required": result.isUpdateRequired
            ]
        )
    }
}
