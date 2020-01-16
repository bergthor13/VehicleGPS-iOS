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
        logsController.tabBarItem = UITabBarItem(title: "Ferlar",
                                                 image: UIImage(imageLiteralResourceName: "LogIcon"),
                                                 tag: 0)
        self.addChild(logsController)

        let historyController = VGHistoryNavigationController(nibName: "HistoryView", bundle: nil)
        historyController.tabBarItem = UITabBarItem(title: "Saga",
                                                    image: UIImage(imageLiteralResourceName: "HistoryIcon"),
                                                    tag: 0)
        self.addChild(historyController)
        
        let journeysController = VGJourneyNavigationViewController()
        journeysController.tabBarItem = UITabBarItem(title: "Ferðalög",
                                                     image: UIImage(imageLiteralResourceName: "JourneyIcon"),
                                                     tag: 0)
        self.addChild(journeysController)
        
        let settingsController = VGSettingsNavigationController()
        settingsController.tabBarItem = UITabBarItem(title: "Stillingar",
                                                     image: UIImage(imageLiteralResourceName: "SettingsIcon"),
                                                     tag: 0)
        self.addChild(settingsController)

        self.selectedIndex = 0
    }
}
