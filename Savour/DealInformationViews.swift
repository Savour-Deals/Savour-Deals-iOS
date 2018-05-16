//
//  DiscountViewController.swift
//  Savour
//
//  Created by Chris Patterson on 9/27/17.
//  Copyright © 2017 Chris Patterson. All rights reserved.
//

import UIKit
var newDeal: DealData!
import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage
import SDWebImage
import OneSignal

class DiscountViewController: UIViewController {
    var handler: AuthStateDidChangeListenerHandle!
    @IBOutlet weak var BOGOContainer: UIView!
    @IBOutlet weak var percentContainer: UIView!
    @IBOutlet weak var dollarContainer: UIView!
    @IBOutlet weak var segmentCont: UISegmentedControl!
    var BOGOvc: BogoController!
    var PercVC: PercentController!
    var DolVC: DollarController!
    var type: String!
    var resName: String!
    var deal: DealData!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var prevButton: UIButton!
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.isNavigationBarHidden = true
        
        if deal != nil{
            prevButton.setTitle("CANCEL", for: .normal)
            prevButton.setTitleColor(UIColor.red, for: .normal)
            newDeal = deal
            if (newDeal.dealDescription?.contains("$"))!{
                let strings = newDeal.dealDescription?.split(separator: " ", maxSplits: 2, omittingEmptySubsequences: false)
                segmentCont.selectedSegmentIndex = 2
                let dealTxt = "\(strings![0]) \(strings![1])"
                for i in 0..<DolVC.pickerView.numberOfRows(inComponent: 0){
                    if dealTxt == DolVC.pickerDataSource[i]{
                        DolVC.pickerView.selectRow(i, inComponent: 0, animated: true)
                    }
                }
            }
            else if (newDeal.dealDescription?.contains("%"))!{
                let strings = newDeal.dealDescription?.split(separator: " ", maxSplits: 2, omittingEmptySubsequences: false)
                segmentCont.selectedSegmentIndex = 1
                let dealTxt = "\(strings![0]) \(strings![1])"
                for i in 0..<PercVC.pickerView.numberOfRows(inComponent: 0){
                    if dealTxt == PercVC.pickerDataSource[i]{
                        PercVC.pickerView.selectRow(i, inComponent: 0, animated: true)
                    }
                }
            }
            else{
                segmentCont.selectedSegmentIndex = 0
            }
        }
        else{
            newDeal = DealData(ID: "")
            newDeal.type = type
            newDeal.name = self.resName
            newDeal.id = Auth.auth().currentUser?.uid
        }

        if segmentCont.selectedSegmentIndex == 0 {
            showBOGO()
        }
        else if segmentCont.selectedSegmentIndex == 1 {
            showPerc()
        }
        else if segmentCont.selectedSegmentIndex == 2 {
            showDollar()
        }
    }
    
    func showBOGO(){
        BOGOContainer.isHidden = false
        percentContainer.isHidden = true
        dollarContainer.isHidden = true
    }
    
    func showPerc(){
        BOGOContainer.isHidden = true
        percentContainer.isHidden = false
        dollarContainer.isHidden = true
    }
    
    func showDollar(){
        BOGOContainer.isHidden = true
        percentContainer.isHidden = true
        dollarContainer.isHidden = false
    }
    
    
    @IBAction func exitPressed(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    @IBAction func nextPressed(_ sender: Any) {
        if segmentCont.selectedSegmentIndex == 0 {
            newDeal?.dealDescription = "Buy One Get One Free \(newDeal.type!)"
            self.performSegue(withIdentifier: "datePick", sender: nil)
        }
        else if segmentCont.selectedSegmentIndex == 1 {
            newDeal?.dealDescription  = "\(PercVC.pickerDataSource[PercVC.pickerView.selectedRow(inComponent: 0)]) \(newDeal.type!)"
            self.performSegue(withIdentifier: "datePick", sender: nil)
        }
        else if segmentCont.selectedSegmentIndex == 2 {
            newDeal?.dealDescription  = "\(DolVC.pickerDataSource[DolVC.pickerView.selectedRow(inComponent: 0)]) \(newDeal.type!)"
            self.performSegue(withIdentifier: "datePick", sender: nil)
        }
    }
    
    @IBAction func segmentChanged(_ sender: UISegmentedControl) {
        if segmentCont.selectedSegmentIndex == 0 {
            showBOGO()
        }
        else if segmentCont.selectedSegmentIndex == 1 {
            showPerc()
        }
        else if segmentCont.selectedSegmentIndex == 2 {
            showDollar()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "bogo"{
            BOGOvc = segue.destination as! BogoController
        }
        if segue.identifier == "perc"{
            PercVC = segue.destination as! PercentController
        }
        if segue.identifier == "doll"{
            DolVC = segue.destination as! DollarController
        }
    }
    @IBAction func prevPressed(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
}





class BogoController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }
}





