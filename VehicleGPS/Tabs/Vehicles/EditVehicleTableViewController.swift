//
//  EditVehicleTableViewController.swift
//  VehicleGPS
//
//  Created by Bergþór Þrastarson on 07/02/2020.
//  Copyright © 2020 Bergþór Þrastarson. All rights reserved.
//

import UIKit

class EditVehicleTableViewController: NewVehicleTableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        title = NSLocalizedString("Breyta farartæki", comment: "")

    }
    
    @objc override func tappedSave() {
        dismiss(animated: true) {
            let vehicle = VGVehicle()
            vehicle.name = self.cell.txtName.text
            vehicle.id = self.vehicle?.id
            self.dataStore.update(vehicle)
            if let vehiclesController = self.vehiclesController {
                vehiclesController.editVehicle(vehicle)
            }
        }
    }
}
