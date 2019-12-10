//
//  VGLogParser.swift
//  VehicleGPS
//
//  Created by Bergþór Þrastarson on 02/06/2019.
//  Copyright © 2019 Bergþór Þrastarson. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation
import CoreGraphics
import MapKit

class VGLogParser {
    let progress_update_delay = TimeInterval(0.1)
    let PNG_PADDING:CGFloat = 0.9
    var vgFileManager = VGFileManager()
    
    func fileToTrack(fileUrl:URL, progress:@escaping (UInt, UInt)->Void, callback:@escaping (VGTrack)->Void, imageCallback:((VGTrack) -> Void)? = nil){
        DispatchQueue.global(qos: .background).async {
            var lastProgressUpdate = Date()
            var fileString = String()
            do {
                fileString = try String(contentsOf: fileUrl)
            }
            catch {/* error handling here */}
            let track = VGTrack()
            track.fileName = fileUrl.lastPathComponent
            do {
                let resources = try fileUrl.resourceValues(forKeys:[.fileSizeKey])
                let fileSize = resources.fileSize!
                track.fileSize = fileSize
            } catch {
                print("Error: \(error)")
            }
            let lines = fileString.split { $0.isNewline }
            let lineCount = lines.count
            var lastDataPoint:VGDataPoint?
            for (index, line) in lines.enumerated() {
                if abs(lastProgressUpdate.timeIntervalSinceNow) > self.progress_update_delay {
                    progress(UInt(index), UInt(lineCount))
                    lastProgressUpdate = Date()
                }
                if !VGDataPoint.isValid(line: String(line)) {
                    continue
                }

                let dataPoint = VGDataPoint(csvLine: String(line))
                if dataPoint.hasOBDData && track.hasOBDData == false {
                    track.hasOBDData = true
                }
                
                if dataPoint.fixType > 1 {
                    if track.timeStart == nil && dataPoint.timestamp! > Date(timeIntervalSince1970: 1388534400) {
                        track.timeStart = dataPoint.timestamp
                    }
                    
                    guard let latitude = dataPoint.latitude, let longitude = dataPoint.longitude else {
                        continue
                    }
                    
                    if track.minLat < latitude {
                        track.minLat = latitude
                    }
                    if track.maxLat > latitude {
                        track.maxLat = latitude
                    }
                    if track.minLon < longitude {
                        track.minLon = longitude
                    }
                    if track.maxLon > longitude {
                        track.maxLon = longitude
                    }

                    if lastDataPoint != nil && lastDataPoint!.fixType > 1 {
                        guard let lastLatitude = lastDataPoint!.latitude, let lastLongitude = lastDataPoint!.longitude else {
                            continue
                        }
                        let coord = CLLocation(latitude: latitude, longitude: longitude)
                        let lastCoord = CLLocation(latitude: lastLatitude, longitude: lastLongitude)

                        track.distance += coord.distance(from: lastCoord)/1000
                    }
                    
                }
                track.trackPoints.append(dataPoint)

                lastDataPoint = dataPoint
            }
            if track.timeStart != nil {
                track.duration = Double(track.trackPoints.last!.timestamp!.timeIntervalSince(track.timeStart!))
            }
            
            if !self.vgFileManager.pngForTrackExists(track: track) {
                self.drawTrack(vgTrack: track, imageCallback: {
                    if imageCallback != nil {
                        imageCallback!(track)
                    }
                })
            }
            

            
            track.processed = true
            
            callback(track)
        }
    }
    
//    func getImageCoordinate(vgTrack:VGTrack, point:VGDataPoint, size:CGSize) -> CGPoint{
//        guard let latitude = point.latitude, let longitude = point.longitude else {
//            return
//        }
//
//        let minMaxLonDelta = (vgTrack.maxLon - vgTrack.minLon)
//        let minMaxLatDelta = (vgTrack.maxLat - vgTrack.minLat)
//        let aspect = minMaxLatDelta/minMaxLonDelta
//        let lonDelta = longitude-vgTrack.minLon
//        let latDelta = latitude-vgTrack.minLat
//
//        let lonPerc = (1-(lonDelta/minMaxLonDelta))
//        let latPerc = (latDelta/minMaxLatDelta)
//
//        let imageLonLoc = (CGFloat(lonPerc)*size.width*PNG_PADDING)
//        let imageLatLoc = (CGFloat(latPerc)*size.height*PNG_PADDING*CGFloat(aspect))
//        return CGPoint(x:imageLonLoc+(size.width*(1-PNG_PADDING))/2, y: imageLatLoc+(size.height*(1-PNG_PADDING))/2)
//    }
//
    func drawTrack(vgTrack:VGTrack, imageCallback:@escaping ()->Void) {
        let mapSnapshotOptions = MKMapSnapshotter.Options()
        
        // If there are no points, create an image showing Iceland.
        if vgTrack.getCoordinateList().count == 0 {
            
            // Set the region of the map that is rendered.
            let location = CLLocationCoordinate2DMake(64.9, -18.9)
            
            let latitudeDelta = 4.0
            let longitudeDelta = 12.0
        
            
            let region = MKCoordinateRegion(center: location, span: MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta))
            mapSnapshotOptions.region = region
            
            // Set the scale of the image. We'll just use the scale of the current device, which is 2x scale on Retina screens.
            mapSnapshotOptions.scale = UIScreen.main.scale
            
            // Set the size of the image output.
            mapSnapshotOptions.size = CGSize(width: 110, height: 110)
            
            // Show buildings and Points of Interest on the snapshot
            mapSnapshotOptions.showsBuildings = true
            mapSnapshotOptions.showsPointsOfInterest = true
            
            let snapShotter = MKMapSnapshotter(options: mapSnapshotOptions)
                snapShotter.start { (snapshot:MKMapSnapshotter.Snapshot?, error:Error?) in
                    self.vgFileManager.savePNG(image: snapshot!.image, for: vgTrack)
                    imageCallback()
                }
            
            return
        }
        
