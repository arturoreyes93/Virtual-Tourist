//
//  Collection+CoreDataClass.swift
//  Virtual Tourist
//
//  Created by Arturo Reyes on 9/29/17.
//  Copyright © 2017 Arturo Reyes. All rights reserved.
//
//

import Foundation
import CoreData
import MapKit

@objc(Collection)
public class Collection: NSManagedObject, MKAnnotation {
    
    public var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2DMake(latitude, longitude)
    }
    convenience init(latitude: Double, longitude: Double, context: NSManagedObjectContext) {
        if let entity = NSEntityDescription.entity(forEntityName: "Collection", in: CoreDataStack.sharedInstance.context) {
            self.init(entity: entity, insertInto: CoreDataStack.sharedInstance.context)
            self.createdAt = NSDate()
            self.latitude = latitude
            self.longitude = longitude
        } else {
            fatalError("Unable to find Entity name!")
        }
    }

}
