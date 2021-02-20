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
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(image:Icons.moreActions, primaryAction: nil, menu: self.createMenu())
            if track!.trackPoints.count != 0 {
                return
            }
            self.dataStore.getDataPointsForTrack(with: track!.id!) { (points) in
                self.track!.trackPoints = points
                self.mapViewController.tracks = [self.track!]
                self.summaryViewController.tracks = [self.track!]
            } onFailure: { (error) in
                self.appDelegate.display(error: error)
            }

            
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
        if vgFileManager.fileForTrackExists(track: track) {
            actions.append(UIAction(title: Strings.shareCSV, image:Icons.share, handler: { (action) in
                let activityVC = UIActivityViewController(activityItems: [self.vgFileManager.getAbsoluteFilePathFor(track: track)!], applicationActivities: nil)
                self.present(activityVC, animated: true, completion: nil)
            }))
        }
        
        actions.append(UIAction(title: Strings.shareGPX, image:Icons.share, handler: { (action) in
            //self.track.trackPoints = self.dataStore.getDataPointsForTrack(vgTrack: self.track)
            let activityVC = UIActivityViewController(activityItems: [self.vgGPXGenerator.generateGPXFor(tracks: [track])!], applicationActivities: nil)
            self.present(activityVC, animated: true, completion: nil)
        }))
        
        actions.append(UIAction(title: Strings.selectVehicle, image:Icons.vehicle, handler: { (action) in
            let vehCont = VGVehiclesSelectionTableViewController(style: .insetGrouped)
            vehCont.track = track
            let navCont = UINavigationController(rootViewController: vehCont)
            self.present(navCont, animated: true, completion: nil)
        }))
        
        actions.append(UIAction(title: Strings.delete, image:Icons.delete, attributes: .destructive, handler: { (action) in
            self.dataStore.delete(trackWith: track.id!) {
                self.navigationController?.popViewController(animated: true)
            } onFailure: { (error) in
                self.appDelegate.display(error: error)
            }
        }))
        
        actions.append(UIAction(title: Strings.exportMapAsImage, image: Icons.photo) { (action) in
            self.mapToImage()
        })
        
        return UIMenu(title: "", children: actions)
    }
    
    func split(track:VGTrack, at timestamp:Date) -> (VGTrack?, VGTrack?) {
        let newTrack = VGTrack()
        var pointIndex = -1
        for (index, (dataPoint1,dataPoint2)) in zip(track.trackPoints, track.trackPoints.dropFirst()).enumerated() {
            if dataPoint1.timestamp! < timestamp {
                pointIndex = index
                
            }
            if abs(dataPoint1.timestamp!.timeIntervalSince(timestamp)) > abs(dataPoint2.timestamp!.timeIntervalSince(timestamp)) {
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
            print("ADDED SUCCESSFULLY \(id)")
            self.dataStore.update(vgTrack: leftTrack, onSuccess: { (id) in
                print("UPDATED SUCCESSFULLY: \(id)")
                self.dataStore.getDataPointsForTrack(with: track.id!) { (points) in
                    leftTrack.trackPoints = points
                    trackViewController.tvcontroller.dlpTime = nil
                    trackViewController.tvcontroller.dlpPoint = nil
                    mapViewController.tracks = [leftTrack]
                    trackViewController.tracks = [leftTrack]
                    
                } onFailure: { (error) in
                    self.appDelegate.display(error: error)
                }

                mapViewController.tracks = [oldTrack!]
                trackViewController.tracks = [oldTrack!]
            }) { (error) in
                print("ERROR UPDATING")
                self.appDelegate.display(error: error)
            }
        }) { (error) in
            print("ERROR ADDING")
            self.appDelegate.display(error: error)
        }


    }

}

extension PulleyEditorViewController: VGEditorToolbarDelegate  {
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
            break
        case .previous:
            if selectedDataPointIndex == -1 {
                selectedDataPointIndex = track.trackPoints.count-1
            } else if selectedDataPointIndex == 0 {
                selectedDataPointIndex = track.trackPoints.count-1
            } else {
                selectedDataPointIndex -= 1
            }
            print(track.trackPoints[selectedDataPointIndex])
            break
        case .split:
            split()
            break
        }
        //mapViewController.editorMapView
        
    }
    
    func mapToImage() {
        guard let delegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        guard let track = self.track else {
            return
        }
        self.dataStore.getMapPointsForTrack(with: track.id!, onSuccess: { (mapPoints) in
            track.mapPoints = mapPoints
            
            var drawnTracks = [VGTrack]()
        
            if track.distance != 0.0 {
                drawnTracks.append(track)
            }
        
            delegate.snapshotter.drawTracks(vgTracks: drawnTracks) { (image, style) -> Void? in
                if let image = image {
                    guard let pngImageData = image.pngData() else {
                        return nil
                    }
                    let vc = UIActivityViewController(activityItems: [pngImageData], applicationActivities: [])
                    DispatchQueue.main.async {
                        self.present(vc, animated: true)
                    }
                }
                return nil
            }


        }) { (error) in
            print(error)
        }

    }


}
