//
//  AppDelegate.swift
//  VehicleGPS
//
//  Created by Bergþór Þrastarson on 03/06/2019.
//  Copyright © 2019 Bergþór Þrastarson. All rights reserved.
//

import UIKit
import NMSSH

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    var dataStore = VGDataStore()
    var fileManager = VGFileManager()
    var tabController = VGTabBarController()
    var snapshotter: VGSnapshotMaker!
    var deviceCommunicator: DeviceCommunicator!
    var trackDetailsViewController = VGLogDetailsViewController()
//    var splitViewController = UISplitViewController(style: .tripleColumn)

    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        NMSSHLogger.shared().isEnabled = false
        
        snapshotter = VGSnapshotMaker(fileManager: self.fileManager, dataStore: self.dataStore)
        deviceCommunicator = DeviceCommunicator()
        self.window = UIWindow(frame: UIScreen.main.bounds)
        self.window?.tintColor = UIColor.init(named: "appColor")
                
//        splitViewController.preferredDisplayMode = .twoOverSecondary
//
//        splitViewController.setViewController(VGSplitViewController(), for: .primary)
//        splitViewController.setViewController(VGLogsTableViewController(style: .plain), for: .supplementary)
//        splitViewController.setViewController(trackDetailsViewController, for: .secondary)
//        splitViewController.setViewController(tabController, for: .compact)
        

        self.window?.rootViewController = tabController
        self.window?.makeKeyAndVisible()
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        DispatchQueue.global(qos: .utility).async {
            self.deviceCommunicator.disconnectFromVehicleGPS()
        }
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        DispatchQueue.global(qos: .utility).async {
            self.deviceCommunicator.reconnectToVehicleGPS()
        }
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
    }

    func applicationWillTerminate(_ application: UIApplication) {
    }
    
    func application(_ app: UIApplication,
                       open url: URL,
                       options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        let importController = VGImportFileTableViewController(style: .insetGrouped, fileUrls: [url])
        let navController = UINavigationController(rootViewController: importController)
        tabController.present(navController, animated: true)
        return true
        
    }
}
