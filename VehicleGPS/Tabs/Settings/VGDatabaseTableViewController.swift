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
    var dataStore: VGDataStore!
    var fileManager: VGFileManager!

    override func viewDidLoad() {
        super.viewDidLoad()
        title = Strings.titles.database
        dataTypes = ["Track", "DataPoint", "MapPoint", "Vehicle"]
        fileTypes = [Strings.settings.logFiles, Strings.settings.previewImages]
        
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            self.dataStore = appDelegate.dataStore
            self.fileManager = appDelegate.fileManager
        }
        
    }

    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return Strings.settings.objects
        } else if section == 1 {
            return Strings.settings.files
        } else {
            return nil
        }
    }
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return dataTypes.count
        } else if section == 1 {
            return 2
        } else {
            return 1
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = UITableViewCell()

        if indexPath.section == 0 {
            cell = UITableViewCell.init(style: .value1, reuseIdentifier: Strings.dummyIdentifier)
            cell.textLabel?.text = dataTypes[indexPath.row]

            DispatchQueue.global(qos: .userInitiated).async {
                self.dataStore.countAllData(entity: self.dataTypes[indexPath.row]) { (count) in
                    DispatchQueue.main.async {
                        let nf = NumberFormatter()
                        nf.numberStyle = .decimal
                        cell.detailTextLabel!.text = nf.string(from: NSNumber(value: count))
                    }
                }
            }
        } else if indexPath.section == 1 {
            guard let fileManager = self.fileManager else {
                return cell
            }
            
            cell = UITableViewCell.init(style: .value1, reuseIdentifier: Strings.dummyIdentifier)
            cell.textLabel?.text = fileTypes[indexPath.row]
            
            if indexPath.row == 0 {
                cell.detailTextLabel?.text = String(fileManager.getTrackFileCount())
            } else if indexPath.row == 1 {
                cell.detailTextLabel?.text = String(fileManager.getTrackImageCount())
            }

        } else if indexPath.section == 2 {
            cell = UITableViewCell.init(style: .default, reuseIdentifier: Strings.dummyIdentifier)
            cell.textLabel?.text = Strings.settings.databaseMaintenance
            cell.textLabel?.textColor = view.tintColor
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            let alert = UIAlertController(
                title: "Eyða öllum \(dataTypes[indexPath.row]) hlutum",
                message: "Ertu viss um að þú viljir eyða öllum \(dataTypes[indexPath.row]) hlutunum?",
                preferredStyle: .actionSheet
            )
            
            alert.addAction(UIAlertAction(title: Strings.delete, style: .destructive, handler: { (_) in
                self.dataStore.deleteAllData(entity: self.dataTypes[indexPath.row])
            }))
            
            alert.addAction(UIAlertAction(title: Strings.cancel, style: .cancel, handler: nil))
            present(alert, animated: true, completion: nil)
        }
        if indexPath.section == 2 {
            
        }
    }
}
