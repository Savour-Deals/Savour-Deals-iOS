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

    @IBOutlet weak var img: UIImageView!
    @IBOutlet weak var NameField: UITextField!
    @IBOutlet weak var EmailField: UITextField!
    @IBOutlet weak var SignupButton: UIButton!
    @IBOutlet weak var PasswordField: UITextField!
    var keyboardShowing = false
    var keyboardHeight: CGFloat!

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
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        let gradientLayer = CAGradientLayer()
        let statusBar = UIApplication.shared.value(forKey: "statusBar") as! UIView
        statusBar.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0)
        gradientLayer.frame = self.view.bounds
        gradientLayer.colors = [#colorLiteral(red: 0.2848863602, green: 0.6698332429, blue: 0.6656947136, alpha: 1).cgColor, #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1).cgColor]
        self.view.layer.insertSublayer(gradientLayer, at: 0)
        NameField.layer.borderColor = UIColor.white.cgColor
        NameField.layer.borderWidth = 2
        EmailField.layer.borderColor = UIColor.white.cgColor
        EmailField.layer.borderWidth = 2
        SignupButton.layer.borderColor = UIColor.white.cgColor
        SignupButton.layer.borderWidth = 2
        PasswordField.layer.borderColor = UIColor.white.cgColor
        PasswordField.layer.borderWidth = 2
        NameField.textColor = UIColor.white
        EmailField.textColor = UIColor.white
        PasswordField.textColor = UIColor.white
        NameField.layer.cornerRadius = 5
        EmailField.layer.cornerRadius = 5
        PasswordField.layer.cornerRadius = 5
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
        let statusBar = UIApplication.shared.value(forKey: "statusBar") as! UIView
        statusBar.backgroundColor = #colorLiteral(red: 0.2848863602, green: 0.6698332429, blue: 0.6656947136, alpha: 1)
        
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

 

    
    @objc func SignupPressed(_ sender: Any) {
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
                self.ref.child("Users").child(user!.uid).child("Onboarded").setValue("true")
                self.performSegue(withIdentifier: "tutorial", sender: self)

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
    @objc func keyboardWillShow(notification: NSNotification){
        if !keyboardShowing{
            keyboardShowing = true
            img.isHidden = true
            if ((notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue) != nil {
                //if self.view.frame.origin.y == 0{
                    let keyboardRectValue = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
                    keyboardHeight = keyboardRectValue?.height
                    self.view.frame.origin.y -= keyboardHeight!
               // }
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
