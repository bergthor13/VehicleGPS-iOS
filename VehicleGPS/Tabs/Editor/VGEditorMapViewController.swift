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
        
    @IBOutlet weak var editorMapView: VGMapView!
    
    var tracks = [VGTrack]() {
        didSet {
            editorMapView.mapType = .satellite
            editorMapView.tracks = tracks
        }
    }

//    init(tracks:[VGTrack]) {
//        super.init(nibName: "VGEditorView", bundle: nil)
//        initialize()
//        self.tracks = tracks
//        editorMapView.tracks = tracks
//    }
    
    @IBAction func didTapDone(_ sender: Any) {
        dismiss(animated: true)
    }
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        //self.initialize()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    func initialize() {
        view.backgroundColor = .systemBackground
        //editorMapView.layoutMargins = UIEdgeInsets(top: 44, left: 0, bottom: 44, right: 0)
        //editorMapView.mapType = .hybrid
    }
}
