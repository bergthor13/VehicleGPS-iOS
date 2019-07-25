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
    
    let appDelegate:AppDelegate
    let context: NSManagedObjectContext
    init() {
        self.appDelegate = (UIApplication.shared.delegate as? AppDelegate)!
        self.context = appDelegate.persistentContainer.viewContext
    }
    
    func getAllTracks() -> [VGTrack] {
        var result = [VGTrack]()
        //2
        let fetchRequest =
            NSFetchRequest<NSManagedObject>(entityName: "Track")
        
        //3
        do {
            let cdTracks = try self.context.fetch(fetchRequest)
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
                
                result.append(vgTrack)
            }
            
        } catch {
            return []
        }
        return result
    }
    
    func getPointsForTrack(vgTrack:VGTrack) -> [VGDataPoint] {
        var result = [VGDataPoint]()
        let trackFetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Track")
        trackFetchRequest.predicate = NSPredicate(format: "fileName = %@", vgTrack.fileName)
        
        do {
            guard let fetchedTrack = try self.context.fetch(trackFetchRequest).first else {
                return []
            }
            let dataPointFetchRequest = NSFetchRequest<NSManagedObject>(entityName: "DataPoint")
            dataPointFetchRequest.predicate = NSPredicate(format: "track = %@", fetchedTrack)
            
            let fetchedDataPoints = try self.context.fetch(dataPointFetchRequest)
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
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entity)
        fetchRequest.returnsObjectsAsFaults = false
        do {
            guard let appDelegate =
                UIApplication.shared.delegate as? AppDelegate else {
                    return
            }
            let results = try appDelegate.persistentContainer.viewContext.fetch(fetchRequest)
            for object in results {
                guard let objectData = object as? NSManagedObject else {continue}
                appDelegate.persistentContainer.viewContext.delete(objectData)
                
            }
            do {
                try appDelegate.persistentContainer.viewContext.save()
            } catch let error {
                print(error)
            }
        } catch let error {
            print("Detele all data in \(entity) error :", error)
        }
    }
    
    func add(vgDataPoint:VGDataPoint, to vgTrack: NSManagedObject) {
        // 2
        let entity = NSEntityDescription.entity(forEntityName: "DataPoint", in: self.context)!
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
        if vgDataPoint.rpm != nil {
            dataPoint.setValue(vgDataPoint.rpm, forKey: "rpm")
        }
        
        if vgDataPoint.engineLoad != nil {
            dataPoint.setValue(vgDataPoint.engineLoad, forKey: "engineLoad")
        }
        
        if vgDataPoint.coolantTemperature != nil {
            dataPoint.setValue(vgDataPoint.coolantTemperature, forKey: "coolantTemperature")
        }
        
        if vgDataPoint.ambientTemperature != nil {
            dataPoint.setValue(vgDataPoint.ambientTemperature, forKey: "ambientTemperature")
        }
        
        if vgDataPoint.throttlePosition != nil {
            dataPoint.setValue(vgDataPoint.throttlePosition, forKey: "throttlePosition")
        }
        
        dataPoint.setValue(vgTrack, forKey: "track")
        
    }
    
    func add(vgTrack: VGTrack) {
        
        // 2
        let entity =
            NSEntityDescription.entity(forEntityName: "Track",
                                       in: self.context)!
        
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
        
        for point in vgTrack.trackPoints {
            add(vgDataPoint: point, to: track)
        }
        
        // 4
        do {
            try context.save()
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
    }
    
    func update(vgTrack: VGTrack) {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Track")
        fetchRequest.predicate = NSPredicate(format: "fileName = %@", vgTrack.fileName)
        do {
            let test = try self.context.fetch(fetchRequest)
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
                    try context.save()
                }
            } else {
                self.add(vgTrack: vgTrack)
            }
            
            
        } catch let error {
            print(error)
        }
        
    }
    
    func delete(vgTrack: VGTrack) {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Track")
        fetchRequest.predicate = NSPredicate(format: "fileName = %@", vgTrack.fileName)
        do {
            let test = try self.context.fetch(fetchRequest)
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
