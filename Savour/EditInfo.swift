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

class EditInfoViewController: UITableViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    var handle: AuthStateDidChangeListenerHandle?
    var ref: DatabaseReference!
    var storageRef: StorageReference!
    var data: NSData!
    var id: String!
    var menu: String!
    var keyboardHeight: CGFloat!
    @IBOutlet weak var rImg: UIImageView!
    @IBOutlet weak var rAddress: UITextField!
    @IBOutlet weak var rName: UITextField!
    @IBOutlet weak var rDesc: UITextView!
    var tempName: String!
    var tempAddress: String!
    var tempDesc: String!
    var keyboardShowing = false
    let imagePicker = UIImagePickerController()

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIStatusBarStyle.default
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        storageRef = StorageReference()
        loadData()
        imagePicker.delegate = self
        self.imagePicker.allowsEditing = true
        let footerView = UIView()
        footerView.backgroundColor = #colorLiteral(red: 0.2848863602, green: 0.6698332429, blue: 0.6656947136, alpha: 0)
        self.tableView.tableFooterView = footerView
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
            if photo != ""{
                // Reference to an image file in Firebase Storage
                let storage = Storage.storage()
                let storageref = storage.reference(forURL: photo)
                // Reference to an image file in Firebase Storage
                let reference = storageref
                
                // UIImageView in your ViewController
                let imageView: UIImageView = self.rImg
                
                // Placeholder image
                let placeholderImage = UIImage(named: "placeholder.jpg")
                
                // Load the image using SDWebImage
                imageView.sd_setImage(with: reference, placeholderImage: placeholderImage)
            }
            
        }){ (error) in
            print(error.localizedDescription)
        }
    }
    
    @IBAction func selectNewImgPressed(_ sender: Any) {
        imagePicker.allowsEditing = false
        imagePicker.sourceType = .photoLibrary
        
        present(imagePicker, animated: true, completion: nil)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        if indexPath.row > 0 && indexPath.row < 3{
            tableView.scrollToRow(at: indexPath, at: .top, animated: true)
            let cell = tableView.cellForRow(at: indexPath)
            let textfield = cell?.contentView.subviews[0] as! UITextField
            textfield.becomeFirstResponder()
        }
    }
    
    private func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        
        if let pickedImage = info[UIImagePickerControllerEditedImage] as? UIImage
        {
            rImg.contentMode = .scaleAspectFit
            rImg.image = pickedImage
        }
        else if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            rImg.contentMode = .scaleAspectFit
            rImg.image = pickedImage
        }

        dismiss(animated: true, completion: nil)
        data = NSData()
        data = UIImageJPEGRepresentation(rImg.image!, 0.8)! as NSData
    }
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            rImg.contentMode = .scaleToFill
            rImg.image = image
        }
        dismiss(animated: true, completion: nil)
    }

    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }

    @IBAction func SaveChanges(_ sender: Any) {
        
        // set upload path
        let filePath = "Restaurants/\(Auth.auth().currentUser!.uid)/Photos/\("restaurantPhoto")"
        self.data = NSData()
        self.data = UIImageJPEGRepresentation(self.rImg.image!, 0.8)! as NSData
        let metaData = StorageMetadata()
        metaData.contentType = "image/jpg"
        self.storageRef.child(filePath).putData(data as Data, metadata: metaData){(metaData,error) in
            if let error = error {
                print(error.localizedDescription)
                return
            }else{
                //store downloadURL
                let downloadURL = metaData!.downloadURL()!.absoluteString
                //store downloadURL at database
                self.ref.child("Restaurants").child(Auth.auth().currentUser!.uid).updateChildValues(["Photo": downloadURL])
            }
        }
        ref.child("Restaurants").child(id!).child("Name").setValue(rName.text)
        ref.child("Restaurants").child(id!).child("Address").setValue(rAddress.text)
        ref.child("Restaurants").child(id!).child("Desc").setValue(rDesc.text)
        self.navigationController?.popViewController(animated: true)
    }
    
}
