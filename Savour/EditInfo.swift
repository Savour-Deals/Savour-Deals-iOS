//
//  VendorHomeViewController.swift
//  Savour
//
//  Created by Chris Patterson on 9/25/17.
//  Copyright © 2017 Chris Patterson. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage

class EditInfoViewController: UIViewController {
    var handle: AuthStateDidChangeListenerHandle?
    var ref: DatabaseReference!
    var id: String!
    var menu: String!
    @IBOutlet weak var rImg: UIImageView!
    @IBOutlet weak var rAddress: UITextField!
    @IBOutlet weak var rName: UITextField!
    @IBOutlet weak var rDesc: UITextView!
    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var submitButton: UIButton!
    var tempName: String!
    var tempAddress: String!
    var tempDesc: String!
    var keyboardShowing = false

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIStatusBarStyle.default
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        editButton.layer.cornerRadius = 5
        cancelButton.layer.cornerRadius = 5
        submitButton.layer.cornerRadius = 5
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        loadData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: self.view.window)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: self.view.window)
    }
    
    func loadData(){
        //Set overall restraunt info
        id = Auth.auth().currentUser?.uid
        ref = Database.database().reference()
        ref.keepSynced(true)
        ref.child("Restaurants").child(id!).observeSingleEvent(of: .value, with: { (snapshot) in
            let value = snapshot.value as? NSDictionary
            self.menu = value?["Menu"] as? String ?? ""
            self.rName.text = value?["Name"] as? String ?? ""
            self.rAddress.text = value?["Address"] as? String ?? ""
            self.rDesc.text = value?["Desc"] as? String ?? ""
            let photo = value?["Photo"] as? String ?? ""
            // Reference to an image file in Firebase Storage
            let storage = Storage.storage()
            let storageref = storage.reference()
            // Reference to an image file in Firebase Storage
            let reference = storageref.child("rPhotos/" + photo)
            
            // UIImageView in your ViewController
            let imageView: UIImageView = self.rImg
            
            // Placeholder image
            let placeholderImage = UIImage(named: "placeholder.jpg")
            
            // Load the image using SDWebImage
            imageView.sd_setImage(with: reference, placeholderImage: placeholderImage)
            
        }){ (error) in
            print(error.localizedDescription)
        }
    }
    @IBAction func editInfo(_ sender: Any) {
            cancelButton.isHidden = false
            submitButton.isHidden = false
            editButton.isHidden = true
            rName.isEnabled = true
            rAddress.isEnabled = true
            rDesc.isEditable = true
            tempDesc = rDesc.text
            tempName = rName.text
            tempAddress = rAddress.text
            rName.borderStyle = UITextBorderStyle.roundedRect
            rAddress.borderStyle = UITextBorderStyle.roundedRect
            rDesc.backgroundColor = UIColor.lightGray
            rName.becomeFirstResponder()        
    }
    @IBAction func submitPress(_ sender: Any) {
            cancelButton.isHidden = true
            submitButton.isHidden = true
            editButton.isHidden = false
            rName.isEnabled = false
            rAddress.isEnabled = false
            rDesc.isEditable = false
            rName.borderStyle = UITextBorderStyle.none
            rAddress.borderStyle = UITextBorderStyle.none
            rDesc.backgroundColor = UIColor.white
            ref.child("Restaurants").child(id!).child("Name").setValue(rName.text)
            ref.child("Restaurants").child(id!).child("Address").setValue(rAddress.text)
            ref.child("Restaurants").child(id!).child("Desc").setValue(rDesc.text)
    }
    
    
    @IBAction func cancelEdit(_ sender: Any) {
            cancelButton.isHidden = true
            submitButton.isHidden = true
            editButton.isHidden = false
            rDesc.text = tempDesc
            rName.text = tempName
            rAddress.text = tempAddress
            cancelButton.isHidden = true
            rName.isEnabled = false
            rAddress.isEnabled = false
            rDesc.isEditable = false
            rName.borderStyle = UITextBorderStyle.none
            rAddress.borderStyle = UITextBorderStyle.none
            rDesc.backgroundColor = UIColor.white
    }
    
    @objc func keyboardWillShow(notification: NSNotification){
        if !keyboardShowing{
            keyboardShowing = true
            rImg.isHidden = true
            self.navigationController?.navigationBar.isHidden = true
            if ((notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue) != nil {
                if self.view.frame.origin.y == 0{
                    self.view.frame.origin.y -= rImg.frame.height + (self.navigationController?.navigationBar.frame.height)!
                }
            }
        }
    }
    @objc func keyboardWillHide(notification: NSNotification){
        keyboardShowing = false
        rImg.isHidden = false
        self.navigationController?.navigationBar.isHidden = false
        if ((notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue) != nil {
            if self.view.frame.origin.y != 0{
                self.view.frame.origin.y += rImg.frame.height + (self.navigationController?.navigationBar.frame.height)!
            }
        }
    }
    
   
}
