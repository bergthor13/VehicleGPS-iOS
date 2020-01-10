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

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        self.window = UIWindow(frame: UIScreen.main.bounds)
        
        self.dataStore = VGDataStore()
        self.fileManager = VGFileManager()
        
        let tabController = VGTabBarController()
        
        let dashboardController = VGDashboardNavigationController()
        dashboardController.tabBarItem = UITabBarItem(title: "Mælaborð", image: nil, tag: 0)
        tabController.addChild(dashboardController)
        
        let historyController = VGHistoryNavigationController(nibName: "HistoryView", bundle: nil)
        historyController.tabBarItem = UITabBarItem(title: "Saga", image:nil, tag: 0)
        tabController.addChild(historyController)
        
        let logsController = VGLogsNavigationViewController()
        logsController.tabBarItem = UITabBarItem(title: "Ferlar", image:UIImage(imageLiteralResourceName: "LogIcon"), tag: 0)
        tabController.addChild(logsController)
        
        let settingsController = VGSettingsNavigationController()
        settingsController.tabBarItem = UITabBarItem(title: "Stillingar", image: nil, tag: 0)
        tabController.addChild(settingsController)
        tabController.selectedIndex = 2
        
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
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
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
