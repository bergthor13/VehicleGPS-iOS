//
//  VGTag.swift
//  VehicleGPS
//
//  Created by Bergþór Þrastarson on 2.2.2021.
//  Copyright © 2021 Bergþór Þrastarson. All rights reserved.
//

import Foundation

class VGTag {
    public var id: UUID?
    public var name: String?
    public var tracks: [VGTrack]!
    
    init(tag:Tag) {
        self.id = tag.id
        self.name = tag.name
        self.tracks = [VGTrack]()
    }
    
    init() {
        self.tracks = [VGTrack]()
    }
}

extension VGTag: Equatable {
    static func == (lhs: VGTag, rhs: VGTag) -> Bool {
        if rhs.id == nil || lhs.id == nil {
            return false
        }
        return lhs.id == rhs.id
    }
}
