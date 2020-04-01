//
//  VGTabBarController.swift
//  VehicleGPS
//
//  Created by Bergþór Þrastarson on 05/10/2018.
//  Copyright © 2018 Bergþór Þrastarson. All rights reserved.
//

import UIKit

class VGTabBarController: UITabBarController {
    let controllers = [
        VGLogsTableViewController(style: .plain),
        VGHistoryTableViewController(style: .insetGrouped),
        VGJourneyTableViewController(style: .insetGrouped),
        VGVehiclesTableViewController(style: .insetGrouped),
        VGSettingsTableViewController(style: .grouped)
    ]
    override func viewDidLoad() {
        super.viewDidLoad()
        for controller in controllers {
            self.addChild(UINavigationController(rootViewController: controller))
        }
        self.selectedIndex = 0
    }
}
