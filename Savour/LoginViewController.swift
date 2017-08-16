//
//  ViewController.swift
//  Savour
//
//  Created by Chris Patterson on 7/30/17.
//  Copyright © 2017 Chris Patterson. All rights reserved.
//

import UIKit
import Firebase
import FBSDKCoreKit
import FBSDKLoginKit

class LoginViewController: UIViewController, FBSDKLoginButtonDelegate {
    /**
     Sent to the delegate when the button was used to logout.
     - Parameter loginButton: The button that was clicked.
     */


    var handle: AuthStateDidChangeListenerHandle?

    @IBOutlet weak var Const: UIView!
    @IBOutlet weak var LoginEmail: UITextField!
    @IBOutlet weak var LoginPassword: UITextField!
    @IBOutlet weak var LoginButton: UIButton!
    @IBOutlet weak var SignUpButton: UIButton!
    @IBOutlet weak var FBLoginButton: FBSDKLoginButton!
    @IBOutlet weak var loginIndicator: UIActivityIndicatorView!
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if Auth.auth().currentUser != nil {
            // User is signed in.
            self.performSegue(withIdentifier: "Main", sender: self)
        }
        else {
            // No user is signed in.
            setUpUI()
            FBSDKLoginManager().logOut()
            FBLoginButton.delegate = self
        }
       
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController!.setNavigationBarHidden(true, animated: true)

        // [START auth_listener]
        handle = Auth.auth().addStateDidChangeListener { (auth, user) in
            // [START_EXCLUDE]
            // [END_EXCLUDE]
        }
        // [END auth_listener]

    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // [START remove_auth_listener]
        Auth.auth().removeStateDidChangeListener(handle!)
        // [END remove_auth_listener]
    }

        
    func setUpUI(){
        LoginButton.layer.cornerRadius = 5
        SignUpButton.layer.cornerRadius = 5
    }
   

    @IBAction func LoginButtonPressed(_ sender: Any) {
        loginIndicator.startAnimating()
        if let email = self.LoginEmail.text, let password = self.LoginPassword.text {
                // [START headless_email_auth]
                Auth.auth().signIn(withEmail: email, password: password) { (user, error) in
                    // [START_EXCLUDE]
                    if let error = error {
                        let alert = UIAlertController(title: "Alert", message: error.localizedDescription, preferredStyle: UIAlertControllerStyle.alert)
                        alert.addAction(UIAlertAction(title: "Okay", style: UIAlertActionStyle.default, handler: nil))
                        self.present(alert, animated: true, completion: nil)
                        return
                    }
                    self.performSegue(withIdentifier: "MainS", sender: self)

                }
            // [END_EXCLUDE]
            }
                // [END headless_email_auth]
        else {
            loginIndicator.stopAnimating()

            let alert = UIAlertController(title: "Alert", message: "email/password can't be empty", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "Okay", style: UIAlertActionStyle.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
        self.loginIndicator.stopAnimating()
    }

 
    func loginButtonDidLogOut(_ loginButton: FBSDKLoginButton!) {
        print("Did log out of facebook")
    }
    
    func loginButton(_ loginButton: FBSDKLoginButton!, didCompleteWith result: FBSDKLoginManagerLoginResult!, error: Error!) {
        loginIndicator.startAnimating()

        if error != nil {
            print(error)
            return
        }
        if result.isCancelled {
            return
        }
        print("Successfully logged in with facebook...")
        let credential = FacebookAuthProvider.credential(withAccessToken: FBSDKAccessToken.current().tokenString)
        Auth.auth().signIn(with: credential) { (user, error) in
            if error != nil {
                print(error.debugDescription)
                return
            }
            // User is signed in
            self.performSegue(withIdentifier: "MainS", sender: self)
            self.loginIndicator.stopAnimating()


        }
    }
}


