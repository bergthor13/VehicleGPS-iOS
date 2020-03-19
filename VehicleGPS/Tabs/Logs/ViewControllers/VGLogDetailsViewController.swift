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
    
    var trackDataTableViewController: VGLogDetailsTrackTableViewController?
    
    var mapView: MKMapView!
    
    var track: VGTrack!
    var dataStore: VGDataStore!
    var vgFileManager: VGFileManager!
    var vgLogParser: IVGLogParser!
    var vgGPXGenerator = VGGPXGenerator()
    var vgSnapshotMaker:VGSnapshotMaker!
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.navigationBar.prefersLargeTitles = false
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            self.vgFileManager = appDelegate.fileManager
        }
        initializeMapView()
        initializeTrackDataView()
        self.view.backgroundColor = .systemBackground
        
        let shareButton = UIBarButtonItem(barButtonSystemItem: .action,
                                          target: self,
                                          action: #selector(displayShareSelection))
        self.navigationItem.rightBarButtonItem = shareButton
        let detailSegment = UISegmentedControl(items: [NSLocalizedString("Kort", comment: ""), NSLocalizedString("Tölfræði", comment: "")])
        detailSegment.addTarget(self, action: #selector(segmentedControlValueChanged), for: .valueChanged)
        detailSegment.selectedSegmentIndex = 0
        self.navigationItem.titleView = detailSegment
        view.addSubview(mapSegmentView)
 
        self.mapView.delegate = self
        self.mapView.mapType = .hybrid
        
        DispatchQueue.global(qos: .userInitiated).async {
            let mapList = self.dataStore.getMapPointsForTrack(vgTrack: self.track)
            if mapList.count > 0 {
                let points = mapList.map { (point) -> CLLocationCoordinate2D in
                    return CLLocationCoordinate2D(latitude: point.latitude, longitude: point.longitude)
                }
                DispatchQueue.main.async {
                    self.display(track: self.track, list: points, on: self.mapView)
                }
            }
            

            let fullList = self.dataStore.getPointsForTrack(vgTrack: self.track)
            self.track.trackPoints = fullList
            self.vgSnapshotMaker = VGSnapshotMaker(fileManager: self.vgFileManager)

            DispatchQueue.main.async {
                if fullList.count > 0 {
                    self.display(track: self.track, list: self.track.getCoordinateList(), on: self.mapView)
                } else {
                    self.process(track: self.track)
                }
            }

            self.vgSnapshotMaker.drawTrack(vgTrack: self.track)
        }
    }
    
    func display(track: VGTrack, list: [CLLocationCoordinate2D], on mapView: MKMapView) {
        // pad our map by 10% around the farthest annotations
        let MAP_PADDING = 1.1
        
        // we'll make sure that our minimum vertical span is about a kilometer
        // there are ~111km to a degree of latitude. regionThatFits will take care of
        // longitude, which is more complicated, anyway.
        let MINIMUM_VISIBLE_LATITUDE = 0.01
        let centerLat = (track.minLat + track.maxLat) / 2
        let centerLon = (track.minLon + track.maxLon) / 2
        
        let centerCoord = CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon)
        
        var latitudeDelta = abs(track.maxLat - track.minLat) * MAP_PADDING
        
        latitudeDelta = (latitudeDelta < MINIMUM_VISIBLE_LATITUDE)
            ? MINIMUM_VISIBLE_LATITUDE
            : latitudeDelta
        
        let longitudeDelta = abs((track.maxLon - track.minLon) * MAP_PADDING)
        let span = MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
        let region = MKCoordinateRegion(center: centerCoord, span: span)
        
        DispatchQueue.main.async {
            if list.count > 0 {
                self.mapView.setRegion(region, animated: false)
            }
            let polyline = MKPolyline(coordinates: list, count: list.count)
            mapView.addOverlay(polyline)
        }
    }
    
    func process(track: VGTrack) {
        let hud = MBProgressHUD.showAdded(to: self.parent!.view, animated: true)
        hud.label.text = "Les skrá..."
        vgLogParser = vgFileManager?.getParser(for: track)
        vgLogParser.fileToTrack(fileUrl: self.vgFileManager.getAbsoluteFilePathFor(track: track)!, progress: { (index, count) in
            DispatchQueue.main.async {
                hud.mode = .annularDeterminate
                hud.progress = Float(index)/Float(count)
                hud.label.text = "Þáttar línur"
            }
        }, callback: { (track) in
            // TODO: Check for main in debugger
            self.track = track
            self.trackDataTableViewController?.track = track
            DispatchQueue.main.async {
                hud.hide(animated: true)
            }
            let mapPoints = track.trackPoints.filter { (point) -> Bool in
                return point.hasGoodFix()
            }
            track.mapPoints = VGTrack.getFilteredPointList(list:mapPoints)
            self.dataStore.update(vgTrack: track)
            
            let points = track.getCoordinateList()
            self.display(track: track, list: points, on: self.mapView)
        }, imageCallback: nil)
    }
    
    @objc func displayShareSelection() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.popoverPresentationController?.barButtonItem = self.navigationItem.rightBarButtonItem
        
        alert.addAction(UIAlertAction(title: NSLocalizedString("Hætta við", comment: ""), style: .cancel, handler: nil))

        if vgFileManager.fileForTrackExists(track: track) {
            alert.addAction(UIAlertAction(title: NSLocalizedString("Deila CSV skrá", comment: ""), style: .default, handler: { (_) in
                let activityVC = UIActivityViewController(activityItems: [self.vgFileManager.getAbsoluteFilePathFor(track: self.track)!], applicationActivities: nil)
                self.present(activityVC, animated: true, completion: nil)
            }))
            
            alert.addAction(UIAlertAction(title: NSLocalizedString("Deila GPX skrá", comment: ""), style: .default, handler: { (_) in
                let activityVC = UIActivityViewController(activityItems: [self.vgGPXGenerator.generateGPXFor(track: self.track)!], applicationActivities: nil)
                self.present(activityVC, animated: true, completion: nil)
            }))
            
            alert.addAction(UIAlertAction(title: NSLocalizedString("Vinna úr skránni aftur", comment: ""), style: .default, handler: { (_) in
                self.process(track: self.track)
            }))
            
            alert.addAction(UIAlertAction(title: NSLocalizedString("Velja farartæki", comment: ""), style: .default, handler: { (_) in
                let vehCont = VGVehiclesSelectionTableViewController(style: .insetGrouped)
                vehCont.track = self.track
                let navCont = UINavigationController(rootViewController: vehCont)
                self.present(navCont, animated: true, completion: nil)
            }))
            
            alert.addAction(UIAlertAction(title: NSLocalizedString("Skipta ferli í tvennt", comment: ""), style: .default, handler: { (_) in
                guard let selectedTime = self.trackDataTableViewController?.dlpTime else {
                    return
                }

                self.vgFileManager.split(track: self.track, at: selectedTime)
                let (oldTrack, newTrack) = self.dataStore.split(track: self.track, at: selectedTime)
                self.dataStore.delete(vgTrack: self.track)
                oldTrack.process()
                self.vgSnapshotMaker.drawTrack(vgTrack: oldTrack)
                self.dataStore.update(vgTrack: oldTrack)
                newTrack.process()
                self.vgSnapshotMaker.drawTrack(vgTrack: newTrack)
                self.dataStore.update(vgTrack: newTrack)
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
        default:
            break
        }
    }
    
    func initializeMapView() {
        mapSegmentView = UIView(frame: view.bounds)
        mapView = MKMapView(frame: view.bounds)
        mapSegmentView.addSubview(mapView)
    }
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        
        coordinator.animate(alongsideTransition: { (UIViewControllerTransitionCoordinatorContext) -> Void in
            
        }, completion: { (UIViewControllerTransitionCoordinatorContext) -> Void in
            self.mapView.frame = self.view.frame
            self.mapView.bounds = self.view.bounds
            
        })
        super.viewWillTransition(to: size, with: coordinator)
        
    }

    func initializeTrackDataView() {
        trackSegmentView = UIView(frame: view.frame)
        trackDataTableViewController = VGLogDetailsTrackTableViewController(style: .grouped)
        trackDataTableViewController!.tableView.frame = view.frame
        trackDataTableViewController!.track = self.track
        addChild(trackDataTableViewController!)
        trackSegmentView.addSubview(trackDataTableViewController!.view)
        trackDataTableViewController!.didMove(toParent: self)

    }
}

extension VGLogDetailsViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        
        if overlay is MKPolyline {
            let polylineRender = MKPolylineRenderer(overlay: overlay)
            if let color = track.vehicle?.mapColor {
                polylineRender.strokeColor = color
            } else {
                polylineRender.strokeColor = .red
            }
            
            polylineRender.lineWidth = 2
            return polylineRender
        }
        
        if overlay is MKCircle {
            let circle = MKCircleRenderer(overlay: overlay)
            circle.strokeColor = UIColor.green
            circle.fillColor = UIColor(red: 0, green: 255, blue: 0)
            circle.lineWidth = 1
            return circle
        }

        return MKOverlayRenderer(overlay: overlay)
    }
}
