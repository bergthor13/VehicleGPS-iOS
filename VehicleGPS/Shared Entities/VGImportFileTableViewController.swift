//
//  ImportFileTableViewController.swift
//  VehicleGPS
//
//  Created by Bergþór Þrastarson on 21/03/2020.
//  Copyright © 2020 Bergþór Þrastarson. All rights reserved.
//

import UIKit

class VGImportFileTableViewController: UITableViewController {
    
    var fileUrl:URL?
    
    var dataStore = VGDataStore()
    
    var importedTrack:VGTrack!

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Flytja inn skrá"
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: NSLocalizedString("Flytja inn", comment: ""), style: .done, target: self, action: #selector(tappedImport))
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: NSLocalizedString("Hætta við", comment: ""), style: .plain, target: self, action: #selector(tappedCancel))
        
        let asdf = VGGPXParser(snapshotter: VGSnapshotMaker(fileManager: VGFileManager()))
        guard let fileUrl = fileUrl else {
            return
        }
        DispatchQueue.global(qos: .userInitiated).async {
            asdf.fileToTrack(fileUrl: fileUrl, progress: { (curr, count) in
                  
            }, callback: { (parsedTrack) in
                self.importedTrack = parsedTrack
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }) { (track, style) in
                  
            }
        }
    }
    
    init(style: UITableView.Style, fileUrl:URL) {
        super.init(style:style)
        self.fileUrl = fileUrl
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func tappedImport() {
        if let track = importedTrack {
            self.dataStore.update(vgTrack: track)
        }
        dismiss(animated: true)
    }
    
    @objc func tappedCancel() {
        dismiss(animated: true)
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
        let cell = UITableViewCell(style: .value2, reuseIdentifier: "asdf")
        
        guard let currTrack = self.importedTrack else {
            return cell
        }
        cell.tintColor = UIApplication.shared.delegate?.window!!.tintColor
        
        if indexPath.row == 0 {
            cell.detailTextLabel?.text = String(fileUrl!.lastPathComponent)
            cell.textLabel?.text = "Skráarheiti"
        } else if indexPath.row == 1 {
            cell.detailTextLabel?.text = VGDistanceFormatter().string(fromMeters: currTrack.distance*1000)
            cell.textLabel?.text = NSLocalizedString("Vegalengd", comment: "")
        } else if indexPath.row == 2 {
            cell.detailTextLabel?.text = String(VGDurationFormatter().string(from: currTrack.duration)!)
            cell.textLabel?.text = NSLocalizedString("Tímalengd", comment: "")
        }
        cell.detailTextLabel?.numberOfLines = 0

        

        // Configure the cell...

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
