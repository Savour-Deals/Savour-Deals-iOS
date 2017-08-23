//
//  AccountViewController.swift
//  Savour
//
//  Created by Chris Patterson on 8/9/17.
//  Copyright © 2017 Chris Patterson. All rights reserved.
//

import UIKit
import Firebase


class AccountViewController: UIViewController {

    var handle: AuthStateDidChangeListenerHandle?
    var ref: DatabaseReference!

    
    @IBOutlet weak var welcomeLabel: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        let user = Auth.auth().currentUser
        //welcomeLabel.text = "Welcome " + (
    }
    
    override func viewWillAppear(_ animated: Bool) {
    }
    override func viewDidAppear(_ animated: Bool) {
        handle = Auth.auth().addStateDidChangeListener { (auth, user) in
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    
    @IBAction func LogoutPressed(_ sender: Any) {
        // [START signout]
        let firebaseAuth = Auth.auth()
       
            let user = Auth.auth().currentUser?.uid
            self.ref = Database.database().reference()
            
            var favs = Dictionary<String, String>()
            for member in favorites{
                favs[member.value.dealID!] = member.value.dealID
            }
            self.ref.child("Users").child(user!).child("Favorites").setValue(favs)

        favorites.removeAll()
        do {
            try firebaseAuth.signOut()
            self.performSegue(withIdentifier: "OnboardingSegue", sender: self)
        } catch let signOutError as NSError {
            print ("Error signing out: %@", signOutError)
        }
        // [END signout]
    }

}
