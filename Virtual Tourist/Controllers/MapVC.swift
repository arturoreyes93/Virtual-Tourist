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

class MapVC: UIViewController {
    
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var deleteLabel: UILabel!
    
    let stack = CoreDataStack.sharedInstance
    var isDeletingAlbums = false
    var mapRegion : MapViewPersistence!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        if !(fetchAlbums().isEmpty) {
            mapView.addAnnotations(fetchAlbums())
        }
        
        navigationItem.title = "Virtual Tourist"
        
        mapRegion = MapViewPersistence(mapView)
        if let storedRegion = mapRegion.getLastRegion() {
            self.mapView.region = storedRegion
        }

        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(self.addAlbum(_:)))
        longPress.minimumPressDuration = 1.5
        mapView.addGestureRecognizer(longPress)

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setToolbarHidden(true, animated: true)
        showDeleteLabel(isDeletingAlbums)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "albumSegue" {
            let album = sender as! Collection
            let destination = segue.destination as! AlbumVC
            destination.album = album
        }
    }

    @IBAction func editButtonPressed(_ sender: UIBarButtonItem) {
        isDeletingAlbums = !isDeletingAlbums
        if isDeletingAlbums {
            sender.title = "Done"
        } else {
            sender.title = "Edit"
        }
        showDeleteLabel(isDeletingAlbums)
    }
    
    
    @objc func addAlbum(_ recognizer: UIGestureRecognizer) {
        
        let pressedAt = recognizer.location(in: self.mapView)
        let pressedAtCoordinate: CLLocationCoordinate2D = mapView.convert(pressedAt, toCoordinateFrom: mapView)
        
        let lat = pressedAtCoordinate.latitude
        let lon = pressedAtCoordinate.longitude
        let album = Collection(latitude: lat, longitude: lon, context: self.stack.context)
        print("album: \(album) added")
        stack.save()
        mapView.addAnnotation(album)
        
    }
    
    func fetchAlbums() -> [Collection] {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Collection")
        var albums = [Collection]()
        
        do {
            let fetchedObjects = try stack.context.fetch(fetchRequest)
            albums = fetchedObjects as! [Collection]
        } catch let e as NSError {
            print("Error while trying to perform fetch: \n\(e)\n Albums")
        }
        
        return albums
    }
    
    func showDeleteLabel(_ isDeleting: Bool) {
        if isDeleting {
            let guide = view.safeAreaLayoutGuide
            //self.mapView.bottomAnchor.constraint(equalTo: self.deleteLabel.topAnchor)
            //self.view.safeAreaLayoutGuide.layoutFrame.origin = self.deleteLabel.bounds.size.height * (-1)
            //self.mapView.frame.origin.y = self.deleteLabel.bounds.size.height * (-1)
            //self.view.safeAreaInsets.bottom = self.deleteLabel.bounds.size.height * (-1)
            UIView.animate(withDuration: 0.25, animations: {
                self.deleteLabel.backgroundColor = .red
                self.deleteLabel.text = "Tap Pins to Delete"
                self.deleteLabel.textColor = .white
                self.deleteLabel.font = UIFont(name: "Arial", size: 18)
                self.deleteLabel.textAlignment = NSTextAlignment.center
                self.deleteLabel.isEnabled = self.isDeletingAlbums
                self.deleteLabel.alpha = 1.0
            })
        } else {
            self.mapView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
            UIView.animate(withDuration: 0.25, animations: {
                self.deleteLabel.text = ""
                self.deleteLabel.alpha = 0.0
            })
        }
    }
}
    
extension MapVC: MKMapViewDelegate {
        
     func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.animatesDrop = true
            
        }
        else {
            pinView!.annotation = annotation
            pinView!.animatesDrop = true
        }
        
        return pinView
    }

    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
        print("pin pressed")
        
        let album = view.annotation as! Collection
        if isDeletingAlbums {
            mapView.removeAnnotation(album)
            stack.context.delete(album)
            stack.save()
        } else {
            mapView.deselectAnnotation(album, animated: false)
            performSegue(withIdentifier: "albumSegue", sender: album)
        }
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        mapRegion.storeRegion()
    }
    
}

