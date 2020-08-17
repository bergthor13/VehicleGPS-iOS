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
        VGHistoryTableViewController(style: .grouped),
        VGJourneyTableViewController(style: .grouped),
        VGVehiclesTableViewController(style: .grouped),
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
