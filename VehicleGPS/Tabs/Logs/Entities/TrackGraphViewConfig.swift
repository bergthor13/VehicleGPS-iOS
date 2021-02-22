//
//  TrackGraphViewConfig.swift
//  VehicleGPS
//
//  Created by Bergþór Þrastarson on 12/01/2020.
//  Copyright © 2020 Bergþór Þrastarson. All rights reserved.
//

import Foundation
import UIKit

enum TrackGraphType {
    case speed
    case elevation
    case pdop
    case horizontalAccuracy
    
    case rpm
    case engineLoad
    case throttlePosition
    case coolantTemperature
    case ambientTemperature
    
    case heartRate
    case cadence
    case power
    
    case none
}

class TrackGraphViewConfig {
    var type = TrackGraphType.none
    var name = ""
    var color = UIColor(red: 0, green: 0.8, blue: 0, alpha: 0.3)
    var showMinMaxValue = true
    var numbersList = [(Date,Double)]()
    var horizontalLineMarkers = [Double]()
    var verticalLineMarkers = [(Date, Double)]()
    var graphMinValue: Double?
    var graphMaxValue: Double?
    var inset = UIEdgeInsets(top: 12, left: 20, bottom: 12, right: 60)
    
    var startTime: Date?
    var endTime: Date?
}
