//
//  VGLogDetailsTrackTableViewController.swift
//  VehicleGPS
//
//  Created by Bergþór Þrastarson on 30/07/2019.
//  Copyright © 2019 Bergþór Þrastarson. All rights reserved.
//

import UIKit

class VGLogDetailsTrackTableViewController: UITableViewController {

    var track: VGTrack?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.register(UINib(nibName: "GraphTableViewCell", bundle: nil), forCellReuseIdentifier: "GraphCell")
        
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 7
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 1
    }
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {return "Elevation"}
        if section == 1 {return "PDOP"}
        if section == 2 {return "Horizontal Accuracy"}
        if section == 3 {return "RPM"}
        if section == 4 {return "Engine Load"}
        if section == 5 {return "Coolant Temperature"}
        if section == 6 {return "Ambient Temperature"}
        if section == 7 {return "Throttle Position"}
        return ""
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "GraphCell", for: indexPath) as! VGGraphTableViewCell
        
        
        if indexPath.section == 0 {
            cell.graphView.color = UIColor(red: 0, green: 0.8, blue: 0, alpha: 0.3)
            cell.graphView.numbersList = (track?.trackPoints.map {$0.elevation})!
        } else if indexPath.section == 1 {
            var list = [Double]()
            for point in track!.trackPoints {
                list.append(point.pdop)
            }
            cell.graphView.color = UIColor(red: 0, green: 0.8, blue: 0, alpha: 0.3)
            cell.graphView.numbersList = list

        } else if indexPath.section == 2 {
            var list = [Double]()
            for point in track!.trackPoints {
                list.append(point.horizontalAccuracy)
            }
            cell.graphView.color = UIColor(red: 0, green: 0.8, blue: 0, alpha: 0.3)
            cell.graphView.numbersList = list
            
        } else if indexPath.section == 3 {
            var list = [Double]()
            for point in track!.trackPoints {
                if let coolant = point.rpm {
                    list.append(coolant)
                }
            }
            cell.graphView.color = UIColor(red: 0, green: 0.8, blue: 0, alpha: 0.3)
            cell.graphView.numbersList = list
            
        } else if indexPath.section == 4 {
            var list = [Double]()
            for point in track!.trackPoints {
                if let coolant = point.engineLoad {
                    list.append(coolant)
                }
            }
            cell.graphView.color = UIColor(red: 0, green: 0.8, blue: 0, alpha: 0.3)
            cell.graphView.numbersList = list
            
        } else if indexPath.section == 5 {
            var list = [Double]()
            for point in track!.trackPoints {
                if let coolant = point.coolantTemperature {
                    list.append(coolant)
                }
            }
            cell.graphView.color = UIColor(red: 0.8, green: 0.0, blue: 0, alpha: 0.3)
            cell.graphView.numbersList = list
            
        } else if indexPath.section == 6 {
            var list = [Double]()
            for point in track!.trackPoints {
                if let coolant = point.ambientTemperature {
                    list.append(coolant)
                }
            }
            cell.graphView.color = UIColor(red: 0, green: 0.8, blue: 0, alpha: 0.3)
            cell.graphView.numbersList = list
            
        } else if indexPath.section == 7 {
            var list = [Double]()
            for point in track!.trackPoints {
                if let coolant = point.throttlePosition {
                    list.append(coolant)
                }
            }
            cell.graphView.color = UIColor(red: 0, green: 0.8, blue: 0, alpha: 0.3)
            cell.graphView.numbersList = list
            
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 200
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
