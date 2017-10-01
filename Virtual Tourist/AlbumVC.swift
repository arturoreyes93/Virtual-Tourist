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
import CoreData

class AlbumVC: UIViewController {
    
    @IBOutlet weak var mapDisplayView: MKMapView!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    @IBOutlet weak var collectionView: UICollectionView!
    
    var album : Collection!
    let stack = CoreDataStack.sharedInstance
    var fetchedResultsController : NSFetchedResultsController<Photo>!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setFlowLayout()
        setMapDisplay(album)
        
        if fetchPhotos().isEmpty {
            
        }
    }
    
    
    func setFlowLayout() {
        let space: CGFloat = 3.0
        let widthDimension = (self.view.frame.size.width - (2 * space)) / 3
        let heightDimension = (self.view.frame.size.height - (2 * space)) / 3
        
        
        flowLayout.minimumLineSpacing = space
        flowLayout.minimumInteritemSpacing = space
        flowLayout.itemSize = CGSize(width: widthDimension, height: heightDimension)
    }
    
    func setMapDisplay(_ annotation: MKAnnotation) {
        let center = annotation.coordinate
        let span = MKCoordinateSpanMake(0.12, 0.12)
        let region = MKCoordinateRegion(center: center, span: span)
        mapDisplayView.region = region
    }
    
    func fetchPhotos() -> [Photo] {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Photo")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "url", ascending: true)]
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: stack.context, sectionNameKeyPath: nil, cacheName: nil) as! NSFetchedResultsController<Photo>
        var photos = [Photo]()
        
        if let fc = fetchedResultsController {
            do {
                try fc.performFetch()
                photos = fc.fetchedObjects!
            } catch let e as NSError {
                print("Error while trying to perform fetch: \n\(e)\n\(fetchedResultsController)")
            }
        }
        
        return photos
    }
    
    func getPhotoURLs() {
        FlickrClient.sharedInstance.getPhotoURLsWithLocation(latitude: album.latitude, longitude: album.longitude) { (success, results, errorString) in
            if success {
                if let photoArray = results {
                    for photoURL in photoArray {
                        _ = Photo(url: photoURL)
                        self.stack.save()
                    }
                } else {
                    print(errorString)
                }
            }
        }
    }
}

extension AlbumVC : UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCell", for: indexPath) as! PhotoCell
        let fetchedObject = fetchedResultsController.object(at: indexPath)
        
        if let photo = fetchedObject.imageData {
            cell.photoView.image = UIImage(data: photo as Data)
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let numberOfItems: Int
        guard let fetchedItems = fetchedResultsController.fetchedObjects?.count else {
            numberOfItems = 0
            return numberOfItems
        }
        numberOfItems = fetchedItems
        return numberOfItems
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
    }
    
}

extension AlbumVC : NSFetchedResultsControllerDelegate {
    
}


