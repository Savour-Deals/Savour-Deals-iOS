//
//  SignUpViewController.swift
//  Savour
//
//  Created by Chris Patterson on 8/1/17.
//  Copyright © 2017 Chris Patterson. All rights reserved.
//

import UIKit
import Firebase


class SignUpViewController: UIViewController {

    @IBOutlet weak var NameField: UITextField!
    @IBOutlet weak var EmailField: UITextField!
    @IBOutlet weak var SignupButton: UIButton!
    @IBOutlet weak var PasswordField: UITextField!
    
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    @IBOutlet weak var loadingView: UIView!
    
    @IBOutlet weak var loadingLabel: UIView!
    var handle: AuthStateDidChangeListenerHandle?
    var ref: DatabaseReference!
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        SignupButton.addTarget(self, action: #selector(SignupPressed), for: .touchUpInside)
        SignupButton.layer.cornerRadius = 5
    }
    func isLoading(){
        loadingIndicator.startAnimating()
        loadingView.isHidden = false
        loadingLabel.isHidden = false
        SignupButton.isEnabled = false
    }
    
    func doneLoading(){
    
        loadingIndicator.stopAnimating()
        loadingView.isHidden = true
        loadingLabel.isHidden = true
        SignupButton.isEnabled = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController!.setNavigationBarHidden(false, animated: false)

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

 

    
    func SignupPressed(_ sender: Any) {
        isLoading()
        if let password = PasswordField.text, let email = EmailField.text, let name = NameField.text {//let username = UsernameField.text {
            // [START create_user]
            //let userDict = ["Username": username]
            Auth.auth().createUser(withEmail: email, password: password) { (user, error) in
            // [START_EXCLUDE]
            if let error = error {
                let alert = UIAlertController(title: "Alert", message: error.localizedDescription, preferredStyle: UIAlertControllerStyle.alert)
                alert.addAction(UIAlertAction(title: "Okay", style: UIAlertActionStyle.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
                return
            }
                self.ref = Database.database().reference()
                
                var favs = Dictionary<String, String>()
                for member in favorites{
                    favs[member.value.dealID!] = member.value.dealID
                }
                self.ref.child("Users").child(user!.uid).child("FullName").setValue(name)
                if let user = user {
                    let changeRequest = user.createProfileChangeRequest()
                    
                    changeRequest.displayName = name
                    //changeRequest.photoURL =
                    changeRequest.commitChanges { error in
                        if error != nil {
                            // An error happened.
                        } else {
                            // Profile updated.
                        }
                    }
                }
                self.navigationController?.isNavigationBarHidden = true
                self.performSegue(withIdentifier: "signedUp", sender: self)

        }
        // [END_EXCLUDE]
    }
    // [END create_user]
    else {
            let alert = UIAlertController(title: "Alert", message: "Username or password can't be empty", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "Okay", style: UIAlertActionStyle.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
        self.doneLoading()

    }
    
   
    
}
