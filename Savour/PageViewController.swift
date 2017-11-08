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

class OnboardingViewController: UIViewController, UIScrollViewDelegate {

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var pageControl: UIPageControl!
    var frame: CGRect = CGRect(x:0, y:0, width:0, height:0)
    var gradientLayer: CAGradientLayer!

    lazy var arrayVC: [UIViewController] = {
        return [self.VCInstance(name: "WelcomeViewController"), self.VCInstance(name: "DoneViewController")]
    }()
    
    private func VCInstance(name: String) -> UIViewController {
        return (storyboard?.instantiateViewController(withIdentifier: name))!
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
    
    func setupUI(){
        gradientLayer = CAGradientLayer()
        
        gradientLayer.frame = self.view.bounds
        gradientLayer.colors = [#colorLiteral(red: 0.2848863602, green: 0.6698332429, blue: 0.6656947136, alpha: 1).cgColor, #colorLiteral(red: 0.2848863602, green: 0.6698332429, blue: 0.6656947136, alpha: 0.5).cgColor]
        self.view.layer.insertSublayer(gradientLayer, at: 0)
        let statusBar = UIApplication.shared.value(forKey: "statusBar") as! UIView
        statusBar.backgroundColor = #colorLiteral(red: 0.2848863602, green: 0.6698332429, blue: 0.6656947136, alpha: 1)
    }
        
    // MARK : TO CHANGE WHILE CLICKING ON PAGE CONTROL
    @objc func changePage(sender: AnyObject) -> () {
        let x = CGFloat(pageControl.currentPage) * scrollView.frame.size.width
        scrollView.setContentOffset(CGPoint(x:x, y:0), animated: true)
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let pageNumber = round(scrollView.contentOffset.x / scrollView.frame.size.width)
        pageControl.currentPage = Int(pageNumber)
    }

}


class WelcomeViewController: UIViewController{
    @IBOutlet weak var textBox: UILabel!
    
    @IBOutlet weak var svrheight: NSLayoutConstraint!
    @IBOutlet weak var svrImg: UIImageView!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.clear
        textSize()
    }
    
    func textSize(){
        if textBox.frame.height < 220{
            textBox.font = textBox.font.withSize(13.0)
            svrheight.constant = 60.0
            view.layoutIfNeeded()
        }
        
    
    }
    
}

class DoneViewController: UIViewController{
    @IBOutlet weak var continueBtn: UIButton!
    var ref: DatabaseReference!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.clear
        continueBtn.layer.borderWidth = 1.0
        continueBtn.layer.borderColor = UIColor.white.cgColor
        continueBtn.layer.cornerRadius = 5
        ref = Database.database().reference().child("Users").child((Auth.auth().currentUser?.uid)!).child("Onboarded")
    }
    
    @IBAction func continuePressed(_ sender: Any) {
        //let date = "\(Date().timeIntervalSince1970)"
        //ref.setValue(date)
        self.parent?.performSegue(withIdentifier: "tabMain", sender: self)
    }
}
