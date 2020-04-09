//
//  Constants.swift
//  VehicleGPS
//
//  Created by Bergþór Þrastarson on 03/04/2020.
//  Copyright © 2020 Bergþór Þrastarson. All rights reserved.
//

import Foundation

struct Constants {
    struct wireless {
        static let ssid = "VehicleGPS"
        static let password = "easyprintsequence"
    }
    
    struct sftp {
        static let host = "cargps.local"
        static let username = "pi"
        static let password = "easyprintsequence"
    }
}
