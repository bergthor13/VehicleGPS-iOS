//
//  HeaderDateParser.swift
//  VehicleGPS
//
//  Created by Bergþór Þrastarson on 26/01/2020.
//  Copyright © 2020 Bergþór Þrastarson. All rights reserved.
//

import Foundation
import UIKit

class HeaderParseDateFormatter: DateFormatter {
    override init() {
        super.init()
        configure()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }
    
    func configure() {
        self.dateFormat = "yyyy-MM-dd"
        self.locale = Locale(identifier: "en_US_POSIX")
    }
}
