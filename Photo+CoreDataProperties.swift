//
//  Photo+CoreDataProperties.swift
//  Virtual Tourist
//
//  Created by Arturo Reyes on 9/29/17.
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
    @NSManaged public var collection: Collection?

}
