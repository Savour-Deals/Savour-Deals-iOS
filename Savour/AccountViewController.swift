//
//  AccountViewController.swift
//  Savour
//
//  Created by Chris Patterson on 8/9/17.
//  Copyright © 2017 Chris Patterson. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase
import MessageUI
import AcknowList
import OneSignal
import UserNotifications
import FBSDKCoreKit
import FBSDKShareKit

class AccountViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, MFMailComposeViewControllerDelegate{

    var handle: AuthStateDidChangeListenerHandle?
    var ref: DatabaseReference!
    var imgURL: String!
    var friendsText = ""

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    
    
    @IBOutlet weak var welcomeLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 11.0, *) {
            tableView.contentInsetAdjustmentBehavior = .never
        }
        let user = Auth.auth().currentUser
        let ref = Database.database().reference().child("Users").child((user?.uid)!).child("FacebookID")
        self.friendsText = "Click here to invite your friends to Savour Deals!"
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            if snapshot.exists(){
                let value = snapshot.value as! String
                self.imgURL = "https://graph.facebook.com/" + value + "/picture?height=500"
            }
            else{
                self.imgURL = nil
            }
            self.tableView.reloadData()
        })
        let graphRequest:FBSDKGraphRequest = FBSDKGraphRequest(graphPath: "me", parameters: ["fields":"friends"])
        
        graphRequest.start(completionHandler: { (connection, result, error) -> Void in
            
            if ((error) != nil){
                print("Error: \(String(describing: error))")
            }else{
                var data = result as! [String : AnyObject]
                data = data["friends"] as! [String : AnyObject]
                let friends = data["data"] as! NSArray
                if friends.count > 0{
                     self.friendsText = "You have \(friends.count) friend using Savour!\nClick here to invite more!"
                }else{
                    self.friendsText = "Click here to invite your Facebook friends to Savour Deals!"
                }
                self.tableView.reloadData()
            }
        })
        let footerView = UIView()
        footerView.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0)
        tableView.tableFooterView = footerView
    }
    
    override func viewDidAppear(_ animated: Bool) {
        let statusBar = UIApplication.shared.value(forKey: "statusBar") as! UIView
        statusBar.backgroundColor = UIColor.white
        handle = Auth.auth().addStateDidChangeListener { (auth, user) in
        }

    }
    
    override func viewWillDisappear(_ animated: Bool) {
        UIApplication.shared.statusBarStyle = .lightContent
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 5
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        if indexPath.row == 0{
            return 160
        }else if indexPath.row == 1{
            return 90
        }
        else{
            return 45
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell!
        if indexPath.row == 0 {
            var cell1: AccountCell!
            cell1 = tableView.dequeueReusableCell(withIdentifier: "Welcome", for: indexPath) as! AccountCell
            let user = Auth.auth().currentUser
            if self.imgURL != nil{
                let imageView: UIImageView = cell1.Img

                // Placeholder image
                let placeholderImage = UIImage(named: "placeholder.jpg")
                
                // Load the image using SDWebImage
                imageView.sd_setImage(with: URL(string: self.imgURL), placeholderImage: placeholderImage)
                cell1.Img.layer.cornerRadius = cell1.Img.frame.size.width/2
                cell1.Img.clipsToBounds = true
                
            }else{
                cell1.Img.image = #imageLiteral(resourceName: "Savour_FullColor")
            }
            cell1.Welcome.text = (user?.displayName)!
            
            cell1.selectionStyle = UITableViewCellSelectionStyle.none

            return cell1
        }else if indexPath.row == 1{
            let cell2 = tableView.dequeueReusableCell(withIdentifier: "seperate", for: indexPath) as! friendsCell
            
            cell2.friendLabel.text = friendsText
            
            return cell2

        }else if indexPath.row == 2 {
             cell = tableView.dequeueReusableCell(withIdentifier: "Contact", for: indexPath)
        }else if indexPath.row == 3{
            cell = tableView.dequeueReusableCell(withIdentifier: "settings", for: indexPath)
        }else if indexPath.row == 4{
            cell = tableView.dequeueReusableCell(withIdentifier: "acknowledgements", for: indexPath)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath){
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.row == 2{
            let mailComposeViewController = configureMailController()
            if !MFMailComposeViewController.canSendMail() {
                let email = "info@savourdeals.com"
                let url = URL(string: "mailto:\(email)")
                if #available(iOS 10.0, *) {
                    UIApplication.shared.open(url!)
                } else {
                    UIApplication.shared.openURL(url!)
                }
                return
            }
            else{
                self.present(mailComposeViewController, animated: true, completion: nil)
            }
        }else if indexPath.row == 1{

            let textToShare = "Check out Savour to get deals from local restaurants!"
            
            if let myWebsite = URL(string: "http://www.savourdeals.com/getsavour") {//Enter link to your app here
                let objectsToShare = [myWebsite,textToShare] as [Any]
                let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
                //Excluded Activities
                activityVC.excludedActivityTypes = [UIActivityType.airDrop, UIActivityType.addToReadingList]
                self.present(activityVC, animated: true, completion: nil)
            }
        }else if indexPath.row == 4{
            let path = Bundle.main.path(forResource: "Acknowledgements", ofType: "plist")
            let viewController = AcknowListViewController(acknowledgementsPlistPath: path)
            self.navigationController?.navigationBar.tintColor = UIColor.black
            self.navigationController?.pushViewController(viewController, animated: true)
        }
       
    }
    
    func configureMailController() -> MFMailComposeViewController {
        let mailComposerVC = MFMailComposeViewController()
        mailComposerVC.mailComposeDelegate = self
        
        mailComposerVC.setToRecipients(["info@savourdeals.com"])
        mailComposerVC.setSubject("Savour Deals")
        return mailComposerVC
    }
    func showMailError() {
        let sendMailErrorAlert = UIAlertController(title: "Could not send email", message: "Your device could not send email", preferredStyle: .alert)
        let dismiss = UIAlertAction(title: "Ok", style: .default, handler: nil)
        sendMailErrorAlert.addAction(dismiss)
        self.present(sendMailErrorAlert, animated: true, completion: nil)
    }
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func logoutPressed(_ sender: Any) {
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
    
    @IBAction func updateTimes(_ sender: Any) {
        let errorAlert = UIAlertController(title: "WARNING!!!!!", message: "Do not accidently hit ok. This will mess with your backend! Remove this before launch", preferredStyle: .alert)
        let dismiss = UIAlertAction(title: "CANCEL", style: .default, handler: nil)
        errorAlert.addAction(dismiss)
        let okay = UIAlertAction(title: "Okay", style: .default) { (alert: UIAlertAction!) -> Void in
            add_TwoMonth()
        };
        errorAlert.addAction(okay)
        self.present(errorAlert, animated: true, completion: nil)
    }
    
}

class AccountCell: UITableViewCell {
    
    @IBOutlet weak var Welcome: UILabel!
    @IBOutlet weak var Img: UIImageView!
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
    }
    
}

