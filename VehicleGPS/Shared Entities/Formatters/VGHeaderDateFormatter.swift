//
//  HeaderDateParser.swift
//  VehicleGPS
//
//  Created by Bergþór Þrastarson on 26/01/2020.
//  Copyright © 2020 Bergþór Þrastarson. All rights reserved.
//

import Foundation
import UIKit

class VGHeaderDateFormatter: DateFormatter {
    let parsingFormatter = VGDateParsingFormatter()
    override init() {
        super.init()
        configure()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }
    
    func configure() {
        self.dateStyle = .full
        self.locale = Locale.current
        self.doesRelativeDateFormatting = true
    }
    
    func sectionKeyToDateString(sectionKey: String) -> String {
        guard let date = parsingFormatter.date(from: sectionKey) else {
            return ""
        }
        return self.string(from: date)

    }
}
