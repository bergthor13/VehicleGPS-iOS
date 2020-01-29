//
//  VehiclesTableViewController.swift
//  VehicleGPS
//
//  Created by Bergþór Þrastarson on 24/01/2020.
//  Copyright © 2020 Bergþór Þrastarson. All rights reserved.
//

import UIKit

class VGVehiclesTableViewController: UITableViewController {

    var vehicles = [VGVehicle]()
    let dataStore = VGDataStore()
    
    var emptyLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        title = NSLocalizedString("Farartæki", comment: "Vehicles Title")
        tableView.tintColor = navigationController?.view.tintColor
        configureEmptyListLabel()
        registerCells()
        reloadVehicles(shouldReloadTableView: true)
        self.navigationController?.navigationBar.prefersLargeTitles = true
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "plus.circle.fill"), style: .plain, target: self, action: #selector(didTapAddVehicle))
    }
    fileprivate func registerCells() {
        let newVehicleCell = UINib(nibName: "VehicleTableViewCell", bundle: nil)
        self.tableView.register(newVehicleCell, forCellReuseIdentifier: "VehicleCell")
    }
    
    func reloadVehicles(shouldReloadTableView:Bool) {
        self.vehicles = dataStore.getAllVehicles()
        if self.vehicles.count > 0 {
            self.emptyLabel.isHidden = true
        } else {
            self.emptyLabel.isHidden = false
        }
        if shouldReloadTableView {
            tableView.reloadData()
        }
    }
    
    func addVehicle(_ vehicle:VGVehicle) {
        tableView.beginUpdates()
        if vehicles.count == 0 {
            tableView.insertRows(at: [IndexPath(row: vehicles.count, section: 0)], with: .automatic)
        } else {
             tableView.insertRows(at: [IndexPath(row: vehicles.count, section: 0)], with: .top)
        }
        
        vehicles.append(vehicle)
        reloadVehicles(shouldReloadTableView: false)
        tableView.endUpdates()
    }
    
    fileprivate func configureEmptyListLabel() {
        if let delegate = UIApplication.shared.delegate as? AppDelegate {
              emptyLabel = VGListEmptyLabel(text: NSLocalizedString("Engin farartæki", comment: ""),
                                            containerView: self.view,
                                            navigationBar: navigationController!.navigationBar,
                                            tabBar: delegate.tabController.tabBar)
          }
        view.addSubview(emptyLabel)
    }
    
    @objc func didTapAddVehicle() {
        let newVehicleVC = NewVehicleTableViewController(style: .grouped)
        newVehicleVC.vehiclesController = self
        self.present(UINavigationController(rootViewController: newVehicleVC), animated: true, completion: nil)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        var height: CGFloat = 0.0
        guard let delegate = UIApplication.shared.delegate as? AppDelegate else {
            height = view.frame.height-(navigationController?.navigationBar.frame.height)!
            return
        }
        height = view.frame.height-(navigationController?.navigationBar.frame.height)!-delegate.tabController.tabBar.frame.height
        let frame = CGRect(x: 0.0, y: 0.0, width: view.frame.width, height: height)
        
        emptyLabel.frame = frame
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let vehicle = vehicles[indexPath.row]
            dataStore.delete(vgVehicle: vehicle) {
                DispatchQueue.main.async {
                    self.vehicles.remove(at: indexPath.row)
                    tableView.deleteRows(at: [indexPath], with: .top)
                    self.reloadVehicles(shouldReloadTableView: false)
                }
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return vehicles.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "VehicleCell", for: indexPath) as! VehicleTableViewCell
        cell.lblName.text = vehicles[indexPath.row].name
        guard let tracks = vehicles[indexPath.row].tracks else {
            return cell
        }
        var distance = 0.0
        var duration = 0.0
        for track in tracks {
            distance += track.distance
            duration += track.duration
        }
        
        cell.lblDistance.text = VGDistanceFormatter().string(for: distance)
        cell.lblDuration.text = VGDurationFormatter().string(from: duration)
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        navigationController?.pushViewController(UIViewController(), animated: true)
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
