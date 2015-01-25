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
        
        let addressBook: ABAddressBookRef? = getRefAddressBook()
        
        if let addressBook: ABAddressBookRef = addressBook {
            
            let approval = getOkForAddressBook(addressBook)
            
            if approval {
                
                let person: ABAddressBookRef? = getPersonByNameFromAddressBook(addressBook, firstName: "Homeward")
                
                if let person: ABRecordRef = person {
                    
                    // use multivalue properties to get at street address, city, state, and zip or what ever is needed to pass to MapKit
                    
                    let contactName = ABRecordCopyValue(person,kABPersonFirstNameProperty).takeRetainedValue() as String
                    
                    println("The name of this contact is \(contactName)")
                    
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
        
        if ABAddressBookGetAuthorizationStatus() == .Authorized {
            
            result = true
            
        } else {
        
            ABAddressBookRequestAccessWithCompletion(addressBook) {
                (allowed: Bool, error: CFError!) in
                if allowed {
                    // success
                    println("User allowed access to addressbook")
                    result = true
                } else {
                    // fail
                    println("User did not allow access to addressbook")
                    result = false
                }
            }
        }
        
        return result
    }
    
    private func getPersonByNameFromAddressBook(addressBook: ABAddressBookRef?, firstName: String?) -> ABRecordRef? {
        
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
    
    private func displayErrorAlert(errorID: Int, tryAgain: Bool) {
        
    }
}
