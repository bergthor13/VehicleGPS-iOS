//
//  VGAvailableDownloadTableViewController.swift
//  VehicleGPS
//
//  Created by Bergþór Þrastarson on 18/01/2020.
//  Copyright © 2020 Bergþór Þrastarson. All rights reserved.
//

import UIKit

class VGAvailableDownloadTableViewController: UITableViewController {
    var tracksDict = [String: [VGTrack]]() {
        didSet {
            tableView.reloadData()
        }
    }
    var sectionKeys = [String]()
    let headerDateFormatter = VGHeaderDateFormatter()
    
    var downloadManager:VGSFTPManager?
    init(style: UITableView.Style, downloadManager:VGSFTPManager?) {
        super.init(style: style)
        self.downloadManager = downloadManager
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    fileprivate func registerCells() {
        self.tableView.register(VGAvailableLogsTableViewCell.nib, forCellReuseIdentifier: VGAvailableLogsTableViewCell.identifier)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        registerCells()
    }

    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return sectionKeys.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let tracksForSection = tracksDict[sectionKeys[section]] else {
            return 0
        }
        return tracksForSection.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: VGAvailableLogsTableViewCell.identifier, for: indexPath) as? VGAvailableLogsTableViewCell else {
            return UITableViewCell()
        }
        
        cell.show(track: tracksDict[sectionKeys[indexPath.section]]![indexPath.row])
        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return headerDateFormatter.sectionKeyToDateString(sectionKey: sectionKeys[section])
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
    func getTrackAt(indexPath:IndexPath) -> VGTrack {
        let dayFileList = tracksDict[sectionKeys[indexPath.section]]
        let file = dayFileList![indexPath.row]
        return file
    }
    
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            let track = self.getTrackAt(indexPath: indexPath)
            
            self.downloadManager?.deleteFile(filename: track.fileName, callback: { (success) in
                if success {
                    DispatchQueue.main.async {
                        tableView.beginUpdates()
                        self.tracksDict[self.sectionKeys[indexPath.section]]?.remove(at: indexPath.row)
                        tableView.deleteRows(at: [indexPath], with: .fade)

                        if self.tracksDict[self.sectionKeys[indexPath.section]]?.count == 0 {
                            self.sectionKeys.remove(at: indexPath.section)
                            tableView.deleteSections(IndexSet(integer: indexPath.section), with: .top)
                        }
                        tableView.endUpdates()
                    }
                }
            })
        }
    }

}
