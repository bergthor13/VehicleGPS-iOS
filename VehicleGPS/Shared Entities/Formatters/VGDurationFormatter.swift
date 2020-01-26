//
//  VGDurationFormatter.swift
//  VehicleGPS
//
//  Created by Bergþór Þrastarson on 26/01/2020.
//  Copyright © 2020 Bergþór Þrastarson. All rights reserved.
//

import Foundation

class VGDurationFormatter: DateComponentsFormatter {
    override init() {
        super.init()
        configure()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }
    
    func configure() {
        self.unitsStyle = .abbreviated
        self.allowedUnits = [ .hour, .minute, .second ]
        self.zeroFormattingBehavior = [ .default ]
        var calendar = Calendar.current
        calendar.locale = Locale(identifier: "en")
        self.calendar = calendar
        
    }
}
