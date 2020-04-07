//
//  NotificationCenterNames.swift
//  VehicleGPS
//
//  Created by Bergþór Þrastarson on 19/02/2020.
//  Copyright © 2020 Bergþór Þrastarson. All rights reserved.
//

import Foundation

extension Notification.Name {
    static let vehicleUpdated = Notification.Name("vehicleUpdated")
    static let logsAdded = Notification.Name("logsAdded")
    static let logUpdated = Notification.Name("logUpdated")
    static let vehicleAddedToTrack = Notification.Name("vehiceAddedToTrack")
    static let previewImageStartingUpdate = Notification.Name("previewImageStartingUpdate")
    static let previewImageFinishingUpdate = Notification.Name("previewImageFinishingUpdate")
}
