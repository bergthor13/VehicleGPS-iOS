//
//  VGJourneyNavigationController.swift
//  VehicleGPS
//
//  Created by Bergþór Þrastarson on 11/01/2020.
//  Copyright © 2020 Bergþór Þrastarson. All rights reserved.
//

import UIKit

class VGJourneyNavigationViewController: UINavigationController {

    override func viewDidLoad() {
        super.viewDidLoad()
        let journeyController = VGJourneyTableViewController.init(style: .insetGrouped)
        self.navigationBar.prefersLargeTitles = true
        self.pushViewController(journeyController, animated: false)
    }
}
