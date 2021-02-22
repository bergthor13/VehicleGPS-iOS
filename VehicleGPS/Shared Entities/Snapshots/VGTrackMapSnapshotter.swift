//
//  VGTrackMapSnapshotter.swift
//  VehicleGPS
//
//  Created by Bergþór Þrastarson on 20/01/2020.
//  Copyright © 2020 Bergþór Þrastarson. All rights reserved.
//

import Foundation
import MapKit

class VGTrackMapSnapshotter: MKMapSnapshotter {
    
    init(style: UIUserInterfaceStyle, coordinates: [CLLocationCoordinate2D]) {
        let mapSnapshotOptions = MKMapSnapshotter.Options()
        
        var maxLat = -200.0, minLat = 200.0, maxLon = -200.0, minLon = 200.0
        
        for coord in coordinates {
            if coord.latitude > maxLat {
                maxLat = coord.latitude
            }
            if coord.latitude < minLat {
                minLat = coord.latitude
            }
            if coord.longitude > maxLon {
                maxLon = coord.longitude
            }
            if coord.longitude < minLon {
                minLon = coord.longitude
            }
        }
        
        let latCenter = (maxLat+minLat)/2
        let lonCenter = (maxLon+minLon)/2
        
        let location = CLLocationCoordinate2DMake(latCenter, lonCenter)
        
        // pad our map by 10% around the farthest annotations
        let MAP_PADDING = 1.1
        
        // we'll make sure that our minimum vertical span is about a kilometer
        // there are ~111km to a degree of latitude. regionThatFits will take care of
        // longitude, which is more complicated, anyway.
        let MINIMUM_VISIBLE_LATITUDE = 0.005

        var latitudeDelta = abs(maxLat - minLat) * MAP_PADDING
        
        latitudeDelta = (latitudeDelta < MINIMUM_VISIBLE_LATITUDE)
            ? MINIMUM_VISIBLE_LATITUDE
            : latitudeDelta
        
        let longitudeDelta = abs((maxLon - minLon) * MAP_PADDING)

        // Set the region of the map that is rendered.
        let region = MKCoordinateRegion(center: location, span: MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta))
        mapSnapshotOptions.region = region
        
        // Set the scale of the image. We'll just use the scale of the current device, which is 2x scale on Retina screens.
        mapSnapshotOptions.scale = UIScreen.main.scale
        
        // Set the size of the image output.
        mapSnapshotOptions.size = CGSize(width: 110, height: 110)
        
        // Show buildings and Points of Interest on the snapshot
        mapSnapshotOptions.showsBuildings = true
        let poiFilter = MKPointOfInterestFilter(excluding: [])
        mapSnapshotOptions.pointOfInterestFilter = poiFilter
        
        let tc = UITraitCollection(userInterfaceStyle: style)
        mapSnapshotOptions.traitCollection = tc
        
        super.init(options: mapSnapshotOptions)
    }
    
    func drawCoordinates() {
        
    }
}
