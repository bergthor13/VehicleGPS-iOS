//
//  SpeedFormatter.swift
//  VehicleGPS
//
//  Created by Bergþór Þrastarson on 25/07/2020.
//  Copyright © 2020 Bergþór Þrastarson. All rights reserved.
//

import Foundation

class VGSpeedFormatter: MeasurementFormatter {
        override init() {
        super.init()
        configure()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }
    
    func configure() {
        self.numberFormatter.maximumFractionDigits = 2
        self.numberFormatter.minimumFractionDigits = 0
    }
}
