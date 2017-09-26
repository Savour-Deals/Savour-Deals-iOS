//
//  VendorHomeViewController.swift
//  Savour
//
//  Created by Chris Patterson on 9/26/17.
//  Copyright © 2017 Chris Patterson. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase

class VendorHomeViewController: UIViewController {

    var handle: AuthStateDidChangeListenerHandle?
    var ref: DatabaseReference!
    var id: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    func setupUI(){
        id = Auth.auth().currentUser?.uid
        ref = Database.database().reference()
        ref.child("Restaurants").child(id!).observeSingleEvent(of: .value, with: { (snapshot) in
            let value = snapshot.value as? NSDictionary
            self.navigationItem.title = value?["Name"] as? String ?? ""
        })
    }

    @IBAction func LogoutPressed(_ sender: Any) {
        // [START signout]
        let firebaseAuth = Auth.auth()
        do {
            try firebaseAuth.signOut()
            self.performSegue(withIdentifier: "OnboardingSegue", sender: self)
        } catch let signOutError as NSError {
            print ("Error signing out: %@", signOutError)
        }
        // [END signout]
    }
    
    

   

}
