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
    
    let storeCoordinator: NSPersistentStoreCoordinator
    
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
    
    func getAllTracks() -> [VGTrack] {
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
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
                
                result.append(vgTrack)
            }
            
        } catch {
            return []
        }
        return result
    }
    
    func getPointsForTrack(vgTrack:VGTrack) -> [VGDataPoint] {
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.persistentStoreCoordinator = self.storeCoordinator

        var result = [VGDataPoint]()
        let trackFetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Track")
        trackFetchRequest.predicate = NSPredicate(format: "fileName = %@", vgTrack.fileName)
        
        do {
            guard let fetchedTrack = try context.fetch(trackFetchRequest).first else {
                return []
            }
            let dataPointFetchRequest = NSFetchRequest<NSManagedObject>(entityName: "DataPoint")
            dataPointFetchRequest.predicate = NSPredicate(format: "track = %@", fetchedTrack)
            
            let fetchedDataPoints = try context.fetch(dataPointFetchRequest)
            for point in fetchedDataPoints {
                let vgPoint = VGDataPoint(managedPoint: point)
                result.append(vgPoint)
            }
            
        } catch let error {
            print(error)
        }
        
        return result
    }
    
    
    
    func deleteAllData(_ entity:String) {
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.persistentStoreCoordinator = self.storeCoordinator
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entity)
        fetchRequest.returnsObjectsAsFaults = false
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
    
    func countAllData(_ entity:String, callback:(Int)->()) {
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.persistentStoreCoordinator = self.storeCoordinator
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entity)
        fetchRequest.returnsObjectsAsFaults = false
        do {
            let results = try context.fetch(fetchRequest)
            callback(results.count)
        } catch let error {
            print("Count all data in \(entity) error :", error)
            callback(0)
        }
    }
    
    func add(vgDataPoint:VGDataPoint, to vgTrack: NSManagedObject, in context:NSManagedObjectContext) {
        // 2
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
    
    fileprivate func add(vgTrack: VGTrack) {
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.persistentStoreCoordinator = self.storeCoordinator
        
        // 2
        let entity =
            NSEntityDescription.entity(forEntityName: "Track",
                                       in: context)!
        
        let track = NSManagedObject(entity: entity,
                                    insertInto: context)
        
        // 3
        track.setValue(vgTrack.fileName, forKey: "fileName")
        track.setValue(vgTrack.fileSize, forKey: "fileSize")
        track.setValue(vgTrack.duration, forKey: "duration")
        track.setValue(vgTrack.distance, forKey: "distance")
        track.setValue(vgTrack.minLat, forKey: "minLat")
        track.setValue(vgTrack.maxLat, forKey: "maxLat")
        track.setValue(vgTrack.minLon, forKey: "minLon")
        track.setValue(vgTrack.maxLon, forKey: "maxLon")
        track.setValue(vgTrack.processed, forKey: "processed")
        track.setValue(vgTrack.timeStart, forKey: "timeStart")

        for point in vgTrack.trackPoints {
            if point.hasGoodFix() {
                add(vgDataPoint: point, to: track, in: context)
            }
            
        }
        
        // 4
        do {
            try context.save()
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
    }
    
//    func update(vgDataPoint:VGDataPoint, to track: NSManagedObject) {
//        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "DataPoint")
//        fetchRequest.predicate = NSPredicate(format: "timeStamp = %@", vgDataPoint.timestamp! as CVarArg)
//        do {
//            let test = try context.fetch(fetchRequest)
//            print(test)
//            if test.count > 0 {
//                if let trackUpdate = test[0] as? NSManagedObject {
//                    try context.save()
//                }
//            } else {
//                self.add(vgDataPoint: vgDataPoint, to: track)
//            }
//
//        } catch let error {
//            print(error)
//        }
//
//    }
    
    func update(vgTrack: VGTrack) {
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.persistentStoreCoordinator = self.storeCoordinator
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Track")
        fetchRequest.predicate = NSPredicate(format: "fileName = %@", vgTrack.fileName)
        context.perform {
            do {
                let test = try context.fetch(fetchRequest)
                if test.count > 0 {
                    if let trackUpdate = test[0] as? NSManagedObject {
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
                            if point.hasGoodFix() {
                                self.add(vgDataPoint: point, to: trackUpdate, in: context)
                            }
                        }
                        
                        try context.save()
                    }
                } else {
                    self.add(vgTrack: vgTrack)
                }
                
                
            } catch let error {
                print(error)
            }

        }
        
    }
    
    func delete(vgTrack: VGTrack) {
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.persistentStoreCoordinator = self.storeCoordinator
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Track")
        fetchRequest.predicate = NSPredicate(format: "fileName = %@", vgTrack.fileName)
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
