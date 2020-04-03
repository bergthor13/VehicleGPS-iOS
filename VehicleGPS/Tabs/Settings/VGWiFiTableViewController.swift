//
//  VGWiFiTableViewController.swift
//  VehicleGPS
//
//  Created by Bergþór Þrastarson on 22/11/2018.
//  Copyright © 2018 Bergþór Þrastarson. All rights reserved.
//

import UIKit

class VGWiFiTableViewController: UITableViewController {

    var networks = [String]()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Wi-Fi"
        networks = ["Hnodravellir 34", "iPhone 6s Plus"]
    }

    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Saved Networks"
        } else {
            return nil
        }
    }
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return networks.count
        } else {
            return 1
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = UITableViewCell()
        if indexPath.section == 0 {
            cell = UITableViewCell.init(style: .default, reuseIdentifier: Strings.dummyIdentifier)
            cell.accessoryType = .detailButton
            cell.textLabel?.text = networks[indexPath.row]
        } else {
            cell = UITableViewCell.init(style: .default, reuseIdentifier: Strings.dummyIdentifier)
            cell.textLabel?.text = "Add Wi-Fi Network"
            cell.textLabel?.textColor = self.view.tintColor
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 1 {
            let newNetwork = NewNetworkTableViewController.init(style: .grouped)
            present(newNetwork, animated: true, completion: nil)
        }
    }
}
