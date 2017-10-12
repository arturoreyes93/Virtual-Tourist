//
//  Photo+CoreDataClass.swift
//  Virtual Tourist
//
//  Created by Arturo Reyes on 9/29/17.
//  Copyright © 2017 Arturo Reyes. All rights reserved.
//
//

import Foundation
import CoreData

@objc(Photo)
public class Photo: NSManagedObject {
    
    
    convenience init(url: String, imageData: Data) {
        if let entity = NSEntityDescription.entity(forEntityName: "Photo", in: CoreDataStack.sharedInstance.context) {
            self.init(entity: entity, insertInto: CoreDataStack.sharedInstance.context)
            self.url = url
            self.imageData = imageData as NSData
        } else {
            fatalError("Failed to initialize Photo")
        }
    }

}
