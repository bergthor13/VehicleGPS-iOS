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
        static let username = "gps"
        static let password = "easyprintsequence"
        static let remoteFolder = "/home/pi/Tracks/"
        static let deleteFolder = "/home/pi/DeletedTracks/"
    }
    
    struct persistentContainer {
        static let name = "VehicleGPS"
    }
}
