//
//  NewJourneyTableViewController.swift
//  VehicleGPS
//
//  Created by Bergþór Þrastarson on 16/01/2020.
//  Copyright © 2020 Bergþór Þrastarson. All rights reserved.
//

import UIKit

protocol ColorPickerDelegate {
    func didPick(color:UIColor)
}

class VGNewVehicleTableViewController: UITableViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {

    var cell: VGNewVehicleTableViewCell! {
        didSet {
            cell.txtName.text = vehicle.name
            cell.colorBox.backgroundColor = vehicle.mapColor

            self.cell.imgProfile.isUserInteractionEnabled = true
            let imageTapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapImage))
            self.cell.imgProfile?.addGestureRecognizer(imageTapGesture)
            let colorTapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapColor))
            self.cell.colorContainer.addGestureRecognizer(colorTapGesture)
            
        }
    }
    
    var dataStore: VGDataStore!
    var vehiclesController: VGVehiclesTableViewController!
    var vehicle = VGVehicle()
    var imagePicker: UIImagePickerController!
    var selectedImage:UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = NSLocalizedString("Nýtt farartæki", comment: "")
        dataStore = VGDataStore()
        registerCells()
        tableView.allowsSelection = false
        tableView.tintColor = navigationController?.view.tintColor
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: NSLocalizedString("Vista", comment: ""), style: .done, target: self, action: #selector(tappedSave))
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: NSLocalizedString("Hætta við", comment: ""), style: .plain, target: self, action: #selector(tappedCancel))
    }
    
    //MARK: - Add image to Library
    func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            // we got back an error!
            let ac = UIAlertController(title: "Save error", message: error.localizedDescription, preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
        } else {
            let ac = UIAlertController(title: "Saved!", message: "Your altered image has been saved to your photos.", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
        }
    }

    //MARK: - Done image capture here
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]){
        imagePicker.dismiss(animated: true, completion: nil)
        guard let selectedImage = info[.editedImage] as? UIImage else {
            print("Image not found!")
            return
        }
        self.selectedImage = selectedImage
        cell.imgProfile.image = self.selectedImage
    }

    // MARK: - Table view data source
    @objc func didTapColor() {
        let colorPicker = VGColorPickerTableViewController(style: .insetGrouped)
        colorPicker.delegate = self
        
        self.present(UINavigationController(rootViewController: colorPicker), animated: true, completion: nil)
    }
    
    
    @objc func didTapImage() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Taka mynd", style: .default, handler: { (action) in
            self.imagePicker =  UIImagePickerController()
            self.imagePicker.delegate = self
            self.imagePicker.sourceType = .camera
            self.present(self.imagePicker, animated: true, completion: nil)
        }))
        
        alert.addAction(UIAlertAction(title: "Myndasafn", style: .default, handler: { (action) in
            self.imagePicker =  UIImagePickerController()
            self.imagePicker.delegate = self
            self.imagePicker.sourceType = .photoLibrary
            self.imagePicker.allowsEditing = true
            self.present(self.imagePicker, animated: true, completion: nil)

        }))
        
        alert.addAction(UIAlertAction(title: NSLocalizedString("Hætta við", comment: ""), style: .cancel, handler: { (action) in
            
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    @objc func tappedCancel() {
        dismiss(animated: true, completion: nil)
    }
    
    @objc func tappedSave() {
        dismiss(animated: true) {
            if self.vehicle.mapColor == nil {
                self.vehicle.mapColor = UIColor.red
            }
            
            self.vehicle.name = self.cell.txtName.text
            self.vehicle.id = self.vehicle.id
            self.vehicle.image = self.selectedImage
            self.dataStore.add(vgVehicle: self.vehicle)
            if let vehiclesController = self.vehiclesController {
                vehiclesController.addVehicle(self.vehicle)
            }
        }
    }
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 1
    }
    fileprivate func registerCells() {
        let newVehicleCell = UINib(nibName: "VGNewVehicleTableViewCell", bundle: nil)
        self.tableView.register(newVehicleCell, forCellReuseIdentifier: "NewVehicleCell")
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "NewVehicleCell", for: indexPath)
        self.cell = cell as? VGNewVehicleTableViewCell
        return cell
    }
}


extension VGNewVehicleTableViewController: ColorPickerDelegate {
    func didPick(color: UIColor) {
        self.cell.colorBox.backgroundColor = color
        vehicle.mapColor = color
    }
}
