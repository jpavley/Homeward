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
    
    // outlets
    
    @IBOutlet weak var messageField: UITextField!
    @IBOutlet weak var messageButton: UIBarButtonItem!
    
    // constants for errors
    
    private let kErrorNotOkToAccessAddressBook = 2
    private let kErrorHomewardContactMissing   = 3
    
    enum HomewardErrorStates {
        case userRejectedAddressBook, homewardContactMissing, deniedAccessAddressBook, addressBookRestricted, unknownError
    }
    
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
        
        
    }
    
    override func viewDidAppear(animated: Bool) {
        
        println("viewDidAppear")

        // NOTE: viewDidAppear is called after the view is visible and will be called multiple times while the app is running and view is visible.  What the user sees at this point is the view.
        
        switch ABAddressBookGetAuthorizationStatus() {
            
        case .Authorized:
            
            println("App is authorized to access address book")
            doSomethingGood()
            
        case .Denied:
            
            println("App is denied access address book")
            displayErrorAlert(.deniedAccessAddressBook, tryAgain: false)
            
            
        case .NotDetermined:
            
            println("Need to ask user for permission to access address book")
            ABAddressBookRequestAccessWithCompletion(addressBook, {
                [weak self] (allowed: Bool, error: CFError!) in
                
                let strongSelf = self!
                if allowed {
                    println("user allowed app to access address book")
                    strongSelf.doSomethingGood()
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

    private func doSomethingGood() {
        
        let person: ABAddressBookRef? = getPersonByNameFromAddressBook(addressBook, firstName: "Homeward")
        
        if let person: ABRecordRef = person {
            
            // use multivalue properties to get at street address, city, state, and zip or what ever is needed to pass to MapKit
            let contactName = ABRecordCopyValue(person,kABPersonFirstNameProperty).takeRetainedValue() as String
            println("The name of this contact is \(contactName)")
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
}
