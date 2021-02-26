//
//  VehiclesTableViewController.swift
//  VehicleGPS
//
//  Created by Bergþór Þrastarson on 24/01/2020.
//  Copyright © 2020 Bergþór Þrastarson. All rights reserved.
//

import UIKit

class VGVehiclesSelectionTableViewController: VGVehiclesTableViewController {

    var track: VGTrack?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: Strings.cancel, style: .plain, target: self, action: #selector(didTapCancel))
    }
    
    @objc func didTapCancel() {
        self.dismiss(animated: true)
    }

    // MARK: - Table view data source    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: VGVehicleTableViewCell.identifier, for: indexPath) as? VGVehicleTableViewCell else {
            return UITableViewCell()
        }
        cell.lblName.text = vehicles[indexPath.row].name

        cell.accessoryType = .none
        if let vehicle = self.track?.vehicle {
            if vehicles[indexPath.row].id == vehicle.id {
                cell.accessoryType = .checkmark
            }
        }
        
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
        cell.lblDistance.text = (distance*1000).asDistanceString()
        cell.lblDuration.text = duration.asDurationString()
        cell.imgVehicle?.image = VGFileManager().getImage(for: vehicles[indexPath.row])

        if dataStore.getDefaultVehicleID() == vehicles[indexPath.row].id {
            cell.defaultViewBackground.isHidden = false
            cell.defaultStarView.isHidden = false
        } else {
            cell.defaultViewBackground.isHidden = true
            cell.defaultStarView.isHidden = true
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        dataStore.add(vehicleWith: vehicles[indexPath.row].id!, toTrackWith: track!.id!, onSuccess: {
            self.track?.vehicle = self.vehicles[indexPath.row]
            self.dismiss(animated: true, completion: nil)
        }, onFailure: { (error) in
            self.dismiss(animated: true, completion: nil)
            self.appDelegate.display(error: error)
        })
    }
}
