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
        beingProcessed = false
        
        trackPoints = [VGDataPoint]()
    }
    
    func getCoordinateList() -> [CLLocationCoordinate2D] {
        var list = [CLLocationCoordinate2D]()
        for point in trackPoints {
            list.append(CLLocationCoordinate2D(latitude: point.latitude, longitude: point.longitude))
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
        return "duration: \(duration) distance: \(distance) fileName: \(fileName) fileSize: \(fileSize) timeStart: \(String(describing: timeStart)) trackPoints: \(trackPoints.count)"
    }
}

