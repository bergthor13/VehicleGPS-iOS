//
//  VGLogDetailsViewController.swift
//  VehicleGPS
//
//  Created by Bergþór Þrastarson on 31/05/2019.
//  Copyright © 2019 Bergþór Þrastarson. All rights reserved.
//

import UIKit
import MapKit
import MBProgressHUD

class VGLogDetailsViewController: UIViewController {
    var mapSegmentView: UIView!
    var trackSegmentView: UIView!
    var carSegmentView: UIView!
    
    var mapView: MKMapView!
    
    var track: VGTrack!
    var dataStore: VGDataStore!
    var vgFileManager =  VGFileManager()
    var vgLogParser = VGLogParser()
    var vgGPXGenerator = VGGPXGenerator()

    
    override func viewDidLoad() {
        super.viewDidLoad()
        initializeMapView()
        initializeTrackDataView()
        initializeCarDataView()
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(displayShareSelection))
        let detailSegment = UISegmentedControl(items: ["Map", "Track Data", "Car Data"])
        detailSegment.addTarget(self, action: Selector(("segmentedControlValueChanged:")), for:.valueChanged)
        detailSegment.selectedSegmentIndex = 0
        self.navigationItem.titleView = detailSegment
    
        view.addSubview(mapSegmentView)
    
        self.view.backgroundColor = .white
        self.mapView.delegate = self
        self.mapView.mapType = .hybrid
        process(track: track)
    }
    
    func process(track:VGTrack) {
        let logParser = VGLogParser()
        let hud = MBProgressHUD.showAdded(to: self.parent!.view, animated: true)
        hud.label.text = "Reading file..."
        logParser.fileToTrack(fileUrl: self.vgFileManager.getAbsoluteFilePathFor(track: track)! , progress: { (index, count) in
            DispatchQueue.main.async {
                hud.mode = .annularDeterminate
                hud.progress = Float(index)/Float(count)
                hud.label.text = "Parsing lines"
            }
            
        }) { (track) in
            self.track = track
            DispatchQueue.main.async {
                hud.hide(animated: true)
            }
            self.dataStore.update(vgTrack: track)
            
            var points = track.getCoordinateList()
            // pad our map by 10% around the farthest annotations
            let MAP_PADDING = 1.1
            
            // we'll make sure that our minimum vertical span is about a kilometer
            // there are ~111km to a degree of latitude. regionThatFits will take care of
            // longitude, which is more complicated, anyway.
            let MINIMUM_VISIBLE_LATITUDE = 0.01
            let centerLat = (track.minLat + track.maxLat) / 2;
            let centerLon = (track.minLon + track.maxLon) / 2;
            
            let centerCoord = CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon)
            
            var latitudeDelta = abs(track.maxLat - track.minLat) * MAP_PADDING;
            
            latitudeDelta = (latitudeDelta < MINIMUM_VISIBLE_LATITUDE)
                ? MINIMUM_VISIBLE_LATITUDE
                : latitudeDelta;
            
            let longitudeDelta = abs((track.maxLon - track.minLon) * MAP_PADDING)
            let region = MKCoordinateRegion(center: centerCoord, span: MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta))
            
            DispatchQueue.main.async {
                if points.count > 0 {
                    self.mapView.setRegion(region, animated: true)
                }
                let polyline = MKPolyline(coordinates: &points, count: points.count)
                self.mapView.addOverlay(polyline)
            }
        }

    }
    
    @objc func displayShareSelection() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

        if vgFileManager.fileForTrackExists(track: track) {
            alert.addAction(UIAlertAction(title: "Download CSV File", style: .default, handler: { (alertAction) in
                let activityVC = UIActivityViewController(activityItems: [self.vgFileManager.getAbsoluteFilePathFor(track: self.track)!], applicationActivities: nil)
                self.present(activityVC, animated: true, completion: nil)
            }))
            
            alert.addAction(UIAlertAction(title: "Download GPX File", style: .default, handler: { (alertAction) in
                let activityVC = UIActivityViewController(activityItems: [self.vgGPXGenerator.generateGPXFor(track: self.track)!], applicationActivities: nil)
                self.present(activityVC, animated: true, completion: nil)
            }))
            
            alert.addAction(UIAlertAction(title: "Reprocess File", style: .default, handler: { (alertAction) in
                self.process(track: self.track)
            }))
            
            alert.addAction(UIAlertAction(title: "Redownload File", style: .default, handler: { (alertAction) in
                
            }))
        }
        

        self.present(alert, animated: true, completion: nil)
    }
    @objc func segmentedControlValueChanged(_ sender: UISegmentedControl?) {
        for view in self.view.subviews {
            view.removeFromSuperview()
        }
        
        switch sender!.selectedSegmentIndex {
        case 0:
            view.addSubview(mapSegmentView)
        case 1:
            view.addSubview(trackSegmentView)
        case 2:
            view.addSubview(carSegmentView)
        default:
            break;
        }
    }
    
    func initializeMapView() {
        mapSegmentView = UIView(frame: view.frame)
        mapView = MKMapView(frame: self.view.frame)
        mapSegmentView.addSubview(mapView)
    }
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        
        coordinator.animate(alongsideTransition: { (UIViewControllerTransitionCoordinatorContext) -> Void in
            let orient = UIApplication.shared.statusBarOrientation
            
            switch orient {
                
            case .portrait:
                
                print("Portrait")
                
            case .landscapeLeft,.landscapeRight :
                
                print("Landscape")
                
            default:
                
                print("Anything But Portrait")
            }
            
        }, completion: { (UIViewControllerTransitionCoordinatorContext) -> Void in
            self.mapView.frame = self.view.frame
            
        })
        super.viewWillTransition(to: size, with: coordinator)
        
    }

    func initializeTrackDataView() {
        trackSegmentView = UIView(frame: view.frame)
//        let trackDataViewController = VGLogDetailsTrackTableViewController(style: .grouped)
//        trackDataViewController.fileLocation = self.fileLocation
//        addChild(trackDataViewController)
//        trackSegmentView.addSubview(trackDataViewController.view)
//        trackDataViewController.didMove(toParent: self)

    }
    
    func initializeCarDataView() {
        carSegmentView = UIView(frame: view.frame)
//        let carDataViewController = VGLogDetailsCarTableViewController(style: .grouped)
//        addChild(carDataViewController)
//        carSegmentView.addSubview(carDataViewController.view)
//        carDataViewController.didMove(toParent: self)

    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension VGLogDetailsViewController : MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        
        if (overlay is MKPolyline) {
            let polylineRender = MKPolylineRenderer(overlay: overlay)
            polylineRender.strokeColor = UIColor.red
            polylineRender.lineWidth = 2
            return polylineRender
        }
        return MKOverlayRenderer(overlay: overlay)
    }
    
}