class PercentController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {
    @IBOutlet weak var pickerView: UIPickerView!
    var pickerDataSource = [String]()
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerDataSource.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerDataSource[row]
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        for index in 5...12 {
            let percent = index * 5
            pickerDataSource.append("\(percent)% Off")
        }
        self.pickerView.dataSource = self
        self.pickerView.delegate = self
    }
  
}






class DollarController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {
    @IBOutlet weak var pickerView: UIPickerView!
    var pickerDataSource = [String]()
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerDataSource.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerDataSource[row]
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        for dollars in 2...50 {
            pickerDataSource.append("$\(dollars) Off")
        }
        self.pickerView.dataSource = self
        self.pickerView.delegate = self
    }
    
}





class EndTimeController: UIViewController{
    @IBOutlet weak var EndPicker: UIDatePicker!

    override func viewDidLoad() {
        super.viewDidLoad()
        if newDeal.endTime != 0{
            let date = Date(timeIntervalSince1970: newDeal.endTime!)
            EndPicker.setDate(date, animated: true)
        }
    }
    
    @IBAction func nextPressed(_ sender: Any) {
        newDeal?.endTime = EndPicker.date.timeIntervalSince1970
        self.performSegue(withIdentifier: "photo", sender: nil)
    }
    @IBAction func prevPressed(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
}



class StartTimeController: UIViewController{
    @IBOutlet weak var startPicker: UIDatePicker!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if newDeal.startTime != 0{
            let date = Date(timeIntervalSince1970: newDeal.startTime!)
            startPicker.setDate(date, animated: true)
        }
        //make min date current date
        
    }
    
    @IBAction func nextPressed(_ sender: Any) {
        newDeal?.startTime = startPicker.date.timeIntervalSince1970
        self.performSegue(withIdentifier: "date", sender: nil)
    }
    @IBAction func prevPressed(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
}




class PhotoSelectController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    let imagePicker = UIImagePickerController()
    var data = NSData()
    var ref: DatabaseReference!
    var storageRef: StorageReference!

    @IBOutlet weak var nextBtn: UIButton!
    @IBOutlet weak var selectPhoto: UIButton!
    @IBOutlet weak var rImg: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.nextBtn.isEnabled = false
        imagePicker.delegate = self
        self.ref = Database.database().reference()
        storageRef = StorageReference()
        if newDeal.photo != ""{
            self.nextBtn.isEnabled = true

            // Reference to an image file in Firebase Storage
            let storage = Storage.storage()
            let storageref = storage.reference(forURL: newDeal.photo!)
            // Reference to an image file in Firebase Storage
            let reference = storageref
                    
            // UIImageView in your ViewController
            let imageView: UIImageView = self.rImg
            
            // Placeholder image
            let placeholderImage = UIImage(named: "placeholder.jpg")
                    
            // Load the image using SDWebImage
            imageView.sd_setImage(with: reference, placeholderImage: placeholderImage)
            
        }
    }
    @IBAction func nextPressed(_ sender: Any) {
        self.nextBtn.isEnabled = false
       let working = UIActivityIndicatorView()
        working.frame = rImg.frame
        working.activityIndicatorViewStyle = .whiteLarge  
        view.addSubview(working)
        working.color = UIColor.white
        working.startAnimating()
        self.ref.child("Deals").observeSingleEvent(of: .value, with: { (snapshot) in
            // set upload path for image
            if newDeal.id != nil {
                newDeal.id = "\(snapshot.childrenCount+1)"
            }
            let filePath = "Restaurants/\(Auth.auth().currentUser!.uid)/Photos/\(newDeal.id!)"
            let metaData = StorageMetadata()
            metaData.contentType = "image/jpg"
            self.storageRef.child(filePath).putData(self.data as Data, metadata: metaData){(metaData,error) in
                if let error = error {
                    print(error.localizedDescription)
                    let alert = UIAlertController(title: "Upload Failed!", message: "Your image failed to upload to the database. Please try again.", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Okay", style: .default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                    self.rImg.image = nil
                    self.nextBtn.isEnabled = true

                }else{
                    let downloadURL = metaData!.downloadURL()!.absoluteString
                    newDeal.photo = downloadURL
                    self.performSegue(withIdentifier: "review", sender: nil)
                    self.nextBtn.isEnabled = true
                    working.stopAnimating()

                }
            }
            
        })

    }
    @IBAction func selectNewImgPressed(_ sender: Any) {
        imagePicker.allowsEditing = false
        imagePicker.sourceType = .photoLibrary
        
        present(imagePicker, animated: true, completion: nil)
    }
    
    
    private func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            rImg.contentMode = .scaleToFill
            rImg.image = pickedImage
            dismiss(animated: true, completion: nil)
            data = UIImageJPEGRepresentation(rImg.image!, 0.8)! as NSData
            self.nextBtn.isEnabled = true

            
        }
    }
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            rImg.contentMode = .scaleToFill
            rImg.image = pickedImage
            
            dismiss(animated: true, completion: nil)
            data = UIImageJPEGRepresentation(rImg.image!, 0.8)! as NSData
            self.nextBtn.isEnabled = true

        }
    }
        
            
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let VC = segue.destination as! ReviewController
        VC.img = self.rImg.image
    }
    @IBAction func prevPressed(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
}









