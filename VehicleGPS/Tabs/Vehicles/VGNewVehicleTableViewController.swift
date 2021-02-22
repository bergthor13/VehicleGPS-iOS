//
//  NewJourneyTableViewController.swift
//  VehicleGPS
//
//  Created by Bergþór Þrastarson on 16/01/2020.
//  Copyright © 2020 Bergþór Þrastarson. All rights reserved.
//

import UIKit

class VGNewVehicleTableViewController: UITableViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    var cell: VGNewVehicleTableViewCell! {
        didSet {
            cell.txtName.text = vehicle.name
            cell.txtName.becomeFirstResponder()
            cell.colorWell.selectedColor = vehicle.mapColor
            if vehicle.image != nil {
                cell.imgProfile.image = vehicle.image
                selectedImage = vehicle.image
            }
            
            self.cell.imgProfile.isUserInteractionEnabled = true
            let imageTapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapImage))
            self.cell.imgProfile?.addGestureRecognizer(imageTapGesture)
            
            self.cell.txtName.addTarget(self, action: #selector(nameDidChange(_:)), for: .editingChanged)
            
            enableDisableSave(button: self.navigationItem.rightBarButtonItem!, string: self.cell.txtName.text!)
            self.cell.colorWell.addTarget(self, action: #selector(colorWellChanged(_:)), for: .valueChanged)
            
        }
    }
    
    var dataStore: VGDataStore!
    var vehiclesController: VGVehiclesTableViewController!
    var vehicle = VGVehicle()
    var imagePicker: UIImagePickerController!
    var selectedImage: UIImage?
    
    @objc func nameDidChange(_ sender: UITextField) {
        enableDisableSave(button: self.navigationItem.rightBarButtonItem!, string: sender.text!)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = Strings.Titles.newVehicle
        if vehicle.mapColor == nil {
            vehicle.mapColor = .red
        }
        dataStore = VGDataStore()
        registerCells()
        tableView.allowsSelection = false
        tableView.tintColor = navigationController?.view.tintColor
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: Strings.save, style: .done, target: self, action: #selector(tappedSave))
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: Strings.cancel, style: .plain, target: self, action: #selector(tappedCancel))
    }
    
    func enableDisableSave(button: UIBarButtonItem, string: String) {
        if string.count == 0 {
            button.isEnabled = false
        } else {
            button.isEnabled = true
        }
    }
    
    // MARK: - Add image to Library
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

    // MARK: - Done image capture here
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        imagePicker.dismiss(animated: true, completion: nil)
        guard let selectedImage = info[.editedImage] as? UIImage else {
            print("Image not found!")
            return
        }
        self.selectedImage = selectedImage
        cell.imgProfile.image = self.selectedImage
    }

    // MARK: - Table view data source
    
    @objc func didTapImage() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        if let popoverController = alert.popoverPresentationController {
            popoverController.sourceView = cell.imgProfile
            popoverController.permittedArrowDirections = [.up]
        }
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            alert.addAction(UIAlertAction(title: Strings.takePicture, style: .default, handler: { (action) in
                self.imagePicker =  UIImagePickerController()
                self.imagePicker.delegate = self
                self.imagePicker.sourceType = .camera
                self.imagePicker.allowsEditing = true
                self.present(self.imagePicker, animated: true, completion: nil)
            }))
        }

        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            alert.addAction(UIAlertAction(title: Strings.photoLibrary, style: .default, handler: { (action) in
                self.imagePicker =  UIImagePickerController()
                self.imagePicker.delegate = self
                self.imagePicker.sourceType = .photoLibrary
                self.imagePicker.allowsEditing = true
                self.present(self.imagePicker, animated: true, completion: nil)

            }))
        }
        
        alert.addAction(UIAlertAction(title: Strings.cancel, style: .cancel, handler: nil))
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
            self.dataStore.add(
                vgVehicle: self.vehicle,
                onSuccess: { (id) in
                    if let vehiclesController = self.vehiclesController {
                        vehiclesController.addVehicle(self.vehicle)
                    }
                }, onFailure: { (error) in
                    self.appDelegate.display(error: error)
                }
            )

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
        self.tableView.register(VGNewVehicleTableViewCell.nib, forCellReuseIdentifier: VGNewVehicleTableViewCell.identifier)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: VGNewVehicleTableViewCell.identifier, for: indexPath)
        self.cell = cell as? VGNewVehicleTableViewCell
        return cell
    }
    
    @objc func colorWellChanged(_ colorWell: VGColorWell) {
        let color = cell.colorWell.selectedColor
        self.cell.colorWell.selectedColor = color
        vehicle.mapColor = color
    }
}
