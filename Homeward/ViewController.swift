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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        accessContacts()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    private func accessContacts() {
        
        // create reference to the addressbook
        
        var error:Unmanaged<CFErrorRef>? = nil
        
        var addressBook: ABAddressBookRef? = ABAddressBookCreateWithOptions(nil, &error)?.takeRetainedValue()
        
        if let addressBook: ABAddressBookRef = addressBook {
            // ref succeeded
            println("Addressbook ref created!")
        } else {
            // ref failed
            let e = error!.takeUnretainedValue() as AnyObject as NSError
            println("Addressbook ref creation error: \(e)")
            // in the real world need to tell the user to try again later!
        }
        
        // ask the user if it's ok to use the address book
        // (only have to do this once)
        
        ABAddressBookRequestAccessWithCompletion(addressBook) {
            (success, error) in
            if success {
                println("User allowed access to addressbook")
            } else {
                let e = error as AnyObject as NSError
                println("User did not allow access to addressbookL \(e)")
                // in the realworld need to tell the user the app is not usable with access to the addressbook!
            }
        }
        
    }

}

