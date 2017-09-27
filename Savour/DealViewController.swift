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
import FirebaseAuth



class DealViewController: UIViewController {

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

    
    @IBOutlet var redeemedView: UIView!
    @IBOutlet weak var redeem: UIButton!
    @IBOutlet weak var dealLbl: UILabel!
    @IBOutlet weak var imgbound: UIImageView!
    @IBOutlet weak var moreBtn: UIButton!
    @IBOutlet weak var img: UIImageView!
    @IBOutlet var DealView: UIView!
    var newImg: UIImage!
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    @IBAction func backSwipe(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        if #available(iOS 11, *) {
            let verticalSpace = NSLayoutConstraint(item: self.redeem, attribute: .bottom, relatedBy: .equal, toItem: self.view.safeAreaLayoutGuide, attribute: .bottom, multiplier: 1, constant: 1)
            // activate the constraint
            NSLayoutConstraint.activate([verticalSpace])
        } else {
            let verticalSpace = NSLayoutConstraint(item: self.redeem, attribute: .bottom, relatedBy: .equal, toItem: self.view.superview, attribute: .bottom, multiplier: 1, constant:1)
            // activate the constraint
            NSLayoutConstraint.activate([verticalSpace])
        }
    
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = Deal?.restrauntName
        if (Deal?.redeemed)!{
            self.redeem.isEnabled = false
            self.redeem.backgroundColor = UIColor.red
            self.redeem.setTitle("Already Redeemed!", for: .normal)
            self.redeem.alpha = 0.6
            
        }
        else{
            pulsator.start()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        SetupUI()
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
    
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        pulsator.stop()
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
        img.image = newImg
        self.img.layer.cornerRadius = img.frame.size.width / 2
        moreBtn.setTitle("See More From " + (Deal?.restrauntName)!, for: .normal)
        imgbound.layer.insertSublayer(pulsator, below: img.layer)
        pulsator.numPulse = 4
        pulsator.radius = 230
        pulsator.backgroundColor = redeem.backgroundColor?.cgColor
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "RestaurantDetails" {
            self.title = ""
            let vc = segue.destination as! DetailsViewController
            vc.Deal = Deal
        }
    }
    
    @IBAction func authenticatePressed(_ sender: Any) {        let alert = UIAlertController(title: "Notice!", message: "You must use the coupon on the day that you redeem it! By selecting Redeem below you aknowledge that you understand the discount must be used today. \n\nIf you do not want to use it today, but intend to use another day, simply favorite the discount and it will be saved under your Starred section. \n\nBe aware that even if you star a discount you must still redeem it and use it before the expiry time.", preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: .destructive) { (alert: UIAlertAction!) -> Void in
            
        }
        let approveAction = UIAlertAction(title: "Redeem Today!", style: .default) { (alert: UIAlertAction!) -> Void in
            let alert = UIAlertController(title: "Cashier Approval", message: "Give this message to the cashier to redeem your coupon.", preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "Cancel", style: .destructive) { (alert: UIAlertAction!) -> Void in
                
            }
            let approveAction = UIAlertAction(title: "Approve", style: .default) { (alert: UIAlertAction!) -> Void in
                let ref = Database.database().reference().child("Redeemed").child((self.Deal?.dealID)!)
                let currTime = Date().timeIntervalSince1970
                let uID = Auth.auth().currentUser?.uid
                var userRedemption = Dictionary<String, String>()
                userRedemption[uID!] = String(currTime)
                ref.setValue(userRedemption)
                
                //set and draw checkmark
                self.drawCheckFix(color: UIColor.green.cgColor)
                
                self.redeem.isEnabled = false
                self.redeem.backgroundColor = UIColor.red
                self.redeem.setTitle("Already Redeemed!", for: .normal)
                self.redeem.alpha = 0.6
                self.pulsator.stop()
                mainVC?.filteredDeals[self.index].redeemed = true
                mainVC?.filteredDeals[self.index].redeemedTime = currTime
                self.Deal?.redeemedTime = currTime
                self.Deal?.redeemed = true
                if favorites[(mainVC?.filteredDeals[self.index].dealID)!] != nil{
                    favorites.removeValue(forKey: (mainVC?.filteredDeals[self.index].dealID)!)
                }
                self.runTimer()
            }
            alert.addAction(cancelAction)
            alert.addAction(approveAction)
            self.present(alert, animated: true, completion:nil)
        }
        alert.addAction(cancelAction)
        alert.addAction(approveAction)
        present(alert, animated: true, completion:nil)
    }
    
    
    
    //Timer functions
    func runTimer() {
        timer = Timer.scheduledTimer(timeInterval: 1, target: self,   selector: (#selector(self.updateTimer)), userInfo: nil, repeats: true)
        let timeSince = Date().timeIntervalSince1970 - (Deal?.redeemedTime)!
        timerLabel.text = timeString(time: timeSince) //This will update the label
        if (timeSince) > 3600 {
            timerLabel.text = "Reedeemed over an hour ago"
            self.shapeLayer?.strokeColor = UIColor.red.cgColor
            timer.invalidate()
        }
    }
    
    func drawCheck(color: CGColor){
        //set and draw checkmark
        let path = UIBezierPath()
        path.move(to: CGPoint(x: self.img.frame.origin.x - 60, y: self.img.frame.origin.y - 60))
        path.addLine(to: CGPoint(x: self.img.frame.origin.x , y: self.img.frame.origin.y + 10))
        path.addLine(to: CGPoint(x: self.img.frame.origin.x + 80, y: self.img.frame.origin.y - 140))
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
    
    func drawCheckFix(color: CGColor){
        //set and draw checkmark - This fixes problem with drawing initially after redemption
        let path = UIBezierPath()
        path.move(to: CGPoint(x: self.img.frame.origin.x - 80, y: self.img.frame.origin.y - 60))
        path.addLine(to: CGPoint(x: self.img.frame.origin.x-20, y: self.img.frame.origin.y))
        path.addLine(to: CGPoint(x: self.img.frame.origin.x + 60, y: self.img.frame.origin.y - 140))
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

    
    @objc func updateTimer() {
        let timeSince = Date().timeIntervalSince1970 - (Deal?.redeemedTime)!
        timerLabel.text = timeString(time: timeSince) //This will update the label.
        if (timeSince) > 3600 {
            timerLabel.text = "Reedeemed over an hour ago"
            self.shapeLayer?.strokeColor = UIColor.red.cgColor
            timer.invalidate()
        }
    }
    
    func timeString(time:TimeInterval)->String{
        let minutes = Int(time) / 60 % 60
        let seconds = Int(time) % 60
        return String(format:"Redeemed %02i minutes %02i seconds ago", minutes, seconds)
    }
}
