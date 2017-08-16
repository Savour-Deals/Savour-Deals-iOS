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

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
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
