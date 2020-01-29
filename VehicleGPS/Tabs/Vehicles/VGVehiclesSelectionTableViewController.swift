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

    // MARK: - Table view data source    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "VehicleCell", for: indexPath) as! VehicleTableViewCell
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
        cell.lblDistance.text = VGDistanceFormatter().string(for: distance)
        cell.lblDuration.text = VGDurationFormatter().string(from: duration)

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        dataStore.add(vgVehicle: vehicles[indexPath.row], to: track!)
        dismiss(animated: true, completion: nil)
    }
}
