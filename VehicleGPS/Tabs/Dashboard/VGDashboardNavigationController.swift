//
//  VGDashboardNavigationController.swift
//  VehicleGPS
//
//  Created by Bergþór Þrastarson on 05/10/2018.
//  Copyright © 2018 Bergþór Þrastarson. All rights reserved.
//

import UIKit

class VGDashboardNavigationController: UINavigationController {

    override func viewDidLoad() {
        super.viewDidLoad()
        let dashController = DashboardViewController.init()
        dashController.view.backgroundColor = .systemBackground
        self.pushViewController(dashController, animated: false)
    }
}
