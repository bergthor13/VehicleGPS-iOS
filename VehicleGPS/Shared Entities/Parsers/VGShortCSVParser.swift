//
//  VGShortCSVParser.swift
//  VehicleGPS
//
//  Created by Bergþór Þrastarson on 08/03/2020.
//  Copyright © 2020 Bergþór Þrastarson. All rights reserved.
//

import Foundation
import UIKit
import fastCSV

class VGShortCSVParser: VGCSVParser {

    override func isValid(row:[String]) -> Bool {
        if row.count < 15 {
            return false
        }
        return true
    }
    
    override func rowToDataPoint(row: [String]) -> VGDataPoint {
        let dataPoint = VGDataPoint()
        dataPoint.timestamp = ISO8601DateParser.parse(String(row[0]))
        dataPoint.latitude = Double(row[1])
        dataPoint.longitude = Double(row[2])
        dataPoint.elevation = Double(row[3])
        dataPoint.satellites = Int(row[4])
        dataPoint.horizontalAccuracy = Double(row[5])!
        dataPoint.verticalAccuracy = Double(row[6])!
        dataPoint.pdop = Double(row[7])!
        
        if row[8] == "True" {
            dataPoint.gnssFixOk = true
        } else {
            dataPoint.gnssFixOk = false
        }
        
        if row[9] == "True" {
            dataPoint.fullyResolved = true
        } else {
            dataPoint.fullyResolved = false
        }
        
        if row[11] != "None" {
            dataPoint.rpm = Double(row[11])
        }
        
        if row[11] != "None" {
            dataPoint.engineLoad = Double(row[11])
        }
        
        if row[12] != "None" {
            dataPoint.coolantTemperature = Double(row[12])
        }
        
        if row[13] != "None" {
            dataPoint.ambientTemperature = Double(row[13])
        }
        
        if row[14] != "None" {
            dataPoint.throttlePosition = Double(row[14])
        }
        return dataPoint
    }
    
}


