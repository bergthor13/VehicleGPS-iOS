//
//  AppDelegate.swift
//  VehicleGPS
//
//  Created by Bergþór Þrastarson on 03/06/2019.
//  Copyright © 2019 Bergþór Þrastarson. All rights reserved.
//

import UIKit
import CoreData
import NetworkExtension

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    var dataStore: VGDataStore?
    var fileManager: VGFileManager?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        self.window = UIWindow(frame: UIScreen.main.bounds)
        
        self.dataStore = VGDataStore()
        self.fileManager = VGFileManager()
        
        let tabController = VGTabBarController()
        
        let dashboardController = VGDashboardNavigationController()
        dashboardController.tabBarItem = UITabBarItem(title: "Mælaborð",
                                                      image: nil, tag: 0)
        tabController.addChild(dashboardController)
        
        let logsController = VGLogsNavigationViewController()
        logsController.tabBarItem = UITabBarItem(title: "Ferlar",
                                                 image: UIImage(imageLiteralResourceName: "LogIcon"),
                                                 tag: 0)
        tabController.addChild(logsController)

        let historyController = VGHistoryNavigationController(nibName: "HistoryView", bundle: nil)
        historyController.tabBarItem = UITabBarItem(title: "Saga",
                                                    image: nil,
                                                    tag: 0)
        tabController.addChild(historyController)
        
        let journeysController = VGJourneyNavigationViewController()
        journeysController.tabBarItem = UITabBarItem(title: "Ferðalög",
                                                     image: nil,
                                                     tag: 0)
        tabController.addChild(journeysController)
        
        let settingsController = VGSettingsNavigationController()
        settingsController.tabBarItem = UITabBarItem(title: "Stillingar",
                                                     image: nil,
                                                     tag: 0)
        tabController.addChild(settingsController)
        tabController.selectedIndex = 1
        
        self.window?.rootViewController = tabController
        self.window?.makeKeyAndVisible()
        
        let configuration = NEHotspotConfiguration(ssid: "VehicleGPS", passphrase: "easyprintsequence", isWEP: false)
        configuration.joinOnce = true
        configuration.hidden = true
//        NEHotspotConfigurationManager.shared.apply(configuration) { (error) in
//            print(error)
//        }
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
    }

    func applicationWillTerminate(_ application: UIApplication) {
        //self.saveContext()
    }
}

extension UIColor {
    convenience init(red: Int, green: Int, blue: Int) {
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")
        
        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
    }
    
    convenience init(rgb: Int) {
        self.init(
            red: (rgb >> 16) & 0xFF,
            green: (rgb >> 8) & 0xFF,
            blue: rgb & 0xFF
        )
    }
}

public extension UIImage {
    convenience init?(color: UIColor, size: CGSize = CGSize(width: 1, height: 1)) {
        let rect = CGRect(origin: .zero, size: size)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0.0)
        color.setFill()
        UIRectFill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        guard let cgImage = image?.cgImage else { return nil }
        self.init(cgImage: cgImage)
    }
}
