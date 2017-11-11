//
//  Photo+CoreDataProperties.swift
//  Virtual Tourist
//
//  Created by Arturo Reyes on 11/10/17.
//  Copyright © 2017 Arturo Reyes. All rights reserved.
//
//

import Foundation
import CoreData


extension Photo {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Photo> {
        return NSFetchRequest<Photo>(entityName: "Photo")
    }

    @NSManaged public var imageData: NSData?
    @NSManaged public var url: String?
    @NSManaged public var collection: Collection?

}
