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
    
    var distanceFormatter = VGDistanceFormatter()
    var durationFormatter = VGDurationFormatter()
    var fileManager = VGFileManager()
    
    var emptyLabel: UILabel!
    
    override init(style: UITableView.Style) {
        super.init(style: style)
        initializeTableViewController()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initializeTableViewController()

    }

    func initializeTableViewController() {
        title = Strings.titles.vehicles
        tabBarItem = UITabBarItem(title: Strings.titles.vehicles,
                                  image: Icons.vehicle,
                                  tag: 0)
        self.navigationController?.navigationBar.prefersLargeTitles = true
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: Icons.add, style: .plain, target: self, action: #selector(didTapAddVehicle))

    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.tintColor = navigationController?.view.tintColor
        configureEmptyListLabel()
        registerCells()
        reloadVehicles(shouldReloadTableView: true)
        NotificationCenter.default.addObserver(self, selector: #selector(onVehicleUpdated(_:)), name: .vehicleUpdated, object: nil)
        
    }
    fileprivate func registerCells() {
        self.tableView.register(VGVehicleTableViewCell.nib, forCellReuseIdentifier: VGVehicleTableViewCell.identifier)
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
        for vehicle in vehicles {
            vehicle.image = self.fileManager.getImage(for: vehicle)
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
    
    func editVehicle(_ editedVehicle:VGVehicle) {
        tableView.beginUpdates()
        for (index, vehicle) in vehicles.enumerated() {
            if vehicle == editedVehicle {
                let bla = tableView.cellForRow(at: IndexPath(row: index, section: 0)) as! VGVehicleTableViewCell
                bla.lblName.text = editedVehicle.name
                bla.colorBanner.backgroundColor = editedVehicle.mapColor
                vehicles.remove(at: index)
                vehicles.insert(editedVehicle, at: index)
                
            }
        }
        
        reloadVehicles(shouldReloadTableView: false)
        tableView.endUpdates()
    }
    
    fileprivate func configureEmptyListLabel() {
        if let delegate = UIApplication.shared.delegate as? AppDelegate {
            emptyLabel = VGListEmptyLabel(text: Strings.noVehicles,
                                            containerView: self.view,
                                            navigationBar: navigationController!.navigationBar,
                                            tabBar: delegate.tabController.tabBar)
          }
        view.addSubview(emptyLabel)
    }
    
    @objc func didTapAddVehicle() {
        let newVehicleVC = VGNewVehicleTableViewController(style: .grouped)
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
    
    @objc func onVehicleUpdated(_ notification:Notification) {
        guard let updatedVehicle = notification.object as? VGVehicle else {
            return
        }
        
        for (index, vehicle) in vehicles.enumerated() {
            if vehicle.id == updatedVehicle.id {
                vehicles[index] = updatedVehicle
                break
            }
        }
        tableView.reloadData()
    }

    // MARK: - Table view data source
    
    fileprivate func setVehicleAsDefault(at indexPath:IndexPath) {
        let vehicle = self.vehicles[indexPath.row]
        if let vehicleID = vehicle.id {
            self.dataStore.setDefaultVehicleID(id: vehicleID)
        }
        
        let visibleVehicles = tableView.indexPathsForVisibleRows
        
        for visVehicleIndexPath in visibleVehicles! {
            let cell = tableView.cellForRow(at: visVehicleIndexPath) as! VGVehicleTableViewCell
            if vehicle.id == self.vehicles[visVehicleIndexPath.row].id {
                cell.defaultViewBackground.isHidden = false
                cell.defaultStarView.isHidden = false
            } else {
                cell.defaultViewBackground.isHidden = true
                cell.defaultStarView.isHidden = true
            }
        }
    }
    
    fileprivate func deleteVehicle(at indexPath:IndexPath) {
        let vehicle = self.vehicles[indexPath.row]
        self.dataStore.delete(vgVehicle: vehicle) {
            DispatchQueue.main.async {
                self.vehicles.remove(at: indexPath.row)
                self.tableView.deleteRows(at: [indexPath], with: .top)
                self.reloadVehicles(shouldReloadTableView: false)
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        
        let setDefaultAction = UIContextualAction(style: .normal, title: Strings.setAsDefault) { (action, view, completion) in
            self.setVehicleAsDefault(at: indexPath)
            completion(true)
        }
        
        let deleteAction = UIContextualAction(style: .destructive, title: Strings.delete) { (action, view, completion) in
            self.deleteVehicle(at: indexPath)
            completion(true)
        }
        
        let actionConfig = UISwipeActionsConfiguration(actions: [deleteAction, setDefaultAction])
        return actionConfig
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return vehicles.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: VGVehicleTableViewCell.identifier, for: indexPath) as! VGVehicleTableViewCell
        let vehicle = vehicles[indexPath.row]
        cell.lblName.text = vehicle.name
        guard let tracks = vehicle.tracks else {
            return cell
        }
        var distance = 0.0
        var duration = 0.0
        for track in tracks {
            distance += track.distance
            duration += track.duration
        }
        
        if let color = vehicle.mapColor {
            cell.colorBanner.backgroundColor = color
        } else {
            cell.colorBanner.backgroundColor = .red
        }

        cell.lblDistance.text = distanceFormatter.string(for: distance*1000)
        cell.lblDuration.text = durationFormatter.string(from: duration)
        cell.imgVehicle?.image = vehicle.image
        
        
        if dataStore.getDefaultVehicleID() == vehicle.id {
            cell.defaultViewBackground.isHidden = false
            cell.defaultStarView.isHidden = false
        } else {
            cell.defaultViewBackground.isHidden = true
            cell.defaultStarView.isHidden = true
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 84
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let detailsVC = VGVehicleDetailsTableViewController(style: .insetGrouped)
        detailsVC.vehicle = vehicles[indexPath.row]
        navigationController?.pushViewController(detailsVC, animated: true)
    }
    
    override func tableView(_ tableView: UITableView,
      contextMenuConfigurationForRowAt indexPath: IndexPath,
      point: CGPoint) -> UIContextMenuConfiguration? {
        let edit = UIAction(title: Strings.edit) { _ in
            self.editVehicle(at: indexPath)
        }
        edit.image = Icons.edit

        
        let favorite = UIAction(title: Strings.setAsDefault) { _ in
            self.setVehicleAsDefault(at: indexPath)

        }
        favorite.image = UIImage(systemName: "star.fill")

        
        let delete = UIAction(title: Strings.delete) {_ in
            self.deleteVehicle(at: indexPath)

        }
        delete.image = Icons.delete
        delete.attributes = .destructive
        
        let deleteMenu = UIMenu(title: Strings.delete, image: Icons.delete, identifier: .none, options: .destructive, children: [delete])

      return UIContextMenuConfiguration(identifier: nil,
        previewProvider: nil) { _ in
        UIMenu(title: "", children: [edit, favorite, deleteMenu])
      }
    }
    
    func editVehicle(at indexPath:IndexPath) {
        let editVehicleVC = VGEditVehicleTableViewController(style: .grouped)
        editVehicleVC.vehicle = vehicles[indexPath.row]
        self.present(UINavigationController(rootViewController: editVehicleVC), animated: true, completion: nil)
    }
    

}


