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
    }

    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {return "Hlutir"}
        else if section == 1 {return "Skrár"}
        else {return nil}
    }
    override func numberOfSections(in tableView: UITableView) -> Int {
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
}
