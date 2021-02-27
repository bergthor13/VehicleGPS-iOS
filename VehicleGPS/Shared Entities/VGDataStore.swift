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
    let semaphore = DispatchSemaphore(value: 1)
    
    func initializeContainer() {
        let container = NSPersistentContainer(name: Constants.PersistentContainer.name)
        
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
        guard let modelURL = Bundle.main.url(forResource: "VehicleGPS", withExtension: "momd") else {
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
    fileprivate func getDataPoints(in context: NSManagedObjectContext, forTrackWith id: UUID) -> [DataPoint] {
        guard let fetchedTrack = getTrack(in: context, with: id) else {
            return [DataPoint]()
        }
        
        let dataPointFetchRequest = DataPoint.fetchRequest() as NSFetchRequest<DataPoint>
        dataPointFetchRequest.predicate = NSPredicate(format: "track = %@", fetchedTrack)
        
        do {
            return try context.fetch(dataPointFetchRequest)
        } catch let error {
            print(error)
            return []
        }
    }
    
    fileprivate func getMapPoints(in context: NSManagedObjectContext, forTrackWith id: UUID) -> [MapPoint] {
        guard let fetchedTrack = getTrack(in: context, with: id) else {
            return [MapPoint]()
        }
        do {
            let dataPointFetchRequest = MapPoint.fetchRequest() as NSFetchRequest<MapPoint>
            dataPointFetchRequest.predicate = NSPredicate(format: "track = %@", fetchedTrack)
            let mapPoints = try context.fetch(dataPointFetchRequest)
            return mapPoints
        } catch let error {
            print(error)
            return []
        }
    }
    
    fileprivate func getTags(in context: NSManagedObjectContext, forTrackWith id: UUID) -> [Tag] {
        guard let fetchedTrack = getTrack(in: context, with: id) else {
            return []
        }
        do {
            let tagFetchRequest = Tag.fetchRequest() as NSFetchRequest<Tag>
            tagFetchRequest.predicate = NSPredicate(format: "ANY tracks == %@", fetchedTrack)
            return try context.fetch(tagFetchRequest)
        } catch let error {
            print(error)
            return []
        }
    }
    
    fileprivate func getTrack(in context: NSManagedObjectContext, with id: UUID) -> Track? {
        let trackFetchRequest = Track.fetchRequest() as NSFetchRequest<Track>
        trackFetchRequest.predicate = self.getPredicate(for: id)
        do {
            guard let fetchedTrack = try context.fetch(trackFetchRequest).first else {
                print("Fetching track failed")
                return nil
            }
            return fetchedTrack
        } catch let error {
            print(error)
            print("Fetching track failed")
            return nil
        }
    }
    
    fileprivate func getVehicle(in context: NSManagedObjectContext, with id: UUID) -> Vehicle? {
        let vehicleFetchRequest = Vehicle.fetchRequest() as NSFetchRequest<Vehicle>
        vehicleFetchRequest.predicate = self.getPredicate(for: id)
        do {
            guard let fetchedVehicle = try context.fetch(vehicleFetchRequest).first else {
                print("Fetching vehicle failed")
                return nil
            }
            return fetchedVehicle
        } catch let error {
            print(error)
            print("Fetching vehicle failed")
            return nil
        }
    }
    
    fileprivate func getTag(in context: NSManagedObjectContext, with id: UUID) -> Tag? {
        let tagFetchRequest = Tag.fetchRequest() as NSFetchRequest<Tag>
        tagFetchRequest.predicate = self.getPredicate(for: id)
        do {
            guard let fetchedTag = try context.fetch(tagFetchRequest).first else {
                print("Fetching tag failed")
                return nil
            }
            return fetchedTag
        } catch let error {
            print(error)
            print("Fetching tag failed")
            return nil
        }
    }
    
    fileprivate func getAllTracks(in context: NSManagedObjectContext, forVehicleWith id: UUID, onSuccess: @escaping([VGTrack]) -> Void, onFailure: @escaping(Error) -> Void) {
        let predicate = NSPredicate(format: "vehicle.id = %@", argumentArray: [id])
        getTracks(in: context, with: predicate, onSuccess: { (tracks) in
            onSuccess(tracks)
        }, onFailure: { (error) in
            onFailure(error)
        })
    }
    
    func getTracks(in context: NSManagedObjectContext, with predicate: NSPredicate?, onSuccess: @escaping([VGTrack]) -> Void, onFailure: @escaping(Error) -> Void) {
        var result = [VGTrack]()
        let fetchRequest = Track.fetchRequest() as NSFetchRequest<Track>
        fetchRequest.predicate = predicate
            do {
                for track in try context.fetch(fetchRequest) {
                    track.tags?.addingObjects(from: getTags(in: context, forTrackWith: track.id!))
                    result.append(VGTrack(track: track))
                }
            } catch let error {
                onFailure(error)
                return
            }
            onSuccess(result)
    }
    
    fileprivate func add(vgDataPoint: VGDataPoint, to track: Track, in context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entity(forEntityName: "DataPoint", in: context)!
        var dataPoint = DataPoint(entity: entity, insertInto: context)
        dataPoint = vgDataPoint.setEntity(dataPoint: dataPoint, track: track)
    }
    
    fileprivate func add(vgMapPoint: VGMapPoint, to track: Track, in context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entity(forEntityName: "MapPoint", in: context)!
        var mapPoint = MapPoint(entity: entity, insertInto: context)
        mapPoint = vgMapPoint.setEntity(mapPoint: mapPoint, track: track)
        
    }
    
    fileprivate func removeAllDataPoints(from track: Track, in context: NSManagedObjectContext) {
        let dataPoints = getDataPoints(in: context, forTrackWith: track.id!)
        for dataPoint in dataPoints {
            context.delete(dataPoint)
        }
    }
    
    fileprivate func removeAllMapPoints(from track: Track, in context: NSManagedObjectContext) {
        let mapPoints = getMapPoints(in: context, forTrackWith: track.id!)
        for mapPoint in mapPoints {
            context.delete(mapPoint)
        }
    }
    
    fileprivate func getPredicate(for id: UUID) -> NSPredicate {
        return NSPredicate(format: "id = %@", argumentArray: [id])
    }
    
    // MARK: - Public Functions
    // MARK: Database Functions
    func deleteAllData(entity: String, onSuccess: @escaping() -> Void, onFailure: @escaping(Error) -> Void) {
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
    
    func countAllData(entity: String, onSuccess: @escaping(Int) -> Void, onFailure: @escaping(Error) -> Void) {
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
    func getAllTracks(onSuccess: @escaping([VGTrack]) -> Void, onFailure: @escaping(Error) -> Void) {
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.persistentStoreCoordinator = self.storeCoordinator
        context.perform {
            self.getTracks(in: context, with: nil, onSuccess: { (tracks) in
                DispatchQueue.main.async {
                    onSuccess(tracks)
                }
                
            }, onFailure: { (error) in
                DispatchQueue.main.async {
                    onFailure(error)
                }
            })
        }

    }
    
    func add(vgTrack: VGTrack, onSuccess: @escaping(UUID) -> Void, onFailure: @escaping(Error) -> Void) {
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.persistentStoreCoordinator = self.storeCoordinator
        context.perform {
            let entity = NSEntityDescription.entity(forEntityName: "Track", in: context)!
            var newTrack = Track(entity: entity, insertInto: context)
            
            newTrack = vgTrack.setEntity(track: newTrack)
            newTrack.id = UUID()
            let newID = newTrack.id!
            for point in vgTrack.trackPoints {
                self.add(vgDataPoint: point, to: newTrack, in: context)
            }
            
            for point in vgTrack.mapPoints {
                self.add(vgMapPoint: point, to: newTrack, in: context)
            }
            vgTrack.trackPoints = []
            vgTrack.mapPoints = []
            self.semaphore.wait()
            if let defaultVehicleID = self.getDefaultVehicleID() {
                // Get the vehicle in question
                if let vehicle = self.getVehicle(in: context, with: defaultVehicleID) {
                    vgTrack.vehicle = VGVehicle(vehicle: vehicle)
                    newTrack.vehicle = vehicle
                }
            }

            vgTrack.id = newID

            do {
                
                try context.save()
                NotificationCenter.default.post(name: .logsAdded, object: [vgTrack])
                self.semaphore.signal()
                DispatchQueue.main.async {
                    vgTrack.id = newID
                    onSuccess(newID)
                    return
                }
            } catch let error {
                self.semaphore.signal()
                DispatchQueue.main.async {
                    onFailure(error)
                }
                return
            }
        }
    }
    
    /// Returns the magnitude of a vector in three dimensions
    /// from the given components.
    ///
    /// - Parameters:
    ///     - vgTrack: The *x* component of the vector.
    ///     - onSuccess: The *y* component of the vector.
    ///     - onFailure: The *z* component of the vector.

    func update(vgTrack: VGTrack, onSuccess: @escaping(UUID) -> Void, onFailure: @escaping(Error) -> Void) {
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.persistentStoreCoordinator = self.storeCoordinator
        context.perform {
            guard var oldTrack = self.getTrack(in: context, with: vgTrack.id!) else {
                let error = NSError(domain: "", code: 123, userInfo: ["NSLocalizedDescriptionKey": "Can't find old track"])
                onFailure(error)
                return
            }
            // Update the track with new information.
            oldTrack = vgTrack.setEntity(track: oldTrack)
            
            // Remove all map and data points from the track.
            self.removeAllDataPoints(from: oldTrack, in: context)
            self.removeAllMapPoints(from: oldTrack, in: context)
            
            // And then add the new ones.
            for point in vgTrack.trackPoints {
                self.add(vgDataPoint: point, to: oldTrack, in: context)
            }
            
            for point in vgTrack.mapPoints {
                self.add(vgMapPoint: point, to: oldTrack, in: context)
            }
            vgTrack.trackPoints = []
            vgTrack.mapPoints = []
            // Then try to save.
            do {
                try context.save()
                NotificationCenter.default.post(name: .logUpdated, object: vgTrack)
                DispatchQueue.main.async {
                    onSuccess(vgTrack.id!)
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
    
    func delete(trackWith id: UUID, onSuccess: @escaping() -> Void, onFailure: @escaping(Error) -> Void) {
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
    
    func getDataPointsForTrack(with id: UUID, onSuccess: @escaping([VGDataPoint]) -> Void, onFailure: @escaping(Error) -> Void) {
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
            onSuccess(result.sorted())
        }
    }
    
    func getMapPointsForTrack(with id: UUID, onSuccess: @escaping([VGMapPoint]) -> Void, onFailure: @escaping(Error) -> Void) {
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
            onSuccess(result.sorted())
            
        }
    }
    
    // MARK: Vehicle
    func getAllVehicles(onSuccess: @escaping([VGVehicle]) -> Void, onFailure: @escaping(Error) -> Void) {
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.persistentStoreCoordinator = self.storeCoordinator
        context.perform {
            let tracksForVehicleRequests = DispatchGroup()
            let fetchRequest = Vehicle.fetchRequest() as NSFetchRequest<Vehicle>
            do {
                var returnList = [VGVehicle]()
                let result = try context.fetch(fetchRequest)
                for item in result {
                    let newVehicle = VGVehicle(vehicle: item)
                    tracksForVehicleRequests.enter()
                    self.getAllTracks(in: context, forVehicleWith: newVehicle.id!, onSuccess: { (tracks) in
                        newVehicle.tracks = tracks
                        returnList.append(newVehicle)
                        tracksForVehicleRequests.leave()

                    }, onFailure: { (error) in
                        print(error)
                        tracksForVehicleRequests.leave()
                    })
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
    
    func add(vgVehicle: VGVehicle, onSuccess: @escaping(UUID) -> Void, onFailure: @escaping(Error) -> Void) {
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.persistentStoreCoordinator = self.storeCoordinator
        context.perform {
            let newID = UUID()
            let entityDescription = NSEntityDescription.entity(forEntityName: "Vehicle", in: context)!
            let newVehicle = Vehicle.init(entity: entityDescription, insertInto: context)
            newVehicle.name = vgVehicle.name
            newVehicle.id = newID
            newVehicle.mapColor = vgVehicle.mapColor
            newVehicle.order = Int16(vgVehicle.order ?? -1)
            vgVehicle.id = newVehicle.id
            if let image = vgVehicle.image {
                newVehicle.image = self.vgFileManager.save(image: image, for: vgVehicle)
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
    
    func update(vgVehicle: VGVehicle, onSuccess: @escaping() -> Void, onFailure: @escaping(Error) -> Void) {
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.persistentStoreCoordinator = self.storeCoordinator
        guard let newVehicle = getVehicle(in: context, with: vgVehicle.id!) else {
            return
        }
        
        newVehicle.name = vgVehicle.name
        newVehicle.id = vgVehicle.id
        newVehicle.mapColor = vgVehicle.mapColor
        newVehicle.order = Int16(vgVehicle.order ?? -1)
        
        if let image = vgVehicle.image {
            newVehicle.image = vgFileManager.save(image: image, for: vgVehicle)
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
    
    func delete(vehicleWith id: UUID, onSuccess: @escaping() -> Void, onFailure: @escaping(Error) -> Void) {
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
    
    func add(vehicleWith vehicleId: UUID, toTrackWith trackId: UUID, onSuccess: @escaping() -> Void, onFailure:@escaping(Error) -> Void) {
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
            
            track.setValue(vehicle, forKey: "vehicle")
            do {
                try context.save()
                let vgVehicle = VGVehicle(vehicle: vehicle)
                let vgTrack = VGTrack(track: track)
                vgTrack.vehicle = vgVehicle

                DispatchQueue.main.async {
                    onSuccess()
                    NotificationCenter.default.post(name: .vehicleAddedToTrack, object: vgTrack)
                    self.vgFileManager.deletePreviewImage(for: vgTrack)
                    let ssm = VGSnapshotMaker(fileManager: self.vgFileManager, dataStore: self)
                    ssm.generateImageFor(track: vgTrack)
                }
                
            } catch let error {
                DispatchQueue.main.async {
                    onFailure(error)
                }
            }
        }
    }
    
    // MARK: - DownloadedFile
    func getDownloadedFiles(onSuccess:@escaping([DownloadedFile]) -> Void, onFailure:@escaping(Error) -> Void) {
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.persistentStoreCoordinator = self.storeCoordinator
        context.perform {
            let fetchRequest = DownloadedFile.fetchRequest() as NSFetchRequest<DownloadedFile>
            do {
                let result = try context.fetch(fetchRequest) as [DownloadedFile]
                onSuccess(result)
                
            } catch let error {
                DispatchQueue.main.async {
                    onFailure(error)
                }
            }
        }
    }
    
    func add(file: VGDownloadedFile, onSuccess: @escaping() -> Void, onFailure: @escaping(Error) -> Void) {
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.persistentStoreCoordinator = self.storeCoordinator
        context.perform {
            let entityDescription = NSEntityDescription.entity(forEntityName: "DownloadedFile", in: context)!
            let downloadedFile = DownloadedFile.init(entity: entityDescription, insertInto: context)
            downloadedFile.name = file.name
            downloadedFile.size = Int64(file.size!)
            context.insert(downloadedFile)
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
    }
    
    func update(file: VGDownloadedFile, onSuccess: @escaping() -> Void, onFailure: @escaping(Error) -> Void) {
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.persistentStoreCoordinator = self.storeCoordinator
        context.perform {
            let fetchRequest = DownloadedFile.fetchRequest() as NSFetchRequest<DownloadedFile>
            fetchRequest.predicate = NSPredicate(format: "name = %@", file.name)
            
            do {
                if let bla = try context.fetch(fetchRequest).first {
                    bla.name = file.name
                    bla.size = Int64(file.size!)
                }
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
    }
    
    // MARK: - Tags
    func getTags(onSuccess: @escaping([VGTag]) -> Void, onFailure: @escaping(Error) -> Void) {
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.persistentStoreCoordinator = self.storeCoordinator
        context.perform {
            let fetchRequest = Tag.fetchRequest() as NSFetchRequest<Tag>
            do {
                let result = try context.fetch(fetchRequest) as [Tag]
                var tags = [VGTag]()
                for tag in result {
                    tags.append(VGTag(tag: tag))
                }
                onSuccess(tags)
                
            } catch let error {
                DispatchQueue.main.async {
                    onFailure(error)
                }
            }
        }
    }
    
    func add(tag: VGTag, onSuccess: @escaping(UUID) -> Void, onFailure: @escaping(Error) -> Void) {
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.persistentStoreCoordinator = self.storeCoordinator
        context.perform {
            let entityDescription = NSEntityDescription.entity(forEntityName: "Tag", in: context)!
            let tagEntity = Tag.init(entity: entityDescription, insertInto: context)
            tagEntity.name = tag.name
            tagEntity.id = UUID()
            context.insert(tagEntity)
            do {
                let tagID = tagEntity.id!
                try context.save()
                DispatchQueue.main.async {
                    onSuccess(tagID)
                }
                
            } catch let error {
                DispatchQueue.main.async {
                    onFailure(error)
                }
            }
        }
    }
    
    func update(tag: VGTag, onSuccess: @escaping() -> Void, onFailure: @escaping(Error) -> Void) {
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.persistentStoreCoordinator = self.storeCoordinator
        context.perform {
            let fetchRequest = Tag.fetchRequest() as NSFetchRequest<Tag>
            fetchRequest.predicate = NSPredicate(format: "name = %@", tag.name!)
            
            do {
                if let bla = try context.fetch(fetchRequest).first {
                    bla.name = tag.name
                }
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
    }
    
    func delete(tagWith id: UUID, onSuccess: @escaping() -> Void, onFailure: @escaping(Error) -> Void) {
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.persistentStoreCoordinator = self.storeCoordinator
        context.perform {
            let fetchRequest = Tag.fetchRequest() as NSFetchRequest<Tag>
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
    
    func add(tagWith tagId: UUID, toTrackWith trackId: UUID, onSuccess: @escaping() -> Void, onFailure: @escaping(Error) -> Void) {
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.persistentStoreCoordinator = self.storeCoordinator
        context.perform {
            // Get the track in question
            guard let tag = self.getTag(in: context, with: tagId) else {
                return
            }
            
            guard let track = self.getTrack(in: context, with: trackId) else {
                return
            }
            
            track.addToTags(tag)
            do {
                try context.save()
                let vgTag = VGTag(tag: tag)
                let vgTrack = VGTrack(track: track)
                vgTrack.tags.append(vgTag)

                DispatchQueue.main.async {
                    onSuccess()
                }
                
            } catch let error {
                DispatchQueue.main.async {
                    onFailure(error)
                }
            }
        }
    }
    
    func remove(tagWith tagId: UUID, fromTrackWith trackId: UUID, onSuccess: @escaping() -> Void, onFailure: @escaping(Error) -> Void) {
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.persistentStoreCoordinator = self.storeCoordinator
        context.perform {
            // Get the track in question
            guard let tag = self.getTag(in: context, with: tagId) else {
                return
            }
            
            guard let track = self.getTrack(in: context, with: trackId) else {
                return
            }
            
            track.removeFromTags(tag)
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
    
    func setDefaultVehicleID(id: UUID) {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(id) {
            UserDefaults.standard.set(encoded, forKey: "DefaultVehicle")
        }
    }
    
    func getHost() -> String? {
        return UserDefaults.standard.string(forKey: "SftpHost")
    }
    
    func getUsername() -> String? {
        return UserDefaults.standard.string(forKey: "SftpUsername")
    }
    
    func setHost(host: String) {
        UserDefaults.standard.setValue(host, forKey: "SftpHost")
    }
    
    func setUsername(username: String) {
        UserDefaults.standard.setValue(username, forKey: "SftpUsername")
    }
}
