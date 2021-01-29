//
//  VGEditorViewController.swift
//  VehicleGPS
//
//  Created by Bergþór Þrastarson on 22.11.2020.
//  Copyright © 2020 Bergþór Þrastarson. All rights reserved.
//

import UIKit
import MapKit

class VGEditorMapViewController: UIViewController {
    var dlpPoint: CGPoint?
    var dlpTime: Date?
    var editorMapView: VGMapView!
    
    var tracks = [VGTrack]() {
        didSet {
            editorMapView.mapType = .satellite
            editorMapView.tracks = tracks
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        editorMapView = VGMapView()
        editorMapView.fill(parentView: self.view, with: .zero)
        

    }
}

extension VGEditorMapViewController: DisplayLineProtocol {
    func didTouchGraph(at point: CGPoint) {
        print("asdf")
    }
}
