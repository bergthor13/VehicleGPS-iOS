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
    var cadence:Int?
    var power:Double?
    var heartRate:Int?
    
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
        self.cadence = dataPoint.value(forKey: "cadence") as? Int
        self.power = dataPoint.value(forKey: "power") as? Double
        self.heartRate = dataPoint.value(forKey: "heartRate") as? Int
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
        if let cadence = self.cadence {
            dataPoint.cadence = Int16(cadence)
        }
        if let power = self.power {
            dataPoint.power = power
        }
        if let heartRate = self.heartRate {
            dataPoint.heartRate = Int16(heartRate)
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
        
        return (!(fixType <= 1 || horizontalAccuracy > 100)) && timestamp != nil
    }
}

extension VGDataPoint: Equatable {
    static func == (lhs: VGDataPoint, rhs: VGDataPoint) -> Bool {
        return lhs.timestamp == rhs.timestamp
    }
}


extension VGDataPoint: Comparable {
    static func < (lhs: VGDataPoint, rhs: VGDataPoint) -> Bool {
        guard let leftTimeStamp = lhs.timestamp, let rightTimeStamp = rhs.timestamp else {
            return false
        }
        return leftTimeStamp < rightTimeStamp
    }
}


extension VGDataPoint: CustomStringConvertible {
    var description: String {
        var result = ""
        if timestamp != nil          {result += "         timestamp: " + String(describing: self.timestamp!) + "\n"}
        if latitude != nil           {result += "          latitude: " + String(describing: self.latitude!) + "\n"}
        if longitude != nil          {result += "         longitude: " + String(describing: self.longitude!) + "\n"}
        if elevation != nil          {result += "         elevation: " + String(describing: self.elevation!) + "\n"}
        if satellites != nil         {result += "        satellites: " + String(describing: self.satellites!) + "\n"}
        if horizontalAccuracy != nil {result += "horizontalAccuracy: " + String(describing: self.horizontalAccuracy!) + "\n"}
        if verticalAccuracy != nil   {result += "  verticalAccuracy: " + String(describing: self.verticalAccuracy!) + "\n"}
        if pdop != nil               {result += "              pdop: " + String(describing: self.pdop!) + "\n"}
        if fixType != nil            {result += "           fixType: " + String(describing: self.fixType!) + "\n"}
        if gnssFixOk != nil          {result += "         gnssFixOk: " + String(describing: self.gnssFixOk!) + "\n"}
        if fullyResolved != nil      {result += "     fullyResolved: " + String(describing: self.fullyResolved!) + "\n"}
        if rpm != nil                {result += "               rpm: " + String(describing: self.rpm!) + "\n"}
        if engineLoad != nil         {result += "        engineLoad: " + String(describing: self.engineLoad!) + "\n"}
        if coolantTemperature != nil {result += "coolantTemperature: " + String(describing: self.coolantTemperature!) + "\n"}
        if ambientTemperature != nil {result += "ambientTemperature: " + String(describing: self.ambientTemperature!) + "\n"}
        if throttlePosition != nil   {result += "  throttlePosition: " + String(describing: self.throttlePosition!) + "\n"}
        if cadence != nil            {result += "           cadence: " + String(describing: self.cadence!) + "\n"}
        if power != nil              {result += "             power: " + String(describing: self.power!) + "\n"}
        return result
    }
}
