//
//  VGSettingsNavigationController.swift
//  VehicleGPS
//
//  Created by Bergþór Þrastarson on 05/10/2018.
//  Copyright © 2018 Bergþór Þrastarson. All rights reserved.
//

import UIKit

class VGSettingsNavigationController: UINavigationController {

    override func viewDidLoad() {
        super.viewDidLoad()
        let tvController = VGSettingsTableViewController.init(style: .insetGrouped)
        self.pushViewController(tvController, animated: false)
        // Do any additional setup after loading the view.
    }
}
