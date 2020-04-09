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
        DispatchQueue.global(qos: .userInitiated).async {
            if self.track.mapPoints.count == 0 {
                self.track.mapPoints = self.dataStore.getMapPointsForTrack(vgTrack: self.track)
                if self.track.mapPoints.count != 0 {
                    DispatchQueue.main.async {
                        self.mapView.tracks = [self.track]
                    }
                }
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
            
            alert.addAction(UIAlertAction(title: Strings.shareGPX, style: .default, handler: { (_) in
                self.track.trackPoints = self.dataStore.getPointsForTrack(vgTrack: self.track)
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
                self.dataStore.delete(vgTrack: self.track)
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
            let layoutLeft = NSLayoutConstraint(item: mapSegmentView, attribute: .leading, relatedBy: .equal, toItem: self.view, attribute: .leading, multiplier: 1, constant: 0)
            let layoutRight = NSLayoutConstraint(item: mapSegmentView, attribute: .trailing, relatedBy: .equal, toItem: self.view, attribute: .trailing, multiplier: 1, constant: 0)
            let layoutTop = NSLayoutConstraint(item: mapSegmentView, attribute: .top, relatedBy: .equal, toItem: self.view, attribute: .top, multiplier: 1, constant: 0)
            let layoutBottom = NSLayoutConstraint(item: mapSegmentView, attribute: .bottom, relatedBy: .equal, toItem: self.view, attribute: .bottom, multiplier: 1, constant: 0)
            self.view.addConstraints([layoutLeft, layoutRight, layoutTop, layoutBottom])

        case 1:
            trackSegmentView.backgroundColor = .red
            view.addSubview(trackSegmentView)
            let layoutLeft = NSLayoutConstraint(item: trackSegmentView, attribute: .leading, relatedBy: .equal, toItem: self.view, attribute: .leading, multiplier: 1, constant: 0)
            let layoutRight = NSLayoutConstraint(item: trackSegmentView, attribute: .trailing, relatedBy: .equal, toItem: self.view, attribute: .trailing, multiplier: 1, constant: 0)
            let layoutTop = NSLayoutConstraint(item: trackSegmentView, attribute: .top, relatedBy: .equal, toItem: self.view, attribute: .top, multiplier: 1, constant: 0)
            let layoutBottom = NSLayoutConstraint(item: trackSegmentView, attribute: .bottom, relatedBy: .equal, toItem: self.view, attribute: .bottom, multiplier: 1, constant: 0)
            self.view.addConstraints([layoutLeft, layoutRight, layoutTop, layoutBottom])

        default:
            break
        }
    }
    
    @objc func preferredContentSizeChanged(_ notification: Notification) {
        guard let segment = detailSegment else {
            return
        }
        switch segment.selectedSegmentIndex {
        case 0:
            let layoutLeft = NSLayoutConstraint(item: mapSegmentView, attribute: .leading, relatedBy: .equal, toItem: self.view, attribute: .leading, multiplier: 1, constant: 0)
            let layoutRight = NSLayoutConstraint(item: mapSegmentView, attribute: .trailing, relatedBy: .equal, toItem: self.view, attribute: .trailing, multiplier: 1, constant: 0)
            let layoutTop = NSLayoutConstraint(item: mapSegmentView, attribute: .top, relatedBy: .equal, toItem: self.view, attribute: .top, multiplier: 1, constant: 0)
            let layoutBottom = NSLayoutConstraint(item: mapSegmentView, attribute: .bottom, relatedBy: .equal, toItem: self.view, attribute: .bottom, multiplier: 1, constant: 0)
            self.view.addConstraints([layoutLeft, layoutRight, layoutTop, layoutBottom])

        case 1:
            trackSegmentView.backgroundColor = .red
            let layoutLeft = NSLayoutConstraint(item: trackSegmentView, attribute: .leading, relatedBy: .equal, toItem: self.view, attribute: .leading, multiplier: 1, constant: 0)
            let layoutRight = NSLayoutConstraint(item: trackSegmentView, attribute: .trailing, relatedBy: .equal, toItem: self.view, attribute: .trailing, multiplier: 1, constant: 0)
            let layoutTop = NSLayoutConstraint(item: trackSegmentView, attribute: .top, relatedBy: .equal, toItem: self.view, attribute: .top, multiplier: 1, constant: 0)
            let layoutBottom = NSLayoutConstraint(item: trackSegmentView, attribute: .bottom, relatedBy: .equal, toItem: self.view, attribute: .bottom, multiplier: 1, constant: 0)
            
            let layoutLeft1 = NSLayoutConstraint(item: trackDataTableViewController!.tableView, attribute: .leading, relatedBy: .equal, toItem: self.view, attribute: .leading, multiplier: 1, constant: 0)
            let layoutRight1 = NSLayoutConstraint(item: trackDataTableViewController!.tableView, attribute: .trailing, relatedBy: .equal, toItem: self.view, attribute: .trailing, multiplier: 1, constant: 0)
            let layoutTop1 = NSLayoutConstraint(item: trackDataTableViewController!.tableView, attribute: .top, relatedBy: .equal, toItem: self.view, attribute: .top, multiplier: 1, constant: 0)
            let layoutBottom1 = NSLayoutConstraint(item: trackDataTableViewController!.tableView, attribute: .bottom, relatedBy: .equal, toItem: self.view, attribute: .bottom, multiplier: 1, constant: 0)

            self.view.addConstraints([layoutLeft, layoutRight, layoutTop, layoutBottom, layoutLeft1, layoutRight1, layoutTop1, layoutBottom1])

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
