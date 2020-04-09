//
//  VGDataStore.swift
//  VehicleGPS
//
//  Created by Bergþór Þrastarson on 04/06/2019.
//  Copyright © 2019 Bergþór Þrastarson. All rights reserved.
//

import UIKit
import CoreData

class VGDataStore {
    // MARK: - Initialization
    let storeCoordinator: NSPersistentStoreCoordinator
    let vgFileManager = VGFileManager()
    
    func initializeContainer() {
        let container = NSPersistentContainer(name: "VehicleGPS")
        
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            self.storeCoordinator.addPersistentStore(with: storeDescription, completionHandler: { (storedescr, error) in
                if let error = error as NSError? {
                    fatalError("Unresolved error \(error), \(error.userInfo)")
                }
            })
            
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
    }
    
    init() {
        guard let modelURL = Bundle.main.url(forResource: "VehicleGPS", withExtension:"momd") else {
            fatalError("Error loading model from bundle")
        }
        
        // The managed object model for the application. It is a fatal error for the application not to be able to find and load its model.
        guard let mom = NSManagedObjectModel(contentsOf: modelURL) else {
            fatalError("Error initializing mom from: \(modelURL)")
        }
        
        self.storeCoordinator = NSPersistentStoreCoordinator(managedObjectModel: mom)
        initializeContainer()
    }
    

    // MARK: - Private Functions
    fileprivate func getPoints(for track:VGTrack, in context:NSManagedObjectContext) -> [NSManagedObject] {
        guard let fetchedTrack = getTrack(for: track, in: context) else {
            return [NSManagedObject]()
        }

        let dataPointFetchRequest = NSFetchRequest<NSManagedObject>(entityName: "DataPoint")
        dataPointFetchRequest.predicate = NSPredicate(format: "track = %@", fetchedTrack)
    
        do {
            return try context.fetch(dataPointFetchRequest)
        } catch {
            return []
        }
    }
    
    fileprivate func getMapPoints(for track:VGTrack, in context:NSManagedObjectContext) -> [MapPoint] {
        guard let fetchedTrack = getTrack(for: track, in: context) else {
            return [MapPoint]()
        }

        do {
            let dataPointFetchRequest = NSFetchRequest<MapPoint>(entityName: "MapPoint")
            dataPointFetchRequest.predicate = NSPredicate(format: "track = %@", fetchedTrack)
            
            return try context.fetch(dataPointFetchRequest)
            
        } catch {
            return []
        }
    }
    
    fileprivate func getTrack(for track: VGTrack, in context:NSManagedObjectContext) -> NSManagedObject? {
        if let id = track.id {
            let trackFetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Track")
            trackFetchRequest.predicate = NSPredicate(format: "id = %@", argumentArray: [track.id])
            do {
                guard let fetchedTrack = try context.fetch(trackFetchRequest).first else {
                    print("Fetching track failed")
                    return nil
                }
                return fetchedTrack
            } catch {
                return nil
            }
        }
        return nil
    }
    
    fileprivate func getVehicle(for vgVehicle: VGVehicle, in context:NSManagedObjectContext) -> Vehicle? {
        let vehicleFetchRequest = Vehicle.fetchRequest() as NSFetchRequest<Vehicle>
        vehicleFetchRequest.predicate = NSPredicate(format: "id = %@", argumentArray: [vgVehicle.id!])
        do {
            guard let fetchedVehicle = try context.fetch(vehicleFetchRequest).first else {
                print("Fetching vehicle failed")
                return nil
            }
            return fetchedVehicle
        } catch {
            return nil
        }
    }
    
