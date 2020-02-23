import Foundation
import UIKit
import fastCSV

class VGCSVParser: IVGLogParser {
    let progress_update_delay = TimeInterval(0.1)
    let PNG_PADDING:CGFloat = 0.9
    var vgSnapshotMaker:VGSnapshotMaker

    func isValid(row:[String]) -> Bool {
        if row.count < 16 {
            return false
        }
        return true
    }
    
    init(snapshotter:VGSnapshotMaker) {
        self.vgSnapshotMaker = snapshotter
    }
    
    func fileToTrack(fileUrl: URL, progress: @escaping (UInt, UInt) -> Void, callback: @escaping (VGTrack) -> Void, imageCallback: ((VGTrack, UIUserInterfaceStyle?) -> Void)?) {
        DispatchQueue.global(qos: .background).async {
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

            let csv = CSV(string: fileString)

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

    }
    
    func rowToDataPoint(row: [String]) -> VGDataPoint {
        let dataPoint = VGDataPoint()
        dataPoint.timestamp = ISO8601DateParser.parse(String(row[0]))
        dataPoint.latitude = Double(row[1])
        dataPoint.longitude = Double(row[2])
        dataPoint.elevation = Double(row[3])
        dataPoint.satellites = Int(row[4])
        dataPoint.horizontalAccuracy = Double(row[5])!
        dataPoint.verticalAccuracy = Double(row[6])!
        dataPoint.pdop = Double(row[7])!
        dataPoint.fixType = Int(row[8])!
        
        if row[9] == "True" {
            dataPoint.gnssFixOk = true
        } else {
            dataPoint.gnssFixOk = false
        }
        
        if row[10] == "True" {
            dataPoint.fullyResolved = true
        } else {
            dataPoint.fullyResolved = false
        }
        
        if row[11] != "None" {
            dataPoint.rpm = Double(row[11])
        }
        
        if row[12] != "None" {
            dataPoint.engineLoad = Double(row[12])
        }
        
        if row[13] != "None" {
            dataPoint.coolantTemperature = Double(row[13])
        }
        
        if row[14] != "None" {
            dataPoint.ambientTemperature = Double(row[14])
        }
        
        if row[15] != "None" {
            dataPoint.throttlePosition = Double(row[15])
        }
        return dataPoint
    }
    
}
