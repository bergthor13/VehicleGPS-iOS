import Foundation
import CoreLocation
import CoreData

class VGTrack {
    /// The ID of the track.
    var id:UUID?
    
    /// The name of the track.
    var name:String?
    
    /// A comment for the track.
    var comment:String?
    
    /// The duration of the track. The time between the first and last point of the track.
    /// Measured in seconds.
    var duration:Double
    
    /// The distance between all points of the track.
    /// Measured in kilometers
    var distance:Double
    
    
    var fileName:String
    var fileSize:Int // In bytes
    var timeStart:Date?
    var trackPoints:[VGDataPoint]
    var mapPoints:[VGMapPoint]
    var minLat:Double
    var maxLat:Double
    var minLon:Double
    var maxLon:Double
    var processed:Bool
    var isRemote:Bool
    var isLocal:Bool
    var isRecording:Bool
    var beingProcessed = false
    var dataPointCount = 0
    
    /// The vehicle associated with the track
    var vehicle:VGVehicle?
    
    /// Returns the average speed of the track.
    /// Unit in km/h
    var averageSpeed:Double {
        get {
            return distance/(duration/60/60)
        }
    }
    
    init(track:Track) {
        // Database stored values
        self.duration = track.duration
        self.distance = track.distance
        if let fileName = track.fileName {
            self.fileName = fileName
        } else {
            self.fileName = ""
        }
        self.fileSize = Int(track.fileSize)
        self.timeStart = track.timeStart
        self.minLat = track.minLat
        self.maxLat = track.maxLat
        self.minLon = track.minLon
        self.maxLon = track.maxLon
        self.processed = track.processed
        
        if let vehicle = track.vehicle {
            self.vehicle = VGVehicle(vehicle:vehicle)
        }

        trackPoints = [VGDataPoint]()
        mapPoints = [VGMapPoint]()

        // Memory stored values
        self.isRemote = false
        self.isLocal = false
        self.id = track.id
        self.isRecording = false
    }
    
    init() {
        duration = 0
        distance = 0
        fileName = ""
        fileSize = 0
        minLat = -200.0
        maxLat = 200.0
        minLon = -200.0
        maxLon = 200.0
        processed = false
        isRemote = false
        isLocal = false
        isRecording = false

        trackPoints = [VGDataPoint]()
        mapPoints = [VGMapPoint]()
    }
    
    func setEntity(track:Track) -> Track {
        track.fileName = self.fileName
        track.fileSize = Int64(self.fileSize)
        track.duration = self.duration
        track.distance = self.distance
        track.minLat = self.minLat
        track.maxLat = self.maxLat
        track.minLon = self.minLon
        track.maxLon = self.maxLon
        track.processed = self.processed
        track.timeStart = self.timeStart
        return track
    }
    
    
    var hasOBDData: Bool {
        if self.trackPoints.count == 0 {
            return false
        }
        for point in self.trackPoints {
            if point.hasOBDData {
                return true
            }
        }
        return false
    }
    
    var isoStartTime: String {
        guard let startTime = timeStart else {
            return fileName
        }
        return String(describing: startTime)
    }
    
    func getStartTime() -> Date? {
        if timeStart != nil {
            return timeStart
        }
        return nil
    }
    
    func getMapPoints() -> [CLLocationCoordinate2D] {
        if mapPoints.count > 0 {
            return mapPoints.map { (point) -> CLLocationCoordinate2D in
                return CLLocationCoordinate2D(latitude: point.latitude, longitude: point.longitude)
            }
        }
        return [CLLocationCoordinate2D]()
    }
    
    func getCoordinateList() -> [CLLocationCoordinate2D] {
        
        
        guard let firstPoint = trackPoints.first else {
            return []
        }
        var list = [CLLocationCoordinate2D]()

        if let firstLatitude = firstPoint.latitude, let firstLongitude = firstPoint.longitude {
            if firstPoint.hasGoodFix() {
                list.append(CLLocationCoordinate2D(latitude: firstLatitude, longitude: firstLongitude))
            }
        }
        
        for (point1, point2) in zip(trackPoints, trackPoints.dropFirst()) {
            guard let _ = point1.latitude, let _ = point1.longitude else {
                continue
            }
            guard let latitude2 = point2.latitude, let longitude2 = point2.longitude else {
                continue
            }
            let speed = VGTrack.getSpeedBetween(point1: point1, point2: point2)
            if speed > 0.5 && point1.hasGoodFix() && point2.hasGoodFix() {
                list.append(CLLocationCoordinate2D(latitude: latitude2, longitude: longitude2))
            }
            
        }
        return list
    }
    
