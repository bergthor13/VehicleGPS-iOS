//
//  VGSettingsTableViewController.swift
//  VehicleGPS
//
//  Created by Bergþór Þrastarson on 05/10/2018.
//  Copyright © 2018 Bergþór Þrastarson. All rights reserved.
//

import UIKit

class VGSettingsTableViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.prefersLargeTitles = true
        self.title = "Stillingar"
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 3
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 { return "Almennt" }
        if section == 1 { return "GPS kubbur" }
        if section == 2 { return "Öryggisafrit og samstilling" }
        return ""
    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 { return 3 }
        if section == 1 { return 2 }
        if section == 2 { return 3 }
        return 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = UITableViewCell()
        if indexPath.section == 0 {
            if indexPath.row == 0 {
                cell = UITableViewCell.init(style: .default, reuseIdentifier: "unitsCell")
                cell.accessoryType = .disclosureIndicator
                cell.textLabel?.text = "Einingar"
            }
            if indexPath.row == 1 {
                cell = UITableViewCell.init(style: .default, reuseIdentifier: "gaugesCell")
                cell.accessoryType = .disclosureIndicator
                cell.textLabel?.text = "Mælar"
            }
            if indexPath.row == 2 {
                cell = UITableViewCell.init(style: .default, reuseIdentifier: "databaseCell")
                cell.accessoryType = .disclosureIndicator
                cell.textLabel?.text = "Gagnagrunnur"
            }
        }
        if indexPath.section == 1 {
            if indexPath.row == 0 {
                cell = UITableViewCell.init(style: .default, reuseIdentifier: "messagesCell")
                cell.accessoryType = .disclosureIndicator
                cell.textLabel?.text = "Skilaboð"
            }
            if indexPath.row == 1 {
                cell = UITableViewCell.init(style: .default, reuseIdentifier: "ForceColdStartCell")
                cell.accessoryType = .disclosureIndicator
                cell.textLabel?.text = "Neyða endurræsingu"
            }
        }

        if indexPath.section == 2 {
            if indexPath.row == 0 {
                cell = UITableViewCell.init(style: .default, reuseIdentifier: "messagesCell")
                cell.accessoryType = .disclosureIndicator
                cell.textLabel?.text = "Wi-Fi"
            }
            if indexPath.row == 1 {
                cell = UITableViewCell.init(style: .default, reuseIdentifier: "ForceColdStartCell")
                cell.accessoryType = .disclosureIndicator
                cell.textLabel?.text = "Dropbox"
            }
            if indexPath.row == 2 {
                cell = UITableViewCell.init(style: .default, reuseIdentifier: "ForceColdStartCell")
                cell.accessoryType = .disclosureIndicator
                cell.textLabel?.text = "SFTP"
            }
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            if indexPath.row == 0 {
            }
            if indexPath.row == 1 {
            }
            if indexPath.row == 2 {
                let databaseController = VGDatabaseTableViewController.init(style: .grouped)
                navigationController?.pushViewController(databaseController, animated: true)
            }
        }
        if indexPath.section == 1 {
            if indexPath.row == 0 {
            }
            if indexPath.row == 1 {
            }
        }

        if indexPath.section == 2 {
            if indexPath.row == 0 {
                let wifiController = VGWiFiTableViewController.init(style: .grouped)
                navigationController?.pushViewController(wifiController, animated: true)
            }
            if indexPath.row == 1 {
            }
            if indexPath.row == 2 {
            }
        }
    }
}