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

                self.vgFileManager.split(track: self.track, at: selectedTime)
                let (oldTrack, newTrack) = self.dataStore.split(track: self.track, at: selectedTime)
                //self.dataStore.delete(vgTrack: self.track)
                //oldTrack.process()
                //self.vgSnapshotMaker.drawTrack(vgTrack: oldTrack)
                //self.dataStore.update(vgTrack: oldTrack)
                //newTrack.process()
                //self.vgSnapshotMaker.drawTrack(vgTrack: newTrack)
                //self.dataStore.update(vgTrack: newTrack)
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
            trackSegmentView.backgroundColor = .red
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