    static func getFilteredPointList(list:[VGDataPoint]) -> [VGMapPoint] {
        let maxDurationBetweenPoints = 60.0 // in seconds
        let minDurationBetweenPoints = 1.0
        
        var mapPoints = [VGMapPoint]()
        var lastAddedPoint: VGMapPoint?
        var lastBearing: Double?
        for (point1, point2) in zip(list, list.dropFirst()) {
            guard let latitude1 = point1.latitude, let longitude1 = point1.longitude else {
                continue
            }
            guard let latitude2 = point2.latitude, let longitude2 = point2.longitude else {
                continue
            }
            
            let p1 = CLLocationCoordinate2D(latitude: latitude1, longitude: longitude1)
            let p2 = CLLocationCoordinate2D(latitude: latitude2, longitude: longitude2)
            
            let speed = VGTrack.getSpeedBetween(point1: point1, point2: point2)
            if speed <= 0.5 {
                continue
            }
            let bearing = VGTrack.getBearingBetween(point1: p1, point2: p2)

            
            if lastAddedPoint == nil {
                let newPoint = VGMapPoint(point: p1, timestamp: point1.timestamp!)
                mapPoints.append(newPoint)
                lastBearing = bearing
                lastAddedPoint = newPoint
                continue
            }
            
            if (point1.timestamp?.timeIntervalSince(lastAddedPoint!.timestamp))! < minDurationBetweenPoints {
                continue
            }
            
            let timeCondition = (point1.timestamp?.timeIntervalSince(lastAddedPoint!.timestamp))! > maxDurationBetweenPoints
            let courseCondition = (abs(lastBearing!-bearing)) > 1.0
            
            if timeCondition || courseCondition {
                let newPoint = VGMapPoint(point: p1, timestamp: point1.timestamp!)
                mapPoints.append(newPoint)
                lastBearing = bearing
                lastAddedPoint = newPoint
                continue
            }
        }
        if let last = list.last {
            guard let lastLat = last.latitude, let lastLong = last.longitude, let lastTime = last.timestamp else {
                return mapPoints
            }
            let newPoint = VGMapPoint(point: CLLocationCoordinate2D(latitude: lastLat, longitude: lastLong), timestamp: lastTime)
            mapPoints.append(newPoint)
        }
        return mapPoints
    }
    
    static func degreesToRadians(degrees: Double) -> Double { return degrees * .pi / 180.0 }
    static func radiansToDegrees(radians: Double) -> Double { return radians * 180.0 / .pi }

    static func getBearingBetween(point1 : CLLocationCoordinate2D, point2 : CLLocationCoordinate2D) -> Double {
        let lat1 = degreesToRadians(degrees: point1.latitude)
        let lon1 = degreesToRadians(degrees: point1.longitude)

        let lat2 = degreesToRadians(degrees: point2.latitude)
        let lon2 = degreesToRadians(degrees: point2.longitude)

        let dLon = lon2 - lon1

        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        let radiansBearing = atan2(y, x)

        return radiansToDegrees(radians: radiansBearing)
    }
    
    static func getSpeedBetween(point1:VGDataPoint, point2:VGDataPoint) -> Double {
        guard let timestamp1 = point1.timestamp, let timestamp2 = point2.timestamp else {
            return 0.0
        }
        
        guard let latitude1 = point1.latitude, let latitude2 = point2.latitude else {
            return 0.0
        }
        
        guard let longitude1 = point2.longitude, let longitude2 = point2.longitude else {
            return 0.0
        }
        
        let duration = timestamp2.timeIntervalSince(timestamp1)
        let lastCoord = CLLocation(latitude: latitude1, longitude: longitude1)
        let coord = CLLocation(latitude: latitude2, longitude: longitude2)
        let distance = coord.distance(from: lastCoord)
        
        return (distance/duration)*3.6

    }
    
    func process() {
        var lastDataPoint: VGDataPoint?
        self.distance = 0.0
        minLat = -200.0
        maxLat = 200.0
        minLon = -200.0
        maxLon = 200.0
        for dataPoint in trackPoints {
            var typeOfFix = dataPoint.fixType
            
            // If we don't know the fixType,
            // assume that all points are good.
            if typeOfFix == nil {
                typeOfFix = 2
            }
            
            if typeOfFix! > 1 && self.timeStart == nil {
                self.timeStart = dataPoint.timestamp
            }
            
            if dataPoint.hasGoodFix() {
                guard let latitude = dataPoint.latitude, let longitude = dataPoint.longitude else {
                    continue
                }
                
                if self.minLat < latitude {
                    self.minLat = latitude
                }
                if self.maxLat > latitude {
                    self.maxLat = latitude
                }
                if self.minLon < longitude {
                    self.minLon = longitude
                }
                if self.maxLon > longitude {
                    self.maxLon = longitude
                }

                if lastDataPoint != nil && lastDataPoint!.hasGoodFix() {
                    guard let lastLatitude = lastDataPoint!.latitude, let lastLongitude = lastDataPoint!.longitude else {
                        continue
                    }
                    let coord = CLLocation(latitude: latitude, longitude: longitude)
                    let lastCoord = CLLocation(latitude: lastLatitude, longitude: lastLongitude)

                    self.distance += coord.distance(from: lastCoord)/1000
                }
            }
            
            lastDataPoint = dataPoint
        }
        
        guard let start = self.timeStart else {
            self.processed = true
            return
        }
        
        guard let lastTrackPoint = self.trackPoints.last else {
            self.processed = true
            return
        }
        
        guard let timestampForLastPoint = lastTrackPoint.timestamp else {
            self.processed = true
            return
        }
        self.duration = Double(timestampForLastPoint.timeIntervalSince(start))
        self.mapPoints = VGTrack.getFilteredPointList(list: self.trackPoints)
        self.processed = true
    }
}

extension VGTrack: Equatable {
    static func == (lhs: VGTrack, rhs: VGTrack) -> Bool {
        if rhs.id == nil || lhs.id == nil{
            return false
        }
        return lhs.id == rhs.id
    }
}
extension VGTrack: Comparable {
    static func < (first: VGTrack, second: VGTrack) -> Bool {
        guard let start1 = first.timeStart, let start2 = second.timeStart else {
            return false
        }
        return start1 > start2
    }
}

extension VGTrack: CustomStringConvertible {
    var description: String {
        guard let timeStart = timeStart else {
            return "fileName: \(self.fileName)"
        }
        return "fileName: \(self.fileName), timeStart: \(String(describing: timeStart)), maxLat: \(self.maxLat), maxLon: \(self.maxLon), minLat: \(self.minLat), minLon: \(self.minLon)"
    }
}

