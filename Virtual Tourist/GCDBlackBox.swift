//
//  GCDBlackBox.swift
//  Virtual Tourist
//
//  Created by Arturo Reyes on 9/28/17.
//  Copyright © 2017 Arturo Reyes. All rights reserved.
//

import Foundation

func performUIUpdatesOnMain(_ updates: @escaping () -> Void) {
    DispatchQueue.main.async {
        updates()
    }
}
