//
//  File.swift
//  VehicleGPS
//
//  Created by Bergþór Þrastarson on 20/01/2020.
//  Copyright © 2020 Bergþór Þrastarson. All rights reserved.
//

import Foundation
import MapKit

class VGZeroMapSnapshotter: MKMapSnapshotter {
    init(style: UIUserInterfaceStyle) {
        let options = MKMapSnapshotter.Options()
        let location = CLLocationCoordinate2DMake(64.9, -18.9)
        let latitudeDelta = 4.0
        let longitudeDelta = 12.0

        let region = MKCoordinateRegion(center: location, span: MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta))
        
        options.region = region
        options.scale  = UIScreen.main.scale
        options.size   = CGSize(width: 110, height: 110)
        
        options.showsBuildings = true
        let poiFilter = MKPointOfInterestFilter(excluding: [])
        options.pointOfInterestFilter = poiFilter
        
        let tc = UITraitCollection(userInterfaceStyle: style)
        options.traitCollection = tc
        super.init(options: options)
    }
}
