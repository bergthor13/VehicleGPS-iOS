//
//  VGDataPoint.swift
//  VehicleGPS
//
//  Created by Bergþór Þrastarson on 01/06/2019.
//  Copyright © 2019 Bergþór Þrastarson. All rights reserved.
//

import Foundation
import CoreData

class VGDataPoint {
    var timestamp:Date?
    var latitude:Double?
    var longitude:Double?
    var elevation:Double?
    var satellites:Int?
    var horizontalAccuracy:Double?
    var verticalAccuracy:Double?
    var pdop:Double?
    var fixType:Int?
    var gnssFixOk:Bool?
    var fullyResolved:Bool?
    var rpm:Double?
    var engineLoad:Double?
    var coolantTemperature:Double?
    var ambientTemperature:Double?
    var throttlePosition:Double?
    
    var hasOBDData: Bool {
        return (rpm != nil || engineLoad != nil || coolantTemperature != nil || ambientTemperature != nil || throttlePosition != nil)
    }
    
    var relatedTrack: VGTrack?
    
    init() {
        
    }
    
    init(managedPoint:NSManagedObject) {
        if let timestamp = managedPoint.value(forKey: "timeStamp") as? Date? {
            self.timestamp = timestamp
        } else {
            self.timestamp = Date(timeIntervalSince1970: 0.0)
        }
        
        if let latitude = managedPoint.value(forKey: "latitude") as? Double {
            self.latitude = latitude
        }
        
        if let longitude = managedPoint.value(forKey: "longitude") as? Double {
            self.longitude = longitude
        }
        
        if let elevation = managedPoint.value(forKey: "elevation") as? Double {
            self.elevation = elevation
        }
        
        if let satellites = managedPoint.value(forKey: "satellites") as? Int {
            self.satellites = satellites
        } else {
            self.satellites = 0
        }
        if let horizontalAccuracy = managedPoint.value(forKey: "horizontalAccuracy") as? Double {
            self.horizontalAccuracy = horizontalAccuracy
        } else {
            self.horizontalAccuracy = Double.infinity
        }
        if let verticalAccuracy = managedPoint.value(forKey: "verticalAccuracy") as? Double {
            self.verticalAccuracy = verticalAccuracy
        } else {
            self.verticalAccuracy = Double.infinity
        }
        if let pdop = managedPoint.value(forKey: "pdop") as? Double {
            self.pdop = pdop
        } else {
            self.pdop = Double.infinity
        }
        if let fixType = managedPoint.value(forKey: "fixType") as? Int {
            self.fixType = fixType
        }
        
        if let gnssFixOk = managedPoint.value(forKey: "gnssFixOK") as? Bool {
            self.gnssFixOk = gnssFixOk
        } else {
            self.gnssFixOk = false
        }
        if let fullyResolved = managedPoint.value(forKey: "fullyResolved") as? Bool {
            self.fullyResolved = fullyResolved
        } else {
            self.fullyResolved = false
        }
        if let rpm = managedPoint.value(forKey: "rpm") as? Double? {
            self.rpm = rpm
        } else {
            self.rpm = 0.0
        }
        if let engineLoad = managedPoint.value(forKey: "engineLoad") as? Double? {
            self.engineLoad = engineLoad
        } else {
            self.engineLoad = 0.0
        }
        if let coolantTemperature = managedPoint.value(forKey: "coolantTemperature") as? Double? {
            self.coolantTemperature = coolantTemperature
        } else {
            self.coolantTemperature = 0.0
        }
        if let ambientTemperature = managedPoint.value(forKey: "ambientTemperature") as? Double? {
            self.ambientTemperature = ambientTemperature
        } else {
            self.ambientTemperature = 0.0
        }
        if let throttlePosition = managedPoint.value(forKey: "throttlePosition") as? Double? {
            self.throttlePosition = throttlePosition
        } else {
            self.throttlePosition = 0.0
        }
    }
    
    func hasGoodFix() -> Bool {
        guard let fixType = self.fixType else {
            return true
        }
        
        guard let horizontalAccuracy = self.horizontalAccuracy else {
            return true
        }
        
        return (!(fixType <= 1 || horizontalAccuracy > 2)) && timestamp != nil
    }
}

extension VGDataPoint: Equatable {
    static func == (lhs: VGDataPoint, rhs: VGDataPoint) -> Bool {
        return lhs.timestamp == rhs.timestamp
    }
}


extension VGDataPoint: Comparable {
    static func < (lhs: VGDataPoint, rhs: VGDataPoint) -> Bool {
        return lhs.timestamp! < rhs.timestamp!
    }
}
