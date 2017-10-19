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
    @IBOutlet weak var bottomButton: UIButton!
    
    var album : Collection!
    let stack = CoreDataStack.sharedInstance
    var fetchedResultsController : NSFetchedResultsController<Photo>!
    var deletePhotos: [IndexPath] = [] {
        didSet {
            let title = deletePhotos.isEmpty ? "New Collection" : "Delete Photos"
            bottomButton.setTitle(title, for: UIControlState.normal)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setFlowLayout()
        setMapDisplay(album)
        
        if fetchPhotos().isEmpty {
            downloadPhotos()
        }
    }
    
    @IBAction func pressBottomButton(_ sender: Any) {
        if deletePhotos.isEmpty {
            for photo in fetchedResultsController.fetchedObjects! {
                fetchedResultsController.managedObjectContext.delete(photo)
            }
            downloadPhotos()
        } else {
            for index in deletePhotos {
                let photo = fetchedResultsController.object(at: index)
                fetchedResultsController.managedObjectContext.delete(photo)
            }
            deletePhotos.removeAll()
            stack.save()
        }
        
    }
    
    func setFlowLayout() {
        let space: CGFloat = 3.0
        let cellDimension = (self.view.frame.size.width - (2 * space)) / 3
        
        flowLayout.minimumLineSpacing = space
        flowLayout.minimumInteritemSpacing = space
        flowLayout.itemSize = CGSize(width: cellDimension, height: cellDimension)
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
    
    func downloadPhotos() {
        FlickrClient.sharedInstance.getURLArray(latitude: album.latitude, longitude: album.longitude) { (success, results, errorString) in
            if success {
                if let urlArray = results {
                    for photoURL in urlArray {
                        FlickrClient.sharedInstance.getImageData(URL(string: photoURL)!) { (data, error, errorSt) in
                            if let photoData = data {
                                _ = Photo(url: photoURL, imageData: photoData)
                                self.stack.save()
                            } else {
                                print(errorSt!)
                            }
                        }
                    }
    
                } else {
                    print("Could not find URLs in results")
                }
            } else {
                print(errorString!)
            }
        }
    }
}

extension AlbumVC : UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCell", for: indexPath) as! PhotoCell
        cell.activityIndicator.isHidden = true
        let photo = fetchedResultsController.object(at: indexPath)

        if let photoData = photo.imageData {
            cell.photoView.image = UIImage(data: photoData as Data)
        } else {
            performUIUpdatesOnMain {
                cell.activityIndicator.startAnimating()
                cell.activityIndicator.isHidden = false
            }
            let url = photo.url
            FlickrClient.sharedInstance.getImageData(URL(string: url!)!) { (data, error, errorSt) in
                if let photoData = data {
                    performUIUpdatesOnMain {
                        cell.photoView.image = UIImage(data: photoData as Data)
                        cell.activityIndicator.stopAnimating()
                        cell.activityIndicator.isHidden = true
                    }
                    photo.imageData = photoData as NSData
                    self.stack.save()
                } else {
                    print(errorSt!)
                }
            }
            
        }
        setAlphaValue(cell, indexPath)
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
        let cell = collectionView.cellForItem(at: indexPath) as! PhotoCell
        if let index = deletePhotos.index(of: indexPath) {
            deletePhotos.remove(at: index)
        } else {
            deletePhotos.append(indexPath)
        }
        setAlphaValue(cell, indexPath)
    }
    
    func setAlphaValue(_ cell: PhotoCell, _ index: IndexPath) {
        if deletePhotos.index(of: index) != nil {
            cell.photoView.alpha = 0.5
        } else {
            cell.photoView.alpha = 1.0
        }
    }
}

//extension AlbumVC : NSFetchedResultsControllerDelegate {
    
//}


