//
//  PulleyEditorViewController.swift
//  VehicleGPS
//
//  Created by Bergþór Þrastarson on 28.1.2021.
//  Copyright © 2021 Bergþór Þrastarson. All rights reserved.
//

import UIKit
import Pulley

class PulleyEditorViewController: PulleyViewController {
    var mapViewController: VGEditorMapViewController!
    var summaryViewController: VGEditorTrackViewController!
    
    var track: VGTrack? {
        didSet {
            if track == nil {
                return
            }
            title = VGFullDateFormatter().string(for: track?.timeStart)
            if #available(iOS 14.0, *) {
                self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: Icons.moreActions, primaryAction: nil, menu: self.createMenu())
            } else {
                self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: Icons.moreActions, style: .plain, target: self, action: #selector(displayMoreMenu))
            }
            if track!.trackPoints.count != 0 {
                return
            }
            self.dataStore.getDataPointsForTrack(with: track!.id!, onSuccess: { (points) in
                self.track!.trackPoints = points
                self.mapViewController.tracks = [self.track!]
                self.summaryViewController.tracks = [self.track!]
            }, onFailure: { (error) in
                self.appDelegate.display(error: error)
            })
        }
    }
    
    var dataStore = VGDataStore()
    var vgFileManager = VGFileManager()
    var vgGPXGenerator = VGGPXGenerator()
    
    var selectedDataPointIndex = -1

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    required init(contentViewController: UIViewController, drawerViewController: UIViewController) {
        super.init(contentViewController: contentViewController, drawerViewController: drawerViewController)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    init() {
        mapViewController = VGEditorMapViewController()
        summaryViewController = VGEditorTrackViewController()
        super.init(contentViewController: mapViewController, drawerViewController: summaryViewController)
        summaryViewController.toolbar.delegate = self
        self.displayMode = .automatic
        self.backgroundDimmingOpacity = 0
        self.initialDrawerPosition = .partiallyRevealed
    }
    
    func createMenu() -> UIMenu? {
        var actions = [UIAction]()
        guard let track = track else {
            return nil
        }
        let cma = VGMenuActions(viewController: self)
        
        if vgFileManager.fileForTrackExists(track: track) {
            actions.append(cma.getShareFileAction(for: track))
        }
        
        actions.append(cma.getGPXFileAction(for: track))
        actions.append(cma.getSelectVehicleAction(for: track))
        actions.append(cma.getDeleteAction(for: track))
        actions.append(cma.getMapToImageAction(for: [track]))
        
        return UIMenu(title: "", children: actions)
    }
    
    @objc func displayMoreMenu() {
        let alert = UIAlertController()
        guard let track = track else {
            return
        }
        let cma = VGMenuActions(viewController: self)
        
        if vgFileManager.fileForTrackExists(track: track) {
            alert.addAction(cma.getShareFileAction(for: track))
        }
        
        alert.addAction(cma.getGPXFileAction(for: track))
        alert.addAction(cma.getSelectVehicleAction(for: track))
        alert.addAction(cma.getDeleteAction(for: track))
        alert.addAction(cma.getMapToImageAction(for: [track]))
        alert.addAction(cma.getCancelAction())
        
        present(alert, animated: true)
    }
    
    func split(track: VGTrack, at timestamp: Date) -> (VGTrack?, VGTrack?) {
        let newTrack = VGTrack()
        var pointIndex = -1
        for (index, (dataPoint1, dataPoint2)) in zip(track.trackPoints, track.trackPoints.dropFirst()).enumerated() {
            guard let timestamp1 = dataPoint1.timestamp, let timestamp2 = dataPoint2.timestamp else {
                continue
            }
            
            if timestamp1 < timestamp {
                pointIndex = index
            }
            
            if abs(timestamp1.timeIntervalSince(timestamp)) > abs(timestamp2.timeIntervalSince(timestamp)) {
                pointIndex += 1
            }
        }
        
        if pointIndex == -1 {
            return (nil, nil)
        }
        
        if pointIndex >= track.trackPoints.count {
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
    
    func split() {
        guard let track = track else {
            return
        }
        
        guard let trackViewController = self.drawerContentViewController as? VGEditorTrackViewController else {
            return
        }
        
        guard let mapViewController = self.primaryContentViewController as? VGEditorMapViewController else {
            return
        }
        
        guard let selectedTime = trackViewController.tvcontroller.dlpTime else {
            return
        }

        let (oldTrack, newTrack) = self.split(track: track, at: selectedTime)

        guard let leftTrack = oldTrack, let rightTrack = newTrack else {
            return
        }

        leftTrack.process()
        rightTrack.process()
        
        self.dataStore.add(vgTrack: rightTrack, onSuccess: { (id) in
            self.dataStore.update(vgTrack: leftTrack, onSuccess: { (id) in
                self.dataStore.getDataPointsForTrack(with: track.id!, onSuccess: { (points) in
                    leftTrack.trackPoints = points
                    trackViewController.tvcontroller.dlpTime = nil
                    trackViewController.tvcontroller.dlpPoint = nil
                    mapViewController.tracks = [leftTrack]
                    trackViewController.tracks = [leftTrack]
                    
                }, onFailure: { (error) in
                    self.appDelegate.display(error: error)
                })

                mapViewController.tracks = [oldTrack!]
                trackViewController.tracks = [oldTrack!]
            }, onFailure: { (error) in
                print("ERROR UPDATING")
                self.appDelegate.display(error: error)
            })
        }, onFailure: { (error) in
            print("ERROR ADDING")
            self.appDelegate.display(error: error)
        })
    }
}

extension PulleyEditorViewController: VGEditorToolbarDelegate {
    func didTap(button: ButtonType) {
        guard let track = track else {
            return
        }
        switch button {
        case .next:
            if selectedDataPointIndex == track.trackPoints.count-1 {
                selectedDataPointIndex = 0
            } else {
                selectedDataPointIndex += 1
            }
            print(track.trackPoints[selectedDataPointIndex])
        case .previous:
            if selectedDataPointIndex == -1 {
                selectedDataPointIndex = track.trackPoints.count-1
            } else if selectedDataPointIndex == 0 {
                selectedDataPointIndex = track.trackPoints.count-1
            } else {
                selectedDataPointIndex -= 1
            }
            print(track.trackPoints[selectedDataPointIndex])
        case .split:
            split()
        }
        //mapViewController.editorMapView
        
    }
}
