//
//  ViewController.swift
//  Homeward
//
//  Created by John Pavley (SSD) on 1/24/15.
//  Copyright (c) 2015 John F Pavley. All rights reserved.
//

import UIKit
import AddressBook

class ViewController: UIViewController {
    
    private let kErrorCantCreateAddressBookRef = 1
    private let kErrorNotOkToAccessAddressBook = 2
    private let kErrorHomewardContactMissing   = 3
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        //accessContacts()
        
        let addressBook: ABAddressBookRef? = getRefAddressBook()
        
        if let addressBook: ABAddressBookRef = addressBook {
            
            let approval = getOkForAddressBook(addressBook)
            
            if approval {
                
                let person: ABAddressBookRef? = getPersonByNameFromAddressBook(addressBook, firstName: "Homeward")
                
                if let person: ABRecordRef = person {
                    
                    // use multivalue properties to get at street address, city, state, and zip or what ever is needed to pass to MapKit
                    
                    
                } else {
    
                    displayErrorAlert(kErrorNotOkToAccessAddressBook, tryAgain: true)
                }
                
            } else {
                
                displayErrorAlert(kErrorHomewardContactMissing, tryAgain: false)
            }
            
        } else {
            
            displayErrorAlert(kErrorCantCreateAddressBookRef, tryAgain: false)
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func getRefAddressBook() -> ABAddressBookRef? {
        
        var error:Unmanaged<CFErrorRef>? = nil
        
        var addressBook: ABAddressBookRef? = ABAddressBookCreateWithOptions(nil, &error)?.takeRetainedValue()
        
        if let addressBook: ABAddressBookRef = addressBook {
            // success
            println("Addressbook ref created!")
        } else {
            // fail
            println("Addressbook ref not created")
        }

        return addressBook
    }
    
    private func getOkForAddressBook(addressBook: ABAddressBookRef?) -> Bool {
        
        var result: Bool = false
        
        ABAddressBookRequestAccessWithCompletion(addressBook) {
            (allowed: Bool, error: CFError!) in
            if allowed {
                // success
                println("User allowed access to addressbook")
            } else {
                // fail
                println("User did not allow access to addressbook")
            }
            result = allowed
        }
        
        return result
    }
    
    private func getPersonByNameFromAddressBook(addressBook: ABAddressBookRef?, firstName: String?) -> ABRecordRef? {
        
        let people = ABAddressBookCopyPeopleWithName(addressBook, firstName! as NSString as CFStringRef).takeRetainedValue() as NSArray
        
        if people.count > 0 {
            // success
            println("Homeward contact found!")
        } else {
            // fail
            println("Homeward contact not found")
        }
        return people.firstObject as [ABRecordRef]
    }
    
    private func displayErrorAlert(errorID: Int, tryAgain: Bool) {
        
    }

    private func accessContacts() {
        
        // create reference to the address book
        
        var error:Unmanaged<CFErrorRef>? = nil
        
        var addressBook: ABAddressBookRef? = ABAddressBookCreateWithOptions(nil, &error)?.takeRetainedValue()
        
        if let addressBook: ABAddressBookRef = addressBook {
            // success
            println("Addressbook ref created!")
        } else {
            // fail
            let e = error!.takeUnretainedValue() as AnyObject as NSError
            println("Addressbook ref creation error: \(e)")
            // in the real world need to tell the user to try again later!
            // need try again button and to stop here
        }
        
        // ask the user if it's ok to use the address book
        // (only have to do this once)
        
        ABAddressBookRequestAccessWithCompletion(addressBook) {
            (success, error) in
            if success {
                // success
                println("User allowed access to addressbook")
            } else {
                // fail
                println("User did not allow access to addressbook")
                // in the realworld need to tell the user the app is not usable with access to the address book!
                // need a try again button and to stop here!
            }
        }
        
        // get the Homeward person in the address book
        var firstName = "Homeward"
        let people = ABAddressBookCopyPeopleWithName(addressBook, firstName as NSString as CFStringRef).takeRetainedValue() as NSArray
        
        if people.count > 0 {
            // success
            println("Homeward contact found!")
        } else {
            // fail
            println("Homeward contact not found")
        }
        
        
    }

}

