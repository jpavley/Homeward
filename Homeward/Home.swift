//
//  Home.swift
//  Homeward
//
//  Created by John Pavley (SSD) on 1/31/15.
//  Copyright (c) 2015 John F Pavley. All rights reserved.
//

import Foundation
import MapKit
import CoreLocation

class Home: NSObject, MKAnnotation {
    let title: String
    let subtitle: String
    let coordinate: CLLocationCoordinate2D
    
    init(title: String, subtitle: String, coordinate: CLLocationCoordinate2D) {
        self.title = title
        self.subtitle = subtitle
        self.coordinate = coordinate
    }
}
