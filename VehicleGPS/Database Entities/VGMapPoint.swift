//
//  VGMapPoint.swift
//  VehicleGPS
//
//  Created by Bergþór Þrastarson on 09/02/2020.
//  Copyright © 2020 Bergþór Þrastarson. All rights reserved.
//

import Foundation
import CoreLocation

class VGMapPoint {
    var latitude:Double
    var longitude:Double
    var timestamp:Date
    var relatedTrack: VGTrack?

    init(point:MapPoint) {
        self.latitude = point.latitude
        self.longitude = point.longitude
        self.timestamp = point.timeStamp!
    }
    
    init(point:CLLocationCoordinate2D, timestamp:Date) {
        self.latitude = point.latitude
        self.longitude = point.longitude
        self.timestamp = timestamp
    }
}

extension VGMapPoint: Equatable {
    static func == (lhs: VGMapPoint, rhs: VGMapPoint) -> Bool {
        return lhs.timestamp == rhs.timestamp
    }
}

extension VGMapPoint: Comparable {
    static func < (lhs: VGMapPoint, rhs: VGMapPoint) -> Bool {
        return lhs.timestamp < rhs.timestamp
    }
}
