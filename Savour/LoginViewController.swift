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
    @IBOutlet weak var forgotPasswordbutton: UIButton!

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if isUserVerified(user: Auth.auth().currentUser){
            // User is signed in or verified.
            self.gotoMain()
        }else {
            // user is not verified or signed in.
            setUpUI()
            ref = Database.database().reference()
            FBSDKLoginManager().logOut()
            FBLoginButton.delegate = self
            FBLoginButton.readPermissions = ["public_profile", "email", "user_friends"]
            NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        }
       
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController!.setNavigationBarHidden(true, animated: true)
        let statusBar = UIApplication.shared.value(forKey: "statusBar") as! UIView
        statusBar.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }

        
    func setUpUI(){
        LoginView.isHidden = true
        LoginLabel.isHidden = true
        let statusBar = UIApplication.shared.value(forKey: "statusBar") as! UIView
        statusBar.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0)
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = self.view.bounds
        gradientLayer.colors = [#colorLiteral(red: 0.2848863602, green: 0.6698332429, blue: 0.6656947136, alpha: 0).cgColor, #colorLiteral(red: 0.2848863602, green: 0.6698332429, blue: 0.6656947136, alpha: 0.4).cgColor]
        self.view.layer.insertSublayer(gradientLayer, at: 0)
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
    
    func isLoggingin(){
        loginIndicator.startAnimating()
        LoginView.isHidden = false
        LoginLabel.isHidden = false
        FBLoginButton.isEnabled = false
        LoginButton.isEnabled = false
        SignUpButton.isEnabled = false
        FBLoginButton.isHidden = true

    }
    
    func endLoggingin(){
        loginIndicator.stopAnimating()
        LoginView.isHidden = true
        LoginLabel.isHidden = true
        FBLoginButton.isEnabled = true
        LoginButton.isEnabled = true
        SignUpButton.isEnabled = true
        FBLoginButton.isHidden = false

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
            Auth.auth().signIn(withEmail: email, password: password) { (user, error) in
                if error != nil {
                    self.loginIndicator.stopAnimating()
                    self.endLoggingin()
                    let alert = UIAlertController(title: "Alert", message: "Username or password incorrect. Please try again.", preferredStyle: UIAlertController.Style.alert)
                    alert.addAction(UIAlertAction(title: "Okay", style: UIAlertAction.Style.default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                    return
                }
                if let userData = user{
                    self.successfulEmailLogin(userData: userData)
                }
            }
        }
    }

    @IBAction func FBLoginPressed(_ sender: Any) {
       
    }
    
    func loginButtonDidLogOut(_ loginButton: FBSDKLoginButton!) {
        print("Did log out of facebook")
    }
    
    
    func loginButton(_ loginButton: FBSDKLoginButton!, didCompleteWith result: FBSDKLoginManagerLoginResult!, error: Error!){
        isLoggingin()
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
        Auth.auth().signInAndRetrieveData(with: credential) { (user, error) in
            if error != nil {
                print(error.debugDescription)
                return
            }
            if let userData = user{
                self.successfulFBLogin(userData: userData)
            }
        }
    }
    
    func successfulEmailLogin(userData: AuthDataResult){
        let user = userData.user
        if (user.isEmailVerified){
            //Were gucci. They verified
            //set time stamp for login. First time will trigger firebase referral trigger
            let userRecord = Database.database().reference().child("users").child(user.uid)
            userRecord.child("last_signin_at").setValue(ServerValue.timestamp())
            
            self.gotoMain()
            self.endLoggingin()
        }else{
            //not verified. Remind the user
            let alert = UIAlertController(title: "Unverified Account!", message: "Please check your email to verify your account. Then come back and try again.", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "Okay", style: UIAlertAction.Style.default, handler: nil))
            alert.addAction(UIAlertAction(title: "Resend Email", style: UIAlertAction.Style.default, handler: { (alert: UIAlertAction!) in
                user.sendEmailVerification(completion: { (err) in
                    if err != nil{
                        print(err!)
                    }
                })
            }))
            self.present(alert, animated: true, completion: nil)
            self.endLoggingin()
        }
    }
    
    func successfulFBLogin(userData: AuthDataResult){
        let user = userData.user

        //fb login with firebase successful, graph request some data
        let graphRequest:FBSDKGraphRequest = FBSDKGraphRequest(graphPath: "me", parameters: ["fields":"name,email, picture.type(large), birthday"])
        graphRequest.start(completionHandler: { (connection, result, error) -> Void in
            if ((error) != nil){
                print("Error: \(String(describing: error))")
            }else{
                //get graph result from fb and update user data
                if let data = result as? [String : AnyObject]{
                    if let name = data["name"] as? String{
                        self.ref.child("Users").child(user.uid).child("full_name").setValue(name)
                    }
                    if let id = data["id"] as? String{
                        self.ref.child("Users").child(user.uid).child("facebook_id").setValue(id)
                    }
                    if let email = data["email"] as? String{
                        user.updateEmail(to: email, completion: { (error) in
                            if ((error) != nil)
                            {
                                print("Error: \(String(describing: error))")
                            }
                        })
                    }
                    if let birthday = data["birthday"] {
                        self.ref.child("Users").child(user.uid).child("birthday").setValue(birthday)
                    }
                }
            }
        })
        
        //set time stamp for login. First time will trigger firebase referral trigger
        let userRecord = Database.database().reference().child("users").child(user.uid)
        userRecord.child("last_signin_at").setValue(ServerValue.timestamp())
        
        self.gotoMain()
        self.endLoggingin()
    }
    
    @IBAction func sendResetEmail(_ sender: Any) {
        if LoginEmail.text == ""{
            let alert = UIAlertController(title: "Alert", message: "Please enter your email in the field below.", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "Okay", style: UIAlertAction.Style.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }else{
            let email = LoginEmail.text!
            Auth.auth().fetchProviders(forEmail: email, completion: { (provider, error) in
                if provider == nil{
                    let alert = UIAlertController(title: "Alert", message: "Account with the provided email was not found.", preferredStyle: UIAlertController.Style.alert)
                    alert.addAction(UIAlertAction(title: "Okay", style: UIAlertAction.Style.default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                }else if (provider?.contains("password"))!{
                    Auth.auth().sendPasswordReset(withEmail: email) { (error) in
                        let alert = UIAlertController(title: "Success!", message: "An email has been sent to \(email) to reset your password.", preferredStyle: UIAlertController.Style.alert)
                        alert.addAction(UIAlertAction(title: "Okay", style: UIAlertAction.Style.default, handler: nil))
                        self.present(alert, animated: true, completion: nil)
                    }
                }else{
                    //Change this if we ever add more authentication services
                    let alert = UIAlertController(title: "Alert", message: "Account was created using Facebook. Reset your password there and try again.", preferredStyle: UIAlertController.Style.alert)
                    alert.addAction(UIAlertAction(title: "Okay", style: UIAlertAction.Style.default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                }
            })
            
        }
    }
    
    func gotoMain(){
        //Set root as our tab view controller
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let tabVC = storyboard.instantiateViewController(withIdentifier: "tabMain") as! UITabBarController
        tabVC.selectedIndex = 0
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.window!.rootViewController = tabVC
    }
                
    @objc func keyboardWillShow(notification: NSNotification){
        if !keyboardShowing{
            keyboardShowing = true
            img.isHidden = true
            if ((notification.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue) != nil {
                if self.view.frame.origin.y == 0{
                    let keyboardRectValue = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
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
            if ((notification.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue) != nil {
                if self.view.frame.origin.y != 0{
                    self.view.frame.origin.y += keyboardHeight!
                }
            }
        }
    }
}


