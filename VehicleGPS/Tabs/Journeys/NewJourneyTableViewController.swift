//
//  NewJourneyTableViewController.swift
//  VehicleGPS
//
//  Created by Bergþór Þrastarson on 16/01/2020.
//  Copyright © 2020 Bergþór Þrastarson. All rights reserved.
//

import UIKit

class NewJourneyTableViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Nýtt ferðalag"
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(tappedDone))
    }

    // MARK: - Table view data source

    @objc func tappedDone() {
        dismiss(animated: true, completion: nil)
    }
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        if section == 0 {
            return 1
        }
        
        if section == 1 {
            return 2
        }
        return 0
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        if indexPath.section == 0 {
            let cell1 = UITableViewCell(style: .value2, reuseIdentifier: "asdf")
            cell1.detailTextLabel!.text = "Titill"
            cell1.textLabel!.text = "Titill"
            return cell1
        }
        
        if indexPath.section == 1 {
            if indexPath.row == 0 {
                let cell1 = UITableViewCell(style: .value2, reuseIdentifier: "asdf")
                cell1.textLabel!.text = "Byrjun"
                cell1.detailTextLabel!.text = "16.01.2020 08:00"
                return cell1
            }
            
            if indexPath.row == 1 {
                let cell1 = UITableViewCell(style: .value2, reuseIdentifier: "asdf")
                cell1.textLabel!.text = "Endir"
                cell1.detailTextLabel!.text = "18.01.2020 08:00"
                return cell1
            }
        }
        return cell
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
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
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