class ReviewController: UIViewController{
    var ref: DatabaseReference!
    var img: UIImage!
    @IBOutlet weak var rImg: UIImageView!
    @IBOutlet weak var rName: UILabel!
    @IBOutlet weak var desc: UILabel!
    @IBOutlet weak var startDate: UILabel!
    @IBOutlet weak var endDate: UILabel!
    @IBOutlet weak var endTime: UILabel!
    @IBOutlet weak var startTime: UILabel!
    var date: Date!
    
    override func viewDidLoad(){
        super.viewDidLoad()
        self.ref = Database.database().reference()
        rImg.image = img
        rName.text = newDeal.name
        desc.text = newDeal.dealDescription
        let startD = Date(timeIntervalSince1970: newDeal.startTime!)
        date = startD
        let endD = Date(timeIntervalSince1970: newDeal.endTime!)
        let calendar = NSCalendar.current
        var year = calendar.component(.year, from: startD)
        var month = calendar.component(.month, from: startD)
        var day = calendar.component(.day, from: startD)
        var hour = calendar.component(.hour, from: startD)
        var minute = calendar.component(.minute, from: startD)

        startDate.text = "Start Date: \(month)/\(day)/\(year)"
        startTime.text = "Start Time: \(hour):\(minute)"
        year = calendar.component(.year, from: endD)
        month = calendar.component(.month, from: endD)
        day = calendar.component(.day, from: endD)
        hour = calendar.component(.hour, from: startD)
        minute = calendar.component(.minute, from: startD)
        endDate.text = "End Date: \(month)/\(day)/\(year)"
        startTime.text = "End Time: \(hour):\(minute)"

    }
    @IBAction func submitDeal(_ sender: Any) {
        let deal = [
            "rID": newDeal.id!,
            "rName":  newDeal.name!,
            "dealDesc": newDeal.dealDescription!,
            "rPhotoLoc":   newDeal.photo!,
            "EndTime": newDeal.endTime!,
            "StartTime": newDeal.startTime!,
            "Filter": newDeal.type!
            ] as [String : Any]
        ref = Database.database().reference()
        ref.child("Deals").child(newDeal.id!).setValue(deal)
        self.navigationController?.dismiss(animated: true, completion: nil)
        ref.child("Restaurants").child((Auth.auth().currentUser?.uid)!).child("Followers").observeSingleEvent(of: .value, with: { (snapshot) in
            var users = [String]()
            for entry in snapshot.children {
                let snap = entry as! DataSnapshot
                users.append(snap.value as! String)
            }
            if users.count > 0 {
                OneSignal.postNotification(
                    [
                        "include_player_ids" : users,
                        "headings" : ["en": "New Deal From \(newDeal.name!)!"],
                        "contents" : ["en": "\(newDeal.name!) just posted a new deal! Click here to check it out!"],
                        "data" : ["deal": newDeal.id],
                        "send_after" : "\(self.date)"
                    ],
                    onSuccess: { (notificationData) in
                        print("Success")
                }) { (error) in
                    print(error!)
                }
            }
        })
    
       
    }
    
    @IBAction func prevPressed(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
}