    fileprivate func getAllTracks(for vgVehicle:VGVehicle, in context: NSManagedObjectContext) -> [VGTrack] {
        var result = [VGTrack]()
        //2
        let fetchRequest =
            NSFetchRequest<NSManagedObject>(entityName: "Track")
        fetchRequest.predicate = NSPredicate(format: "vehicle.id = %@", argumentArray: [vgVehicle.id!])
        
        //3
        do {
            let cdTracks = try context.fetch(fetchRequest)
            for track in cdTracks  {
                let vgTrack = VGTrack()
                
                if let distance = track.value(forKey: "distance") as? Double {
                    vgTrack.distance = distance
                }
                
                if let duration = track.value(forKey: "duration") as? Double {
                    vgTrack.duration = duration
                }
                
                if let fileName = track.value(forKey: "fileName") as? String {
                    vgTrack.fileName = fileName
                }
                
                if let fileSize = track.value(forKey: "fileSize") as? Int {
                    vgTrack.fileSize = fileSize
                }
                
                if let minLat = track.value(forKey: "minLat") as? Double {
                    vgTrack.minLat = minLat
                }
                
                if let maxLat = track.value(forKey: "maxLat") as? Double {
                    vgTrack.maxLat = maxLat
                }
                
                if let minLon = track.value(forKey: "minLon") as? Double {
                    vgTrack.minLon = minLon
                }
                
                if let maxLon = track.value(forKey: "maxLon") as? Double {
                    vgTrack.maxLon = maxLon
                }
                
                if let processed = track.value(forKey: "processed") as? Bool {
                    vgTrack.processed = processed
                }
                
                if let timeStart = track.value(forKey: "timeStart") as? Date {
                    vgTrack.timeStart = timeStart
                }
                
                if let vehicle = track.value(forKey: "vehicle") as? Vehicle {
                    vgTrack.vehicle = VGVehicle(vehicle: vehicle)
                }
                
                if let id = track.value(forKey: "id") as? UUID {
                    vgTrack.id = id
                }
                
                
                
                result.append(vgTrack)
            }
            
        } catch {
            return []
        }
        return result

    }
    
    fileprivate func add(vgDataPoint:VGDataPoint, to vgTrack: Track, in context:NSManagedObjectContext) {
        let entity = NSEntityDescription.entity(forEntityName: "DataPoint", in: context)!
        
        let dataPoint = NSManagedObject(entity: entity, insertInto: context)
        if vgDataPoint.timestamp != nil {
            dataPoint.setValue(vgDataPoint.timestamp, forKey: "timeStamp")
        }
        
        dataPoint.setValue(vgDataPoint.latitude, forKey: "latitude")
        dataPoint.setValue(vgDataPoint.longitude, forKey: "longitude")
        dataPoint.setValue(vgDataPoint.elevation, forKey: "elevation")
        dataPoint.setValue(vgDataPoint.satellites, forKey: "satellites")
        dataPoint.setValue(vgDataPoint.horizontalAccuracy, forKey: "horizontalAccuracy")
        dataPoint.setValue(vgDataPoint.verticalAccuracy, forKey: "verticalAccuracy")
        dataPoint.setValue(vgDataPoint.pdop, forKey: "pdop")
        dataPoint.setValue(vgDataPoint.fixType, forKey: "fixType")
        dataPoint.setValue(vgDataPoint.gnssFixOk, forKey: "gnssFixOK")
        dataPoint.setValue(vgDataPoint.fullyResolved, forKey: "fullyResolved")
        dataPoint.setValue(vgDataPoint.rpm, forKey: "rpm")
        dataPoint.setValue(vgDataPoint.engineLoad, forKey: "engineLoad")
        dataPoint.setValue(vgDataPoint.coolantTemperature, forKey: "coolantTemperature")
        dataPoint.setValue(vgDataPoint.ambientTemperature, forKey: "ambientTemperature")
        dataPoint.setValue(vgDataPoint.throttlePosition, forKey: "throttlePosition")
        dataPoint.setValue(vgTrack, forKey: "track")
    }
    
