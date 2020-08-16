//
//  VGSpeedGraphGenerator.swift
//  VehicleGPS
//
//  Created by Bergþór Þrastarson on 16/08/2020.
//  Copyright © 2020 Bergþór Þrastarson. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation

class VGElevationGraphGenerator: VGGraphGenerator {
    
    func generate(from track:VGTrack) -> TrackGraphViewConfig {
        let configuration = TrackGraphViewConfig()
        configuration.name = Strings.elevation
        for point in track.trackPoints {
            if point.latitude == nil && point.longitude == nil {
                continue
            }
            if !point.hasGoodFix() {
                continue
            }
            guard let time = point.timestamp, let ele = point.elevation else {
                continue
            }
            configuration.numbersList.append((time, ele))
        }
        configuration.color = UIColor(red: 0, green: 0.8, blue: 0, alpha: 0.3)
        configuration.startTime = track.timeStart
        configuration.endTime = track.timeStart?.addingTimeInterval(track.duration)

        return configuration

    }
}