        let latCenter = (vgTrack.maxLat+vgTrack.minLat)/2
        let lonCenter = (vgTrack.maxLon+vgTrack.minLon)/2
        
        // Set the region of the map that is rendered.
        let location = CLLocationCoordinate2DMake(latCenter, lonCenter)
        
        // pad our map by 10% around the farthest annotations
        let MAP_PADDING = 1.1
        
        // we'll make sure that our minimum vertical span is about a kilometer
        // there are ~111km to a degree of latitude. regionThatFits will take care of
        // longitude, which is more complicated, anyway.
        let MINIMUM_VISIBLE_LATITUDE = 0.005

        var latitudeDelta = abs(vgTrack.maxLat - vgTrack.minLat) * MAP_PADDING;
        
        latitudeDelta = (latitudeDelta < MINIMUM_VISIBLE_LATITUDE)
            ? MINIMUM_VISIBLE_LATITUDE
            : latitudeDelta;
        
        let longitudeDelta = abs((vgTrack.maxLon - vgTrack.minLon) * MAP_PADDING)

        let region = MKCoordinateRegion(center: location, span: MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta))
        mapSnapshotOptions.region = region
        
        // Set the scale of the image. We'll just use the scale of the current device, which is 2x scale on Retina screens.
        mapSnapshotOptions.scale = UIScreen.main.scale
        
        // Set the size of the image output.
        mapSnapshotOptions.size = CGSize(width: 110, height: 110)
        
        // Show buildings and Points of Interest on the snapshot
        mapSnapshotOptions.showsBuildings = true
        mapSnapshotOptions.showsPointsOfInterest = true
        
        let snapShotter = MKMapSnapshotter(options: mapSnapshotOptions)
    
        snapShotter.start { (snapshot:MKMapSnapshotter.Snapshot?, error:Error?) in
            DispatchQueue.global(qos: .userInitiated).async {
                guard let snapshot = snapshot else {
                    //self.vgFileManager.savePNG(image: self.drawTrack2(vgTrack: vgTrack), for: vgTrack)
                    imageCallback()
                    return
                }
                
                let finalImage = UIGraphicsImageRenderer(size: snapshot.image.size).image { _ in
                    
                    // draw the map image
                    
                    snapshot.image.draw(at: .zero)
                    
                    // only bother with the following if we have a path with two or more coordinates
                    let coordinates = vgTrack.getCoordinateList()
                    
                    // convert the `[CLLocationCoordinate2D]` into a `[CGPoint]`
                    
                    let points = coordinates.map { coordinate in
                        snapshot.point(for: coordinate)
                    }
                    
                    // build a bezier path using that `[CGPoint]`
                    
                    let path = UIBezierPath()
                    path.move(to: points[0])
                    
                    for point in points.dropFirst() {
                        path.addLine(to: point)
                    }
                    
                    // stroke it
                    
                    path.lineWidth = 3
                    UIColor.red.setStroke()
                    path.stroke()
                }
                
                self.vgFileManager.savePNG(image: finalImage, for: vgTrack)
                imageCallback()
            }
        }

    }
    
//    func drawTrack2(vgTrack:VGTrack) -> UIImage {
//        let size = CGSize(width: 110, height: 110)
//        let renderer = UIGraphicsImageRenderer(size: size)
//        let image = renderer.image { ctx in
//            ctx.cgContext.setStrokeColor(UIColor.red.cgColor)
//            ctx.cgContext.setLineWidth(2)
//            for (point1, point2) in zip(vgTrack.trackPoints, vgTrack.trackPoints.dropFirst()) {
//                let pt1 = getImageCoordinate(vgTrack: vgTrack, point: point1, size: size)
//                let pt2 = getImageCoordinate(vgTrack: vgTrack, point: point2, size: size)
//                
//                ctx.cgContext.move(to: pt1)
//                ctx.cgContext.addLine(to: pt2)
//                ctx.cgContext.strokePath()
//            }
//        }
//        return image
//    }
}
