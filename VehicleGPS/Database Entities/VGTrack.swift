//
//  VGTrack.swift
//  VehicleGPS
//
//  Created by Bergþór Þrastarson on 01/06/2019.
//  Copyright © 2019 Bergþór Þrastarson. All rights reserved.
//

import Foundation
import CoreLocation
import CoreData

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
    var isLocal:Bool
    var beingProcessed = false
    var vehicle:VGVehicle?
    var averageSpeed:Double {
        get {
            return distance/duration/60/60
        }
    }
    
    init(track:Track) {
        // Database stored values
        self.duration = track.duration
        self.distance = track.distance
        if let fileName = track.fileName {
            self.fileName = fileName
        } else {
            self.fileName = ""
        }
        self.fileSize = Int(track.fileSize)
        self.timeStart = track.timeStart
        self.minLat = track.minLat
        self.maxLat = track.maxLat
        self.minLon = track.minLon
        self.maxLon = track.maxLon
        self.processed = track.processed
        
        if let vehicle = track.vehicle {
            self.vehicle = VGVehicle(vehicle:vehicle)
        }

        trackPoints = [VGDataPoint]()

        // Memory stored values
        self.isRemote = false
        self.isLocal = false

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
        isLocal = false
        
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
    
    func process() {
        var lastDataPoint: VGDataPoint?
        self.distance = 0.0
        minLat = -200.0
        maxLat = 200.0
        minLon = -200.0
        maxLon = 200.0
        for dataPoint in trackPoints {
            guard let fixType = dataPoint.fixType else {
                continue
            }
            if fixType > 1 && self.timeStart == nil && dataPoint.timestamp! > Date(timeIntervalSince1970: 1388534400) {
                self.timeStart = dataPoint.timestamp
            }
            
            if dataPoint.hasGoodFix() {
                guard let latitude = dataPoint.latitude, let longitude = dataPoint.longitude else {
                    continue
                }
                
                if self.minLat < latitude {
                    self.minLat = latitude
                }
                if self.maxLat > latitude {
                    self.maxLat = latitude
                }
                if self.minLon < longitude {
                    self.minLon = longitude
                }
                if self.maxLon > longitude {
                    self.maxLon = longitude
                }

                if lastDataPoint != nil && lastDataPoint!.hasGoodFix() {
                    guard let lastLatitude = lastDataPoint!.latitude, let lastLongitude = lastDataPoint!.longitude else {
                        continue
                    }
                    let coord = CLLocation(latitude: latitude, longitude: longitude)
                    let lastCoord = CLLocation(latitude: lastLatitude, longitude: lastLongitude)

                    self.distance += coord.distance(from: lastCoord)/1000
                }
            }
            
            lastDataPoint = dataPoint
        }
        
        if self.timeStart != nil {
            self.duration = Double(self.trackPoints.last!.timestamp!.timeIntervalSince(self.timeStart!))
        }
        self.processed = true
    }
}

extension VGTrack: Equatable {
    static func == (lhs: VGTrack, rhs: VGTrack) -> Bool {
        return lhs.fileName == rhs.fileName
    }
}

extension VGTrack: CustomStringConvertible {
    var description: String {
        guard let timeStart = timeStart else {
            return "fileName: \(self.fileName)"
        }
        return "fileName: \(self.fileName), timeStart: \(String(describing: timeStart)), maxLat: \(self.maxLat), maxLon: \(self.maxLon), minLat: \(self.minLat), minLon: \(self.minLon)"
    }
}

