//
//  VGVehicle.swift
//  VehicleGPS
//
//  Created by Bergþór Þrastarson on 24/01/2020.
//  Copyright © 2020 Bergþór Þrastarson. All rights reserved.
//

import Foundation
import UIKit

class VGVehicle {
    public var id: UUID?
    public var image: UIImage?
    public var mapColor: UIColor?
    public var name: String?
    public var tracks: [VGTrack]?
    
    init(vehicle:Vehicle) {
        self.id = vehicle.id
        self.name = vehicle.name
        self.mapColor = vehicle.mapColor as? UIColor
    }
    
    init() {
        
    }
    
    static func == (lhs: VGVehicle, rhs: VGVehicle) -> Bool {
        return lhs.id == rhs.id
    }
}
