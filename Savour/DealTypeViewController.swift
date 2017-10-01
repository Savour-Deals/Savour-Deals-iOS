//
//  DealTypeViewController.swift
//  Savour
//
//  Created by Chris Patterson on 9/27/17.
//  Copyright © 2017 Chris Patterson. All rights reserved.
//

import UIKit

class DealTypeViewController: UIViewController {
    var Dealtype: String!
    var resName: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.isNavigationBarHidden = false

        let nav = self.navigationController as! CustomNavBar
        self.resName = nav.resName
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = true
        self.navigationController?.view.backgroundColor = UIColor.clear
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.isNavigationBarHidden = true

    }
    
    @IBAction func exitPressed(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
    @IBAction func typePressed(_ sender: UIButton) {
        Dealtype = sender.currentTitle
        self.performSegue(withIdentifier: "discount", sender: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let VC = segue.destination as! DiscountViewController
        VC.Dealtype = self.Dealtype
        VC.resName = self.resName
    }
    
}
