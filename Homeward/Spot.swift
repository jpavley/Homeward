//
//  Spot.swift
//  Homeward
//
//  Created by John Pavley (SSD) on 1/31/15.
//  Copyright (c) 2015 John F Pavley. All rights reserved.
//

// A spot is an annotated location on a map as in "x marks the spot"

import Foundation
import MapKit
import CoreLocation

class Spot: NSObject, MKAnnotation {
    let title: String
    let subtitle: String
    let coordinate: CLLocationCoordinate2D
    
    init(title: String, subtitle: String, coordinate: CLLocationCoordinate2D) {
        self.title = title
        self.subtitle = subtitle
        self.coordinate = coordinate
    }
}
