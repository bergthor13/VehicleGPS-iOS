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
    
    // 2019-04-24T17:46:17.599829,63.995643,-22.634326,41.482,7,0.994,1.484,3.48,3,True,False,1103.5,34.509803921568626,14,5,14.509803921568627
    var timestamp:Date?
    var latitude:Double
    var longitude:Double
    var elevation:Double
    var satellites:Int
    var horizontalAccuracy:Double
    var verticalAccuracy:Double
    var pdop:Double
    var fixType:Int
    var gnssFixOk:Bool
    var fullyResolved:Bool
    var rpm:Double?
    var engineLoad:Double?
    var coolantTemperature:Double?
    var ambientTemperature:Double?
    var throttlePosition:Double?
    
    var relatedTrack: VGTrack?
    
    init(csvLine:String) {
        let data = csvLine.components(separatedBy: ",")
        
        var date:Date?
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX") // set locale to reliable US_POSIX
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
        date = dateFormatter.date(from:data[0])
        if date != nil {
            timestamp = date
        }
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        date = dateFormatter.date(from:data[0])
        if date != nil {
            timestamp = date
        }

        latitude = Double(data[1])!
        longitude = Double(data[2])!
        elevation = Double(data[3])!
        satellites = Int(data[4])!
        horizontalAccuracy = Double(data[5])!
        verticalAccuracy = Double(data[6])!
        pdop = Double(data[7])!
        fixType = Int(data[8])!
        if data[9] == "True" {
            gnssFixOk = true
        } else {
            gnssFixOk = false
        }
        if data[10] == "True" {
            fullyResolved = true
        } else {
            fullyResolved = false
        }
        
        if data[11] != "None" {
            rpm = Double(data[11])
        }
        if data[12] != "None" {
            engineLoad = Double(data[11])
        }
        if data[13] != "None" {
            coolantTemperature = Double(data[11])
        }
        if data[14] != "None" {
            ambientTemperature = Double(data[11])
        }
        if data[15] != "None" {
            throttlePosition = Double(data[11])
        }
    }
    
    init(managedPoint:NSManagedObject) {
        if let timestamp = managedPoint.value(forKey: "timeStamp") as? Date? {
            self.timestamp = timestamp
        } else {
            self.timestamp = Date(timeIntervalSince1970: 0.0)
        }
        if let latitude = managedPoint.value(forKey: "latitude") as? Double {
            self.latitude = latitude
        } else {
            self.latitude = 0.0
        }
        if let longitude = managedPoint.value(forKey: "longitude") as? Double {
            self.longitude = longitude
        } else {
            self.longitude = 0.0
        }
        if let elevation = managedPoint.value(forKey: "elevation") as? Double {
            self.elevation = elevation
        } else {
            self.elevation = 0.0
        }
        if let satellites = managedPoint.value(forKey: "satellites") as? Int {
            self.satellites = satellites
        } else {
            self.satellites = 0
        }
        if let horizontalAccuracy = managedPoint.value(forKey: "horizontalAccuracy") as? Double {
            self.horizontalAccuracy = horizontalAccuracy
        } else {
            self.horizontalAccuracy = 0.0
        }
        if let verticalAccuracy = managedPoint.value(forKey: "verticalAccuracy") as? Double {
            self.verticalAccuracy = verticalAccuracy
        } else {
            self.verticalAccuracy = 0.0
        }
        if let pdop = managedPoint.value(forKey: "pdop") as? Double {
            self.pdop = pdop
        } else {
            self.pdop = 0.0
        }
        if let fixType = managedPoint.value(forKey: "fixType") as? Int {
            self.fixType = fixType
        } else {
            self.fixType = 0
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
    static func isValid(line:String) -> Bool {
        let data = line.components(separatedBy: ",")
        if data.count < 16 {
            return false
        }
        return true
    }
    
    
}

//extension VGDataPoint: CustomStringConvertible {
//    var description: String {
//        return "timestamp: \(timestamp) latitude: \(latitude) longitude: \(longitude) elevation: \(elevation) satellites: \(satellites) horizontalAccuracy: \(horizontalAccuracy) verticalAccuracy: \(verticalAccuracy) pdop: \(pdop) fixType: \(fixType) gnssFixOk: \(gnssFixOk) fullyResolved: \(fullyResolved) rpm: \(rpm) engineLoad: \(engineLoad) coolantTemperature: \(coolantTemperature) ambientTemperature: \(ambientTemperature) throttlePosition: \(throttlePosition)"
//    }
//}
