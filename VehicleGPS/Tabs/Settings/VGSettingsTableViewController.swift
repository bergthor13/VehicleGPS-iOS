//
//  VGSettingsTableViewController.swift
//  VehicleGPS
//
//  Created by Bergþór Þrastarson on 05/10/2018.
//  Copyright © 2018 Bergþór Þrastarson. All rights reserved.
//

import UIKit
import NetworkExtension

class VGSettingsTableViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.prefersLargeTitles = true
    }
    
    override init(style: UITableView.Style) {
        super.init(style: style)
        initializeTableViewController()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initializeTableViewController()

    }

    func initializeTableViewController() {
        self.navigationController?.navigationBar.prefersLargeTitles = true
        self.title = Strings.titles.settings
        tabBarItem = UITabBarItem(title: Strings.titles.settings,
                                  image: Icons.settings,
                                  tag: 0)
    }
    

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 { return Strings.settings.general }
        if section == 1 { return nil }
        return ""
    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 { return 2 }
        if section == 1 { return 1 }
        return 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = UITableViewCell()
        if indexPath.section == 0 {
            if indexPath.row == 0 {
                cell = UITableViewCell.init(style: .default, reuseIdentifier: Strings.dummyIdentifier)
                cell.accessoryType = .disclosureIndicator
                cell.textLabel?.text = Strings.titles.database
            }
            if indexPath.row == 1 {
                cell = UITableViewCell.init(style: .default, reuseIdentifier: Strings.dummyIdentifier)
                cell.accessoryType = .disclosureIndicator
                cell.textLabel?.text = Strings.titles.vgpsDevice
            }

        }
        if indexPath.section == 1 {
            if indexPath.row == 0 {
                cell = UITableViewCell.init(style: .default, reuseIdentifier: Strings.dummyIdentifier)
                cell.textLabel?.textColor = view.tintColor
                cell.textLabel?.text = Strings.settings.connectToVGPS

            }
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            if indexPath.row == 0 {
                let databaseController = VGDatabaseTableViewController.init(style: .grouped)
                navigationController?.pushViewController(databaseController, animated: true)

            } else if indexPath.row == 1 {
                let deviceSettings = VGVGPSDeviceSettingsTableViewController.init(style: .grouped)
                navigationController?.pushViewController(deviceSettings, animated: true)
            }
        }
        if indexPath.section == 1 {
            if indexPath.row == 0 {
                let configuration = NEHotspotConfiguration(ssid: Constants.wireless.ssid, passphrase: Constants.wireless.password, isWEP: false)
                configuration.joinOnce = true
                configuration.hidden = true
                NEHotspotConfigurationManager.shared.apply(configuration) { (error) in
                    if error == nil {
                        if let delegate = UIApplication.shared.delegate as? AppDelegate {
                            delegate.deviceCommunicator.reconnectToVehicleGPS()
                        }

                    }
                }
                tableView.deselectRow(at: indexPath, animated: true)
            }
        }
    }
}
