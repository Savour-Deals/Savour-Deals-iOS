//
//  PageViewController.swift
//  Savour
//
//  Created by Chris Patterson on 10/9/17.
//  Copyright © 2017 Chris Patterson. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase
import OneSignal
import CoreLocation

class OnboardingViewController: UIViewController, UIScrollViewDelegate {

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var pageControl: UIPageControl!
    var sender: ViewController!
    
    var frame: CGRect = CGRect(x:0, y:0, width:0, height:0)
    override var prefersStatusBarHidden: Bool{
        return true
    }

    lazy var arrayVC: [UIViewController] = {
        return [ self.VCInstance(name: "WorksViewController"), self.VCInstance(name: "NotificationViewController"),self.VCInstance(name: "LocationViewController"),self.VCInstance(name: "SwipeViewController")]
    }()
    
    private func VCInstance(name: String) -> UIViewController {
        return (storyboard?.instantiateViewController(withIdentifier: name))!
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = true
        
        setupUI()
        
        scrollView.delegate = self
        scrollView.isPagingEnabled = true
        
        self.view.addSubview(scrollView)
        for index in 0..<arrayVC.count{
            frame.origin.x = self.view.frame.size.width * CGFloat(index)
            frame.size = self.scrollView.frame.size
            let vc = arrayVC[index]
            vc.view.frame = frame
            vc.willMove(toParentViewController: self)
            self.addChildViewController(vc)
            vc.didMove(toParentViewController: self)
            scrollView.addSubview(vc.view)
        }
        pageControl.numberOfPages = arrayVC.count
        
        self.scrollView.contentSize = CGSize(width: self.view.frame.size.width * CGFloat(arrayVC.count), height: self.scrollView.frame.size.height)
        pageControl.addTarget(self, action: #selector(self.changePage(sender:)), for: UIControlEvents.valueChanged)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.navigationController?.navigationBar.shadowImage = nil
        self.navigationController?.navigationBar.setBackgroundImage(nil, for: .default)
        self.navigationController?.navigationBar.isTranslucent = true
        sender.setup()
    }
    func setupUI(){
        
        let statusBar = UIApplication.shared.value(forKey: "statusBar") as! UIView
        statusBar.backgroundColor = #colorLiteral(red: 0.9999960065, green: 1, blue: 1, alpha: 0)
    }
        
    // MARK : TO CHANGE WHILE CLICKING ON PAGE CONTROL
    @objc func changePage(sender: AnyObject) -> () {
        let x = CGFloat(pageControl.currentPage) * scrollView.frame.size.width
        scrollView.setContentOffset(CGPoint(x:x, y:0), animated: true)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        scrollView.contentOffset.y = 0.0
        let pageNumber = round(scrollView.contentOffset.x / scrollView.frame.size.width)
        if Int(pageNumber) > 0{
            scrollView.isScrollEnabled = false
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let pageNumber = round(scrollView.contentOffset.x / scrollView.frame.size.width)
        pageControl.currentPage = Int(pageNumber)
    }

}




class WorksViewController: UIViewController{

    @IBOutlet weak var svrheight: NSLayoutConstraint!
    @IBOutlet weak var svrImg: UIImageView!
    var gradientLayer: CAGradientLayer!

    override func viewDidLoad() {
        super.viewDidLoad()
//        gradientLayer = CAGradientLayer()
//        gradientLayer.frame = self.view.bounds
//        gradientLayer.colors = [#colorLiteral(red: 0.2848863602, green: 0.6698332429, blue: 0.6656947136, alpha: 0.3023598031).cgColor, #colorLiteral(red: 0.2848863602, green: 0.6698332429, blue: 0.6656947136, alpha: 0).cgColor]
//        self.view.layer.insertSublayer(gradientLayer, at: 0)
//self.view.backgroundColor = UIColor.clear
        textSize()
    }
    
    
    func textSize(){
        if UIDevice().userInterfaceIdiom == .phone {
            let height = UIScreen.main.nativeBounds.height
            if height > 1900{
                print("largeBoi")
            }else if height > 1136{
                svrheight.constant = 150.0
                view.layoutIfNeeded()
                
            }else{
                svrheight.constant = 100.0
                view.layoutIfNeeded()
            }
        }
        
    }
}

class LocationViewController: UIViewController, CLLocationManagerDelegate{
    var gradientLayer: CAGradientLayer!

    var ref: DatabaseReference!
    @IBOutlet weak var declineLocation: UIButton!
    var locationManager: CLLocationManager!
    @IBOutlet weak var acceptedLocation: UIButton!
    var sender = ""
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        gradientLayer = CAGradientLayer()
//        gradientLayer.frame = self.view.bounds
//        gradientLayer.colors = [#colorLiteral(red: 0.2848863602, green: 0.6698332429, blue: 0.6656947136, alpha: 0.3023598031).cgColor, #colorLiteral(red: 0.2848863602, green: 0.6698332429, blue: 0.6656947136, alpha: 0).cgColor]
//        self.view.layer.insertSublayer(gradientLayer, at: 0)
        let statusBar = UIApplication.shared.value(forKey: "statusBar") as! UIView
        statusBar.backgroundColor = #colorLiteral(red: 0.9999960065, green: 1, blue: 1, alpha: 0)
        //self.view.backgroundColor = UIColor.clear
        locationManager = CLLocationManager()
        acceptedLocation.layer.cornerRadius = acceptedLocation.frame.height/2
        declineLocation.layer.cornerRadius = declineLocation.frame.height/2
        ref = Database.database().reference().child("Users").child((Auth.auth().currentUser?.uid)!).child("Onboarded")
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        next()
    }
    

    @IBAction func acceptedLocation(_ sender: Any) {
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
    }
    @IBAction func declinedLocation(_ sender: Any) {
        next()
    }
    
    func next(){
        if self.sender == "home"{
            dismiss(animated: true, completion: nil)
        }else{
            let parent = self.parent as! OnboardingViewController
            parent.sender.setup()
            parent.pageControl.currentPage = parent.pageControl.currentPage + 1
            parent.changePage(sender: self)
        }
    }
    
}

class NotificationViewController: UIViewController{
    
