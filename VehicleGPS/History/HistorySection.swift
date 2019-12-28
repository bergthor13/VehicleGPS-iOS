//
//  HistorySection.swift
//  VehicleGPS
//
//  Created by Bergþór Þrastarson on 23/12/2019.
//  Copyright © 2019 Bergþór Þrastarson. All rights reserved.
//

import Foundation

class HistorySection {
    var sectionID: String = ""
    var summaries = [TracksSummary]()
    var dateDescription: String = ""

    
    init(title:String) {
        self.sectionID = title
    }
}
