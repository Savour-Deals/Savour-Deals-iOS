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
import CoreLocation
import FirebaseFunctions



class DealViewController: UIViewController,CLLocationManagerDelegate {

    @IBOutlet weak var blurView: UIVisualEffectView!
    var Deal: DealData!
    var dealsData: DealsData!
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
    var thisVendor: VendorData?
    var locationManager: CLLocationManager!
    var userLocation: CLLocation!
    lazy var functions = Functions.functions()

    
    @IBOutlet weak var restaurantLabel: UILabel!
    @IBOutlet weak var code: UILabel!
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
        self.locationManager = CLLocationManager()
        locationManager!.startUpdatingLocation()
        if #available(iOS 11, *) {
            let verticalSpace = NSLayoutConstraint(item: self.redeem, attribute: .bottom, relatedBy: .equal, toItem: self.DealView.safeAreaLayoutGuide, attribute: .bottom, multiplier: 1.0, constant: -10.0)
            // activate the constraint
            NSLayoutConstraint.activate([verticalSpace])
        }else {
            let verticalSpace = NSLayoutConstraint(item: self.redeem, attribute: .bottom, relatedBy: .equal, toItem: self.redeem.superview, attribute: .bottom, multiplier: 1.0, constant: -10.0)
            // activate the constraint
            NSLayoutConstraint.activate([verticalSpace])
        }
        ref = Database.database().reference()
        SetupUI()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        img.layer.cornerRadius = img.frame.width / 2
        redeem.layer.cornerRadius = redeem.frame.height/2
        moreBtn.layer.cornerRadius = moreBtn.frame.height/2
        img.clipsToBounds = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        SetupUI()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.title = ""
    }
    
    func SetupUI(){
        pulsator.start()
        self.userLocation = self.locationManager.location!
        self.thisVendor = updateDistance(location: self.userLocation, vendor: self.thisVendor!)
        self.navigationController?.navigationBar.tintColor = UIColor.white
        let imageView = UIImageView(image: UIImage(named: "Savour_White"))
        imageView.contentMode = UIView.ContentMode.scaleAspectFit
        let titleView = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 40))
        imageView.frame = titleView.bounds
        titleView.addSubview(imageView)
        self.navigationItem.titleView = titleView

        infoView.layer.cornerRadius = 10
        textView.setContentOffset(CGPoint.zero, animated: false)
        
        if (fromDetails)!{
            moreBtn.isHidden = true
        }
        else{
            moreBtn.isHidden = false
        }
        restaurantLabel.text = Deal?.name
        dealLbl.text = Deal?.dealDescription
        if Deal.id != "SVR"{
            if photo != ""{
                let imageView: UIImageView = img
                
                // Load the image using SDWebImage
                imageView.sd_setImage(with: URL(string:photo!), completed: { (img, err, typ, ref) in
                    
                })
            }
        }else{
            img.image = UIImage(named: "icon")
        }
        moreBtn.setTitle("See More From " + (Deal?.name)!, for: .normal)
        imgbound.layer.insertSublayer(pulsator, below: imgbound.layer)
        pulsator.numPulse = 6
        if UIDevice().userInterfaceIdiom == .phone {
            //if iPhone, make radius fit small screen
            self.pulsator.radius = 230
        }else if UIDevice().userInterfaceIdiom == .pad{
            //if iPad, make large radius to cover screen and not be hidden behind image
            self.pulsator.radius = 600
        }
        
        if (Deal?.redeemed)!{
            self.redeem.isEnabled = false
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
                self.code.text = self.Deal?.code
            }
        }else if let rest = self.thisVendor?.distanceMiles, rest>0.1 && (Deal?.active)!{
            self.redeem.isEnabled = true
            pulsator.backgroundColor = #colorLiteral(red: 0.2848863602, green: 0.6698332429, blue: 0.6656947136, alpha: 1)
            self.redeem.setTitle("Go to Location to Redeem", for: .normal)
            self.redeem.layer.backgroundColor = UIColor.red.cgColor
        }else if !(Deal?.active)!{
            pulsator.backgroundColor = UIColor.red.cgColor
            self.redeem.setTitle("Deal Not Active", for: .normal)
            self.code.text = "This deal is valid " + Deal.inactiveString! + "."
            self.redeem.layer.backgroundColor = UIColor.red.cgColor
            self.redeem.isEnabled = false
            self.redeemIndicator(color: UIColor.red.cgColor)
        }else{
            pulsator.backgroundColor = #colorLiteral(red: 0.2848863602, green: 0.6698332429, blue: 0.6656947136, alpha: 1)
        }
        textView.contentOffset.y = 0
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "RestaurantDetails" {
            self.title = ""
            let vc = segue.destination as! RestaurantViewController
            vc.thisVendor = self.thisVendor
            vc.dealsData = self.dealsData
        }
    }
    
    func openInGoogleMaps(){
        let baseUrl: String = "comgooglemaps://?daddr="
        let encodedName: String = (self.thisVendor?.address?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)!
        let finalUrl = baseUrl + encodedName
        if let url = URL(string: finalUrl){
            UIApplication.shared.openURL(url)
        }
    }
    
    func openInAppleMaps(){
        let baseUrl: String = "http://maps.apple.com/?q="
        let encodedName: String = (self.thisVendor?.address?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)!
        let finalUrl = baseUrl + encodedName
        if let url = URL(string: finalUrl){
            UIApplication.shared.openURL(url)
        }
    }
    
    @IBAction func authenticatePressed(_ sender: Any) {
        if self.redeem.title(for: .normal) == "Go to Location to Redeem"{
            if (UIApplication.shared.canOpenURL(URL(string:"comgooglemaps://")!)) {
                let optionMenu = UIAlertController(title: nil, message: "Open With", preferredStyle: .actionSheet)
                let googleAction = UIAlertAction(title: "Google Maps", style: .default, handler: {
                    (alert: UIAlertAction!) -> Void in
                    self.openInGoogleMaps()
                })
                let appleAction = UIAlertAction(title: "Apple Maps", style: .default, handler: {
                    (alert: UIAlertAction!) -> Void in
                    self.openInAppleMaps()
                })
                let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: {
                    (alert: UIAlertAction!) -> Void in
                })
                optionMenu.addAction(googleAction)
                optionMenu.addAction(appleAction)
                optionMenu.addAction(cancelAction)
                
                self.present(optionMenu, animated: true, completion: nil)
            }else{
                self.openInAppleMaps()
            }
        }else{
            let alert = UIAlertController(title: "Vendor Approval", message: "This deal is intended for one person only. \n\nShow this message to the vendor to redeem your coupon. \n\nThe deal is not guaranteed if the vendor does not see this message.", preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "Cancel", style: .destructive) { (alert: UIAlertAction!) -> Void in
                    
                }
                let approveAction = UIAlertAction(title: "Approve", style: .default) { (alert: UIAlertAction!) -> Void in
                    let currTime = Int(Date().timeIntervalSince1970)
                    let uID = Auth.auth().currentUser?.uid
                    
                    //Note redemption time
                    let redeemRef = self.ref.child("Deals").child((self.Deal?.id)!).child("redeemed").child(uID!)
                    redeemRef.setValue(currTime)
                    
                    //set and draw checkmark
                    self.redeemIndicator(color: UIColor.green.cgColor)
                    
                    self.redeem.isEnabled = false
                    self.redeem.setTitle("Already Redeemed!", for: .normal)
                    self.redeem.layer.backgroundColor = UIColor.red.cgColor
                    self.Deal?.redeemedTime = currTime
                    self.Deal?.redeemed = true
                    self.ref.child("Users").child(uID!).child("favorites").child(self.Deal.id!).removeValue()
                    if self.Deal?.code != ""{
                        self.code.textColor = UIColor.black
                        self.code.text = self.Deal?.code
                    }
                    self.runTimer()
                    let status: OSPermissionSubscriptionState = OneSignal.getPermissionSubscriptionState()
                    if status.subscriptionStatus.userId != " "{
                        //Redundant following for user and rest
                        OneSignal.sendTags([(self.thisVendor?.id)! : "true"])
                        self.ref.child("Vendors").child((self.thisVendor?.id)!).child("followers").child(uID!).setValue(status.subscriptionStatus.userId)
                        self.ref.child("Users").child(uID!).child("following").child((self.thisVendor?.id!)!).setValue(true)
                    }
                    StoreReviewHelper().requestReview()
                }
                alert.addAction(cancelAction)
                alert.addAction(approveAction)
                self.present(alert, animated: true, completion:nil)
        }
    }
    
    //Timer functions
    func runTimer() {
        timer = Timer.scheduledTimer(timeInterval: 1, target: self,   selector: (#selector(self.updateTimer)), userInfo: nil, repeats: true)
        let timeSince = Int(Date().timeIntervalSince1970) - (Deal?.redeemedTime)!
        self.code.textColor = UIColor.black
        timerLabel.text = timeString(time: timeSince) //This will update the label
        if (timeSince) > 1800 {
            code.text = self.Deal.code
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
        let timeSince = Int(Date().timeIntervalSince1970) - (Deal?.redeemedTime)!
        timerLabel.text = timeString(time: timeSince) //This will update the label.
        if (timeSince) > 1800 {
            code.text = ""
            timerLabel.text = "Reedeemed over half an hour ago"
            redeemIndicator(color: UIColor.red.cgColor)
            timer.invalidate()
        }
    }
    
    @IBAction func infoPressed(_ sender: Any) {
        self.moreBtn.isEnabled = false
        self.infoView.isHidden = false
        self.blurView.isHidden = false
        self.view.bringSubviewToFront(blurView)
        self.view.bringSubviewToFront(infoView)
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
            self.moreBtn.isEnabled = true
            self.infoView.isHidden = true
            self.blurView.isHidden = true
        })
        

    }
    func timeString(time:Int)->String{
        let minutes = time / 60 % 60
        let seconds = time % 60
        return String(format:"Redeemed %02i minutes %02i seconds ago", minutes, seconds)
    }
}

