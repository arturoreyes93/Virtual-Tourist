//
//  CollectionData.swift
//  Virtual Tourist
//
//  Created by Arturo Reyes on 9/28/17.
//  Copyright © 2017 Arturo Reyes. All rights reserved.
//

import Foundation
import UIKit

class CollectionData {
    
    var collections: [Collection]!
    
    class func sharedInstance() -> CollectionData {
        struct Singleton {
            static var sharedInstance = CollectionData()
        }
        return Singleton.sharedInstance
    }
}
