//
//  DealViewController.swift
//  Savour
//
//  Created by Chris Patterson on 8/9/17.
//  Copyright © 2017 Chris Patterson. All rights reserved.
//

import UIKit
import Pulsator



class DealViewController: UIViewController {

    var Deal: DealData?
    var fromDetails: Bool?
    let pulsator = Pulsator()
    
    
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        pulsator.start()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        SetupUI()
        
    }
    
    func SetupUI(){
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
            let vc = segue.destination as! DetailsViewController
            vc.Deal = Deal
        }

    }
    
    @IBAction func authenticatePressed(_ sender: Any) {
        self.navigationController?.popToRootViewController(animated: true)
    }
    
    


}
