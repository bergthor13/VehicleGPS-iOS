//
//  VGLogsNavigationViewController.swift
//  VehicleGPS
//
//  Created by Bergþór Þrastarson on 05/10/2018.
//  Copyright © 2018 Bergþór Þrastarson. All rights reserved.
//

import UIKit

class VGLogsNavigationViewController: UINavigationController {

    override func viewDidLoad() {
        super.viewDidLoad()
        let logsController = VGLogsTableViewController.init(style: .plain)
        self.pushViewController(logsController, animated: false)
    }
}
