//
//  VehiclesTableViewController.swift
//  VehicleGPS
//
//  Created by Bergþór Þrastarson on 24/01/2020.
//  Copyright © 2020 Bergþór Þrastarson. All rights reserved.
//

import UIKit

class VGVehiclesTableViewController: UITableViewController {

    var vehicles = [VGVehicle]() {
        didSet {
        }
    }
    let dataStore = VGDataStore()
    
    var fileManager = VGFileManager()
    
    var emptyLabel: VGListEmptyLabel!
    
    var addVehicleTapRecognizer: UITapGestureRecognizer!
    
    override init(style: UITableView.Style) {
        super.init(style: style)
        initializeTableViewController()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initializeTableViewController()

    }

    func initializeTableViewController() {
        title = Strings.Titles.vehicles
        if #available(iOS 14.0, *) {
            tabBarItem = UITabBarItem(title: Strings.Titles.vehicles,
                                      image: Icons.vehicle,
                                      tag: 0)

        } else {
            tabBarItem = UITabBarItem(title: Strings.Titles.vehicles,
                                      image: Icons.vehicleiOS13,
                                      tag: 0)
        }
        self.navigationController?.navigationBar.prefersLargeTitles = true
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: Icons.add, style: .plain, target: self, action: #selector(didTapAddVehicle(_:)))
        self.navigationItem.leftBarButtonItem = editButtonItem
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.tintColor = navigationController?.view.tintColor
        configureEmptyListLabel()
        registerCells()
        NotificationCenter.default.addObserver(self, selector: #selector(onVehicleUpdated(_:)), name: .vehicleUpdated, object: nil)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadVehicles(shouldReloadTableView: true)
        
        navigationController?.navigationBar.prefersLargeTitles = true
    }
    fileprivate func registerCells() {
        self.tableView.register(VGVehicleTableViewCell.nib, forCellReuseIdentifier: VGVehicleTableViewCell.identifier)
    }
    
    func reloadVehicles(shouldReloadTableView: Bool) {
        dataStore.getAllVehicles(
            onSuccess: { (vehicles) in
                self.vehicles = vehicles
                if self.vehicles.count > 0 {
                    self.emptyLabel.isHidden = true
                } else {
                    self.emptyLabel.isHidden = false
                }
                if shouldReloadTableView {
                    self.tableView.reloadData()
                }
                for vehicle in vehicles {
                    vehicle.image = self.fileManager.getImage(for: vehicle)
                }
                self.vehicles.sort()
            },
            onFailure: { (error) in
                self.appDelegate.display(error: error)
            }
        )
        
    }
    
    @objc func didTapAddVehicle(_:Any) {
        let newVehicleVC = VGNewVehicleTableViewController(style: .grouped)
        newVehicleVC.vehiclesController = self
        let navController = UINavigationController(rootViewController: newVehicleVC)
        if self.popoverPresentationController != nil {
            navController.modalPresentationStyle = .currentContext
        }
        self.present(navController, animated: true, completion: nil)
    }
    func addVehicle(_ vehicle: VGVehicle) {
        self.tableView.beginUpdates()
        if self.vehicles.count == 0 {
            self.tableView.insertRows(at: [IndexPath(row: self.vehicles.count, section: 0)], with: .automatic)
        } else {
            self.tableView.insertRows(at: [IndexPath(row: self.vehicles.count, section: 0)], with: .top)
        }
        
        self.vehicles.append(vehicle)
        self.reloadVehicles(shouldReloadTableView: false)
        self.tableView.endUpdates()
    }
    
    func editVehicle(_ editedVehicle: VGVehicle) {
        tableView.beginUpdates()
        for (index, vehicle) in vehicles.enumerated() where vehicle == editedVehicle {
            guard let bla = tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? VGVehicleTableViewCell else {
                continue
            }
            bla.lblName.text = editedVehicle.name
            bla.colorBanner.backgroundColor = editedVehicle.mapColor
            vehicles.remove(at: index)
            vehicles.insert(editedVehicle, at: index)
        }
        
        reloadVehicles(shouldReloadTableView: false)
        tableView.endUpdates()
    }
    
