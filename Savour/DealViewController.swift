//
//  DealViewController.swift
//  Savour
//
//  Created by Chris Patterson on 8/9/17.
//  Copyright © 2017 Chris Patterson. All rights reserved.
//

import UIKit
import Pulsator
import FirebaseDatabase
import FirebaseStorage
import FirebaseAuth
import OneSignal



class DealViewController: UIViewController {

    @IBOutlet weak var blurView: UIVisualEffectView!
    var Deal: DealData!
    var fromDetails: Bool!
    let pulsator = Pulsator()
    var from: String?
    var handle: AuthStateDidChangeListenerHandle?
    var ref: DatabaseReference!
    @IBOutlet weak var timerLabel: UILabel!
    var seconds = 60
    var timer = Timer()
    var isTimerRunning = false
    var timerStartTime: Int!
    weak var shapeLayer: CAShapeLayer?
    
    @IBOutlet weak var restaurantLabel: UILabel!
    @IBOutlet weak var dealCode: UILabel!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var infoView: UIView!
    @IBOutlet var redeemedView: UIView!
    @IBOutlet weak var redeem: UIButton!
    @IBOutlet weak var dealLbl: UILabel!
    @IBOutlet weak var imgbound: UIImageView!
    @IBOutlet weak var moreBtn: UIButton!
    @IBOutlet weak var img: UIImageView!
    @IBOutlet var DealView: UIView!
    var photo: String!
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    @IBAction func backSwipe(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 11, *) {
            let verticalSpace = NSLayoutConstraint(item: self.redeem, attribute: .bottom, relatedBy: .equal, toItem: self.DealView.safeAreaLayoutGuide, attribute: .bottom, multiplier: 1.0, constant: -10.0)
            // activate the constraint
            NSLayoutConstraint.activate([verticalSpace])
        }else {
            let verticalSpace = NSLayoutConstraint(item: self.redeem, attribute: .bottom, relatedBy: .equal, toItem: self.redeem.superview, attribute: .bottom, multiplier: 1.0, constant: -10.0)
            // activate the constraint
            NSLayoutConstraint.activate([verticalSpace])
        }
        SetupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        SetupUI()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.title = ""
    }
    
    func SetupUI(){
        pulsator.start()
        
        self.navigationController?.navigationBar.tintColor = UIColor.white
        let imageView = UIImageView(image: UIImage(named: "Savour_White"))
        imageView.contentMode = UIViewContentMode.scaleAspectFit
        let titleView = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 40))
        imageView.frame = titleView.bounds
        titleView.addSubview(imageView)
        self.navigationItem.titleView = titleView

        moreBtn.layer.cornerRadius = 25
        infoView.layer.cornerRadius = 10
        textView.setContentOffset(CGPoint.zero, animated: false)
        
        if (fromDetails)!{
            moreBtn.isHidden = true
        }
        else{
            moreBtn.isHidden = false
        }
        restaurantLabel.text = Deal?.restrauntName
        dealLbl.text = Deal?.dealDescription
        if photo != ""{
            // Reference to an image file in Firebase Storage
            let storage = Storage.storage()
            let storageref = storage.reference(forURL: photo!)
            
            let imageView: UIImageView = img
            
            // Placeholder image
            let placeholderImage = UIImage(named: "placeholder.jpg")
            
            // Load the image using SDWebImage
            imageView.sd_setImage(with: storageref, placeholderImage: placeholderImage, completion: { (_, err,_ , _) in
                self.img.layer.cornerRadius = self.img.frame.size.height/2
            })
        }
        moreBtn.setTitle("See More From " + (Deal?.restrauntName)!, for: .normal)
        imgbound.layer.insertSublayer(pulsator, below: imgbound.layer)
        pulsator.numPulse = 6
        pulsator.radius = 230
        if (Deal?.redeemed)!{
            self.redeem.isEnabled = false
            redeem.layer.cornerRadius = 25
            self.redeem.setTitle("Already Redeemed!", for: .normal)
            self.redeem.layer.backgroundColor = UIColor.red.cgColor
            if timerLabel.text == ""{
                runTimer()
            }
            if timerLabel.text == "Reedeemed over half an hour ago"{
                self.redeemIndicator(color: UIColor.red.cgColor)
            }
            else{
                self.redeemIndicator(color: UIColor.green.cgColor)
                self.dealCode.text = self.Deal?.dealCode
            }
        }
        else{
            pulsator.backgroundColor = #colorLiteral(red: 0.2848863602, green: 0.6698332429, blue: 0.6656947136, alpha: 1)
            redeem.layer.cornerRadius = 25
        }
        textView.contentOffset.y = 0
        if !(Deal?.valid)!{
            self.redeem.setTitle("Deal Not Active", for: .normal)
            self.dealCode.text = Deal.validHours
            pulsator.backgroundColor = UIColor.red.cgColor
            self.redeem.isEnabled = false
            self.redeem.layer.backgroundColor = UIColor.red.cgColor
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "RestaurantDetails" {
            self.title = ""
            let vc = segue.destination as! RestaurantViewController
            vc.rID = self.Deal?.restrauntID
        }
    }
    
    @IBAction func authenticatePressed(_ sender: Any) {
        let alert = UIAlertController(title: "Vendor Approval", message: "This deal is intended for one person only. \n\nShow this message to the vendor to redeem your coupon. \n\nThe deal is not guaranteed if the vendor does not see this message.", preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "Cancel", style: .destructive) { (alert: UIAlertAction!) -> Void in
                
            }
            let approveAction = UIAlertAction(title: "Approve", style: .default) { (alert: UIAlertAction!) -> Void in
                let currTime = Date().timeIntervalSince1970
                let uID = Auth.auth().currentUser?.uid
                let ref = Database.database().reference().child("Deals").child((self.Deal?.dealID)!).child("redeemed").child(uID!)
                ref.setValue(currTime)
                //set and draw checkmark
                self.redeemIndicator(color: UIColor.green.cgColor)
                
                self.redeem.isEnabled = false
                self.redeem.setTitle("Already Redeemed!", for: .normal)
                self.redeem.layer.backgroundColor = UIColor.red.cgColor
                self.Deal.redeemed = true
                self.self.Deal.redeemedTime = currTime
                self.Deal?.redeemedTime = currTime
                self.Deal?.redeemed = true
                ref.child("Users").child(uID!).child("Favorites").child(self.Deal.dealID!).removeValue()
                if self.Deal?.dealCode != ""{
                    self.dealCode.textColor = UIColor.black
                    self.dealCode.text = self.Deal?.dealCode
                }
                self.runTimer()
                let status: OSPermissionSubscriptionState = OneSignal.getPermissionSubscriptionState()
                if status.subscriptionStatus.userId != " "{
                    let followRef = Database.database().reference().child("Restaurants").child((self.Deal?.restrauntID)!).child("Followers").child(uID!)
                    followRef.setValue(status.subscriptionStatus.userId)

                }
            }
            alert.addAction(cancelAction)
            alert.addAction(approveAction)
            self.present(alert, animated: true, completion:nil)
    }
    
    
    
    //Timer functions
    func runTimer() {
        timer = Timer.scheduledTimer(timeInterval: 1, target: self,   selector: (#selector(self.updateTimer)), userInfo: nil, repeats: true)
        let timeSince = Date().timeIntervalSince1970 - (Deal?.redeemedTime)!
        self.dealCode.textColor = UIColor.black
        timerLabel.text = timeString(time: timeSince) //This will update the label
        if (timeSince) > 1800 {
            dealCode.text = ""
            timerLabel.text = "Reedeemed over half an hour ago"
            redeemIndicator(color: UIColor.red.cgColor)
            timer.invalidate()
        }
    }
    
    
    func redeemIndicator(color: CGColor){
        //self.img.alpha = 0.6
        pulsator.backgroundColor = color
    }

    
    @objc func updateTimer() {
        let timeSince = Date().timeIntervalSince1970 - (Deal?.redeemedTime)!
        timerLabel.text = timeString(time: timeSince) //This will update the label.
        if (timeSince) > 1800 {
            dealCode.text = ""
            timerLabel.text = "Reedeemed over half an hour ago"
            redeemIndicator(color: UIColor.red.cgColor)
            timer.invalidate()
        }
    }
    
    @IBAction func infoPressed(_ sender: Any) {
        self.redeem.isEnabled = false
        self.moreBtn.isEnabled = false
        self.infoView.isHidden = false
        self.blurView.isHidden = false
        self.view.bringSubview(toFront: blurView)
        self.view.bringSubview(toFront: infoView)
        var scaleTrans = CGAffineTransform(scaleX: 0.0, y: 0.0)
        self.blurView.transform = scaleTrans
        self.infoView.transform = scaleTrans
        scaleTrans = CGAffineTransform(scaleX: 1, y: 1)
        UIView.animate(withDuration: 0.8,delay: 0, usingSpringWithDamping:0.6,
            initialSpringVelocity:1.0,  options: .curveEaseInOut, animations: {
            self.blurView.transform = scaleTrans
            self.infoView.transform = scaleTrans
        }, completion: nil)
       
    }
    
    @IBAction func infoDismiss(_ sender: Any) {
        let scaleTrans = CGAffineTransform(scaleX: 0, y: 0)
        UIView.animate(withDuration: 0.8,delay: 0, usingSpringWithDamping:0.6,
                       initialSpringVelocity:1.0,  options: .curveEaseInOut, animations: {
                        self.blurView.transform = scaleTrans
                        self.infoView.transform = scaleTrans
        }, completion: {(value: Bool) in
            self.redeem.isEnabled = true
            self.moreBtn.isEnabled = true
            self.infoView.isHidden = true
            self.blurView.isHidden = true
        })
        

    }
    func timeString(time:TimeInterval)->String{
        let minutes = Int(time) / 60 % 60
        let seconds = Int(time) % 60
        return String(format:"Redeemed %02i minutes %02i seconds ago", minutes, seconds)
    }
}