class friendsCell: UITableViewCell {
    
    @IBOutlet weak var friendLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
    }
    
}


class accountNav: UINavigationController{
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }
}

class settingsViewController: UITableViewController{
    
    @IBOutlet weak var notificationDirections: UILabel!
    @IBOutlet weak var notificationSwitch: UISwitch!
    let status: OSPermissionSubscriptionState = OneSignal.getPermissionSubscriptionState()
    var OSNotiSetting = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "Settings"
        self.navigationItem.backBarButtonItem?.title = ""
    }
    
    override func viewWillAppear(_ animated: Bool) {
        let statusBar = UIApplication.shared.value(forKey: "statusBar") as! UIView
        statusBar.backgroundColor = UIColor.white
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().getNotificationSettings(){ (settings) in
                if settings.authorizationStatus == .authorized{
                    self.OSNotiSetting = true
                }
                DispatchQueue.main.async {
                    self.setupUI()
                }
            }
        } else {
            let isNotificationEnabled = UIApplication.shared.currentUserNotificationSettings?.types.contains(UIUserNotificationType.alert)
            if isNotificationEnabled!{
                OSNotiSetting = true
            }
            setupUI()
        }
    }
    
    func setupUI(){
        let isSubscribed = status.subscriptionStatus.subscribed
        notificationSwitch.isHidden = false
        notificationDirections.isHidden = true
        if isSubscribed {
            notificationSwitch.isOn = true
        }else{
            notificationSwitch.isOn = false
        }
        let footerView = UIView()
        footerView.backgroundColor = #colorLiteral(red: 0.2848863602, green: 0.6698332429, blue: 0.6656947136, alpha: 0)
        self.tableView.tableFooterView = footerView
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    @IBAction func notificationToggles(_ sender: Any) {
        if notificationSwitch.isOn{
            if #available(iOS 10.0, *) {
                let current = UNUserNotificationCenter.current()
                OneSignal.setSubscription(true)
                current.getNotificationSettings(completionHandler: { (settings) in
                    if settings.authorizationStatus == .notDetermined || settings.authorizationStatus == .authorized{
                        OneSignal.promptForPushNotifications(userResponse: { accepted in
                            print("User accepted notifications: \(accepted)")
                            if accepted == false{
                                DispatchQueue.main.async {
                                    self.notificationDirections.isHidden = false
                                    self.notificationSwitch.isHidden = true
                                }
                            }
                        })
                    }
                    if settings.authorizationStatus == .denied {
                        DispatchQueue.main.async {
                            self.notificationDirections.isHidden = false
                            self.notificationSwitch.isHidden = true
                        }
                    }
                })
            } else {
                OneSignal.setSubscription(true)
            }
        }else{
            OneSignal.setSubscription(false)
        }
    }
}

