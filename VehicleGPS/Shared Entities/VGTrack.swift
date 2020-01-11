//
//  VGTrack.swift
//  VehicleGPS
//
//  Created by Bergþór Þrastarson on 01/06/2019.
//  Copyright © 2019 Bergþór Þrastarson. All rights reserved.
//

import Foundation
import CoreLocation

class VGTrack {
    var duration:Double // In seconds
    var distance:Double // In kilometers
    var fileName:String
    var fileSize:Int // In bytes
    var timeStart:Date?
    var trackPoints:[VGDataPoint]
    var minLat:Double
    var maxLat:Double
    var minLon:Double
    var maxLon:Double
    var processed:Bool
    var isRemote:Bool
    var beingProcessed = false
    var averageSpeed:Double {
        get {
            return distance/duration/60/60
        }
    }
    
    init() {
        duration = 0
        distance = 0
        fileName = ""
        fileSize = 0
        minLat = -200.0
        maxLat = 200.0
        minLon = -200.0
        maxLon = 200.0
        processed = false
        isRemote = false
        
        trackPoints = [VGDataPoint]()
    }
    
    var hasOBDData: Bool {
        if self.trackPoints.count == 0 {
            return false
        }
        for point in self.trackPoints {
            if point.hasOBDData {
                return true
            }
        }
        return false
    }
    
    var isoStartTime : String {
        guard let startTime = timeStart else {
            return fileName
        }
        return String(describing: startTime)
    }
    
    func getISOStartTime() -> Date? {
        if timeStart != nil {
            return timeStart
        }
        
        
        return nil
    }
    
    func getCoordinateList() -> [CLLocationCoordinate2D] {
        guard let firstPoint = trackPoints.first else {
            return []
        }
        var list = [CLLocationCoordinate2D]()

        if let firstLatitude = firstPoint.latitude, let firstLongitude = firstPoint.longitude {
            if firstPoint.hasGoodFix() {
                list.append(CLLocationCoordinate2D(latitude: firstLatitude, longitude: firstLongitude))
            }
        }
        for (point1, point2) in zip(trackPoints, trackPoints.dropFirst()) {
            guard let latitude1 = point1.latitude, let longitude1 = point1.longitude else {
                continue
            }
            guard let latitude2 = point2.latitude, let longitude2 = point2.longitude else {
                continue
            }
            let duration = point2.timestamp?.timeIntervalSince(point1.timestamp!)
            let lastCoord = CLLocation(latitude: latitude1, longitude: longitude1)
            let coord = CLLocation(latitude: latitude2, longitude: longitude2)
            
            let distance = coord.distance(from: lastCoord)
            
            let speed = (distance/duration!)*3.6
            if speed > 0.5 && point1.hasGoodFix() && point2.hasGoodFix() {
                list.append(CLLocationCoordinate2D(latitude: latitude2, longitude: longitude2))
            }
            
        }
        return list
    }
}

extension VGTrack: Equatable {
    static func == (lhs: VGTrack, rhs: VGTrack) -> Bool {
        return lhs.fileName == rhs.fileName
    }
}

extension VGTrack: CustomStringConvertible {
    var description: String {
        return "timeStart: \(String(describing: timeStart!)), fileName: \(self.fileName)"
    }
}

