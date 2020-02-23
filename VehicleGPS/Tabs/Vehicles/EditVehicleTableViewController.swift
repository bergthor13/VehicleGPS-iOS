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
        title = NSLocalizedString("Breyta farartæki", comment: "")

    }
    
    @objc override func tappedSave() {
        let vehicle = VGVehicle()
        vehicle.name = self.cell.txtName.text
        vehicle.id = self.vehicle?.id
        vehicle.image = self.selectedImage
        self.dataStore.update(vgVehicle: vehicle)
        if let vehiclesController = self.vehiclesController {
            vehiclesController.editVehicle(vehicle)
        }
        NotificationCenter.default.post(name: .vehicleUpdated, object: vehicle)
        dismiss(animated: true)
    }
}
