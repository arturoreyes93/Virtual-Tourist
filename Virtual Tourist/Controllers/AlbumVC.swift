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
    let stack = CoreDataStack.sharedInstance
    var page : Int = 1
    let perPage: Int = 20
    let pageLimit = 200
    var blockOperations: [BlockOperation] = []
    var deletePhotos: [IndexPath] = [] {
        didSet {
            bottomButton.title = deletePhotos.isEmpty ? "New Collection" : "Delete Selected Photos"
        }
    }

    
    lazy var fetchedResultsController : NSFetchedResultsController<Photo> = { () -> NSFetchedResultsController<Photo> in
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Photo")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "url", ascending: true)]
        fetchRequest.predicate = NSPredicate(format: "collection = %@", argumentArray: [album])
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: stack.context, sectionNameKeyPath: nil, cacheName: nil) as! NSFetchedResultsController<Photo>
        
        fetchedResultsController.delegate = self
        
        return fetchedResultsController
    }()
    
    

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setFlowLayout()
        setMapDisplay(album)
        navigationController?.setToolbarHidden(false, animated: true)
        
        let id = album.objectID
        if fetchPhotos().isEmpty {
            downloadPhotos()
            
            print("photos of \(id) downloaded for the first time")
        }
        
        print("album loaded: \(id)")
    }

    @IBAction func bottomPressed(_ sender: Any) {
        if deletePhotos.isEmpty {
            for photo in fetchedResultsController.fetchedObjects! {
                fetchedResultsController.managedObjectContext.delete(photo)
            }
            stack.save()
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
        let dimension = (self.view.frame.size.width - (2 * space)) / 3
        
        flowLayout.minimumLineSpacing = space
        flowLayout.minimumInteritemSpacing = space
        flowLayout.itemSize = CGSize(width: dimension, height: dimension)
    }
    
    func setMapDisplay(_ annotation: MKAnnotation) {
        let center = annotation.coordinate
        let span = MKCoordinateSpanMake(0.12, 0.12)
        let region = MKCoordinateRegion(center: center, span: span)
        mapDisplayView.region = region
        mapDisplayView.addAnnotation(annotation)
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
        let id = album.objectID
        print("photos of \(id) fetched")
        return photos
    }
        
    
    func downloadPhotos() {
        FlickrClient.sharedInstance.getURLArray(latitude: album.latitude, longitude: album.longitude, page: page, perPage: perPage) { (success, results, errorString) in
            if success {
                if let urlArray = results {
                    for photoURL in urlArray {
                        FlickrClient.sharedInstance.getImageData(URL(string: photoURL)!) { (data, error, errorSt) in
                            if let photoData = data {
                                self.stack.context.performAndWait {
                                    let photo = Photo(url: photoURL, imageData: photoData, context: self.stack.context)
                                    photo.collection = self.album
                                }
                            } else {
                                print(errorSt!)
                            }
                        }
                    }
                    self.stack.save()
                } else {
                    print("Could not find URLs in results")
                }
                //pick a random page!
                self.page = Int(arc4random_uniform(UInt32(self.pageLimit))) + 1
                print("new page: \(self.page)")
            } else {
                print(errorString!)
            }
        }
    }
}

extension AlbumVC : UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCell", for: indexPath) as! PhotoCell
        cell.photoView.image = UIImage(named: "placeholder")
        cell.activityIndicator.isHidden = false
        cell.activityIndicator.startAnimating()
        
        let photo = fetchedResultsController.object(at: indexPath)
        if let photoData = photo.imageData {
            cell.photoView.image = UIImage(data: photoData as Data)
            cell.activityIndicator.stopAnimating()
            cell.activityIndicator.isHidden = true
        } else {
            print("No image data found in photo object for cell")
            let url = photo.url
            FlickrClient.sharedInstance.getImageData(URL(string: url!)!) { (data, error, errorSt) in
                if let photoData = data {
                    cell.activityIndicator.stopAnimating()
                    cell.activityIndicator.isHidden = true
                    cell.photoView.image = UIImage(data: photoData as Data)
                    self.stack.save()
                } else {
                    print(errorSt!)
                }
            }
        }
        
        setAlpha(cell, indexPath)
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
        setAlpha(cell, indexPath)
    }
    
    func setAlpha(_ cell: PhotoCell, _ index: IndexPath) {
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
    
    // Source: https://github.com/AshFurrow/UICollectionView-NSFetchedResultsController/issues/13
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        switch type {
        case .insert:
            blockOperations.append(
                BlockOperation(){ [weak self] in
                    if let block = self {
                        block.collectionView!.insertItems(at: [newIndexPath!])
                    }
                }
            )
        case .delete:
            blockOperations.append(
                BlockOperation() { [weak self] in
                    if let block = self {
                        block.collectionView!.deleteItems(at: [indexPath!])
                    }
                }
            )
        case .update:
            blockOperations.append(
                BlockOperation() { [weak self] in
                    if let block = self {
                        block.collectionView!.reloadItems(at: [indexPath!])
                    }
                }
            )
        case .move:
            blockOperations.append(
                BlockOperation() { [weak self] in
                    if let block = self {
                        block.collectionView!.moveItem(at: indexPath!, to: newIndexPath!)
                    }
                }
            )
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        
        let batchUpdates = {() -> Void in
            for operation in self.blockOperations {
                operation.start()
            }
        }
        collectionView!.performBatchUpdates(batchUpdates) { (finished) -> Void in
            self.blockOperations.removeAll()
        }
    }
    
}


