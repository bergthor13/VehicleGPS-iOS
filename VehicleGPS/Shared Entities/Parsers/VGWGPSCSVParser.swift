//
//  VGWGPSCSVParser.swift
//  VehicleGPS
//
//  Created by Bergþór Þrastarson on 27/02/2021.
//  Copyright © 2020 Bergþór Þrastarson. All rights reserved.
//

import Foundation
import UIKit
import fastCSV

class VGWGPSCSVParser: IVGLogParser {
    
    let progress_update_delay = TimeInterval(0.1)
    let PNG_PADDING: CGFloat = 0.9
    
    func isValid(row: [String]) -> Bool {
        if row.count < 9 {
            return false
        }
        return true
    }
    
    func fileToTrack(fileUrl: URL, progress: @escaping (UInt, UInt) -> Void, onSuccess: @escaping (VGTrack) -> Void, onFailure:@escaping(Error) -> Void) {
        var lastProgressUpdate = Date()
        
        let track = VGTrack()
        track.fileName = fileUrl.lastPathComponent
        do {
            let resources = try fileUrl.resourceValues(forKeys: [.fileSizeKey])
            if let fileSize = resources.fileSize {
                track.fileSize = fileSize
            }
        } catch let error {
            print(error)
            onFailure(error)
        }
        
        var fileData = Data()
        var fileString = String()
        
        do {
            _ = fileUrl.startAccessingSecurityScopedResource()
            fileData = try Data(contentsOf: fileUrl)
            fileString = String(data: fileData, encoding: .utf8)!
        } catch let error {
            print(error)
            fileUrl.stopAccessingSecurityScopedResource()
        }
        fileUrl.stopAccessingSecurityScopedResource()

        let csv = CSV(string: fileString, column: ";", line: "\r\n")
        
        let lineCount = csv.rows.count
        for (index, row) in csv.rows.enumerated() {
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
        track.mapPoints = VGTrack.getFilteredPointList(list: mapPoints)
        track.name = "Track"
        onSuccess(track)
    }
    
    func rowToDataPoint(row: [String]) -> VGDataPoint {
        // TIME,LATITUDE,LONGITUDE,ELEVATION,AMBIENT_TEMPERATURE
        // 2017-07-10T08:44:56.600Z;63.9713329;-22.5916610;54.174;6.945;4.037;4.126;97;94.81

        let dataPoint = VGDataPoint()
        dataPoint.timestamp = ISO8601DateParser.parse(String(row[0]))
        dataPoint.latitude = Double(row[1])
        dataPoint.longitude = Double(row[2])
        dataPoint.elevation = Double(row[3])
        
        return dataPoint
    }
}
