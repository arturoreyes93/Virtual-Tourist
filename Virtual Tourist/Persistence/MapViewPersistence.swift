//
//  MapVCPersistence.swift
//  Virtual Tourist
//
//  Created by Arturo Reyes on 10/25/17.
//  Copyright © 2017 Arturo Reyes. All rights reserved.
//

import Foundation
import MapKit

class MapViewPersistence : NSObject {

    var mapView : MKMapView
    
    func storeRegion() {
        let region = mapView.region
        let lat = region.center.latitude
        let lon = region.center.longitude
        let latSpan = region.span.latitudeDelta
        let lonSpan = region.span.longitudeDelta
        
        UserDefaults.standard.set(lat, forKey: "latitude")
        UserDefaults.standard.set(lon, forKey: "longitude")
        UserDefaults.standard.set(latSpan, forKey: "latSpan")
        UserDefaults.standard.set(lonSpan, forKey: "lonSpan")
        UserDefaults.standard.synchronize()
    }
    
    func getLastRegion() -> MKCoordinateRegion? {
        if let lat = UserDefaults.standard.value(forKey: "latitude") as? CLLocationDegrees, let lon = UserDefaults.standard.value(forKey: "longitude"), let latSpan = UserDefaults.standard.value(forKey: "latSpan"), let lonSpan = UserDefaults.standard.value(forKey: "lonSpan") {
            let coordinate = CLLocationCoordinate2D(latitude: lat,longitude: lon as! CLLocationDegrees)
            let span = MKCoordinateSpanMake(latSpan as! CLLocationDegrees, lonSpan as! CLLocationDegrees)
            let region = MKCoordinateRegion(center: coordinate, span: span)
            return region
            
        } else {
            print("Unable to unwrap stored region or it does not exist")
            return nil
        }
    }
    
    init(_ mapView: MKMapView) {
        self.mapView = mapView
    }
}
