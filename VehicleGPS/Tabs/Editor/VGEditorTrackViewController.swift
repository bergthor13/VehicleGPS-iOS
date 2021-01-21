//
//  VGPulleyViewController.swift
//  VehicleGPS
//
//  Created by Bergþór Þrastarson on 24.11.2020.
//  Copyright © 2020 Bergþór Þrastarson. All rights reserved.
//

import UIKit

class VGEditorTrackViewController: UIViewController {
    

    @IBOutlet weak var tableView: UITableView!
    let tvcontroller = VGLogDetailsTrackTableViewController(style: .grouped)
    var tracks = [VGTrack]() {
        didSet {
            self.tracks.sort()
            self.tracks.reverse()
            tvcontroller.track = tracks.first
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
            
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = tvcontroller
        tableView.delegate = tvcontroller
        self.tableView.register(VGGraphTableViewCell.self, forCellReuseIdentifier: VGGraphTableViewCell.identifier)
        tableView.contentInset = UIEdgeInsets(top: 44, left: 0, bottom: 0, right: 0)
        tableView.showsHorizontalScrollIndicator = true
    }
    
    
}
