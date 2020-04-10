//
//  VGMapView.swift
//  VehicleGPS
//
//  Created by Bergþór Þrastarson on 07/04/2020.
//  Copyright © 2020 Bergþór Þrastarson. All rights reserved.
//

import Foundation
import MapKit
import UIKit

class VGMapView: MKMapView {
    var activity: UIActivityIndicatorView!
    var vehicleColor:UIColor = .red
    var dataStore = VGDataStore()

    
    var tracks = [VGTrack]() {
        didSet {
            activity.startAnimating()
            guard let region = self.getRegion(for:self.tracks) else {
                self.activity.stopAnimating()
                return
            }
            if region.span.latitudeDelta != 400 {
                self.setRegion(region, animated: false)

            }
            let dpGroup = DispatchGroup()
            for track in self.tracks {
                dpGroup.enter()
                self.dataStore.getMapPointsForTrack(with: track.id!, onSuccess: { (mapPoints) in
                    track.mapPoints = mapPoints
                    self.display(track: track, on: self)
                    dpGroup.leave()
                }) { (error) in
                    print(error)
                    dpGroup.leave()
                }
            }
            
            dpGroup.notify(queue: .main) {
                self.activity.stopAnimating()
            }
            

        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        delegate = self
        activity = UIActivityIndicatorView()
        activity.translatesAutoresizingMaskIntoConstraints = false
        activity.style = .large
        activity.hidesWhenStopped = true
        activity.stopAnimating()
        self.addSubview(activity)
        let activityLayoutCenterX = NSLayoutConstraint(item: activity!, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1, constant: 0)
        let activityLayoutCenterY = NSLayoutConstraint(item: activity!, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1, constant: 0)
        self.addConstraints([activityLayoutCenterX, activityLayoutCenterY])

        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func getRegion(for tracks: [VGTrack]) -> MKCoordinateRegion? {
        if tracks.count == 0 {
            return nil
        }
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


extension VGMapView: MKMapViewDelegate {
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
