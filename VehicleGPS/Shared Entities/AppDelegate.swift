//
//  AppDelegate.swift
//  VehicleGPS
//
//  Created by Bergþór Þrastarson on 03/06/2019.
//  Copyright © 2019 Bergþór Þrastarson. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    var dataStore = VGDataStore()
    var fileManager = VGFileManager()
    var tabController = VGTabBarController()
    var snapshotter: VGSnapshotMaker!
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        snapshotter = VGSnapshotMaker(fileManager: self.fileManager, dataStore: self.dataStore)
        self.window = UIWindow(frame: UIScreen.main.bounds)
        self.window?.tintColor = UIColor.init(named: "appColor")
        self.window?.rootViewController = tabController
        self.window?.makeKeyAndVisible()
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
    }
    
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        print(url)
        return true
    }
    
    func application(_ app: UIApplication,
                       open url: URL,
                       options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        
        let importController = VGImportFileTableViewController(style: .insetGrouped, fileUrl: url)
        let navController = UINavigationController(rootViewController: importController)
        tabController.present(navController, animated: true)
        return true
        
    }
    
    func application(_ application: UIApplication, handleOpen url: URL) -> Bool {
        return true
    }
}
