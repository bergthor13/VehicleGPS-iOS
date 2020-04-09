//
//  VGGPXGenerator.swift
//  VehicleGPS
//
//  Created by Bergþór Þrastarson on 10/06/2019.
//  Copyright © 2019 Bergþór Þrastarson. All rights reserved.
//

import Foundation
import UIKit

class VGGPXGenerator {
    var dateFormatter:DateFormatter
    var vgFileManager:VGFileManager!
    init() {
        dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX") // set locale to reliable US_POSIX
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
//        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
//            self.vgFileManager = appDelegate.fileManager
//        }
        self.vgFileManager = VGFileManager()
    }
    
    func getGPXBegin() -> String {
        return "<?xml version=\"1.0\" encoding=\"UTF-8\"?><gpx xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns=\"http://www.topografix.com/GPX/1/0\" xsi:schemaLocation=\"http://www.topografix.com/GPX/1/0 http://www.topografix.com/GPX/1/0/gpx.xsd\" version=\"1.0\" creator=\"gpx.py -- https://github.com/tkrajina/gpxpy\"><trk><trkseg>"
    }
    
    func getGPXEnd() -> String {
        return "</trkseg></trk></gpx>"
    }
    
    func getTrackPointGPX(point:VGDataPoint) -> String {
        guard let timestamp = point.timestamp else {
            return ""
        }
        return "<trkpt lat=\"\(String(describing: point.latitude!))\" lon=\"\(String(describing: point.longitude!))\"><ele>\(String(describing: point.elevation!))</ele><time>\(dateFormatter.string(from: timestamp))</time><pdop>\(String(describing: point.pdop))</pdop></trkpt>"
    }
    
    func generateGPXFor(track: VGTrack) -> URL? {
        var result = getGPXBegin()
        
        for point in track.trackPoints {
            guard let _ = point.latitude, let _ = point.longitude else {
                continue
            }
            
            if !point.hasGoodFix() {
                continue
            }
            
            result += getTrackPointGPX(point: point)
        }
        result += getGPXEnd()
        guard let tmpFile = vgFileManager.getTemporaryGPXPathFor(track: track) else {
            return nil
        }
        
        do {
            try result.write(to: tmpFile, atomically: true, encoding: String.Encoding.utf8)
            return tmpFile

        } catch let error {
            print(error)
            return nil
        }
    }
}
