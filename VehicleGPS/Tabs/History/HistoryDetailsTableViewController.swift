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
            let region = self.getRegion(for:self.tracksSummary!.tracks)
            if region.span.latitudeDelta != 400 {
                DispatchQueue.main.async {
                    self.mapView.setRegion(region, animated: false)
                }
            }
            for track in self.tracksSummary!.tracks {
                track.mapPoints = self.dataStore.getMapPointsForTrack(vgTrack: track)
                self.display(track: track, on: self.mapView)
            }
            DispatchQueue.main.async {
                activity.stopAnimating()
            }
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
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
        return UITableView.automaticDimension
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 1 {
            let track = self.tracksSummary!.tracks[indexPath.row]
            let logDetailsView = VGLogDetailsViewController(nibName: nil, bundle: nil)
            logDetailsView.dataStore = self.dataStore
            logDetailsView.track = track
            self.navigationController?.pushViewController(logDetailsView, animated: true)
        }
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
    var vehicleColor:UIColor = .red
    
    func getRegion(for tracks: [VGTrack]) -> MKCoordinateRegion {
        var maxLat = -Double.infinity
        var minLat = Double.infinity
        var maxLon = -Double.infinity
        var minLon = Double.infinity
        
        for track in tracks {
            let maxLatMax = max(track.maxLat, track.minLat)
            if maxLat < maxLatMax && maxLatMax != 200 {
                maxLat = maxLatMax
            }
            
            let maxLonMax = max(track.maxLon, track.minLon)
            if maxLon < maxLonMax && maxLonMax != 200 {
                maxLon = maxLonMax
            }
            let minLatMin = min(track.minLat, track.maxLat)
            if minLat > minLatMin && minLatMin != -200 {
                minLat = minLatMin
            }
            
            let minLonMin = min(track.minLon, track.maxLon)
            if minLon > minLonMin && minLonMin != -200 {
                minLon = minLonMin
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
        return MKCoordinateRegion(center: centerCoord, span: span)

    }
    func display(track: VGTrack, on mapView: MKMapView) {
        if !(track.mapPoints.count > 0) {
            return
        }

        let points = track.mapPoints.map { (point) -> CLLocationCoordinate2D in
            return CLLocationCoordinate2D(latitude: point.latitude, longitude: point.longitude)
        }
        let polyline = MKPolyline(coordinates: points, count: points.count)

        DispatchQueue.main.async {
            if let color = track.vehicle?.mapColor {
                self.vehicleColor = color
            } else {
                self.vehicleColor = .red
            }
            mapView.addOverlay(polyline)
        }
    }
}

extension HistoryDetailsTableViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        
        if overlay is MKPolyline {
            let polylineRender = MKPolylineRenderer(overlay: overlay)
            polylineRender.strokeColor = vehicleColor
            polylineRender.lineWidth = 1
            return polylineRender
        }
        return MKOverlayRenderer(overlay: overlay)
    }
    
}
