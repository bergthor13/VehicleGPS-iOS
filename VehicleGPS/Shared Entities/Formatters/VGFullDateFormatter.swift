//
//  VGFullDateFormatter.swift
//  VehicleGPS
//
//  Created by Bergþór Þrastarson on 19/04/2020.
//  Copyright © 2020 Bergþór Þrastarson. All rights reserved.
//

import Foundation

class VGFullDateFormatter: DateFormatter {
    override init() {
        super.init()
        configure()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }
    
    func configure() {
        self.locale = Locale.current
        self.dateStyle = .long
        self.timeStyle = .medium
    }
}
