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
    var keyboardHeight: CGFloat!
    
    @IBOutlet weak var img: UIImageView!
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
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
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
        let statusBar = UIApplication.shared.value(forKey: "statusBar") as! UIView
        statusBar.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0)
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
        let statusBar = UIApplication.shared.value(forKey: "statusBar") as! UIView
        statusBar.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0)
        let rounded = LoginEmail.layer.frame.height/2
        LoginEmail.layer.borderColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        LoginEmail.layer.borderWidth = 2
        LoginPassword.layer.borderColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        LoginPassword.layer.borderWidth = 2
        LoginButton.layer.borderColor = UIColor.white.cgColor
        LoginButton.layer.borderWidth = 2
        LoginPassword.textColor = UIColor.white
        LoginEmail.textColor = UIColor.white
        LoginPassword.layer.cornerRadius = rounded
        LoginEmail.layer.cornerRadius = rounded
        LoginButton.layer.cornerRadius = rounded
        LoginView.layer.cornerRadius = rounded
    }
    @IBAction func toSignup(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        self.LoginEmail.resignFirstResponder()
        self.LoginPassword.resignFirstResponder()

    }
   

    @IBAction func LoginButtonPressed(_ sender: Any) {
        FBLoginButton.isEnabled = false
        LoginButton.isEnabled = false
        SignUpButton.isEnabled = false
        isLoggingin()
        
        if let email = self.LoginEmail.text, let password = self.LoginPassword.text {
                // [START headless_email_auth]
                Auth.auth().signIn(withEmail: email, password: password) { (user, error) in
                    // [START_EXCLUDE]
                    if error != nil {
                        self.loginIndicator.stopAnimating()
                        self.endLoggingin()
                        let alert = UIAlertController(title: "Alert", message: "Username or password incorrect. Please try again.", preferredStyle: UIAlertControllerStyle.alert)
                        alert.addAction(UIAlertAction(title: "Okay", style: UIAlertActionStyle.default, handler: nil))
                        self.present(alert, animated: true, completion: nil)
                        return
                    }
                    self.ref.child("Users").child(user!.uid).child("type").observeSingleEvent(of: .value, with: { (snapshot) in
                        // Get user value
                        let type = snapshot.value as? String ?? ""
                        if type == "Vendor"{
                            self.performSegue(withIdentifier: "Vendor", sender: self)
                            self.endLoggingin()

                        }
                        else{
                            self.ref.child("Users").child(user!.uid).child("Onboarded").observeSingleEvent(of: .value, with: { (snapshot) in
                                let boarded = snapshot.value as? String ?? ""
                                if boarded != ""{
                                    self.performSegue(withIdentifier: "MainS", sender: self)
                                    self.endLoggingin()
                                    
                                }
                                else{
                                    self.performSegue(withIdentifier: "tutorial", sender: self)
                                    self.endLoggingin()
                                    
                                }
                            })
                        }
                    })
                }
            // [END_EXCLUDE]
            }
                // [END headless_email_auth]
       
    }

    @IBAction func FBLoginPressed(_ sender: Any) {
       
    }
    
    func loginButtonDidLogOut(_ loginButton: FBSDKLoginButton!) {
        print("Did log out of facebook")
    }
    
    func loginButton(_ loginButton: FBSDKLoginButton!, didCompleteWith result: FBSDKLoginManagerLoginResult!, error: Error!){
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
                    let id = data["id"] as! String
                    self.ref.child("Users").child(user!.uid).child("FullName").setValue(name)
                    self.ref.child("Users").child(user!.uid).child("FacebookID").setValue(id)

                }
            })

            self.ref.child("Users").child(user!.uid).child("type").observeSingleEvent(of: .value, with: { (snapshot) in
                // Get user value
                let type = snapshot.value as? String ?? ""
                if type == "Vendor"{
                    self.performSegue(withIdentifier: "Vendor", sender: self)
                    self.endLoggingin()
                }
                else{
                    self.ref.child("Users").child(user!.uid).child("Onboarded").observeSingleEvent(of: .value, with: { (snapshot) in
                            let boarded = snapshot.value as? String ?? ""
                        if boarded != ""{
                            self.performSegue(withIdentifier: "MainS", sender: self)
                            self.endLoggingin()

                        }
                        else{
                            self.performSegue(withIdentifier: "tutorial", sender: self)
                            self.endLoggingin()

                        }
                    })
                }
            })
        }
    }
                
    @objc func keyboardWillShow(notification: NSNotification){
        if !keyboardShowing{
            keyboardShowing = true
            img.isHidden = true
            if ((notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue) != nil {
                if self.view.frame.origin.y == 0{
                    let keyboardRectValue = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
                    keyboardHeight = keyboardRectValue?.height
                    self.view.frame.origin.y -= keyboardHeight!
                }
            }
        }
    }
    @objc func keyboardWillHide(notification: NSNotification){
        if keyboardShowing{
            keyboardShowing = false
            img.isHidden = false
            if ((notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue) != nil {
                if self.view.frame.origin.y != 0{
                    self.view.frame.origin.y += keyboardHeight!
                }
            }
        }
    }
}


