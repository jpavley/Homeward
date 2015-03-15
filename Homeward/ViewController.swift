//
//  ViewController.swift
//  Homeward
//
//  Created by John Pavley (SSD) on 1/24/15.
//  Copyright (c) 2015 John F Pavley. All rights reserved.
//

import UIKit
import AddressBook
import CoreLocation
import MapKit

class ViewController: UIViewController, CLLocationManagerDelegate {
    
    // MARK: - outlets
    
    @IBOutlet weak var messageButton: UIBarButtonItem!
    @IBOutlet weak var mapView:MKMapView!
    
    //  MARK: - constants
        
    enum HomewardErrorStates {
        case userRejectedAddressBook, homewardContactMissing, deniedAccessAddressBook, addressBookRestricted, addressFieldsMisssing, locationManagerError, unknownError
    }
    
    //  MARK: - properties
    
    private let locationManager = CLLocationManager()
    private var homePoint:CLLocationCoordinate2D?
    private var currentPoint:CLLocationCoordinate2D?
    private var distanceToHome:CLLocationDistance = 0
    private var homeAddress:String = ""
    
    //  MARK: - lazy properties
    
    // get the address book ref when needed
    
    private lazy var addressBook: ABAddressBookRef = {
        println("got address book ref")
        var error: Unmanaged<CFError>?
        return ABAddressBookCreateWithOptions(nil,
            &error).takeRetainedValue() as ABAddressBookRef
        }()
    
    //  MARK: - state vars
    
    var addressBookAccessOK = false
    
    //  MARK: - UIView Controller overrides
    
    override func viewDidLoad() {
        
        println("viewDidLoad")
        
        super.viewDidLoad()
        
        // config the location manager
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        
    }
    
    override func viewDidAppear(animated: Bool) {
        
        println("viewDidAppear")

        // NOTE: viewDidAppear is called after the view is visible and will be called multiple times while the app is running and view is visible.  What the user sees at this point is the view.
        
        switch ABAddressBookGetAuthorizationStatus() {
            
        case .Authorized:
            
            println("App is authorized to access address book")
            accessAddressBook()
            
        case .Denied:
            
            println("App is denied access address book")
            displayErrorAlert(.deniedAccessAddressBook, tryAgain: false)
            
            
        case .NotDetermined:
            
            println("Need to ask user for permission to access address book")
            ABAddressBookRequestAccessWithCompletion(addressBook, {
                [weak self] (allowed: Bool, error: CFError!) in
                
                // TODO: Why weak self and strong self?
                let strongSelf = self!
                
                if allowed {
                    println("user allowed app to access address book")
                    strongSelf.accessAddressBook()
                } else {
                    println("user did not allow to access address book")
                    strongSelf.displayErrorAlert(.userRejectedAddressBook, tryAgain: false)
                }
            })
            
        case .Restricted:
            
            println("Address book is restricted")
            displayErrorAlert(.addressBookRestricted, tryAgain: false)

        default:
            
            println("Unknown address book auth status")
            displayErrorAlert(.unknownError, tryAgain: false)
       }
    }
        
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //  MARK: - CLLocationManagerDelegate implementation
    
    func locationManager(manager: CLLocationManager!,
        didChangeAuthorizationStatus status: CLAuthorizationStatus) {
            println("Authorization status changed to \(status.rawValue)")
            switch status {
            case .AuthorizedWhenInUse:
                locationManager.startUpdatingLocation()
                mapView.showsUserLocation = true
                
            default:
                locationManager.stopUpdatingLocation()
                mapView.showsUserLocation = false
            }
    }

    
    func locationManager(manager: CLLocationManager!,
        didFailWithError error: NSError!) {
            self.displayErrorAlert(.locationManagerError, tryAgain: true)
    }
    
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
        let newLocation = (locations as [CLLocation])[locations.count - 1]
        
        if newLocation.horizontalAccuracy < 0 {
            // invalid accuracy
            return
        }
        
        if newLocation.horizontalAccuracy > 100 ||
            newLocation.verticalAccuracy > 50 {
                // accuracy radius is so large, we don't want to use it
                return
        }
        
