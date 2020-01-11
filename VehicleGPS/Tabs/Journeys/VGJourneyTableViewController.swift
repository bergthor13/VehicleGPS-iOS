//
//  VGJourneyTableViewController.swift
//  VehicleGPS
//
//  Created by Bergþór Þrastarson on 11/01/2020.
//  Copyright © 2020 Bergþór Þrastarson. All rights reserved.
//

import UIKit

class VGJourneyTableViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Ferðalög"
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }
}
