//
//  Vehicle+CoreDataProperties.swift
//  
//
//  Created by Bergþór Þrastarson on 09/08/2020.
//
//

import Foundation
import CoreData


extension Vehicle {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Vehicle> {
        return NSFetchRequest<Vehicle>(entityName: "Vehicle")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var image: URL?
    @NSManaged public var mapColor: Transformable?
    @NSManaged public var name: String?
    @NSManaged public var order: Int16
    @NSManaged public var tracks: NSSet?
    @NSManaged public var vehicleType: VehicleType?

}

// MARK: Generated accessors for tracks
extension Vehicle {

    @objc(addTracksObject:)
    @NSManaged public func addToTracks(_ value: Track)

    @objc(removeTracksObject:)
    @NSManaged public func removeFromTracks(_ value: Track)

    @objc(addTracks:)
    @NSManaged public func addToTracks(_ values: NSSet)

    @objc(removeTracks:)
    @NSManaged public func removeFromTracks(_ values: NSSet)

}
