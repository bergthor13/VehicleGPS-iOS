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

class VGSpeedGraphGenerator: VGGraphGenerator {
    
    func generate(from track:VGTrack) -> TrackGraphViewConfig {
        let configuration = TrackGraphViewConfig()
        configuration.type = .speed
        configuration.name = Strings.speed
        for (point1, point2) in zip(track.trackPoints, track.trackPoints.dropFirst()) {
            guard let latitude1 = point1.latitude, let longitude1 = point1.longitude else {
                continue
            }
            guard let latitude2 = point2.latitude, let longitude2 = point2.longitude else {
                continue
            }
            
            if !point1.hasGoodFix() || !point2.hasGoodFix() {
                continue
            }
            
            guard let time1 = point1.timestamp, let time2 = point2.timestamp else {
                continue
            }
            
            let duration = time2.timeIntervalSince(time1)
            let coord = CLLocation(latitude: latitude2, longitude: longitude2)
            let lastCoord = CLLocation(latitude: latitude1, longitude: longitude1)
            
            let distance = coord.distance(from: lastCoord)
            let speed = (distance/duration)*3.6
            if speed < 1200 {
                configuration.numbersList.append((point1.timestamp!, (distance/duration)*3.6))
            }
        }
        configuration.showMinMaxValue = false
        configuration.color = UIColor(red: 0, green: 0.5, blue: 1, alpha: 0.3)
        configuration.horizontalLineMarkers = [30, 40, 50, 60, 70, 80, 90]
        configuration.startTime = track.timeStart
        configuration.endTime = track.timeStart?.addingTimeInterval(track.duration)

        return configuration

    }
}
