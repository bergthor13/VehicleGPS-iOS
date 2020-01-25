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
    var beingProcessed = false
    var averageSpeed:Double {
        get {
            return distance/duration/60/60
        }
    }
    
    init(object:NSManagedObject) {
        if let duration = object.value(forKey: "duration") as? Double {
            self.duration = duration
        } else {
            self.duration = 0.0
        }
        
        if let distance = object.value(forKey: "distance") as? Double {
            self.distance = distance
        } else {
            self.distance = 0.0
        }
        
        if let fileName = object.value(forKey: "fileName") as? String {
            self.fileName = fileName
        } else {
            self.fileName = ""
        }
        
        if let fileSize = object.value(forKey: "fileSize") as? Int {
            self.fileSize = fileSize
        } else {
            self.fileSize = 0
        }
        
        if let minLat = object.value(forKey: "minLat") as? Double {
            self.minLat = minLat
        } else {
            self.minLat = -200.0
        }
        
        if let maxLat = object.value(forKey: "maxLat") as? Double {
            self.maxLat = maxLat
        } else {
            self.maxLat = 200
        }
        
        if let minLon = object.value(forKey: "minLon") as? Double {
            self.minLon = minLon
        } else {
            self.minLon = -200
        }
        
        if let maxLon = object.value(forKey: "maxLon") as? Double {
            self.maxLon = maxLon
        } else {
            self.maxLon = 200
        }
        
        if let processed = object.value(forKey: "processed") as? Bool {
            self.processed = processed
        } else {
            self.processed = false
        }
        
        self.isRemote = false
        
        trackPoints = [VGDataPoint]()
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

