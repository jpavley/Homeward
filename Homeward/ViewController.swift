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
    
    // constants for errors
    
    private let kErrorNotOkToAccessAddressBook = 2
    private let kErrorHomewardContactMissing   = 3
    
    // get the address book ref when needed
    
    private lazy var addressBook: ABAddressBookRef = {
        println("got address book ref")
        var error: Unmanaged<CFError>?
        return ABAddressBookCreateWithOptions(nil,
            &error).takeRetainedValue() as ABAddressBookRef
        }()
    
    // state vars
    
    var addressBookAccessOK = false
    
    override func viewDidLoad() {
        
        println("viewDidLoad")
        
        // NOTE: viewDidLoad is usally called once, when the view controller is loaded into memory and the view is not yet visible. The view itself is not usable at this point. What the user sees at this point is the launch screen.
        
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        addressBookAccessOK = getOkForAddressBook(addressBook)
        
    }
    
    override func viewDidAppear(animated: Bool) {
        
        println("viewDidAppear")

        // NOTE: viewDidAppear is called after the view is visible and will be called multiple times while the app is running and view is visible.  What the user sees at this point is the view.
        
        // QUESTION: This code makes sure the address book exists, the user is allowing the app to access it, the contact "Homeward" exists, and then kicks off the actuall work of the app. Not all of this code needs be run more than once... or does it? What if the user deletes the contact app? Changes their mind about access? Updates their home address?
        

        if !addressBookAccessOK {
            
            println("addressBookAccessOK = \(addressBookAccessOK)")
            
            displayErrorAlert(kErrorNotOkToAccessAddressBook, tryAgain: false)
            
        } else {
            let person: ABAddressBookRef? = getPersonByNameFromAddressBook(addressBook, firstName: "Homeward")
            
            if let person: ABRecordRef = person {
                
                // use multivalue properties to get at street address, city, state, and zip or what ever is needed to pass to MapKit
                
                let contactName = ABRecordCopyValue(person,kABPersonFirstNameProperty).takeRetainedValue() as String
                
                println("The name of this contact is \(contactName)")
                
            } else {
                
                displayErrorAlert(kErrorHomewardContactMissing, tryAgain: true)
            }
            
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func getOkForAddressBook(addressBook: ABAddressBookRef?) -> Bool {
        
        println("getOkForAddressBook")

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
        
        // need to refactor into swtich statement: There are more than 2 cases here!
        
        return result
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
    
    private func displayErrorAlert(errorID: Int, tryAgain: Bool) {
        
        println("displayErrorAlert")

        var errorMessage = "I have no idea what the heck is going on!"
        var buttonTitle = "Dismiss"
        var handler: UIAlertAction? = nil
        
        switch errorID {
                        
        case kErrorNotOkToAccessAddressBook:
            
            errorMessage = "If you don't let me access your address book I don't do anything!"
            
        case kErrorHomewardContactMissing:
            
            errorMessage = "You need to create a contact with the first name Homeward and your address!"
            
        default:
            
            println("Hey coder! You are missing an error code!")
            
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
}