    @IBOutlet weak var declinedNoti: UIButton!
    @IBOutlet weak var acceptNoti: UIButton!
    var gradientLayer: CAGradientLayer!

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        gradientLayer = CAGradientLayer()
//        gradientLayer.frame = self.view.bounds
//        gradientLayer.colors = [#colorLiteral(red: 0.2848863602, green: 0.6698332429, blue: 0.6656947136, alpha: 0.3023598031).cgColor, #colorLiteral(red: 0.2848863602, green: 0.6698332429, blue: 0.6656947136, alpha: 0).cgColor]
//        self.view.layer.insertSublayer(gradientLayer, at: 0)
//        self.view.backgroundColor = UIColor.clear
        acceptNoti.layer.cornerRadius = acceptNoti.frame.height/2
        declinedNoti.layer.cornerRadius = declinedNoti.frame.height/2
    }
   
    @IBAction func acceptNoti(_ sender: Any) {
        OneSignal.promptForPushNotifications(userResponse: { accepted in
            print("User accepted notifications: \(accepted)")
            self.next()
        })
    }
    
    @IBAction func declinedNoti(_ sender: Any) {
        next()
    }
    
    func next(){
        let parent = self.parent as! OnboardingViewController
        parent.pageControl.currentPage = parent.pageControl.currentPage + 1
        parent.changePage(sender: self)
    }
    
}

class SwipeViewController: UIViewController{
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    @IBOutlet weak var swipe: UIImageView!
    
    @IBOutlet weak var blurr: UIView!
    @IBOutlet weak var done: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        done.layer.cornerRadius = done.frame.height/2
        swipe.image = #imageLiteral(resourceName: "swipe").withRenderingMode(.alwaysTemplate)
        swipe.tintColor = UIColor.white

    }
    override func viewDidAppear(_ animated: Bool) {
        let orgY = self.view.center.y - self.view.frame.height/4
        self.swipe.center.y = self.view.center.y + 100
        UIView.animate(withDuration: 1.5, delay: 0.2, options: .repeat, animations: {
            self.swipe.center.y = orgY
        }, completion: nil)
    }
    
    @IBAction func dismiss(_ sender: Any) {
        Database.database().reference().child("Users").child((Auth.auth().currentUser?.uid)!).child("Onboarded").setValue("true")
        dismiss(animated: false, completion: nil)
    }
    
}



