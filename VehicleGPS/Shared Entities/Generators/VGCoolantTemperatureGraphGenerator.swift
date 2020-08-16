//
//  VGSpeedGraphGenerator.swift
//  VehicleGPS
//
//  Created by Bergþór Þrastarson on 16/08/2020.
//  Copyright © 2020 Bergþór Þrastarson. All rights reserved.
//

import Foundation
import UIKit

class VGCoolantTemperatureGraphGenerator: VGGraphGenerator {
    
    func generate(from track:VGTrack) -> TrackGraphViewConfig {
        let configuration = TrackGraphViewConfig()
        configuration.name = Strings.coolTemp
        for point in track.trackPoints {
            if point.latitude == nil && point.longitude == nil {
                continue
            }
            if !point.hasGoodFix() {
                continue
            }
            guard let time = point.timestamp, let coolantTemperature = point.coolantTemperature else {
                continue
            }
            configuration.numbersList.append((time, Double(coolantTemperature)))
        }
        configuration.color = UIColor(red: 165/255.0, green: 50/255.0, blue: 45/255.0, alpha: 0.3)
        configuration.startTime = track.timeStart
        configuration.endTime = track.timeStart?.addingTimeInterval(track.duration)

        return configuration

    }
}
