//
//  VGWiFiTableViewController.swift
//  VehicleGPS
//
//  Created by Bergþór Þrastarson on 22/11/2018.
//  Copyright © 2018 Bergþór Þrastarson. All rights reserved.
//

import UIKit

class VGDatabaseTableViewController: UITableViewController {

    var dataTypes = [String]()
    var fileTypes = [String]()
    var dataStore = (UIApplication.shared.delegate as! AppDelegate).dataStore!
    var fileManager = (UIApplication.shared.delegate as! AppDelegate).fileManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Gagnagrunnur"
        dataTypes = ["Track", "DataPoint"]
        fileTypes = ["Ferlaskrár", "Yfirlitsmyndir"]
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {return "Hlutir"}
        else if section == 1 {return "Skrár"}
        else {return nil}
    }
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 3
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 { return 2 }
        else if section == 1 {return 2}
        else { return 1 }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = UITableViewCell()
        if indexPath.section == 0 {
            cell = UITableViewCell.init(style: .value1, reuseIdentifier: "wifiCell")
            cell.textLabel?.text = dataTypes[indexPath.row]
            cell.detailTextLabel?.text = String(dataStore.countAllData(dataTypes[indexPath.row]))
        }
        else if indexPath.section == 1 {
            cell = UITableViewCell.init(style: .value1, reuseIdentifier: "wifiCell")
            cell.textLabel?.text = fileTypes[indexPath.row]
            if indexPath.row == 0 {
                cell.detailTextLabel?.text = String(fileManager.getTrackFileCount())
            } else if indexPath.row == 1 {
                cell.detailTextLabel?.text = String(fileManager.getTrackImageCount())
            }
            
        } else if indexPath.section == 2 {
            cell = UITableViewCell.init(style: .default, reuseIdentifier: "wifiCell")
            cell.textLabel?.text = "Framkvæma gagnagrunnsviðhald"
            cell.textLabel?.textColor = view.tintColor
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            let alert = UIAlertController(title: "Eyða öllum \(dataTypes[indexPath.row]) hlutum", message: "Ertu viss um að þú viljir eyða öllum \(dataTypes[indexPath.row]) hlutunum?", preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: "Eyða", style: .destructive, handler: { (action) in
                self.dataStore.deleteAllData(self.dataTypes[indexPath.row])
            }))
            
            alert.addAction(UIAlertAction(title: "Hætta við", style: .cancel, handler: nil))
            present(alert, animated: true, completion: nil)
        }
        if indexPath.section == 2 {
            
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
