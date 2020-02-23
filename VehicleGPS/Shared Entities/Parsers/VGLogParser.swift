import Foundation
import UIKit
import CoreLocation
import CoreGraphics
import MapKit

class VGLogParser: IVGLogParser {
    let progress_update_delay = TimeInterval(0.1)
    let PNG_PADDING:CGFloat = 0.9
    var vgSnapshotMaker:VGSnapshotMaker
    
    init(snapshotter:VGSnapshotMaker) {
        self.vgSnapshotMaker = snapshotter
    }
    
    func isValid(line:String) -> Bool {
        let data = line.split(separator: ",")
        if data.count < 16 {
            return false
        }
        return true
    }
    
    func fileToTrack(fileUrl:URL, progress:@escaping (UInt, UInt) -> Void, callback:@escaping (VGTrack) -> Void, imageCallback: ((VGTrack, UIUserInterfaceStyle?) -> Void)? = nil) {
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
                if let fileSize = resources.fileSize {
                    track.fileSize = fileSize
                }
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
                if !self.isValid(line: String(line)) {
                    continue
                }

                let dataPoint = self.lineToDataPoint(line: String(line))
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
    }
    
    func lineToDataPoint(line:String) -> VGDataPoint {
        let dataPoint = VGDataPoint()
        let data = line.split(separator: ",")
        
        dataPoint.timestamp = ISO8601DateParser.parse(String(data[0]))
        dataPoint.latitude = Double(data[1])
        dataPoint.longitude = Double(data[2])
        dataPoint.elevation = Double(data[3])
        dataPoint.satellites = Int(data[4])
        dataPoint.horizontalAccuracy = Double(data[5])!
        dataPoint.verticalAccuracy = Double(data[6])!
        dataPoint.pdop = Double(data[7])!
        dataPoint.fixType = Int(data[8])!
        
        if data[9] == "True" {
            dataPoint.gnssFixOk = true
        } else {
            dataPoint.gnssFixOk = false
        }
        
        if data[10] == "True" {
            dataPoint.fullyResolved = true
        } else {
            dataPoint.fullyResolved = false
        }
        
        if data[11] != "None" {
            dataPoint.rpm = Double(data[11])
        }
        
        if data[12] != "None" {
            dataPoint.engineLoad = Double(data[12])
        }
        
        if data[13] != "None" {
            dataPoint.coolantTemperature = Double(data[13])
        }
        
        if data[14] != "None" {
            dataPoint.ambientTemperature = Double(data[14])
        }
        
        if data[15] != "None" {
            dataPoint.throttlePosition = Double(data[15])
        }
        return dataPoint
    }
}