    func add(vgMapPoint:VGMapPoint, to vgTrack: Track, in context:NSManagedObjectContext) {
        let entity = NSEntityDescription.entity(forEntityName: "MapPoint", in: context)!
        let mapPoint = NSManagedObject(entity: entity, insertInto: context)
        mapPoint.setValue(vgMapPoint.timestamp, forKey: "timeStamp")
        mapPoint.setValue(vgMapPoint.latitude, forKey: "latitude")
        mapPoint.setValue(vgMapPoint.longitude, forKey: "longitude")
        mapPoint.setValue(vgTrack, forKey: "track")
    }
    

    
    // MARK: - Public Functions
    // MARK: Database Functions
    func deleteAllData(entity:String) {
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.persistentStoreCoordinator = self.storeCoordinator
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entity)
        fetchRequest.returnsObjectsAsFaults = false
        fetchRequest.fetchLimit = 1000000
        context.perform {
            do {
                let results = try context.fetch(fetchRequest)
                for object in results {
                    guard let objectData = object as? NSManagedObject else {continue}
                    context.delete(objectData)
                }
                do {
                    try context.save()
                } catch let error {
                    print(error)
                }
            } catch let error {
                print("Delete all data in \(entity) error :", error)
            }
        }
    }
    
    func countAllData(entity:String, callback:(Int)->()) {
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.persistentStoreCoordinator = self.storeCoordinator
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entity)
        var result = 0
        
        fetchRequest.includesPropertyValues = false
        fetchRequest.includesSubentities    = false
        fetchRequest.resultType = NSFetchRequestResultType.countResultType
        do {
            result = try context.count(for: fetchRequest)
        } catch let error {
            print(error)
        }
        
        callback(result)
    }
    
    // MARK: Track
    func getAllTracks() -> [VGTrack] {
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.persistentStoreCoordinator = self.storeCoordinator
        
        var result = [VGTrack]()
        //2
        let fetchRequest =
            NSFetchRequest<NSManagedObject>(entityName: "Track")
        
        //3
        do {
            let cdTracks = try context.fetch(fetchRequest)
            for track in cdTracks  {
                let vgTrack = VGTrack()
                
                if let distance = track.value(forKey: "distance") as? Double {
                    vgTrack.distance = distance
                }
                
                if let duration = track.value(forKey: "duration") as? Double {
                    vgTrack.duration = duration
                }
                
                if let fileName = track.value(forKey: "fileName") as? String {
                    vgTrack.fileName = fileName
                }
                
                if let fileSize = track.value(forKey: "fileSize") as? Int {
                    vgTrack.fileSize = fileSize
                }
                
                if let minLat = track.value(forKey: "minLat") as? Double {
                    vgTrack.minLat = minLat
                }
                
                if let maxLat = track.value(forKey: "maxLat") as? Double {
                    vgTrack.maxLat = maxLat
                }
                
                if let minLon = track.value(forKey: "minLon") as? Double {
                    vgTrack.minLon = minLon
                }
                
                if let maxLon = track.value(forKey: "maxLon") as? Double {
                    vgTrack.maxLon = maxLon
                }
                
                if let processed = track.value(forKey: "processed") as? Bool {
                    vgTrack.processed = processed
                }
                
                if let timeStart = track.value(forKey: "timeStart") as? Date {
                    vgTrack.timeStart = timeStart
                }
                
                if let vehicle = track.value(forKey: "vehicle") as? Vehicle {
                    vgTrack.vehicle = VGVehicle(vehicle: vehicle)
                }
                
                if let id = track.value(forKey: "id") as? UUID {
                    vgTrack.id = id
                }
                
                result.append(vgTrack)
            }
            
        } catch {
            return []
        }
        return result
    }
    
    func add(vgTrack: VGTrack, callback: @escaping(_ id:UUID?)->()) {
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.persistentStoreCoordinator = self.storeCoordinator
        context.perform {
            let entityDescription = NSEntityDescription.entity(forEntityName: "Track", in: context)!
            let newTrack = Track.init(entity: entityDescription, insertInto: context)
            newTrack.id = UUID()
            newTrack.fileName = vgTrack.fileName
            newTrack.fileSize = Int64(vgTrack.fileSize)
            newTrack.duration = vgTrack.duration
            newTrack.distance = vgTrack.distance
            newTrack.minLat = vgTrack.minLat
            newTrack.maxLat = vgTrack.maxLat
            newTrack.minLon = vgTrack.minLon
            newTrack.maxLon = vgTrack.maxLon
            newTrack.processed = vgTrack.processed
            newTrack.timeStart = vgTrack.timeStart
            
            for point in vgTrack.trackPoints {
                self.add(vgDataPoint: point, to: newTrack, in: context)
            }
            
            for point in vgTrack.mapPoints {
                self.add(vgMapPoint: point, to: newTrack, in: context)
            }
            
            do {
               try context.save()
            } catch let error as NSError {
                print("Could not save. \(error), \(error.userInfo)")
                callback(nil)
            }
 
            if let defaultVehicleID = self.getDefaultVehicleID() {
                let newVehicle = VGVehicle()
                newVehicle.id = defaultVehicleID
                let vehicleObj = self.getVehicle(for: newVehicle, in: context)
                vgTrack.id = newTrack.id
                guard let veh = vehicleObj else {
                    callback(newTrack.id)
                    return
                }
                self.add(vgVehicle: VGVehicle(vehicle: veh), to: vgTrack)
            }
            callback(newTrack.id)
        }
    }
    
    func update(vgTrack: VGTrack) {
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.persistentStoreCoordinator = self.storeCoordinator
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Track")
        guard let id = vgTrack.id else {
            return
        }
        fetchRequest.predicate = NSPredicate(format: "id = %@", argumentArray: [id])
        context.perform {
            do {
                let test = try context.fetch(fetchRequest)
                if test.count > 0 {
                    if let trackUpdate = test[0] as? Track {
                        trackUpdate.setValue(vgTrack.fileName, forKey: "fileName")
                        trackUpdate.setValue(vgTrack.fileSize, forKey: "fileSize")
                        trackUpdate.setValue(vgTrack.duration, forKey: "duration")
                        trackUpdate.setValue(vgTrack.distance, forKey: "distance")
                        trackUpdate.setValue(vgTrack.minLat, forKey: "minLat")
                        trackUpdate.setValue(vgTrack.maxLat, forKey: "maxLat")
                        trackUpdate.setValue(vgTrack.minLon, forKey: "minLon")
                        trackUpdate.setValue(vgTrack.maxLon, forKey: "maxLon")
                        trackUpdate.setValue(vgTrack.processed, forKey: "processed")
                        trackUpdate.setValue(vgTrack.timeStart, forKey: "timeStart")
                        
                        for point in vgTrack.trackPoints {
                            self.add(vgDataPoint: point, to: trackUpdate, in: context)
                        }
                        
                        for point in vgTrack.mapPoints {
                            self.add(vgMapPoint: point, to: trackUpdate, in: context)
                        }
                        
                        try context.save()
                    }
                } else {
                    //self.add(vgTrack: vgTrack)
                }
                
                
            } catch let error {
                print(error)
            }
            
        }
        
    }
    
    func delete(vgTrack: VGTrack) {
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.persistentStoreCoordinator = self.storeCoordinator
        context.perform {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Track")
            fetchRequest.predicate = NSPredicate(format: "id = %@", argumentArray: [vgTrack.id!])
            do {
                let test = try context.fetch(fetchRequest)
                if test.count > 0 {
                    if let trackUpdate = test[0] as? NSManagedObject {
                        context.delete(trackUpdate)
                        try context.save()
                    }
                }
            } catch let error {
                print(error)
            }
        }
        
    }
    
    
    func getPointsForTrack(vgTrack:VGTrack) -> [VGDataPoint] {
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.persistentStoreCoordinator = self.storeCoordinator
        
        var result = [VGDataPoint]()
        
        var fetchedDataPoints = getPoints(for: vgTrack, in: context)
        
        for point in fetchedDataPoints {
            let vgPoint = VGDataPoint(managedPoint: point)
            result.append(vgPoint)
        }
        fetchedDataPoints = []
        return result.sorted()
    }
    
    func getMapPointsForTrack(vgTrack:VGTrack) -> [VGMapPoint] {
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.persistentStoreCoordinator = self.storeCoordinator
        
        var result = [VGMapPoint]()
        
        var fetchedDataPoints = getMapPoints(for: vgTrack, in: context)
        
        for point in fetchedDataPoints {
            let vgPoint = VGMapPoint(point: point)
            result.append(vgPoint)
        }
        fetchedDataPoints = []
        return result.sorted()
    }

    // MARK: Vehicle
    func getAllVehicles() -> [VGVehicle] {
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.persistentStoreCoordinator = self.storeCoordinator

        let fetchRequest = Vehicle.fetchRequest() as NSFetchRequest<Vehicle>
        do {
            var returnList = [VGVehicle]()
            let result =  try context.fetch(fetchRequest)
            for item in result {
                let newVehicle = VGVehicle(vehicle: item)
                newVehicle.tracks = getAllTracks(for: newVehicle, in: context)
                returnList.append(newVehicle)
            }
            return returnList
        } catch let error {
            print(error)
        }
        return []
    }
    func add(vgVehicle:VGVehicle) {
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.persistentStoreCoordinator = self.storeCoordinator
        let entityDescription = NSEntityDescription.entity(forEntityName: "Vehicle", in: context)!
        let newVehicle = Vehicle.init(entity: entityDescription, insertInto: context)
        newVehicle.name = vgVehicle.name
        newVehicle.id = UUID()
        newVehicle.mapColor = vgVehicle.mapColor
        vgVehicle.id = newVehicle.id
        if let image = vgVehicle.image {
            newVehicle.image = vgFileManager.imageToFile(image: image, for: vgVehicle)
        }
        

        context.insert(newVehicle)
        do {
            try context.save()
        } catch let error {
            print(error)
        }
    }
    
    func update(vgVehicle:VGVehicle) {
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.persistentStoreCoordinator = self.storeCoordinator
        
        guard let newVehicle = getVehicle(for: vgVehicle, in: context) else {
            return
        }
        
        newVehicle.name = vgVehicle.name
        newVehicle.id = vgVehicle.id
        newVehicle.mapColor = vgVehicle.mapColor
        
        if let image = vgVehicle.image {
            newVehicle.image = vgFileManager.imageToFile(image: image, for: vgVehicle)
        }

        do {
            try context.save()
        } catch let error {
            print(error)
        }
    }

    func delete(vgVehicle: VGVehicle, callback:@escaping()->()) {
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.persistentStoreCoordinator = self.storeCoordinator
        context.perform {
            let fetchRequest = Vehicle.fetchRequest() as NSFetchRequest<Vehicle>
            fetchRequest.predicate = NSPredicate(format: "id = %@", argumentArray: [vgVehicle.id!])
            do {
                let test = try context.fetch(fetchRequest)
                if test.count > 0 {
                    context.delete(test[0])
                    try context.save()
                    callback()
                }
            } catch let error {
                print(error)
                callback()
            }
        }
    }
    

    
    func add(vgVehicle:VGVehicle, to vgTrack:VGTrack) {
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.persistentStoreCoordinator = self.storeCoordinator
        
        // Get the track in question
        let fetchedTrack = getTrack(for: vgTrack, in: context)
        
        let fetchedVehicle = getVehicle(for: vgVehicle, in: context)
        
        fetchedTrack?.setValue(fetchedVehicle, forKey: "vehicle")
        do {
            try context.save()
            vgTrack.vehicle = vgVehicle
            NotificationCenter.default.post(name: .vehicleAddedToTrack, object: vgTrack)
        } catch let error {
            print(error)
        }
    }
    
    func getDefaultVehicleID() -> UUID? {
        if let items = UserDefaults.standard.data(forKey: "DefaultVehicle") {
            let decoder = JSONDecoder()
            if let defaultVehicleID = try? decoder.decode(UUID.self, from: items) {
                return defaultVehicleID
            }
        }
        return nil
    }
    
    func setDefaultVehicleID(id:UUID) {
         let encoder = JSONEncoder()
         if let encoded = try? encoder.encode(id) {
             UserDefaults.standard.set(encoded, forKey: "DefaultVehicle")
         }
    }
    
    // MARK: Other
    func split(track:VGTrack, at time:Date) -> (VGTrack, VGTrack) {
        var newTrack = VGTrack()
        var pointIndex = -1
        for (index, dataPoint) in track.trackPoints.enumerated() {
            if dataPoint.timestamp! < time {
                pointIndex = index
            }
        }
        
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.persistentStoreCoordinator = self.storeCoordinator
            let fetchedDataPoints = self.getPoints(for: track, in: context)
            
            let lines = fetchedDataPoints.sorted(by: { (first, second) -> Bool in
                
                guard let firstDate = first.value(forKey: "timeStamp") as?  Date else {
                    return false
                }
                guard let secondDate = second.value(forKey: "timeStamp") as? Date else {
                    return false
                }
                
                return  firstDate < secondDate
            })
            
            let leftSplit = lines[0 ... pointIndex]
            let rightSplit = lines[pointIndex ..< lines.count]
            
            if rightSplit.count != 0 {
                let entity = NSEntityDescription.entity(forEntityName: "Track",
                                       
                                                        in: context)!
                
                let trackMo = NSManagedObject(entity: entity,
                                              insertInto: context)
                let fileName = String(describing: time).prefix(19).replacingOccurrences(of: ":", with: "") + ".csv"
                trackMo.setValue(fileName, forKey: "fileName")
                
                track.trackPoints = []
                for item in leftSplit {
                    let dp = VGDataPoint(managedPoint: item)
                    track.trackPoints.append(dp)
                }
                newTrack = VGTrack(track: trackMo as! Track)
                for item in rightSplit {
                    let dp = VGDataPoint(managedPoint: item)
                    newTrack.trackPoints.append(dp)
                    item.setValue(trackMo, forKey: "track")
                }
            }
            do {
                try context.save()
            } catch let error {
                print(error)
            }
        
        return (track, newTrack)
    }
}
