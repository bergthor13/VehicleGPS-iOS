//
//  VGGraphGenerator.swift
//  VehicleGPS
//
//  Created by Bergþór Þrastarson on 16/08/2020.
//  Copyright © 2020 Bergþór Þrastarson. All rights reserved.
//

import Foundation

protocol VGGraphGenerator {
    func generate(from track:VGTrack) -> TrackGraphViewConfig
}
