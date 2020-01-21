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


class VGSnapshotMaker {
    let vgFileManager:VGFileManager
    init(fileManager:VGFileManager) {
        vgFileManager = fileManager
    }
    
    func drawTrack(vgTrack:VGTrack, imageCallback:(@escaping(UIImage?,UIUserInterfaceStyle?)->Void?) = {_,_ in }) {
        let coordinateList = vgTrack.getCoordinateList()
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
                        UIColor.red.setStroke()
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
