import Foundation
import UIKit
import fastCSV

class VGCSVParser: IVGLogParser {
    let progress_update_delay = TimeInterval(0.1)
    let PNG_PADDING:CGFloat = 0.9

    func isValid(row:[String]) -> Bool {
        if row.count < 16 {
            return false
        }
        return true
    }
    
    var csv: CSV?
    
    func fileToTrack(fileUrl: URL, progress: @escaping (UInt, UInt) -> Void, onSuccess: @escaping (VGTrack) -> (), onFailure:@escaping(Error)->()) {
        
        var lastProgressUpdate = Date()
        
        let track = VGTrack()
        track.fileName = fileUrl.lastPathComponent
        do {
            let resources = try fileUrl.resourceValues(forKeys: [.fileSizeKey])
            if let fileSize = resources.fileSize {
                track.fileSize = fileSize
            }
        } catch {
            onFailure(error)
        }
        
        var fileString = String()
        do {
            fileString = try String(contentsOf: fileUrl)
        } catch {/* error handling here */}
        
        autoreleasepool {
            csv = CSV(string: fileString, column: ",", line: "\n")
            }
            let lineCount = csv!.rows.count
            for (index,row) in csv!.rows.enumerated() {
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
            
            onSuccess(track)
            fileString = ""
            csv = nil

        
    }
    
    func rowToDataPoint(row: [String]) -> VGDataPoint {
        // TIME,LATITUDE,LONGITUDE,ELEVATION,SATELLITES,HORIZONTAL_ACCURACY,VERTICAL_ACCURACY,PDOP,FIX_TYPE,GNSS_FIX_OK,FULLY_RESOLVED,RPM,ENGINE_LOAD,COOLANT_TEMPERATURE,AMBIENT_TEMPERATURE,THROTTLE_POSITION
        // 2019-04-24T17:46:17.599829,63.995643,-22.634326,41.482,7,0.994,1.484,3.48,3,True,False,1103.5,34.509803921568626,14,5,14.509803921568627

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


class ISO8601DateParser {
  
static var calendar = Calendar(identifier: .gregorian)

    static func parse(_ dateString: String) -> Date? {
    var components = DateComponents()
    guard let year = getItem(string: dateString, startIndex: 0, count: 4) else {
        return nil
    }

    guard let month = getItem(string: dateString, startIndex: 5, count: 2) else {
        return nil
    }

    guard let day = getItem(string: dateString, startIndex: 8, count: 2) else {
        return nil
    }

    guard let hour = getItem(string: dateString, startIndex: 11, count: 2) else {
        return nil
    }

    guard let minute = getItem(string: dateString, startIndex: 14, count: 2) else {
        return nil
    }

    guard let second = getItem(string: dateString, startIndex: 17, count: 2) else {
        return nil
    }
        
    if dateString.count >= 26 {
        if let nanosecond = getItem(string: dateString, startIndex: 20, count: 6) {
            components.nanosecond = nanosecond*1000
        } else {
            components.nanosecond = 0
        }
    } else {
        if dateString.count >= 23 {
            if let nanosecond = getItem(string: dateString, startIndex: 20, count: 3) {
                components.nanosecond = nanosecond*1000000
            } else {
                components.nanosecond = 0
            }
        } else {
            components.nanosecond = 0
        }
    }
    

    components.year   = year
    components.month  = month
    components.day    = day
    components.hour   = hour
    components.minute = minute
    components.second = second
    let date = calendar.date(from: components)
    return date
  }

    static private func getItem(string:String, startIndex:Int, count:Int) -> Int? {
        if string.count < startIndex+count {
            return nil
        }
        let start = string.index(string.startIndex, offsetBy: startIndex)
        let end = string.index(string.startIndex, offsetBy: startIndex+count)
        let range = start..<end
        return Int(String(string[range]))
    }

}