        if let homePointValue = homePoint {
            
            let current = Home(title:"You Are Here", subtitle:"(Currently)", coordinate: newLocation.coordinate)
            mapView.addAnnotation(current)
            
            let homeLocation = CLLocation(latitude: homePointValue.latitude, longitude: homePointValue.longitude)
            distanceToHome = newLocation.distanceFromLocation(homeLocation)
            let distanceToHomeInFeet = distanceToHome * 3.28084
            let distanceToHomeInMiles = distanceToHomeInFeet * 0.000189394
            messageButton.title = String("\(distanceToHomeInMiles) miles to home")
       }
        
    }
    

    //  MARK: - Homeward implementation

    private func accessAddressBook() {
        
        let person: ABAddressBookRef? = getPersonByNameFromAddressBook(addressBook, firstName: "Homeward")
        
        if let person: ABRecordRef = person {
            
            // use multivalue properties to get at street address, city, state, and zip or what ever is needed to pass to MapKit
            let addressList: ABMultiValueRef? = ABRecordCopyValue(person, kABPersonAddressProperty)?.takeRetainedValue()
            
            // assume first address in the addressList is the one we want
            let primaryAddressIndex = 0
            
            // from the list of address we get a Dictionary which represents the address and its fields
            let addressDict = ABMultiValueCopyValueAtIndex(addressList, primaryAddressIndex)?.takeRetainedValue() as NSDictionary
            
            // All the "as String" enable type conversion from CFString to NSString
            let street = addressDict[kABPersonAddressStreetKey as String] as String
            let city = addressDict[kABPersonAddressCityKey as String] as String
            let state = addressDict[kABPersonAddressStateKey as String] as String
            let zip = addressDict[kABPersonAddressZIPKey as String] as String
          
            println("Street: \(street)")
            println("Street: \(city)")
            println("Street: \(state)")
            println("Street: \(zip)")
            
            // Check if any of these address fields are missing and warn the user!
            
            let fieldsArry = [street, city, state, zip]
            
            if fieldsMissing(fieldsArry) {
                
                self.displayErrorAlert(.addressFieldsMisssing, tryAgain: true)
                
            } else {
                
                // Send this address to MapKit!
                
                showHomeonMap(fieldsArry)
               
            }
            
        } else {
            self.displayErrorAlert(.homewardContactMissing, tryAgain: true)
        }
    }
        
    private func getPersonByNameFromAddressBook(addressBook: ABAddressBookRef?, firstName: String?) -> ABRecordRef? {
        
        println("getPersonByNameFromAddressBook")

        var result: ABRecordRef? = nil
        
        let people = ABAddressBookCopyPeopleWithName(addressBook, firstName! as NSString as CFStringRef).takeRetainedValue() as NSArray
        
        if people.count > 0 {
            // success
            println("Homeward contact found!")
            result = people.firstObject! as AnyObject
        } else {
            // fail
            println("Homeward contact not found")
        }
        return result
    }
    
    private func displayErrorAlert(errorID: HomewardErrorStates, tryAgain: Bool) {
        
        println("displayErrorAlert")

        var errorMessage = "Unknown"
        var buttonTitle = "Dismiss"
        var handler: UIAlertAction? = nil
        
        switch errorID {
                        
        case .userRejectedAddressBook:
            
            errorMessage = "User did not allow app to access address book."
            
        case .homewardContactMissing:
            
            errorMessage = "Homeward contact missing from address book"
            
        case .deniedAccessAddressBook:
            
            errorMessage = "Homeward denied access to address book"
            
        case .addressBookRestricted:
            
            errorMessage = "Address book is restricted"
        
        case .addressFieldsMisssing:
            
            errorMessage = "Contact must contain street, city, state, and zip fields"
            
        case .locationManagerError:
            
            errorMessage = "Unable to get current location"
            
        case .unknownError:
            
            errorMessage = "Unknown error, very mysterious"
            
        default:
            
            println("Missing error, very mysterious")
            
        }
        
        if tryAgain {
            buttonTitle = "Try Again"
            
            // will need to put handler here
        }
        
        let alert = UIAlertController(title: title, message: errorMessage, preferredStyle: .Alert)
        let action = UIAlertAction(title: buttonTitle, style: .Default, handler: nil)
        
        alert.addAction(action)
        presentViewController(alert, animated: true, completion: nil)
        
    }
    
    private func fieldsMissing(fields: [String]) -> Bool {
        
        // returns true if a field is missing

        var filteredArray = fields.filter({countElements($0) > 0})
        
        // the function passed to filter counts the number of characters in each fields of the array. If any field doesn't have 1 or more characters that field is left out the filtered array
        
        return !(filteredArray.count == fields.count)
    }
    
    private func showHomeonMap(fields:[String]) {
        
        homeAddress = ", ".join(fields)
        
        CLGeocoder().geocodeAddressString(homeAddress, completionHandler: {
            (placemarks, error) in
            
            if (error != nil) {
                println("forward geocode fail: \(error).localizedDescription)")
                self.displayErrorAlert(.unknownError, tryAgain: true)
            }
            
            self.homePoint = placemarks[0].location?.coordinate
            var span = MKCoordinateSpanMake(0.0625, 0.0625)
            var region = MKCoordinateRegion(center: self.homePoint!, span: span)
            
            //self.mapView.setRegion(region, animated: true)
            
            var annotation = MKPointAnnotation()
            annotation.setCoordinate(self.homePoint!)
            annotation.title = "Home"
            annotation.subtitle = self.homeAddress
            
            self.mapView.addAnnotation(annotation)
            
        })
        
        
    }
    
    
}
