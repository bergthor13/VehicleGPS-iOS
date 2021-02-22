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
    var availableLogsTVC: VGAvailableDownloadTableViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        availableLogsTVC = VGAvailableDownloadTableViewController(style: .plain)
        view.backgroundColor = .systemBackground
        self.navigationController?.navigationBar.prefersLargeTitles = false
        let segmentedControl = UISegmentedControl(items: ["Nýjir", "Allir ferlar", "Stillingar"])
        segmentedControl.addTarget(self, action: #selector(segmentedControlChanged(sender:)), for: .valueChanged)
        segmentedControl.selectedSegmentIndex = 0
        self.navigationItem.titleView = segmentedControl
        safeArea = view.layoutMarginsGuide
        setupTableView()
    }
    
    @objc func segmentedControlChanged(sender: UISegmentedControl) {
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
        (availableSectionKeys, availableLogs) = LogDateSplitter.splitLogsByDate(trackList: newList)
        (allSectionKeys, allLogs) = LogDateSplitter.splitLogsByDate(trackList: tracks!)
        availableLogsTVC.sectionKeys = availableSectionKeys
        availableLogsTVC.tracksDict = availableLogs
    }
    
}
