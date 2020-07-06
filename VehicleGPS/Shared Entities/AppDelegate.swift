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
    var deviceCommunicator: DeviceCommunicator!
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        snapshotter = VGSnapshotMaker(fileManager: self.fileManager, dataStore: self.dataStore)
        deviceCommunicator = DeviceCommunicator()
        self.window = UIWindow(frame: UIScreen.main.bounds)
        self.window?.tintColor = UIColor.init(named: "appColor")

        let splitViewController = SplitViewController(style: .doubleColumn)
        splitViewController.preferredDisplayMode = .oneBesideSecondary
        let primary = UICollectionViewController(collectionViewLayout: UICollectionViewLayout())
        primary.navigationController?.navigationBar.prefersLargeTitles = true
        primary.navigationItem.largeTitleDisplayMode = .always
        primary.collectionView.backgroundColor = .clear
        primary.title = "VehicleGPS"
        
        splitViewController.setViewController(primary, for: .primary)
        splitViewController.setViewController(VGLogsTableViewController(style: .plain), for: .secondary)
        splitViewController.setViewController(tabController, for: .compact)

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
