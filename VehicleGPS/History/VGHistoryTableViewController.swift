//
//  VGHistoryTableViewController.swift
//  VehicleGPS
//
//  Created by Bergþór Þrastarson on 15/12/2019.
//  Copyright © 2019 Bergþór Þrastarson. All rights reserved.
//

import UIKit

class VGHistoryTableViewController: UITableViewController {
    var tracks = [VGTrack]()
    var months = Dictionary<String, TracksSummary>()
    var sectionKeys = [String]()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.register(UINib(nibName: "HistoryTableViewCell", bundle: nil), forCellReuseIdentifier: "HistoryCell")
        self.title = "Saga"
        let dataStore = VGDataStore()
        
        months = getMonthDictionary(tracks: dataStore.getAllTracks())
        
        sectionKeys.sort()
        sectionKeys.reverse()
    }
    
    func getMonthDictionary(tracks:[VGTrack]) -> Dictionary<String, TracksSummary> {
        for track in tracks {
            var monthKey = String(track.fileName.prefix(7))
            if months[monthKey] == nil {
                sectionKeys.append(monthKey)
                months[monthKey] = TracksSummary()
                let df = DateFormatter()
                df.locale = Locale(identifier: "is_IS")
                df.dateFormat = "yyyy-MM"
                let date = df.date(from: String(track.fileName.prefix(7)))
                df.dateFormat = "MMMM YYYY"
                months[monthKey]!.dateDescription = df.string(from: date!)
            }
            
            months[monthKey]!.distance += track.distance
            months[monthKey]!.trackCount += 1
        }
        return months
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return months.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "HistoryCell", for: indexPath) as! HistoryTableViewCell
        let nf = NumberFormatter()
        nf.locale = Locale.current
        nf.maximumFractionDigits = 0
        nf.minimumFractionDigits = 0
        nf.usesGroupingSeparator = true
        nf.numberStyle = .decimal
        let summary = months[sectionKeys[indexPath.row]]!
        cell.lblDistance.text = String(nf.string(from: NSNumber(value: summary.distance))!)
        cell.lblTripCount.text = String(summary.trackCount)
        cell.lblDate.text = summary.dateDescription
        
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
