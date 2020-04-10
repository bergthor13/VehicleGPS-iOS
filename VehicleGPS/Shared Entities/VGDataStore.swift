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
        let container = NSPersistentContainer(name: Constants.persistentContainer.name)
        
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
    fileprivate func getDataPoints(in context:NSManagedObjectContext, forTrackWith id:UUID) -> [DataPoint] {
        guard let fetchedTrack = getTrack(in: context, with: id) else {
            return [DataPoint]()
        }
        
        let dataPointFetchRequest = DataPoint.fetchRequest() as NSFetchRequest<DataPoint>
        dataPointFetchRequest.predicate = NSPredicate(format: "track = %@", fetchedTrack)
        
        do {
            return try context.fetch(dataPointFetchRequest)
        } catch {
            return []
        }
    }
    
    fileprivate func getMapPoints(in context:NSManagedObjectContext, forTrackWith id:UUID) -> [MapPoint] {
        guard let fetchedTrack = getTrack(in: context, with: id) else {
            return [MapPoint]()
        }
        
        do {
            let dataPointFetchRequest = MapPoint.fetchRequest() as NSFetchRequest<MapPoint>
            dataPointFetchRequest.predicate = NSPredicate(format: "track = %@", fetchedTrack)
            return try context.fetch(dataPointFetchRequest)
            
        } catch {
            return []
        }
    }
    
    fileprivate func getTrack(in context:NSManagedObjectContext, with id: UUID) -> Track? {
        let trackFetchRequest = Track.fetchRequest() as NSFetchRequest<Track>
        trackFetchRequest.predicate = self.getPredicate(for: id)
        do {
            guard let fetchedTrack = try context.fetch(trackFetchRequest).first else {
                print("Fetching track failed")
                return nil
            }
            return fetchedTrack
        } catch {
            print("Fetching track failed")
            return nil
        }
    }
    
    fileprivate func getVehicle(in context:NSManagedObjectContext, with id: UUID) -> Vehicle? {
        let vehicleFetchRequest = Vehicle.fetchRequest() as NSFetchRequest<Vehicle>
        vehicleFetchRequest.predicate = self.getPredicate(for: id)
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
    
    fileprivate func getAllTracks(in context: NSManagedObjectContext, forVehicleWith id:UUID, onSuccess:@escaping([VGTrack])->(), onFailure:@escaping(Error)->()) {
        let predicate = NSPredicate(format: "vehicleID = %@", argumentArray: [id])
        getTracks(in: context, with: predicate, onSuccess: { (tracks) in
            onSuccess(tracks)
        }) { (error) in
            onFailure(error)
        }
    }
    
    func getTracks(in context: NSManagedObjectContext, with predicate:NSPredicate?, onSuccess:@escaping([VGTrack])->(), onFailure:@escaping(Error)->()) {
        var result = [VGTrack]()
        let fetchRequest = Track.fetchRequest() as NSFetchRequest<Track>
        fetchRequest.predicate = predicate
            do {
                for track in try context.fetch(fetchRequest) {
                    let vgTrack = VGTrack(track: track)
                    guard let vehicleID = track.vehicleID else {
                        continue
                    }
                    guard let vehicle = getVehicle(in: context, with: vehicleID) else {
                        continue
                    }
                    
                    vgTrack.vehicle = VGVehicle(vehicle: vehicle)
                    result.append(vgTrack)
                }
            } catch let error {
                onFailure(error)
                return
            }
            onSuccess(result)
    }
    
    fileprivate func add(vgDataPoint:VGDataPoint, to track: Track, in context:NSManagedObjectContext) {
        let entity = NSEntityDescription.entity(forEntityName: "DataPoint", in: context)!
        var dataPoint = DataPoint(entity:entity, insertInto: context)
        dataPoint = vgDataPoint.setEntity(dataPoint: dataPoint, track: track)
    }
    
    func add(vgMapPoint:VGMapPoint, to track: Track, in context:NSManagedObjectContext) {
        let entity = NSEntityDescription.entity(forEntityName: "MapPoint", in: context)!
        var mapPoint = MapPoint(entity:entity, insertInto: context)
        mapPoint = vgMapPoint.setEntity(mapPoint: mapPoint, track: track)
        
    }
    
    fileprivate func getPredicate(for id:UUID) -> NSPredicate {
        return NSPredicate(format: "id = %@", argumentArray: [id])
    }
    
    // MARK: - Public Functions
    // MARK: Database Functions
    func deleteAllData(entity:String, onSuccess: @escaping()->(), onFailure: @escaping(Error)->()) {
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
                    DispatchQueue.main.async {
                        onFailure(error)
                    }
                    return
                }
            } catch let error {
                DispatchQueue.main.async {
                    onFailure(error)
                }
                return
            }
            DispatchQueue.main.async {
                onSuccess()
            }
            
        }
    }
    
    func countAllData(entity:String, onSuccess:@escaping(Int)->(), onFailure:@escaping(Error)->()) {
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.persistentStoreCoordinator = self.storeCoordinator
        context.perform {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entity)
            var result = 0
            
            fetchRequest.includesPropertyValues = false
            fetchRequest.includesSubentities    = false
            fetchRequest.resultType = NSFetchRequestResultType.countResultType
            do {
                result = try context.count(for: fetchRequest)
            } catch let error {
                DispatchQueue.main.async {
                    onFailure(error)
                }
            }
            
            DispatchQueue.main.async {
                onSuccess(result)
            }
        }
    }
    
    // MARK: Track
    func getAllTracks(onSuccess: @escaping([VGTrack])->(), onFailure:@escaping(Error)->()) {
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.persistentStoreCoordinator = self.storeCoordinator
        context.perform {
            self.getTracks(in: context, with: nil, onSuccess: { (tracks) in
                DispatchQueue.main.async {
                    onSuccess(tracks)
                }
                
            }) { (error) in
                DispatchQueue.main.async {
                    onFailure(error)
                }
            }
        }

    }
    
    func add(vgTrack: VGTrack, onSuccess: @escaping(UUID)->(), onFailure:@escaping(Error)->()) {
        print("ADDING")
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.persistentStoreCoordinator = self.storeCoordinator
        context.perform {
            let entity = NSEntityDescription.entity(forEntityName: "Track", in: context)!
            var newTrack = Track(entity: entity, insertInto: context)
            newTrack = vgTrack.setEntity(track:newTrack)
            let newID = newTrack.id!
            for point in vgTrack.trackPoints {
                self.add(vgDataPoint: point, to: newTrack, in: context)
            }
            
            for point in vgTrack.mapPoints {
                self.add(vgMapPoint: point, to: newTrack, in: context)
            }
            
            if let defaultVehicleID = self.getDefaultVehicleID() {
                // Get the track in question
                guard let vehicle = self.getVehicle(in: context, with: defaultVehicleID) else {
                    return
                }
                newTrack.setValue(defaultVehicleID, forKey: "vehicleID")
                vgTrack.id = newID
                vgTrack.vehicle = VGVehicle(vehicle: vehicle)
            }
            
            do {
                try context.save()
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .logsAdded, object: [vgTrack])
                    onSuccess(newID)
                    return
                }
            } catch let error {
                DispatchQueue.main.async {
                    onFailure(error)
                }
                return
            }
        }
    }
    
    func delete(trackWith id: UUID, onSuccess: @escaping()->(), onFailure:@escaping(Error)->()) {
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.persistentStoreCoordinator = self.storeCoordinator
        context.perform {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Track")
            fetchRequest.predicate = self.getPredicate(for: id)
            do {
                let test = try context.fetch(fetchRequest)
                if test.count > 0 {
                    if let trackUpdate = test[0] as? NSManagedObject {
                        context.delete(trackUpdate)
                        try context.save()
                        DispatchQueue.main.async {
                            onSuccess()
                        }
                    }
                }
            } catch let error {
                DispatchQueue.main.async {
                    onFailure(error)
                }
            }
        }
        
    }
    
    
    func getDataPointsForTrack(with id:UUID, onSuccess: @escaping([VGDataPoint])->(), onFailure:@escaping(Error)->())  {
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.persistentStoreCoordinator = self.storeCoordinator
        context.perform {
            var fetchedDataPoints = self.getDataPoints(in: context, forTrackWith: id)
            var result = [VGDataPoint]()
            for point in fetchedDataPoints {
                let vgPoint = VGDataPoint(dataPoint: point)
                result.append(vgPoint)
            }
            fetchedDataPoints = []
            DispatchQueue.main.async {
                onSuccess(result.sorted())
            }
        }
    }
    
    func getMapPointsForTrack(with id:UUID, onSuccess: @escaping([VGMapPoint])->(), onFailure:@escaping(Error)->()) {
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.persistentStoreCoordinator = self.storeCoordinator
        context.perform {
            var fetchedMapPoints = self.getMapPoints(in: context, forTrackWith: id)
            var result = [VGMapPoint]()
            for point in fetchedMapPoints {
                let vgPoint = VGMapPoint(point: point)
                result.append(vgPoint)
            }
            fetchedMapPoints = []
            DispatchQueue.main.async {
                onSuccess(result.sorted())
            }
        }
    }
    
    // MARK: Vehicle
    func getAllVehicles(onSuccess: @escaping([VGVehicle])->(), onFailure: @escaping(Error)->()) {
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.persistentStoreCoordinator = self.storeCoordinator
        context.perform {
            let tracksForVehicleRequests = DispatchGroup()
            let fetchRequest = Vehicle.fetchRequest() as NSFetchRequest<Vehicle>
            do {
                var returnList = [VGVehicle]()
                let result =  try context.fetch(fetchRequest)
                for item in result {
                    let newVehicle = VGVehicle(vehicle: item)
                    tracksForVehicleRequests.enter()
                    self.getAllTracks(in: context, forVehicleWith: newVehicle.id!, onSuccess: { (tracks) in
                        newVehicle.tracks = tracks
                        returnList.append(newVehicle)
                        tracksForVehicleRequests.leave()

                    }) { (error) in
                        print(error)
                        tracksForVehicleRequests.leave()
                    }
                }
                tracksForVehicleRequests.notify(queue: .main) {
                    onSuccess(returnList)
                }
            } catch let error {
                DispatchQueue.main.async {
                    onFailure(error)
                }
            }

        }
    }
    
    func add(vgVehicle:VGVehicle, onSuccess: @escaping(UUID)->(), onFailure:@escaping(Error)->()) {
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.persistentStoreCoordinator = self.storeCoordinator
        context.perform {
            let newID = UUID()
            let entityDescription = NSEntityDescription.entity(forEntityName: "Vehicle", in: context)!
            let newVehicle = Vehicle.init(entity: entityDescription, insertInto: context)
            newVehicle.name = vgVehicle.name
            newVehicle.id = newID
            newVehicle.mapColor = vgVehicle.mapColor
            vgVehicle.id = newVehicle.id
            if let image = vgVehicle.image {
                newVehicle.image = self.vgFileManager.imageToFile(image: image, for: vgVehicle)
            }
            
            
            context.insert(newVehicle)
            do {
                try context.save()
                DispatchQueue.main.async {
                    onSuccess(newID)
                }
            } catch let error {
                DispatchQueue.main.async {
                    onFailure(error)
                }
            }
        }
    }
    
    func update(vgVehicle:VGVehicle, onSuccess: @escaping()->(), onFailure:@escaping(Error)->()) {
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.persistentStoreCoordinator = self.storeCoordinator
        
        guard let newVehicle = getVehicle(in: context, with: vgVehicle.id!) else {
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
            DispatchQueue.main.async {
                onSuccess()
            }
        } catch let error {
            DispatchQueue.main.async {
                onFailure(error)
            }
        }
    }
    
    func delete(vehicleWith id:UUID, onSuccess: @escaping()->(), onFailure:@escaping(Error)->()) {
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.persistentStoreCoordinator = self.storeCoordinator
        context.perform {
            let fetchRequest = Vehicle.fetchRequest() as NSFetchRequest<Vehicle>
            fetchRequest.predicate = self.getPredicate(for: id)
            do {
                let test = try context.fetch(fetchRequest)
                if test.count > 0 {
                    context.delete(test[0])
                    try context.save()
                    DispatchQueue.main.async {
                        onSuccess()
                    }
                }
            } catch let error {
                DispatchQueue.main.async {
                    onFailure(error)
                }
            }
        }
    }
    
    func add(vehicleWith vehicleId:UUID, toTrackWith trackId:UUID, onSuccess: @escaping()->(), onFailure:@escaping(Error)->()) {
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.persistentStoreCoordinator = self.storeCoordinator
        context.perform {
            // Get the track in question
            guard let vehicle = self.getVehicle(in: context, with: vehicleId) else {
                return
            }
            
            guard let track = self.getTrack(in: context, with: trackId) else {
                return
            }
            
            track.setValue(vehicle.id, forKey: "vehicleID")
            do {
                try context.save()
                let vgVehicle = VGVehicle(vehicle:vehicle)
                let vgTrack = VGTrack(track: track)
                vgTrack.vehicle = vgVehicle

                DispatchQueue.main.async {
                    onSuccess()
                    NotificationCenter.default.post(name: .vehicleAddedToTrack, object: vgTrack)
                }
                
            } catch let error {
                DispatchQueue.main.async {
                    onFailure(error)
                }
            }
        }
    }

    
    func getDefaultVehicleID() -> UUID? {
        if let items = UserDefaults.standard.data(forKey: "DefaultVehicle") {
            let decoder = JSONDecoder()
            if let defaultVehicleID = try? decoder.decode(UUID.self, from: items) {
                return defaultVehicleID
            } else {
                return nil
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
        let fetchedDataPoints = self.getDataPoints(in: context, forTrackWith: track.id!)
        
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
                let dp = VGDataPoint(dataPoint: item)
                track.trackPoints.append(dp)
            }
            newTrack = VGTrack(track: trackMo as! Track)
            for item in rightSplit {
                let dp = VGDataPoint(dataPoint: item)
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
