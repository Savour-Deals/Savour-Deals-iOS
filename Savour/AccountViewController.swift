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



class AccountViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, MFMailComposeViewControllerDelegate{

    var handle: AuthStateDidChangeListenerHandle?
    var ref: DatabaseReference!
    var imgURL: String!

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
    }
    
    override func viewWillAppear(_ animated: Bool) {
        tableView.tableFooterView = UIView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.navigationController?.isNavigationBarHidden = true
        
        let statusBar = UIApplication.shared.value(forKey: "statusBar") as! UIView
        statusBar.backgroundColor = UIColor.white
        handle = Auth.auth().addStateDidChangeListener { (auth, user) in
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 5
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        if indexPath.row == 0{
            return 160
        }
        else if indexPath.row == 3{
            return self.tableView.frame.height - (160 + 70 + 70 + 70)
        }
        else{
            return 70
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
            }
            else{
                cell1.Img.image = #imageLiteral(resourceName: "logo")
            }
            cell1.Welcome.text = "Welcome " + (user?.displayName)!
            
            // UIImageView in your ViewController#colorLiteral(red: 1, green: 0.1491314173, blue: 0, alpha: 1)
            return cell1
        }
        else if indexPath.row == 1 {
             cell = tableView.dequeueReusableCell(withIdentifier: "Contact", for: indexPath)
        }
        else if indexPath.row == 2{
            cell = tableView.dequeueReusableCell(withIdentifier: "acknowledgements", for: indexPath)
        }
        else if indexPath.row == 3{
            cell = tableView.dequeueReusableCell(withIdentifier: "space", for: indexPath)
            cell.selectionStyle = UITableViewCellSelectionStyle.none
        }
        else if indexPath.row == 4 {
            cell = tableView.dequeueReusableCell(withIdentifier: "Logout", for: indexPath)
            cell.backgroundColor = #colorLiteral(red: 1, green: 0.1491314173, blue: 0, alpha: 1)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath){
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.row == 1{
            let mailComposeViewController = configureMailController()
            if !MFMailComposeViewController.canSendMail() {
                let email = "patte539@umn.edu"
                let url = URL(string: "mailto:\(email)")
                UIApplication.shared.open(url!)
                return
            }
            else{
                self.present(mailComposeViewController, animated: true, completion: nil)
            }
        }
        else if indexPath.row == 2{
            let path = Bundle.main.path(forResource: "Acknowledgements", ofType: "plist")
            let viewController = AcknowListViewController(acknowledgementsPlistPath: path)
            self.navigationController?.isNavigationBarHidden = false
            let statusBar = UIApplication.shared.value(forKey: "statusBar") as! UIView
            statusBar.backgroundColor  = #colorLiteral(red: 0.2848863602, green: 0.6698332429, blue: 0.6656947136, alpha: 1)
            self.navigationController?.pushViewController(viewController, animated: true)
        }
        else if indexPath.row == 4{
            LogoutPressed()
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
    
    func LogoutPressed() {
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
