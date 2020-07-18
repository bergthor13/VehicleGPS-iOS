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
        NotificationCenter.default.addObserver(self, selector: #selector(generateImagesForTracks(_:)), name: .logsAdded, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(generateImagesForTrack(_:)), name: .logUpdated, object: nil)
    }
    
    func generateImageFor(track:VGTrack) {
        if track.mapPoints.count == 0 {
            vgDataStore.getMapPointsForTrack(
                with: track.id!,
                onSuccess: { (mapPoints) in
                    track.mapPoints = mapPoints
                    NotificationCenter.default.post(name: .previewImageStartingUpdate, object: track)
                    self.drawTrack(vgTrack: track) { (image, style) -> Void? in
                        guard let image = image else {
                            return nil
                        }
                        NotificationCenter.default.post(name: .previewImageFinishingUpdate, object: ImageUpdatedNotification(image: image, style: style!, track: track))
                        self.vgFileManager.savePNG(image: image, for: track, style: style!)
                        return nil
                    }
                }, onFailure: { (error) in
                    print(error)
                }
            )
        } else {
            NotificationCenter.default.post(name: .previewImageStartingUpdate, object: track)
            self.drawTrack(vgTrack: track) { (image, style) -> Void? in
                NotificationCenter.default.post(name: .previewImageFinishingUpdate, object: ImageUpdatedNotification(image: image!, style: style!, track: track))
                self.vgFileManager.savePNG(image: image!, for: track, style: style!)
                return nil
            }

        }
    }
    
    @objc func generateImagesForTracks(_ notification:Notification) {
        guard let newTracks = notification.object as? [VGTrack] else {
            return
        }
        
        for newTrack in newTracks {
            generateImageFor(track: newTrack)
        }
    }
    
    @objc func generateImagesForTrack(_ notification:Notification) {
        guard let newTrack = notification.object as? VGTrack else {
            return
        }
        
        generateImageFor(track: newTrack)
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
        } else {
            NotificationCenter.default.post(name: .previewImageStartingUpdate, object: newTrack)
            self.drawTrack(vgTrack: newTrack) { (image, style) -> Void? in
                NotificationCenter.default.post(name: .previewImageFinishingUpdate, object: ImageUpdatedNotification(image: image!, style: style!, track: newTrack))
                self.vgFileManager.savePNG(image: image!, for: newTrack, style: style!)
                return nil
            }

        }
    }
    
    
    
    func drawTrack(vgTrack:VGTrack, imageCallback:(@escaping(UIImage?,UIUserInterfaceStyle?)->Void?)) {
        let coordinateList = vgTrack.getMapPoints()
        var snapshotter:MKMapSnapshotter?
        
        for style in [UIUserInterfaceStyle.light, UIUserInterfaceStyle.dark] {
            if coordinateList.count == 0 {
                snapshotter = VGZeroMapSnapshotter(style: style)
            } else {
                snapshotter = VGTrackMapSnapshotter(style: style, coordinates: coordinateList)
            }
            
            snapshotter?.start(completionHandler: { (snapshot, error) in
                DispatchQueue.global(qos: .utility).async {
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
                        imageCallback(finalImage, style)
                    }
                }
            })
        }
    }
    
    func drawTracks(vgTracks:[VGTrack], imageCallback:(@escaping(UIImage?,UIUserInterfaceStyle?)->Void?)) {
        
        let coordList = vgTracks.flatMap { (track) -> [CLLocationCoordinate2D] in
            return track.getMapPoints()
        }
        var snapshotter:MKMapSnapshotter?
        if coordList.count == 0 {
            snapshotter = VGZeroMapSnapshotter(style: .dark)
        } else {
            snapshotter = VGMapSnapshotter(style: .dark, coordinates: coordList)
        }
        
        snapshotter?.start(completionHandler: { (snapshot, error) in
            
            DispatchQueue.global(qos: .utility).async {
                
                guard let snapshot = snapshot else {
                    imageCallback(nil,.dark)
                    return
                }
                
                let finalImage = UIGraphicsImageRenderer(size: snapshot.image.size).image { _ in
                        // Draw the map.
                        snapshot.image.draw(at: .zero)
                    for vgTrack in vgTracks {
                        let coordinateList = vgTrack.getMapPoints()
                        if coordinateList.count == 0 {
                            imageCallback(snapshot.image, .dark)
                            return
                        }
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
                }
                if coordList.count > 0 {
                    imageCallback(finalImage, .dark)
                }
            }
        })
    }
}
