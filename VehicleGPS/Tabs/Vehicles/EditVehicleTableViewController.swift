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
        if self.vehicle.mapColor == nil {
            self.vehicle.mapColor = UIColor.red
        }
        
        self.vehicle.name = self.cell.txtName.text
        self.vehicle.id = self.vehicle.id
        self.vehicle.image = self.selectedImage
        self.dataStore.update(vgVehicle: self.vehicle)
        if let vehiclesController = self.vehiclesController {
            vehiclesController.editVehicle(self.vehicle)
        }
        NotificationCenter.default.post(name: .vehicleUpdated, object: self.vehicle)

        dismiss(animated: true)

    }
}
