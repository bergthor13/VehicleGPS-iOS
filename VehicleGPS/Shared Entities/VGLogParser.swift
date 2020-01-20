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
    var vgFileManager:VGFileManager
    var vgSnapshotMaker:VGSnapshotMaker
    
    init(fileManager:VGFileManager, snapshotter:VGSnapshotMaker) {
        self.vgFileManager = fileManager
        self.vgSnapshotMaker = snapshotter
    }
    
    func fileToTrack(fileUrl:URL, progress:@escaping (UInt, UInt) -> Void, callback:@escaping (VGTrack) -> Void, imageCallback: ((VGTrack) -> Void)? = nil) {
        DispatchQueue.global(qos: .background).async {
            var lastProgressUpdate = Date()
            var fileString = String()
            do {
                fileString = try String(contentsOf: fileUrl)
            } catch {/* error handling here */}
            let track = VGTrack()
            track.fileName = fileUrl.lastPathComponent
            do {
                let resources = try fileUrl.resourceValues(forKeys: [.fileSizeKey])
                let fileSize = resources.fileSize!
                track.fileSize = fileSize
            } catch {
                print("Error: \(error)")
            }
            
            let lines = fileString.split { $0.isNewline }
            let lineCount = lines.count
            for (index, line) in lines.enumerated() {
                if abs(lastProgressUpdate.timeIntervalSinceNow) > self.progress_update_delay {
                    progress(UInt(index), UInt(lineCount))
                    lastProgressUpdate = Date()
                }
                if !VGDataPoint.isValid(line: String(line)) {
                    continue
                }

                let dataPoint = VGDataPoint(csvLine: String(line))
                track.trackPoints.append(dataPoint)
            }

            track.process()
            
            self.vgSnapshotMaker.drawTrack(vgTrack: track) { (image, style) in
                guard let imageCallback = imageCallback else {
                    return
                }
                imageCallback(track)
            }
            callback(track)
        }
    }
}
