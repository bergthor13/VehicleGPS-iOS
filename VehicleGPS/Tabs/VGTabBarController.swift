//
//  VGTabBarController.swift
//  VehicleGPS
//
//  Created by Bergþór Þrastarson on 05/10/2018.
//  Copyright © 2018 Bergþór Þrastarson. All rights reserved.
//

import UIKit

class VGTabBarController: UITabBarController {
    let logsTableViewController = VGLogsTableViewController(style: .plain)
    var controllers = [
        UINavigationController(rootViewController: VGHistoryTableViewController(style: .grouped)),
        //UINavigationController(rootViewController: VGJourneyTableViewController(style: .grouped)),
        UINavigationController(rootViewController: VGVehiclesTableViewController(style: .grouped)),
        UINavigationController(rootViewController: VGSettingsTableViewController(style: .grouped))
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 15, *) {
            UINavigationBar.appearance().scrollEdgeAppearance = UINavigationBarAppearance()
            UITabBar.appearance().scrollEdgeAppearance = UITabBarAppearance()
        }
        for controller in controllers {
            self.addChild(controller)
        }

        self.selectedIndex = 0
        addObserver(selector: #selector(deviceConnected(_:)), name: .deviceConnected)
        addObserver(selector: #selector(deviceDisconnected(_:)), name: .deviceDisconnected)
    }
    
    func addObserver(selector: Selector, name: Notification.Name) {
        NotificationCenter.default.addObserver(self, selector: selector, name: name, object: nil)
    }
    
    @objc func deviceConnected(_ notification: Notification) {
        DispatchQueue.main.async {
            self.controllers.insert(UINavigationController(rootViewController: self.logsTableViewController), at: 0)
            self.setViewControllers(self.controllers, animated: true)
        }
    }
    
    @objc func deviceDisconnected(_ notification: Notification) {
        DispatchQueue.main.async {
            if self.controllers.first?.children.first is VGLogsTableViewController {
                self.controllers = Array(self.controllers.dropFirst())
                self.setViewControllers(self.controllers, animated: true)
            }
        }
    }
    
}