    fileprivate func configureEmptyListLabel() {
        if let delegate = UIApplication.shared.delegate as? AppDelegate {
            emptyLabel = VGListEmptyLabel(text: Strings.noVehicles + "\n\n" + Strings.tapHereVehicles + "\n\n" + Strings.vehiclesHint,
                                            containerView: self.view,
                                            navigationBar: navigationController!.navigationBar,
                                            tabBar: delegate.tabController.tabBar)
          }
        view.addSubview(emptyLabel)
        emptyLabel.isEnabled = true
        emptyLabel.numberOfLines = 0
        addVehicleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapAddVehicle(_:)))
        addVehicleTapRecognizer.numberOfTapsRequired = 1
        emptyLabel.isUserInteractionEnabled = true
        emptyLabel.addGestureRecognizer(addVehicleTapRecognizer)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        emptyLabel.setFrame()
    }
    
    @objc func onVehicleUpdated(_ notification: Notification) {
        guard let updatedVehicle = notification.object as? VGVehicle else {
            return
        }
        
        for (index, vehicle) in vehicles.enumerated() where vehicle.id == updatedVehicle.id {
            vehicles[index] = updatedVehicle
            break
        }
        tableView.reloadData()
    }

    // MARK: - Table view data source
    
    fileprivate func setVehicleAsDefault(at indexPath: IndexPath) {
        let vehicle = self.vehicles[indexPath.row]
        if let vehicleID = vehicle.id {
            self.dataStore.setDefaultVehicleID(id: vehicleID)
        }
        
        let visibleVehicles = tableView.indexPathsForVisibleRows
        
        for visVehicleIndexPath in visibleVehicles! {
            guard let cell = tableView.cellForRow(at: visVehicleIndexPath) as? VGVehicleTableViewCell else {
                continue
            }
            if vehicle.id == self.vehicles[visVehicleIndexPath.row].id {
                cell.defaultViewBackground.isHidden = false
                cell.defaultStarView.isHidden = false
            } else {
                cell.defaultViewBackground.isHidden = true
                cell.defaultStarView.isHidden = true
            }
        }
    }
    
    fileprivate func deleteVehicle(at indexPath: IndexPath) {
        let vehicle = self.vehicles[indexPath.row]
        self.dataStore.delete(vehicleWith: vehicle.id!, onSuccess: {
            self.vehicles.remove(at: indexPath.row)
            self.tableView.deleteRows(at: [indexPath], with: .top)
            self.reloadVehicles(shouldReloadTableView: false)
        }, onFailure: { (error) in
            self.appDelegate.display(error: error)
        })

    }
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let vehicleToMove = vehicles[sourceIndexPath.row]
        vehicles.remove(at: sourceIndexPath.row)
        vehicles.insert(vehicleToMove, at: destinationIndexPath.row)
        
        for index in vehicles.indices {
            vehicles[index].order = index
            DispatchQueue.global(qos: .userInitiated).async {
                self.dataStore.update(vgVehicle: self.vehicles[index], onSuccess: {
                    
                }, onFailure: { (error) in
                    self.appDelegate.display(error: error)
                })
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
        guard let cell = tableView.dequeueReusableCell(withIdentifier: VGVehicleTableViewCell.identifier, for: indexPath) as? VGVehicleTableViewCell else {
            return UITableViewCell()
        }
        let vehicle = vehicles[indexPath.row]
        cell.lblName.text = vehicle.name
        cell.imgVehicle?.image = vehicle.image

        if let color = vehicle.mapColor {
            cell.colorBanner.backgroundColor = color
        } else {
            cell.colorBanner.backgroundColor = .red
        }
        
        if dataStore.getDefaultVehicleID() == vehicle.id {
            cell.defaultViewBackground.isHidden = false
            cell.defaultStarView.isHidden = false
        } else {
            cell.defaultViewBackground.isHidden = true
            cell.defaultStarView.isHidden = true
        }
        
        guard let tracks = vehicle.tracks else {
            cell.lblDistance.text = 0.0.asDistanceString()
            cell.lblDuration.text = 0.0.asDurationString()
            return cell
        }
        var distance = 0.0
        var duration = 0.0
        for track in tracks {
            distance += track.distance
            duration += track.duration
        }
        
        cell.lblDistance.text = (distance*1000).asDistanceString()
        cell.lblDuration.text = duration.asDurationString()

        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 84
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let vehicle = vehicles[indexPath.row]
        guard let tracks = vehicle.tracks else { return }
        
        let detailsVC = VGVehicleDetailsTableViewController(style: .plain)
        detailsVC.vehicle = vehicle
        detailsVC.tracksSummary = VGTracksSummary(title: "")
        detailsVC.tracksSummary?.tracks = tracks
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
    
    func editVehicle(at indexPath: IndexPath) {
        let editVehicleVC = VGEditVehicleTableViewController(style: .grouped)
        editVehicleVC.vehicle = vehicles[indexPath.row]
        let navController = UINavigationController(rootViewController: editVehicleVC)
        if self.popoverPresentationController != nil {
            navController.modalPresentationStyle = .currentContext
        }
        self.present(navController, animated: true, completion: nil)
    }
}
