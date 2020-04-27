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
    
    var trackDataTableViewController: VGLogDetailsTrackTableViewController!
    
    var mapView: VGMapView!
    
    var track: VGTrack!
    var dataStore: VGDataStore!
    var vgFileManager: VGFileManager!
    var vgLogParser: IVGLogParser!
    var vgGPXGenerator = VGGPXGenerator()
    var detailSegment: UISegmentedControl?

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
        detailSegment = UISegmentedControl(items: [Strings.map, Strings.statistics])
        detailSegment!.addTarget(self, action: #selector(segmentedControlValueChanged), for: .valueChanged)
        detailSegment!.selectedSegmentIndex = 0
        self.navigationItem.titleView = detailSegment
        self.view.addSubview(mapSegmentView)

        self.mapView.mapType = .hybrid
        if self.track.mapPoints.count == 0 {
            self.dataStore.getMapPointsForTrack(with: self.track.id!, onSuccess: { (mapPoints) in
                self.track.mapPoints = mapPoints
                if self.track.mapPoints.count != 0 {
                    self.mapView.tracks = [self.track]
                }
            }) { (error) in
                print(error)
            }
        } else {
            self.mapView.tracks = [self.track]
        }
        
        if self.track.trackPoints.count == 0 {
            self.dataStore.getDataPointsForTrack(with: self.track.id!, onSuccess: { (dataPoints) in
                self.track.trackPoints = dataPoints
            }) { (error) in
                print(error)
            }
        }
        
    }
    
    @objc func displayShareSelection() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.popoverPresentationController?.barButtonItem = self.navigationItem.rightBarButtonItem
        
        alert.addAction(UIAlertAction(title: Strings.cancel, style: .cancel, handler: nil))
        
        if vgFileManager.fileForTrackExists(track: track) {
            alert.addAction(UIAlertAction(title: Strings.shareCSV, style: .default, handler: { (_) in
                let activityVC = UIActivityViewController(activityItems: [self.vgFileManager.getAbsoluteFilePathFor(track: self.track)!], applicationActivities: nil)
                self.present(activityVC, animated: true, completion: nil)
            }))
        }
        
        alert.addAction(UIAlertAction(title: Strings.shareGPX, style: .default, handler: { (_) in
            //self.track.trackPoints = self.dataStore.getDataPointsForTrack(vgTrack: self.track)
            let activityVC = UIActivityViewController(activityItems: [self.vgGPXGenerator.generateGPXFor(track: self.track)!], applicationActivities: nil)
            self.present(activityVC, animated: true, completion: nil)
        }))
        
        alert.addAction(UIAlertAction(title: Strings.selectVehicle, style: .default, handler: { (_) in
            let vehCont = VGVehiclesSelectionTableViewController(style: .insetGrouped)
            vehCont.track = self.track
            let navCont = UINavigationController(rootViewController: vehCont)
            self.present(navCont, animated: true, completion: nil)
        }))

        alert.addAction(UIAlertAction(title: Strings.splitLog, style: .default, handler: { (_) in
            guard let selectedTime = self.trackDataTableViewController?.dlpTime else {
                return
            }

            let (oldTrack, newTrack) = self.split(track: self.track, at: selectedTime)
            
            guard let leftTrack = oldTrack, let rightTrack = newTrack else {
                return
            }
            

            leftTrack.process()
            self.dataStore.update(vgTrack: leftTrack, onSuccess: { (id) in
                print("UPDATED SUCCESSFULLY: \(id)")
            }) { (error) in
                print("ERROR UPDATING")
                print(error)
            }
            
            rightTrack.process()
            self.dataStore.add(vgTrack: rightTrack, onSuccess: { (id) in
                print("ADDED SUCCESSFULLY \(id)")
            }) { (error) in
                print("ERROR ADDING")
                print(error)
            }
        }))
        
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
        mapView = VGMapView(frame: view.bounds)
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
    
    deinit {
        trackSegmentView.removeFromSuperview()
    }

    func initializeTrackDataView() {
        trackSegmentView = UIView(frame: view.frame)
        trackDataTableViewController = VGLogDetailsTrackTableViewController(style: .grouped)
        trackDataTableViewController!.track = self.track
        addChild(trackDataTableViewController!)
        trackSegmentView.addSubview(trackDataTableViewController!.view)
        trackDataTableViewController!.didMove(toParent: self)
    }
    
    func split(track:VGTrack, at timestamp:Date) -> (VGTrack?, VGTrack?) {
        let newTrack = VGTrack()
        var pointIndex = -1
        for (index, dataPoint) in track.trackPoints.enumerated() {
            if dataPoint.timestamp! < timestamp {
                pointIndex = index
            }
        }
        
        if pointIndex == -1 {
            return (nil, nil)
        }
        
        let leftSplit = track.trackPoints[0 ... pointIndex]
        let rightSplit = track.trackPoints[pointIndex ..< track.trackPoints.count]
        
        if rightSplit.count != 0 {
            track.trackPoints = Array(leftSplit)
            newTrack.trackPoints = Array(rightSplit)
        }
        
        return (track, newTrack)
    }
}
