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
        self.title = "Settings"
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
        if section == 0 { return "General" }
        if section == 1 { return "GPS Chip" }
        if section == 2 { return "Backup and Sync" }
        return ""
    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 { return 2 }
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
                cell.textLabel?.text = "Units"
            }
            if indexPath.row == 1 {
                cell = UITableViewCell.init(style: .default, reuseIdentifier: "gaugesCell")
                cell.accessoryType = .disclosureIndicator
                cell.textLabel?.text = "Gauges"
            }
        }
        if indexPath.section == 1 {
            if indexPath.row == 0 {
                cell = UITableViewCell.init(style: .default, reuseIdentifier: "messagesCell")
                cell.accessoryType = .disclosureIndicator
                cell.textLabel?.text = "Messages"
            }
            if indexPath.row == 1 {
                cell = UITableViewCell.init(style: .default, reuseIdentifier: "ForceColdStartCell")
                cell.accessoryType = .disclosureIndicator
                cell.textLabel?.text = "Force Cold Start"
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
 

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
