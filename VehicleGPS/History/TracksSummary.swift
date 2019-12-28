//
//  TracksSummary.swift
//  VehicleGPS
//
//  Created by Bergþór Þrastarson on 15/12/2019.
//  Copyright © 2019 Bergþór Þrastarson. All rights reserved.
//

import Foundation


class TracksSummary {
    var summaryID: String = ""
    var distance: Double = 0.0
    var trackCount: Int = 0
    var dateDescription: String = ""
    
    init(title:String) {
        self.summaryID = title
    }
}
