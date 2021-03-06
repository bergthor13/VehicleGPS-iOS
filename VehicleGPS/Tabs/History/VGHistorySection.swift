//
//  HistorySection.swift
//  VehicleGPS
//
//  Created by Bergþór Þrastarson on 23/12/2019.
//  Copyright © 2019 Bergþór Þrastarson. All rights reserved.
//

import Foundation

class VGHistorySection {
    var sectionID: String = ""
    var summaries = [VGTracksSummary]()
    var dateDescription: String = ""

    init(title: String) {
        self.sectionID = title
    }
}
