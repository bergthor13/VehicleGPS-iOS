//
//  VGTabBarController.swift
//  VehicleGPS
//
//  Created by Bergþór Þrastarson on 05/10/2018.
//  Copyright © 2018 Bergþór Þrastarson. All rights reserved.
//

import UIKit

class VGTabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.addChild(UINavigationController(rootViewController: VGLogsTableViewController(style: .plain)))
        self.addChild(UINavigationController(rootViewController: VGHistoryTableViewController(style: .insetGrouped)))
        self.addChild(UINavigationController(rootViewController: VGJourneyTableViewController(style: .insetGrouped)))
        self.addChild(UINavigationController(rootViewController: VGVehiclesTableViewController(style: .insetGrouped)))
        self.addChild(UINavigationController(rootViewController: VGSettingsTableViewController(style: .grouped)))

        self.selectedIndex = 0
    }
}
