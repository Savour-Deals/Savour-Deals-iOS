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
    var handle: AuthStateDidChangeListenerHandle?
    var ref: DatabaseReference!

    @IBOutlet weak var Const: UIView!
    @IBOutlet weak var LoginEmail: UITextField!
    @IBOutlet weak var LoginPassword: UITextField!
    @IBOutlet weak var LoginButton: UIButton!
    @IBOutlet weak var SignUpButton: UIButton!
    @IBOutlet weak var FBLoginButton: FBSDKLoginButton!
    @IBOutlet weak var loginIndicator: UIActivityIndicatorView!
    var keyboardShowing = false
    @IBOutlet weak var LoginLabel: UILabel!
    @IBOutlet weak var LoginView: UIView!
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
            ref = Database.database().reference()
            FBSDKLoginManager().logOut()
            FBLoginButton.delegate = self
            NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
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
        LoginView.isHidden = true
        LoginLabel.isHidden = true
        LoginButton.layer.cornerRadius = 5
        SignUpButton.layer.cornerRadius = 5
        LoginView.layer.cornerRadius = 5
    }
    
    func isLoggingin(){
        
        loginIndicator.startAnimating()
        
        LoginView.isHidden = false
        LoginLabel.isHidden = false
        FBLoginButton.isEnabled = false
        LoginButton.isEnabled = false
        SignUpButton.isEnabled = false
    }
    
    func endLoggingin(){
        loginIndicator.stopAnimating()
        LoginView.isHidden = true
        LoginLabel.isHidden = true
        FBLoginButton.isEnabled = true
        LoginButton.isEnabled = true
        SignUpButton.isEnabled = true
    }
   

    @IBAction func LoginButtonPressed(_ sender: Any) {
        isLoggingin()
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
                    self.ref.child("Users").child(user!.uid).child("type").observeSingleEvent(of: .value, with: { (snapshot) in
                        // Get user value
                        let type = snapshot.value as! String
                        if type == "Vendor"{
                            self.performSegue(withIdentifier: "Vendor", sender: self)
                        }
                        else{
                            self.performSegue(withIdentifier: "MainS", sender: self)
                        }
                    })
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
        endLoggingin()
    }

 
    func loginButtonDidLogOut(_ loginButton: FBSDKLoginButton!) {
        print("Did log out of facebook")
    }
    
    func loginButton(_ loginButton: FBSDKLoginButton!, didCompleteWith result: FBSDKLoginManagerLoginResult!, error: Error!) {
        isLoggingin()
        var data:[String:AnyObject]!
        if error != nil {
            print(error)
            self.endLoggingin()
            return
        }
        if result.isCancelled {
            self.endLoggingin()
            return
        }
        print("Successfully logged in with facebook...")
        let credential = FacebookAuthProvider.credential(withAccessToken: FBSDKAccessToken.current().tokenString)
        Auth.auth().signIn(with: credential) { (user, error) in
            if error != nil {
                print(error.debugDescription)
                return
            }
            let graphRequest:FBSDKGraphRequest = FBSDKGraphRequest(graphPath: "me", parameters: ["fields":"name,email, picture.type(large)"])
            
            graphRequest.start(completionHandler: { (connection, result, error) -> Void in
                
                if ((error) != nil)
                {
                    print("Error: \(String(describing: error))")
                }
                else
                {
                    
                    data = result as! [String : AnyObject]
                    let name = data["name"] as! String
                    self.ref.child("Users").child(user!.uid).child("FullName").setValue(name)
                }
            })

            
            // User is signed in
            
        self.performSegue(withIdentifier: "MainS", sender: self)
        self.endLoggingin()
    }
    }
    @objc func keyboardWillShow(notification: NSNotification){
        if !keyboardShowing{
            keyboardShowing = true
            //self.navigationController?.navigationBar.isHidden = true
            if ((notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue) != nil {
                if self.view.frame.origin.y == 0{
                    let keyboardRectValue = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
                    let keyboardHeight = keyboardRectValue?.height
                    self.view.frame.origin.y -= keyboardHeight!
                }
            }
        }
    }
    @objc func keyboardWillHide(notification: NSNotification){
        keyboardShowing = false
        //self.navigationController?.navigationBar.isHidden = false
        if ((notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue) != nil {
            if self.view.frame.origin.y != 0{
                let keyboardRectValue = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
                let keyboardHeight = keyboardRectValue?.height
                self.view.frame.origin.y += keyboardHeight!
            }
        }
    }
}


