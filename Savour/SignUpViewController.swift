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

    @IBOutlet weak var PasswordField2: UITextField!
    @IBOutlet weak var EmailField: UITextField!
    @IBOutlet weak var SignupButton: UIButton!
    @IBOutlet weak var PasswordField: UITextField!
    
    
    var handle: AuthStateDidChangeListenerHandle?

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        SignupButton.addTarget(self, action: #selector(SignupPressed), for: .touchUpInside)
        SignupButton.layer.cornerRadius = 5
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

    
   

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    
    func SignupPressed(_ sender: Any) {
        if let password = PasswordField.text, let email = EmailField.text {//let username = UsernameField.text {
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
                
            print("\(user!.email!) created")
            
            self.navigationController!.popViewController(animated: true)
        }
        // [END_EXCLUDE]
    }
    // [END create_user]
    else {
            let alert = UIAlertController(title: "Alert", message: "Username or password can't be empty", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "Okay", style: UIAlertActionStyle.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    @IBAction func backPressed(_ sender: Any) {
        self.navigationController!.popToRootViewController(animated: true)
    }
    
}
