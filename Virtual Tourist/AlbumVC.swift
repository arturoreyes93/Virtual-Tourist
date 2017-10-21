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
    @IBOutlet weak var bottomButton: UIBarButtonItem!
    
    var album : Collection!
    var page: Int = 1
    let stack = CoreDataStack.sharedInstance
    var blockOperations: [BlockOperation] = []
    var deletePhotos: [IndexPath] = [] {
        didSet {
            bottomButton.title = deletePhotos.isEmpty ? "New Collection" : "Delete Selected Photos"
        }
    }
    
    lazy var fetchedResultsController : NSFetchedResultsController<Photo> = { () -> NSFetchedResultsController<Photo> in
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Photo")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "url", ascending: true)]
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: stack.context, sectionNameKeyPath: nil, cacheName: nil) as! NSFetchedResultsController<Photo>
        
        fetchRequest.predicate = NSPredicate(format: "collection = %@", argumentArray: [album])

        fetchedResultsController.delegate = self
        
        return fetchedResultsController
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setFlowLayout()
        setMapDisplay(album)
        navigationController?.setToolbarHidden(false, animated: true)
        
        if fetchPhotos().isEmpty {
            downloadPhotos()
        }
    }

    @IBAction func bottomPressed(_ sender: Any) {
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
        collectionView.reloadData()
        print("bottom button task finished")
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
    
        var photos = [Photo]()
        
        let fc = fetchedResultsController
        do {
            try fc.performFetch()
            photos = fc.fetchedObjects!
        } catch let e as NSError {
            print("Error while trying to perform fetch: \n\(e)\n\(fetchedResultsController)")
        }
        return photos
    }
        
    
    func downloadPhotos() {
        FlickrClient.sharedInstance.getURLArray(latitude: album.latitude, longitude: album.longitude, page: page) { (success, results, errorString, randomPage) in
            if success {
                
                if let urlArray = results {
                    for photoURL in urlArray {
                        FlickrClient.sharedInstance.getImageData(URL(string: photoURL)!) { (data, error, errorSt) in
                            if let photoData = data {
                                let photo = Photo(url: photoURL, imageData: photoData, context: self.stack.context)
                                photo.collection = self.album
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
        var photo = fetchedResultsController.object(at: indexPath)

        if let photoData = photo.imageData {
            cell.photoView.image = UIImage(data: photoData as Data)
        } else {
            print("No image data found in photo object for cell")
            cell.photoView.image = UIImage(named: "placeholder")
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
                    self.fetchedResultsController.managedObjectContext.delete(photo)
                    self.stack.save()
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

extension AlbumVC : NSFetchedResultsControllerDelegate {
    // MARK: FetchedResultsController Delegate Methods
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) { }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        switch type {
        case .insert:
            blockOperations.append(
                BlockOperation(){ [weak self] in
                    if let this = self {
                        this.collectionView!.insertItems(at: [newIndexPath!])
                    }
                }
            )
        case .update:
            blockOperations.append(
                BlockOperation() { [weak self] in
                    if let this = self {
                        this.collectionView!.reloadItems(at: [indexPath!])
                    }
                }
            )
        case .delete:
            blockOperations.append(
                BlockOperation() { [weak self] in
                    if let this = self {
                        this.collectionView!.deleteItems(at: [indexPath!])
                    }
                }
            )
        case .move:
            blockOperations.append(
                BlockOperation() { [weak self] in
                    if let this = self {
                        this.collectionView!.moveItem(at: indexPath!, to: newIndexPath!)
                    }
                }
            )
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        
        // Source: https://gist.github.com/iwasrobbed/5528897
        let batchUpdatesToPerform = {() -> Void in
            for operation in self.blockOperations {
                operation.start()
            }
        }
        collectionView!.performBatchUpdates(batchUpdatesToPerform) { (finished) -> Void in
            self.blockOperations.removeAll(keepingCapacity: false)
        }
    }
}


