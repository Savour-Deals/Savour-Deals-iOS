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
import SafariServices


class OnboardingViewController: UIViewController, UIScrollViewDelegate {

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var pageControl: UIPageControl!
    var sender: ViewController!
    
    var frame: CGRect = CGRect(x:0, y:0, width:0, height:0)
    override var prefersStatusBarHidden: Bool{
        return true
    }

    lazy var arrayVC: [UIViewController] = {
        return [ self.VCInstance(name: "PermissionViewController"), self.VCInstance(name: "SwipeViewController")]
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
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = true
        setupUI()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.navigationController?.navigationBar.shadowImage = nil
        self.navigationController?.navigationBar.setBackgroundImage(nil, for: .default)
        self.navigationController?.navigationBar.isTranslucent = true
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
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let pageNumber = round(scrollView.contentOffset.x / scrollView.frame.size.width)
        pageControl.currentPage = Int(pageNumber)
    }

}

class PermissionViewController: UIViewController, CLLocationManagerDelegate{
    var locationManager: CLLocationManager!
    var ref: DatabaseReference!
    var sender = ""
    @IBOutlet weak var continueButton: UIButton!
    
    @IBOutlet weak var privacyButton: UIButton!
    @IBOutlet weak var TOSButton: UIButton!
    @IBOutlet weak var locbutton: UIButton!
    @IBOutlet weak var notiButton: UIButton!
    @IBOutlet weak var locText: UILabel!
    @IBOutlet weak var notiText: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ref = Database.database().reference().child("Users").child((Auth.auth().currentUser?.uid)!).child("Onboarded")
        let state = OneSignal.getPermissionSubscriptionState()
        if state?.permissionStatus.status == .authorized{
            self.notiButton.backgroundColor = UIColor.gray
            self.notiButton.isEnabled = false
        }
        continueButton.layer.cornerRadius = continueButton.frame.height/2
        notiButton.layer.cornerRadius = notiButton.frame.height/2
        locbutton.layer.cornerRadius = locbutton.frame.height/2
        self.locationManager = CLLocationManager()

        locationManager.delegate = self
        let status = CLLocationManager.authorizationStatus()
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            self.locationEnabled()
        case .denied:
            self.locText.text = "To use Savour, turn on location for your device and go to:\n Settings → Savour Deals → Location."
            self.locbutton.backgroundColor = UIColor.gray
            self.locbutton.isUserInteractionEnabled = false
        default:
            locationManager.requestAlwaysAuthorization()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            self.locationEnabled()
        case .denied, .restricted, .notDetermined:
            self.locText.text = "To use Savour, turn on location for your device and go to:\n Settings → Savour Deals → Location."
        }
        self.locbutton.backgroundColor = UIColor.gray
        self.locbutton.isUserInteractionEnabled = false
    }
    
    @IBAction func notiPress(_ sender: Any) {
        OneSignal.promptForPushNotifications(userResponse: { accepted in
            self.notiButton.backgroundColor = UIColor.gray
            self.notiButton.isEnabled = false
            if !accepted{
                self.notiText.text = "To turn on notifications later, go to:\n Settings → Savour Deals → Notifications."
            }
            self.notiButton.isUserInteractionEnabled = false
        })
    }
    @IBAction func locPress(_ sender: Any) {
        let status = CLLocationManager.authorizationStatus()
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            self.locationEnabled()
        default:
            locationManager.requestAlwaysAuthorization()
        }
    }
    @IBAction func openWeb(_ sender: Any) {
        if let sender = sender as? UIButton {
            sender.isEnabled = false
            let title = sender.title(for: .normal)
            var url = "https://www.savourdeals.com"
            if title == "Privacy Policy"{
                url = "https://www.savourdeals.com/terms-of-use/"
            } else if title == "Terms of Use"{
                url = "https://www.savourdeals.com/privacy-policy/"
            }
            let svc = SFSafariViewController(url: URL(string:url)!)
            svc.modalTransitionStyle = UIModalTransitionStyle.coverVertical
            self.present(svc, animated: true, completion: nil)
            sender.isEnabled = true
        }
        
    }
    
    func locationEnabled(){
        self.locbutton.isUserInteractionEnabled = false
        self.locbutton.backgroundColor = UIColor.gray
        self.locationManager!.startUpdatingLocation()
        let parent = self.parent as! OnboardingViewController
        //Setup Deal Data for entire app
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let tabBarController = (appDelegate.window?.rootViewController as? TabBarViewController)!
        DispatchQueue.global().sync {
            tabBarController.dealSetup(completion: { (success) in
                parent.sender.finishLoad(tabBarController: tabBarController)
                parent.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
                parent.navigationController?.navigationBar.shadowImage = UIImage()
                parent.navigationController?.navigationBar.isTranslucent = true
                self.continueButton.isEnabled = true
                self.continueButton.alpha = 1.0
            })
        }
    }
    
    @IBAction func next(_ sender: Any) {
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
    
    @IBOutlet weak var textView: UILabel!
    @IBOutlet weak var blurr: UIView!
    override func viewDidLoad() {
        super.viewDidLoad()
        swipe.image = #imageLiteral(resourceName: "swipe").withRenderingMode(.alwaysTemplate)
        swipe.tintColor = UIColor.white
        textView.text = "Swipe to view all the current deals available.\n\nTap a heart to favorite a deal."

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



