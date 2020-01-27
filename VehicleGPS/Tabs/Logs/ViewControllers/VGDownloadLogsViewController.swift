//
//  VGDownloadLogsViewController.swift
//  VehicleGPS
//
//  Created by Bergþór Þrastarson on 18/01/2020.
//  Copyright © 2020 Bergþór Þrastarson. All rights reserved.
//

import UIKit

class VGDownloadLogsViewController: UIViewController {

    var tracks: [VGTrack]?
    var availableSectionKeys = [String]()
    var availableLogs = [String: [VGTrack]]()
    var allSectionKeys = [String]()
    var allLogs = [String: [VGTrack]]()
    var vgFileManager = VGFileManager()
    var safeArea: UILayoutGuide!
    var downloadManager:VGSFTPManager?
    var availableLogsTVC: VGAvailableDownloadTableViewController!
    init(downloadManager:VGSFTPManager?) {
        super.init(nibName: nil, bundle: nil)
        self.downloadManager = downloadManager
        
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        availableLogsTVC = VGAvailableDownloadTableViewController(style: .plain, downloadManager: downloadManager)
        view.backgroundColor = .systemBackground
        self.navigationController?.navigationBar.prefersLargeTitles = false
        let segmentedControl = UISegmentedControl(items: ["Í boði", "Allir ferlar", "Stillingar"])
        segmentedControl.addTarget(self, action: #selector(segmentedControlChanged(sender:)), for: .valueChanged)
        segmentedControl.selectedSegmentIndex = 0
        self.navigationItem.titleView = segmentedControl
        safeArea = view.layoutMarginsGuide
        setupTableView()
    }
    
    @objc func segmentedControlChanged(sender:UISegmentedControl) {
        if sender.selectedSegmentIndex == 0 {
            availableLogsTVC.sectionKeys = availableSectionKeys
            availableLogsTVC.tracksDict = availableLogs
        } else if sender.selectedSegmentIndex == 1 {
            availableLogsTVC.sectionKeys = allSectionKeys
            availableLogsTVC.tracksDict = allLogs
        }
    }

    func setupTableView() {
        view.addSubview(availableLogsTVC.tableView)
        availableLogsTVC.tableView.translatesAutoresizingMaskIntoConstraints = false
        availableLogsTVC.tableView.topAnchor.constraint(equalTo: safeArea.topAnchor).isActive = true
        availableLogsTVC.tableView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        availableLogsTVC.tableView.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor).isActive = true
        availableLogsTVC.tableView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        var newList = [VGTrack]()
        for track in tracks! {
            if !vgFileManager.fileForTrackExists(track: track) {
                track.isLocal = false
                newList.append(track)
            } else {
                track.isLocal = true
            }
        }
        (availableSectionKeys, availableLogs) = tracksToDictionary(trackList: newList)
        (allSectionKeys, allLogs) = tracksToDictionary(trackList: tracks!)
        availableLogsTVC.sectionKeys = availableSectionKeys
        availableLogsTVC.tracksDict = availableLogs
    }
    
    func tracksToDictionary(trackList:[VGTrack]) -> ([String], Dictionary<String, [VGTrack]>){
        var result = Dictionary<String, [VGTrack]>()
        var sectionKeys = [String]()
        for track in trackList {
            var day = ""
            if let timeStart = track.timeStart {
                day = String(String(describing: timeStart).prefix(10))
            } else {
                day = String(track.fileName.prefix(10))
            }
            
            if result[day] == nil {
                result[day] = [VGTrack]()
            }
            if !sectionKeys.contains(day) {
                sectionKeys.append(day)
            }
            result[day]!.append(track)
        }
        
        // Reorder the sections and lists to display the newest log first.
        sectionKeys = sectionKeys.sorted().reversed()
        
        for (day, list) in result {
            result[day] = list.sorted { (first, second) -> Bool in
                if first.timeStart != nil && second.timeStart != nil {
                    return first.timeStart! > second.timeStart!
                }
                return first.fileName > second.fileName
            }
        }
        
        return (sectionKeys, result)
    }
}
