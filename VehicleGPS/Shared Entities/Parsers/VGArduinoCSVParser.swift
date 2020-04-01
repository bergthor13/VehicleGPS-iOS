//
//  VGArduinoCSVParser.swift
//  VehicleGPS
//
//  Created by Bergþór Þrastarson on 23/02/2020.
//  Copyright © 2020 Bergþór Þrastarson. All rights reserved.
//

import Foundation
import UIKit
import fastCSV

class VGArduinoCSVParser: IVGLogParser {
    
    let progress_update_delay = TimeInterval(0.1)
    let PNG_PADDING:CGFloat = 0.9
    var vgSnapshotMaker:VGSnapshotMaker
    
    func isValid(row:[String]) -> Bool {
        if row.count < 5 {
            return false
        }
        return true
    }
    
    init(snapshotter:VGSnapshotMaker) {
        self.vgSnapshotMaker = snapshotter
    }
    
    func fileToTrack(fileUrl: URL, progress: @escaping (UInt, UInt) -> Void, callback: @escaping (VGTrack) -> Void, imageCallback: ((VGTrack, UIUserInterfaceStyle?) -> Void)?) {
        var lastProgressUpdate = Date()
        
        let track = VGTrack()
        track.fileName = fileUrl.lastPathComponent
        do {
            let resources = try fileUrl.resourceValues(forKeys: [.fileSizeKey])
            if let fileSize = resources.fileSize {
                track.fileSize = fileSize
            }
        } catch {
            print("Error: \(error)")
        }
        
        var fileString = String()
        do {
            fileString = try String(contentsOf: fileUrl)
        } catch {/* error handling here */}
        
        let csv = CSV(string: fileString, column: ";", line: "\r\n")
        
        let lineCount = csv.rows.count
        for (index,row) in csv.rows.enumerated() {
            if abs(lastProgressUpdate.timeIntervalSinceNow) > self.progress_update_delay {
                progress(UInt(index), UInt(lineCount))
                lastProgressUpdate = Date()
            }
            if !self.isValid(row: row) {
                continue
            }
            let dataPoint = self.rowToDataPoint(row: row)
            track.trackPoints.append(dataPoint)
        }
        
        
        track.process()
        
        let mapPoints = track.trackPoints.filter { (point) -> Bool in
            return point.hasGoodFix()
        }
        track.mapPoints = VGTrack.getFilteredPointList(list:mapPoints)
        
        self.vgSnapshotMaker.drawTrack(vgTrack: track) { (image, style) in
            guard let imageCallback = imageCallback else {
                return nil
            }
            imageCallback(track, style)
            return nil
        }
        callback(track)
    }
    
    func rowToDataPoint(row: [String]) -> VGDataPoint {
        // TIME,LATITUDE,LONGITUDE,ELEVATION,AMBIENT_TEMPERATURE
        // 2015-07-26T21:10:00.0Z;64.04261779785156;-21.96710968017578;76.10;NULL
        
        let dataPoint = VGDataPoint()
        dataPoint.timestamp = ISO8601DateParser.parse(String(row[0]))
        dataPoint.latitude = Double(row[1])
        dataPoint.longitude = Double(row[2])
        dataPoint.elevation = Double(row[3])
        dataPoint.ambientTemperature = Double(row[4])
        
        return dataPoint
    }
}
