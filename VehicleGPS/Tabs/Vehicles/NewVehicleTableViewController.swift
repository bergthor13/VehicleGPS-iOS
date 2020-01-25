//
//  NewJourneyTableViewController.swift
//  VehicleGPS
//
//  Created by Bergþór Þrastarson on 16/01/2020.
//  Copyright © 2020 Bergþór Þrastarson. All rights reserved.
//

import UIKit

class NewVehicleTableViewController: UITableViewController {

    var cell: NewVehicleTableViewCell!
    var dataStore: VGDataStore!
    var vehiclesController: VGVehiclesTableViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = NSLocalizedString("Nýtt farartæki", comment: "")
        dataStore = VGDataStore()
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        registerCells()
        
        tableView.tintColor = navigationController?.view.tintColor
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: NSLocalizedString("Vista", comment: ""), style: .done, target: self, action: #selector(tappedSave))
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: NSLocalizedString("Hætta við", comment: ""), style: .plain, target: self, action: #selector(tappedCancel))
    }

    // MARK: - Table view data source

    @objc func tappedCancel() {
        dismiss(animated: true, completion: nil)
    }
    
    @objc func tappedSave() {
        let vehicle = VGVehicle()
        vehicle.name = cell.txtName.text
        dataStore.add(vehicle)
        if let vehiclesController = vehiclesController {
            vehiclesController.reloadVehicles(shouldReloadTableView: true)
        }
        dismiss(animated: true, completion: nil)
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
        let newVehicleCell = UINib(nibName: "NewVehicleTableViewCell", bundle: nil)
        self.tableView.register(newVehicleCell, forCellReuseIdentifier: "NewVehicleCell")
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "NewVehicleCell", for: indexPath)
        self.cell = cell as? NewVehicleTableViewCell
        return cell
    }
    

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
