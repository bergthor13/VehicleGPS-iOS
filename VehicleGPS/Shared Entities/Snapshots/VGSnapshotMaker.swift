//
//  VGSnapshotMaker.swift
//  VehicleGPS
//
//  Created by Bergþór Þrastarson on 20/01/2020.
//  Copyright © 2020 Bergþór Þrastarson. All rights reserved.
//

import Foundation
import UIKit
import MapKit

struct ImageUpdatedNotification {
    var image: UIImage
    var style: UIUserInterfaceStyle
    var track: VGTrack
}

class VGSnapshotMaker {
    let vgFileManager:VGFileManager
    let vgDataStore:VGDataStore
    init(fileManager:VGFileManager, dataStore:VGDataStore) {
        vgFileManager = fileManager
        vgDataStore = dataStore
        NotificationCenter.default.addObserver(self, selector: #selector(addedToTrack(_:)), name: .vehicleAddedToTrack , object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(shouldGenerateImage(_:)), name: .logsAdded, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(shouldGenerateImage(_:)), name: .logUpdated, object: nil)
    }
    
    @objc func shouldGenerateImage(_ notification:Notification) {
        guard let newTracks = notification.object as? [VGTrack] else {
            return
        }
        
        for newTrack in newTracks {
            if newTrack.mapPoints.count == 0 {
                vgDataStore.getMapPointsForTrack(
                    with: newTrack.id!,
                    onSuccess: { (mapPoints) in
                        newTrack.mapPoints = mapPoints
                        NotificationCenter.default.post(name: .previewImageStartingUpdate, object: newTrack)
                        self.drawTrack(vgTrack: newTrack) { (image, style) -> Void? in
                            NotificationCenter.default.post(name: .previewImageFinishingUpdate, object: ImageUpdatedNotification(image: image!, style: style!, track: newTrack))
                            self.vgFileManager.savePNG(image: image!, for: newTrack, style: style!)
                            return nil
                        }
                    }, onFailure: { (error) in
                        print(error)
                    }
                )
            }
        }
    }
    
    @objc func addedToTrack(_ notification:Notification) {
        guard let newTrack = notification.object as? VGTrack else {
            return
        }
        if newTrack.mapPoints.count == 0 {
            vgDataStore.getMapPointsForTrack(with: newTrack.id!, onSuccess: { (mapPoints) in
                newTrack.mapPoints = mapPoints
                NotificationCenter.default.post(name: .previewImageStartingUpdate, object: newTrack)
                self.drawTrack(vgTrack: newTrack) { (image, style) -> Void? in
                    NotificationCenter.default.post(name: .previewImageFinishingUpdate, object: ImageUpdatedNotification(image: image!, style: style!, track: newTrack))
                    self.vgFileManager.savePNG(image: image!, for: newTrack, style: style!)
                    return nil
                }
            }) { (error) in
                print(error)
            }
        }
        
        
    }
    
    
    
    func drawTrack(vgTrack:VGTrack, imageCallback:(@escaping(UIImage?,UIUserInterfaceStyle?)->Void?) = {_,_ in }) {
        let coordinateList = vgTrack.getMapPoints()
        var snapshotter:MKMapSnapshotter?
        
        for style in [UIUserInterfaceStyle.light, UIUserInterfaceStyle.dark] {
            if coordinateList.count == 0 {
                snapshotter = VGZeroMapSnapshotter(style: style)
            } else {
                snapshotter = VGTrackMapSnapshotter(style: style, coordinates: coordinateList)
            }
            
            snapshotter?.start(completionHandler: { (snapshot, error) in
                DispatchQueue.global(qos: .userInitiated).async {
                    guard let snapshot = snapshot else {
                        imageCallback(nil,style)
                        return
                    }
                    
                    let finalImage = UIGraphicsImageRenderer(size: snapshot.image.size).image { _ in
                        if coordinateList.count == 0 {
                            self.vgFileManager.savePNG(image: snapshot.image, for: vgTrack, style: style)
                            imageCallback(snapshot.image, style)
                            return
                        }
                        
                        // Draw the map.
                        snapshot.image.draw(at: .zero)
                        
                        // Convert [CLLocationCoordinate2D] to a [CGPoint].
                        let points = coordinateList.map { coordinate in
                            snapshot.point(for: coordinate)
                        }
                        
                        // Go to the first point in the Bezier Path.
                        let path = UIBezierPath()
                        path.move(to: points[0])
                        
                        // Create a path from the first CGPoint to the last.
                        for point in points.dropFirst() {
                            path.addLine(to: point)
                        }
                        
                        // Create a line with the Bezier Path.
                        path.lineWidth = 3
                        if let mapColor = vgTrack.vehicle?.mapColor {
                            mapColor.setStroke()
                        } else {
                            UIColor.red.setStroke()
                        }
                        
                        path.stroke()
                    }
                    if coordinateList.count > 0 {
                        self.vgFileManager.savePNG(image: finalImage, for: vgTrack, style: style)
                        imageCallback(finalImage,style)
                    }
                }
            })
        }
    }
}
