//
//  VGHistoryNavigationController.swift
//  VehicleGPS
//
//  Created by Bergþór Þrastarson on 05/10/2018.
//  Copyright © 2018 Bergþór Þrastarson. All rights reserved.
//

import UIKit

class VGHistoryNavigationController: UINavigationController {

    override func viewDidLoad() {
        super.viewDidLoad()
        let historyController = VGHistoryTableViewController.init(style: .insetGrouped)
        self.navigationBar.prefersLargeTitles = true
        self.pushViewController(historyController, animated: false)
    }
}
