//
//  NewNetworkTableViewController.swift
//  VehicleGPS
//
//  Created by Bergþór Þrastarson on 22/11/2018.
//  Copyright © 2018 Bergþór Þrastarson. All rights reserved.
//

import UIKit

class NewNetworkTableViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 3
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = UITableViewCell()
        if indexPath.section == 0 {
            cell = UITableViewCell.init(style: .default, reuseIdentifier: "wifiCell")
            cell.accessoryType = .detailButton
            //cell.textLabel?.text = networks[indexPath.row]
        } else {
            cell = UITableViewCell.init(style: .default, reuseIdentifier: "wifiCell")
            cell.textLabel?.text = "Add Wi-Fi Network"
            cell.textLabel?.textColor = self.view.tintColor
        }

        return cell
    }
}
