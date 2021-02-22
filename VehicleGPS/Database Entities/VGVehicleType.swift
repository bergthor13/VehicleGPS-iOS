//
//  VGVehicle.swift
//  VehicleGPS
//
//  Created by Bergþór Þrastarson on 24/01/2020.
//  Copyright © 2020 Bergþór Þrastarson. All rights reserved.
//

import Foundation
import UIKit

class VGVehicleType {
    public var id: UUID?
    public var name: String?
    public var icon: UIImage?
    public var order: Int?
    
    init(type: VehicleType) {
        self.id = type.id
        self.name = type.name
        self.order = Int(type.order)
    }
    
    init() {
        
    }
    
    static func == (lhs: VGVehicleType, rhs: VGVehicleType) -> Bool {
        return lhs.id == rhs.id
    }
}
