//
//  EditVehicleTableViewController.swift
//  VehicleGPS
//
//  Created by Bergþór Þrastarson on 07/02/2020.
//  Copyright © 2020 Bergþór Þrastarson. All rights reserved.
//

import UIKit

class VGEditVehicleTableViewController: VGNewVehicleTableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        title = Strings.editVehicle
    }
    
    @objc override func tappedSave() {
        if self.vehicle.mapColor == nil {
            self.vehicle.mapColor = UIColor.red
        }
        
        self.vehicle.name = self.cell.txtName.text
        self.vehicle.id = self.vehicle.id
        self.vehicle.image = self.selectedImage
        self.dataStore.update(vgVehicle: self.vehicle, onSuccess: {
            if let vehiclesController = self.vehiclesController {
                vehiclesController.editVehicle(self.vehicle)
            }
            NotificationCenter.default.post(name: .vehicleUpdated, object: self.vehicle)

            self.dismiss(animated: true)
        }) { (error) in
            self.appDelegate.display(error: error)
        }

    }
}
