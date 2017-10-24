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
    var Deal: DealData?
    var index = -1
    var fromDetails: Bool?
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
        } else {
            
            let verticalSpace = NSLayoutConstraint(item: self.redeem, attribute: .bottom, relatedBy: .equal, toItem: self.redeem.superview, attribute: .bottom, multiplier: 1.0, constant: -10.0)
            // activate the constraint
            NSLayoutConstraint.activate([verticalSpace])
        }
        moreBtn.layer.cornerRadius = 25
        infoView.layer.cornerRadius = 10
        self.navigationController?.navigationBar.tintColor = UIColor.white
        if (Deal?.redeemed)!{
            self.redeem.isEnabled = false
            redeem.layer.cornerRadius = 25
            self.redeem.setTitle("Already Redeemed!", for: .normal)
            self.redeem.layer.backgroundColor = UIColor.red.cgColor

        }
        else{
            pulsator.start()
            redeem.layer.cornerRadius = 25
        }
        SetupUI()

    }
    
    override func viewWillAppear(_ animated: Bool) {
        if !(Deal?.redeemed)!{
            if !pulsator.isPulsating {
                pulsator.start()
            }
        }
        else{
            if timerLabel.text == ""{
                runTimer()
                if timerLabel.text == "Reedeemed over an hour ago"{
                    self.drawCheck(color: UIColor.red.cgColor)
                }
                else {
                    self.drawCheck(color: UIColor.green.cgColor)
                }
            }
        }
        SetupUI()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        pulsator.stop()
        self.title = ""
    }
    
    func SetupUI(){
        self.title = Deal?.restrauntName
        
        if (fromDetails)!{
            moreBtn.isHidden = true
        }
        else{
            moreBtn.isHidden = false
        }
        dealLbl.text = Deal?.dealDescription
        if photo != ""{
            // Reference to an image file in Firebase Storage
            let storage = Storage.storage()
            let storageref = storage.reference(forURL: photo!)
            
            let imageView: UIImageView = img
            
            // Placeholder image
            let placeholderImage = UIImage(named: "placeholder.jpg")
            
            // Load the image using SDWebImage
            imageView.sd_setImage(with: storageref, placeholderImage: placeholderImage)
        }
        self.img.layer.cornerRadius = img.frame.size.width / 2
        moreBtn.setTitle("See More From " + (Deal?.restrauntName)!, for: .normal)
        imgbound.layer.insertSublayer(pulsator, below: img.layer)
        pulsator.numPulse = 6
        pulsator.radius = 230
        pulsator.backgroundColor = #colorLiteral(red: 0.2848863602, green: 0.6698332429, blue: 0.6656947136, alpha: 1)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "RestaurantDetails" {
            self.title = ""
            let vc = segue.destination as! DetailsViewController
            vc.rID = self.Deal?.restrauntID
        }
    }
    
    @IBAction func authenticatePressed(_ sender: Any) {
            let alert = UIAlertController(title: "Cashier Approval", message: "Give this message to the cashier to redeem your coupon.", preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "Cancel", style: .destructive) { (alert: UIAlertAction!) -> Void in
                
            }
            let approveAction = UIAlertAction(title: "Approve", style: .default) { (alert: UIAlertAction!) -> Void in
                let currTime = Date().timeIntervalSince1970
                let uID = Auth.auth().currentUser?.uid
                let ref = Database.database().reference().child("Redeemed").child((self.Deal?.dealID)!).child(uID!)
                ref.setValue(currTime)
                let followRef = Database.database().reference().child("Restaurants").child((self.Deal?.restrauntID)!).child("Followers").child(uID!)
                followRef.setValue(currTime)
                //set and draw checkmark
                self.redeemIndicator(color: UIColor.green.cgColor)
                
                self.redeem.isEnabled = false
                self.redeem.setTitle("Already Redeemed!", for: .normal)
                self.redeem.layer.backgroundColor = UIColor.red.cgColor
                filteredDeals[self.index].redeemed = true
                filteredDeals[self.index].redeemedTime = currTime
                self.Deal?.redeemedTime = currTime
                self.Deal?.redeemed = true
                if favorites[(filteredDeals[self.index].dealID)!] != nil{
                    favorites.removeValue(forKey: (filteredDeals[self.index].dealID)!)
                }
                self.runTimer()
                if signalID != " "{
                    let followRef = Database.database().reference().child("Restaurants").child((self.Deal?.restrauntID)!).child("Followers").child(uID!)
                    followRef.setValue(signalID)
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
        timerLabel.text = timeString(time: timeSince) //This will update the label
        if (timeSince) > 3600 {
            timerLabel.text = "Reedeemed over an hour ago"
            if self.shapeLayer != nil{
                self.shapeLayer?.strokeColor = UIColor.red.cgColor
            }
            else{
                redeemIndicator(color: UIColor.green.cgColor)
            }
            timer.invalidate()
        }
    }
    
    func drawCheck(color: CGColor){
        //set and draw checkmark
        let path = UIBezierPath()
        path.move(to: CGPoint(x: self.img.frame.origin.x - 60, y: self.img.frame.origin.y - 60))
        path.addLine(to: CGPoint(x: self.img.frame.origin.x , y: self.img.frame.origin.y + 10))
        path.addLine(to: CGPoint(x: self.img.frame.origin.x + 80, y: self.img.frame.origin.y - 120))
        let shapeLayer = CAShapeLayer()
        shapeLayer.fillColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0).cgColor
        shapeLayer.strokeColor = color
        shapeLayer.lineWidth = 10
        shapeLayer.path = path.cgPath
        // animate it
        self.img.layer.addSublayer(shapeLayer)
        let animation = CABasicAnimation(keyPath: "strokeEnd")
        animation.fromValue = 0
        animation.duration = 1
        shapeLayer.add(animation, forKey: "MyAnimation")
        
        // save shape layer
        self.shapeLayer = shapeLayer
        self.img.alpha = 0.6
    }
    
    func redeemIndicator(color: CGColor){
        //self.img.alpha = 0.6
        pulsator.backgroundColor = color
    }

    
    @objc func updateTimer() {
        let timeSince = Date().timeIntervalSince1970 - (Deal?.redeemedTime)!
        timerLabel.text = timeString(time: timeSince) //This will update the label.
        if (timeSince) > 3600 {
            timerLabel.text = "Reedeemed over an hour ago"
            if self.shapeLayer != nil{
                self.shapeLayer?.strokeColor = UIColor.red.cgColor
            }
            else{
                redeemIndicator(color: UIColor.green.cgColor)
            }
            timer.invalidate()
        }
    }
    
    @IBAction func infoPressed(_ sender: Any) {
        self.view.bringSubview(toFront: blurView)

        self.view.bringSubview(toFront: infoView)
        redeem.isEnabled = false
        moreBtn.isEnabled = false
        infoView.isHidden = false
        blurView.isHidden = false
    }
    
    @IBAction func infoDismiss(_ sender: Any) {
        redeem.isEnabled = true
        moreBtn.isEnabled = true
        infoView.isHidden = true
        blurView.isHidden = true

    }
    func timeString(time:TimeInterval)->String{
        let minutes = Int(time) / 60 % 60
        let seconds = Int(time) % 60
        return String(format:"Redeemed %02i minutes %02i seconds ago", minutes, seconds)
    }
}
