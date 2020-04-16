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
    
    init(dataPoint:DataPoint) {
        self.timestamp = dataPoint.value(forKey: "timeStamp") as? Date
        self.latitude = dataPoint.value(forKey: "latitude") as? Double
        self.longitude = dataPoint.value(forKey: "longitude") as? Double
        self.elevation = dataPoint.value(forKey: "elevation") as? Double
        self.satellites = dataPoint.value(forKey: "satellites") as? Int
        self.horizontalAccuracy = dataPoint.value(forKey: "horizontalAccuracy") as? Double
        self.verticalAccuracy = dataPoint.value(forKey: "verticalAccuracy") as? Double
        self.pdop = dataPoint.value(forKey: "pdop") as? Double
        self.fixType = dataPoint.value(forKey: "fixType") as? Int
        self.gnssFixOk = dataPoint.value(forKey: "gnssFixOK") as? Bool
        self.fullyResolved = dataPoint.value(forKey: "fullyResolved") as? Bool
        self.rpm = dataPoint.value(forKey: "rpm") as? Double
        self.engineLoad = dataPoint.value(forKey: "engineLoad") as? Double
        self.coolantTemperature = dataPoint.value(forKey: "coolantTemperature") as? Double
        self.ambientTemperature = dataPoint.value(forKey: "ambientTemperature") as? Double
        self.throttlePosition = dataPoint.value(forKey: "throttlePosition") as? Double
    }
    
    func setEntity(dataPoint:DataPoint, track:Track) -> DataPoint{
        if let timestamp = self.timestamp {
            dataPoint.timeStamp = timestamp
        }
        
        if let latitude = self.latitude {
            dataPoint.latitude = latitude
        }
        
        if let longitude = self.longitude {
            dataPoint.longitude = longitude
        }
        
        if let elevation = self.elevation {
            dataPoint.elevation = elevation
        }
        
        if let satellites = self.satellites {
            dataPoint.satellites = Int16(satellites)
        }
        
        if let horizontalAccuracy = self.horizontalAccuracy {
            dataPoint.horizontalAccuracy = horizontalAccuracy
        }
        
        if let verticalAccuracy = self.verticalAccuracy {
            dataPoint.verticalAccuracy = verticalAccuracy
        }
        
        if let pdop = self.pdop {
            dataPoint.pdop = pdop
        }
        
        if let fixType = self.fixType {
            dataPoint.fixType = Int16(fixType)
        }
        
        if let gnssFixOk = self.gnssFixOk {
            dataPoint.gnssFixOK = gnssFixOk
        }
        
        if let fullyResolved = self.fullyResolved {
            dataPoint.fullyResolved = fullyResolved
        }
        
        if let rpm = self.rpm {
            dataPoint.rpm = rpm
        }
        
        if let engineLoad = self.engineLoad {
            dataPoint.engineLoad = engineLoad
        }
        
        if let coolantTemperature = self.coolantTemperature {
            dataPoint.coolantTemperature = coolantTemperature
        }
        
        if let ambientTemperature = self.ambientTemperature {
            dataPoint.ambientTemperature = ambientTemperature
        }
        if let throttlePosition = self.throttlePosition {
            dataPoint.throttlePosition = throttlePosition
        }
        
        dataPoint.track = track
        return dataPoint
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


extension VGDataPoint: CustomStringConvertible {
    var description: String {
        return "timestamp: \(String(describing: self.timestamp)), ele:\(String(describing: self.elevation))"
    }
}
