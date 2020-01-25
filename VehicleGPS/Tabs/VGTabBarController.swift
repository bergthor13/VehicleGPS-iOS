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
//        let dashboardController = VGDashboardNavigationController()
//        dashboardController.tabBarItem = UITabBarItem(title: "Mælaborð",
//                                                      image: UIImage(imageLiteralResourceName: "DashboardIcon"), tag: 0)
//        self.addChild(dashboardController)
        
        let logsController = VGLogsNavigationViewController()
        logsController.tabBarItem = UITabBarItem(title: NSLocalizedString("Ferlar", comment: "Vehicles Title"),
                                                 image: UIImage(imageLiteralResourceName: "LogIcon"),
                                                 tag: 0)
        self.addChild(logsController)

        let historyController = VGHistoryNavigationController(nibName: "HistoryView", bundle: nil)
        historyController.tabBarItem = UITabBarItem(title: NSLocalizedString("Saga", comment: "Vehicles Title"),
                                                    image: UIImage(systemName: "memories"),
                                                    tag: 0)
        self.addChild(historyController)
        
        let journeysController = VGJourneyNavigationViewController()
        journeysController.tabBarItem = UITabBarItem(title: NSLocalizedString("Ferðalög", comment: "Vehicles Title"),
                                                     image: UIImage(systemName: "globe"),
                                                     tag: 0)
        self.addChild(journeysController)
        
        let vehiclesController = VGVehiclesTableViewController(style: .insetGrouped)
        
        vehiclesController.tabBarItem = UITabBarItem(title: NSLocalizedString("Farartæki", comment: "Vehicles Title"),
                                                     image: UIImage(systemName: "car"),
                                                     tag: 0)
        self.addChild(UINavigationController(rootViewController: vehiclesController))
        
        let settingsController = VGSettingsNavigationController()
        settingsController.tabBarItem = UITabBarItem(title: NSLocalizedString("Stillingar", comment: "Vehicles Title"),
                                                     image: UIImage(systemName: "gear"),
                                                     tag: 0)
        self.addChild(settingsController)

        self.selectedIndex = 0
    }
}
