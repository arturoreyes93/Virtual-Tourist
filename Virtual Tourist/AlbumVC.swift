//
//  AlbumVC.swift
//  Virtual Tourist
//
//  Created by Arturo Reyes on 9/27/17.
//  Copyright © 2017 Arturo Reyes. All rights reserved.
//

import Foundation
import UIKit
import MapKit

class AlbumVC: UICollectionViewController, MKMapViewDelegate {
    
    @IBOutlet weak var mapDisplayView: MKMapView!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let space: CGFloat = 3.0
        let widthDimension = (self.view.frame.size.width - (2 * space)) / 3
        let heightDimension = (self.view.frame.size.height - (2 * space)) / 3
        
        
        flowLayout.minimumLineSpacing = space
        flowLayout.minimumInteritemSpacing = space
        flowLayout.itemSize = CGSize(width: widthDimension, height: heightDimension)
    }
    
    private func loadPhotos() {
        
    }
    
    // MARK: UICollectionViewDataSource


    
    
}

