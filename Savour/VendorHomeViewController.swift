//
//  VendorHomeViewController.swift
//  Savour
//
//  Created by Chris Patterson on 9/26/17.
//  Copyright © 2017 Chris Patterson. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase


class VendorHomeViewController: UIViewController {

    var handle: AuthStateDidChangeListenerHandle?
    var ref: DatabaseReference!
    var id: String!
    
    @IBOutlet weak var logoutBtn: UIButton!
    @IBOutlet weak var btn4: UIButton!
    @IBOutlet weak var btn3: UIButton!
    @IBOutlet weak var btn2: UIButton!
    @IBOutlet weak var btn1: UIButton!
    var btns = [UIButton]()
    override func viewDidLoad() {
        super.viewDidLoad()
        btns.append(contentsOf: [btn1, btn2,btn3,btn4])
        setupUI()
    }
    
    func setupUI(){
        id = Auth.auth().currentUser?.uid
        ref = Database.database().reference()
        ref.child("Restaurants").child(id!).observeSingleEvent(of: .value, with: { (snapshot) in
            let value = snapshot.value as? NSDictionary
            self.navigationItem.title = value?["Name"] as? String ?? ""
        })
        for i in 0...btns.count-1{
            btns[i].layer.borderWidth = 1.0
            btns[i].layer.cornerRadius = 5.0
            btns[i].layer.borderColor = #colorLiteral(red: 0.2848863602, green: 0.6698332429, blue: 0.6656947136, alpha: 1)
        }
        logoutBtn.layer.cornerRadius = 5.0
    }
    
    override func viewWillAppear(_ animated: Bool) {
            setupUI()
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "newDeal" {
            let VC = segue.destination as! CustomNavBar
                VC.resName = self.navigationItem.title
        }
        
    }
    
    @IBAction func menuPressed(_ sender: Any) {
        //1. Create the alert controller.
        let alert = UIAlertController(title: "Link Menu", message: "Enter a URL to your menu", preferredStyle: .alert)
        
        //2. Add the text field. You can configure it however you need.
        alert.addTextField { (textField) in
            textField.placeholder = "Paste Menu URL"
        }
        
        // 3. Grab the value from the text field, and print it when the user clicks OK.
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak alert] (_) in
            if let field = alert?.textFields?[0] {
                let menuText = field
                self.ref.child("Restaurants").child(self.id!).child("Menu").setValue(menuText.text)
            }
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .destructive, handler: nil))
        
        // 4. Present the alert.
        self.present(alert, animated: true, completion: nil)
    }
    
   

}

class CustomNavBar: UINavigationController {
    var resName: String!
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }
}
