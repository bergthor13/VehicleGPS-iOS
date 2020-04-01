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
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: NSLocalizedString("Hætta við", comment: ""), style: .plain, target: self, action: #selector(didTapCancel))
    }
    
    @objc func didTapCancel() {
        self.dismiss(animated: true)
    }

    // MARK: - Table view data source    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: VGVehicleTableViewCell.identifier, for: indexPath) as! VGVehicleTableViewCell
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
        cell.lblDistance.text = distanceFormatter.string(for: distance*1000)
        cell.lblDuration.text = durationFormatter.string(from: duration)
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
        dataStore.add(vgVehicle: vehicles[indexPath.row], to: track!)
        dismiss(animated: true, completion: nil)
    }
}
