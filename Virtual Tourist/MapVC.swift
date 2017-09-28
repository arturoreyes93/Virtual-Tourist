//
//  ViewController.swift
//  Virtual Tourist
//
//  Created by Arturo Reyes on 9/27/17.
//  Copyright © 2017 Arturo Reyes. All rights reserved.
//

import UIKit
import MapKit

class MapVC: UIViewController, MKMapViewDelegate {
    
    
    @IBOutlet weak var mapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(self.addPin(_:)))
        longPress.minimumPressDuration = 1.5
        mapView.addGestureRecognizer(longPress)
    }
    
    
    @objc func addPin(_ recognizer: UIGestureRecognizer) {
        
        let pressedAt = recognizer.location(in: self.mapView)
        let pressedAtCoordinate: CLLocationCoordinate2D = mapView.convert(pressedAt, toCoordinateFrom: mapView)
        
        let newPin = MKPointAnnotation()
        newPin.coordinate = pressedAtCoordinate
        mapView.addAnnotation(newPin)
        
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

