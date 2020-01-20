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
    var sectionKeys = [String]()
    var availableLogsTVC = VGAvailableDownloadTableViewController(style: .plain)
    var vgFileManager = VGFileManager()
    var safeArea: UILayoutGuide!
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
        print(sender.selectedSegmentIndex)
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
                newList.append(track)
            }
        }
        availableLogsTVC.tracksDict = tracksToDictionary(trackList: newList)
        availableLogsTVC.sectionKeys = sectionKeys
    }
    
    func tracksToDictionary(trackList:[VGTrack]) -> Dictionary<String, [VGTrack]>{
        var result = Dictionary<String, [VGTrack]>()
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
        self.sectionKeys = self.sectionKeys.sorted().reversed()
        
        for (day, list) in result {
            result[day] = list.sorted { (first, second) -> Bool in
                if first.timeStart != nil && second.timeStart != nil {
                    return first.timeStart! > second.timeStart!
                }
                return first.fileName > second.fileName
            }
        }
        
        return result
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
