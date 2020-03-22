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
        title = NSLocalizedString("Farartæki", comment: "Vehicles Title")
        tabBarItem = UITabBarItem(title: NSLocalizedString("Farartæki", comment: "Vehicles Title"),
                                                     image: UIImage(systemName: "car"),
                                                     tag: 0)
        self.navigationController?.navigationBar.prefersLargeTitles = true
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "plus.circle.fill"), style: .plain, target: self, action: #selector(didTapAddVehicle))

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
        let newVehicleCell = UINib(nibName: "VGVehicleTableViewCell", bundle: nil)
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
              emptyLabel = VGListEmptyLabel(text: NSLocalizedString("Engin farartæki", comment: ""),
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
        
        
        let setDefaultAction = UIContextualAction(style: .normal, title: "Setja sem sjálfgefið") { (action, view, completion) in
            self.setVehicleAsDefault(at: indexPath)
            completion(true)
        }
        
        let deleteAction = UIContextualAction(style: .destructive, title: "Eyða") { (action, view, completion) in
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "VehicleCell", for: indexPath) as! VGVehicleTableViewCell
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
        
        if let color = vehicles[indexPath.row].mapColor {
            cell.colorBanner.backgroundColor = color
        } else {
            cell.colorBanner.backgroundColor = .red
        }

        cell.lblDistance.text = distanceFormatter.string(for: distance*1000)
        cell.lblDuration.text = durationFormatter.string(from: duration)
        cell.imgVehicle?.image = VGFileManager().getImage(for: vehicles[indexPath.row])
        
        guard let items = UserDefaults.standard.data(forKey: "DefaultVehicle") else {
            cell.defaultViewBackground.isHidden = true
            cell.defaultStarView.isHidden = true
            return cell
        }
        
        let decoder = JSONDecoder()
        guard let defaultVehicleID = try? decoder.decode(UUID.self, from: items) else {
            return cell
        }
        
        if defaultVehicleID == vehicles[indexPath.row].id {
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

        let favorite = UIAction(title: "Setja sem sjálfgefið") { _ in
            self.setVehicleAsDefault(at: indexPath)

        }
        
        let delete = UIAction(title: "Eyða", image: UIImage(systemName: "trash"), identifier: .none, discoverabilityTitle: nil, attributes: .destructive, state: .off) {_ in
            self.deleteVehicle(at: indexPath)

        }
        favorite.image = UIImage(systemName: "star.fill")
        delete.image = UIImage(systemName: "trash")

      return UIContextMenuConfiguration(identifier: nil,
        previewProvider: nil) { _ in
        UIMenu(title: "", children: [favorite, delete])
      }
    }
}


