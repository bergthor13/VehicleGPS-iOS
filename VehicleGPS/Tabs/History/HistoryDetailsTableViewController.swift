//
//  HistoryDetailsTableViewController.swift
//  VehicleGPS
//
//  Created by Bergþór Þrastarson on 13/01/2020.
//  Copyright © 2020 Bergþór Þrastarson. All rights reserved.
//

import UIKit
import MapKit

class HistoryDetailsTableViewController: UITableViewController {
    var tracksSummary: TracksSummary? {
        didSet {
            tracksSummary!.tracks.sort { (first, second) -> Bool in
                if first.timeStart != nil && second.timeStart != nil {
                    return first.timeStart! > second.timeStart!
                }
                return first.fileName > second.fileName
            }
        }
    }
    var mapView: MKMapView!
    var dataStore: VGDataStore!
    var mapCell: UITableViewCell!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let tracksSummary = self.tracksSummary {
            title = tracksSummary.dateDescription
        }
        
        let logsTableViewCellNib = UINib(nibName: "LogsTableViewCell", bundle: nil)
        self.tableView.register(logsTableViewCellNib, forCellReuseIdentifier: "LogsCell")
        navigationController?.navigationBar.prefersLargeTitles = false
        
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            self.dataStore = appDelegate.dataStore
        }
        
        mapCell = UITableViewCell()
        mapView = MKMapView(frame: mapCell.contentView.frame)
        self.mapView.delegate = self
        mapView.translatesAutoresizingMaskIntoConstraints = false
        mapCell.contentView.addSubview(mapView)
        let layoutLeft = NSLayoutConstraint(item: mapView!, attribute: .leading, relatedBy: .equal, toItem: mapCell.contentView, attribute: .leading, multiplier: 1, constant: 0)
        let layoutRight = NSLayoutConstraint(item: mapView!, attribute: .trailing, relatedBy: .equal, toItem: mapCell.contentView, attribute: .trailing, multiplier: 1, constant: 0)
        let layoutTop = NSLayoutConstraint(item: mapView!, attribute: .top, relatedBy: .equal, toItem: mapCell.contentView, attribute: .top, multiplier: 1, constant: 0)
        let layoutBottom = NSLayoutConstraint(item: mapView!, attribute: .bottom, relatedBy: .equal, toItem: mapCell.contentView, attribute: .bottom, multiplier: 1, constant: 0)
        mapCell.addConstraints([layoutLeft, layoutRight, layoutTop, layoutBottom])

        let activity = UIActivityIndicatorView()
        activity.translatesAutoresizingMaskIntoConstraints = false
        activity.style = .large
        activity.hidesWhenStopped = true
        activity.stopAnimating()
        mapCell.contentView.addSubview(activity)
        let activityLayoutCenterX = NSLayoutConstraint(item: activity, attribute: .centerX, relatedBy: .equal, toItem: mapCell.contentView, attribute: .centerX, multiplier: 1, constant: 0)
        let activityLayoutCenterY = NSLayoutConstraint(item: activity, attribute: .centerY, relatedBy: .equal, toItem: mapCell.contentView, attribute: .centerY, multiplier: 1, constant: 0)
        mapCell.addConstraints([activityLayoutCenterX, activityLayoutCenterY])

        activity.startAnimating()
        DispatchQueue.global(qos: .userInitiated).async {
            for track in self.tracksSummary!.tracks {
                track.trackPoints = self.dataStore.getPointsForTrack(vgTrack: track).sorted()
            }
            DispatchQueue.main.async {
                self.display(tracks: self.tracksSummary!.tracks, on: self.mapView)
                activity.stopAnimating()
            }
        }

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        }
        return self.tracksSummary!.tracks.count
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            return 300
        }
        return 76
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.section == 0 {
            return mapCell
        }
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: "LogsCell",
            for: indexPath
            ) as? LogsTableViewCell else {
            return UITableViewCell()
        }
        
        cell.show(track:self.tracksSummary!.tracks[indexPath.row])
        return cell
    }
    
    func display(tracks: [VGTrack], on mapView: MKMapView) {
        var maxLat = -Double.infinity
        var minLat = Double.infinity
        var maxLon = -Double.infinity
        var minLon = Double.infinity
        var hasPoints = false
        
        for track in tracks {
            let list = track.getCoordinateList()
            if list.count > 0 {
                hasPoints = true
            } else {
                continue
            }
            if maxLat < max(track.maxLat, track.minLat)  {
                maxLat = max(track.maxLat, track.minLat)
            }
            
            if maxLon < max(track.maxLon, track.minLon)  {
                maxLon = max(track.maxLon, track.minLon)
            }
            
            if minLat > min(track.minLat, track.maxLat)  {
                minLat = min(track.minLat, track.maxLat)
            }
            
            if minLon > min(track.minLon, track.maxLon)  {
                minLon = min(track.minLon, track.maxLon)
            }
            
            DispatchQueue.main.async {
                let polyline = MKPolyline(coordinates: list, count: list.count)
                mapView.addOverlay(polyline)
            }
        }
        
        // pad our map by 10% around the farthest annotations
        let MAP_PADDING = 1.1
        
        // we'll make sure that our minimum vertical span is about a kilometer
        // there are ~111km to a degree of latitude. regionThatFits will take care of
        // longitude, which is more complicated, anyway.
        let MINIMUM_VISIBLE_LATITUDE = 0.01
        let centerLat = (minLat + maxLat) / 2
        let centerLon = (minLon + maxLon) / 2
        
        let centerCoord = CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon)
        
        var latitudeDelta = abs(maxLat - minLat) * MAP_PADDING
        
        latitudeDelta = (latitudeDelta < MINIMUM_VISIBLE_LATITUDE)
            ? MINIMUM_VISIBLE_LATITUDE
            : latitudeDelta
        
        let longitudeDelta = abs((maxLon - minLon) * MAP_PADDING)
        let span = MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
        let region = MKCoordinateRegion(center: centerCoord, span: span)
        if hasPoints {
            self.mapView.setRegion(region, animated: false)
        }
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

extension HistoryDetailsTableViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        
        if overlay is MKPolyline {
            let polylineRender = MKPolylineRenderer(overlay: overlay)
            polylineRender.strokeColor = UIColor.red
            polylineRender.lineWidth = 2
            return polylineRender
        }
        return MKOverlayRenderer(overlay: overlay)
    }
    
}