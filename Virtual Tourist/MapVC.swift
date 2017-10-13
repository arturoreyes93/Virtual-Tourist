//
//  ViewController.swift
//  Virtual Tourist
//
//  Created by Arturo Reyes on 9/27/17.
//  Copyright © 2017 Arturo Reyes. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class MapVC: UIViewController, MKMapViewDelegate {
    
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var deleteLabel: UILabel!
    
    
    let stack = CoreDataStack.sharedInstance
    var fetchedResultsController : NSFetchedResultsController<Collection>!
    var isDeletingAlbums = false
    var editButtonTitle : String = "" {
        didSet {
            if isDeletingAlbums {
                editButtonTitle = "Done"
            } else {
                editButtonTitle = "Edit"
            }
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        guard let navigationBar = self.parent else {
            return
        }
        
        navigationBar.navigationItem.rightBarButtonItem = UIBarButtonItem(title: editButtonTitle, style: UIBarButtonItemStyle.plain, target: self, action: #selector(deleteAlbums))
        
        if !(fetchAlbums().isEmpty) {
            mapView.addAnnotations(populateMap())
        }
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(self.addAlbum(_:)))
        longPress.minimumPressDuration = 1.5
        mapView.addGestureRecognizer(longPress)

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        showDeleteLabel(isDeletingAlbums)
    }
    
    
    @objc func addAlbum(_ recognizer: UIGestureRecognizer) {
        
        let pressedAt = recognizer.location(in: self.mapView)
        let pressedAtCoordinate: CLLocationCoordinate2D = mapView.convert(pressedAt, toCoordinateFrom: mapView)
        
        let newPin = MKPointAnnotation()
        let lat = pressedAtCoordinate.latitude
        let lon = pressedAtCoordinate.longitude
        newPin.coordinate = pressedAtCoordinate
        _ = Collection(latitude: lat, longitude: lon)
        stack.save()
        mapView.addAnnotation(newPin)
        
    }
    
    func fetchAlbums() -> [Collection] {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Collection")
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: stack.context, sectionNameKeyPath: nil, cacheName: nil) as! NSFetchedResultsController<Collection>
        var albums = [Collection]()
        
        if let fc = fetchedResultsController {
            do {
                try fc.performFetch()
                albums = fc.fetchedObjects!
            } catch let e as NSError {
                print("Error while trying to perform fetch: \n\(e)\n\(fetchedResultsController)")
            }
        }
        
        return albums
    }
    
    func populateMap() -> [MKPointAnnotation] {
        var annotations = [MKPointAnnotation]()
        let albums = fetchAlbums()
        for album in albums {
            let lat = CLLocationDegrees(album.latitude)
            let lon = CLLocationDegrees(album.longitude)
            let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            
            annotations.append(annotation)
        }
        
        return annotations

    }
    
    @objc func deleteAlbums() {
        isDeletingAlbums = !isDeletingAlbums
        showDeleteLabel(isDeletingAlbums)
    }
    
    func showDeleteLabel(_ deleting : Bool) {
        if deleting {
            deleteLabel.backgroundColor = .red
            deleteLabel.text = "Tap Pins to Delete"
            deleteLabel.textColor = .white
            deleteLabel.font = UIFont(name: "Arial", size: 20)
            deleteLabel.textAlignment = NSTextAlignment.center
            deleteLabel.isEnabled = isDeletingAlbums
            deleteLabel.alpha = 1.0
            
            mapView.frame.origin = (deleteLabel.bounds.size.height) * (-1)
        } else {
            deleteLabel.text = ""
            deleteLabel.alpha = 0.0
            deleteLabel.isEnabled = !isDeletingAlbums
        }
    }
}
    
extension MKMapViewDelegate {
        
     func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = true
            pinView!.pinTintColor = .red
            pinView!.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        }
        else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }
    
}

