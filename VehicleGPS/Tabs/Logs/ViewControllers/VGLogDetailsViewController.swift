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
    
    var track: VGTrack! {
        didSet {
            if trackDataTableViewController == nil {
                initializeTrackDataView()
            }
            getTrackPoints(for:track)
        }
    }
    var dataStore: VGDataStore!
    var vgFileManager: VGFileManager!
    var vgLogParser: IVGLogParser!
    var vgGPXGenerator = VGGPXGenerator()
    var detailSegment: UISegmentedControl?
    var barsHidden = false

    override func viewWillAppear(_ animated: Bool) {
        navigationController?.navigationBar.prefersLargeTitles = false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            self.vgFileManager = appDelegate.fileManager
            self.dataStore = appDelegate.dataStore
        }
        initializeMapView()
        if trackDataTableViewController == nil {
            initializeTrackDataView()
        }
        self.view.backgroundColor = .systemBackground
                
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image:Icons.moreActions, primaryAction: nil, menu: createMenu())

        detailSegment = UISegmentedControl(items: [Strings.map, Strings.statistics])
        detailSegment!.addTarget(self, action: #selector(segmentedControlValueChanged), for: .valueChanged)
        detailSegment!.selectedSegmentIndex = 0
        self.navigationItem.titleView = detailSegment
        self.view.addSubview(mapSegmentView)

        self.mapView.mapType = .hybrid
        self.mapView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(mapTapped)))
        guard let track = track else {
            return
        }
        getTrackPoints(for:track)
    }
    
    func getTrackPoints(for track:VGTrack) {
        if track.mapPoints.count == 0 {
            self.dataStore.getMapPointsForTrack(with: track.id!, onSuccess: { (mapPoints) in
                track.mapPoints = mapPoints
                if track.mapPoints.count != 0 {
                    self.mapView.tracks = [track]
                }
            }) { (error) in
                self.appDelegate.display(error: error)
            }
        } else {
            if self.mapView != nil {
                let overlays = mapView.overlays
                mapView.removeOverlays(overlays)
                self.mapView.tracks = [track]
            }
        }
        
        if track.trackPoints.count == 0 {
            self.dataStore.getDataPointsForTrack(with: track.id!, onSuccess: { (dataPoints) in
                track.trackPoints = dataPoints
                self.trackDataTableViewController.track = track
            }) { (error) in
                self.appDelegate.display(error: error)
            }
        }

    }
    override var prefersStatusBarHidden: Bool {
        return barsHidden
    }
    
    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return .slide
    }
    
    @objc func mapTapped() {
        
        if barsHidden {
            self.navigationController?.setNavigationBarHidden(false, animated: true)
            barsHidden = false
            self.showTabBar()
        } else {
            self.navigationController?.setNavigationBarHidden(true, animated: true)
            barsHidden = true
            self.hideTabBar()

        }
        
    }
    
    func hideTabBar() {
        guard var frame = self.tabBarController?.tabBar.frame else {
            return
        }
        frame.origin.y = self.view.frame.size.height + frame.size.height
        UIView.animate(withDuration: 0.2, animations: {
            self.tabBarController?.tabBar.frame = frame
            self.setNeedsStatusBarAppearanceUpdate()
        })

    }

    func showTabBar() {
        guard var frame = self.tabBarController?.tabBar.frame else {
            return
        }
        frame.origin.y = self.view.frame.size.height - frame.size.height
        UIView.animate(withDuration: 0.2, animations: {
            self.tabBarController?.tabBar.frame = frame
            self.setNeedsStatusBarAppearanceUpdate()

        })
    }
    
    func createMenu() -> UIMenu? {
        var actions = [UIAction]()
        guard let track = track else {
            return nil
        }
        if vgFileManager.fileForTrackExists(track: track) {
            actions.append(UIAction(title: Strings.shareCSV, image:Icons.share, handler: { (action) in
                let activityVC = UIActivityViewController(activityItems: [self.vgFileManager.getAbsoluteFilePathFor(track: self.track)!], applicationActivities: nil)
                self.present(activityVC, animated: true, completion: nil)
            }))
        }
        
        actions.append(UIAction(title: Strings.shareGPX, image:Icons.share, handler: { (action) in
            //self.track.trackPoints = self.dataStore.getDataPointsForTrack(vgTrack: self.track)
            let activityVC = UIActivityViewController(activityItems: [self.vgGPXGenerator.generateGPXFor(tracks: [self.track])!], applicationActivities: nil)
            self.present(activityVC, animated: true, completion: nil)
        }))
        
        actions.append(UIAction(title: Strings.selectVehicle, image:Icons.vehicle, handler: { (action) in
            let vehCont = VGVehiclesSelectionTableViewController(style: .insetGrouped)
            vehCont.track = self.track
            let navCont = UINavigationController(rootViewController: vehCont)
            self.present(navCont, animated: true, completion: nil)
        }))
        
        actions.append(UIAction(title: Strings.splitLog, image:Icons.split, handler: { (action) in
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
                self.appDelegate.display(error: error)
            }
            
            rightTrack.process()
            self.dataStore.add(vgTrack: rightTrack, onSuccess: { (id) in
                print("ADDED SUCCESSFULLY \(id)")
            }) { (error) in
                print("ERROR ADDING")
                self.appDelegate.display(error: error)
            }
            
        }))
        
        actions.append(UIAction(title: Strings.delete, image:Icons.delete, attributes: .destructive, handler: { (action) in
            self.dataStore.delete(trackWith: self.track.id!) {
                self.navigationController?.popViewController(animated: true)
            } onFailure: { (error) in
                self.appDelegate.display(error: error)
            }
        }))
        
        return UIMenu(title: "", children: actions)
    }
    
    @objc func displayShareSelection() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        alert.addAction(UIAlertAction(title: Strings.splitLog, style: .default, handler: { (_) in

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
        trackSegmentView = UIView(frame: self.view.frame)
        trackDataTableViewController = VGLogDetailsTrackTableViewController(style: .grouped)
        trackDataTableViewController!.track = self.track
        addChild(trackDataTableViewController!)
        trackSegmentView.addSubview(trackDataTableViewController!.view)
        trackDataTableViewController!.view.translatesAutoresizingMaskIntoConstraints = false
        
        guard let dataView = trackDataTableViewController.view else {
            return
        }

        let topConstraint = NSLayoutConstraint(item: dataView, attribute: .top, relatedBy: .equal, toItem: trackSegmentView!, attribute: .top, multiplier: 1, constant: 0)
        let bottomConstraint = NSLayoutConstraint(item: dataView, attribute: .bottom, relatedBy: .equal, toItem: trackSegmentView!, attribute: .bottom, multiplier: 1, constant: 0)
        let leadingConstraint = NSLayoutConstraint(item: dataView, attribute: .leading, relatedBy: .equal, toItem: trackSegmentView!, attribute: .leading, multiplier: 1, constant: 0)
        let trailingConstraint = NSLayoutConstraint(item: dataView, attribute: .trailing, relatedBy: .equal, toItem: trackSegmentView!, attribute: .trailing, multiplier: 1, constant: 0)

        NSLayoutConstraint.activate([topConstraint, bottomConstraint, leadingConstraint, trailingConstraint])

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
