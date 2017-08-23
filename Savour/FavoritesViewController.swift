//
//  FavoritesViewController.swift
//  Savour
//
//  Created by Chris Patterson on 8/6/17.
//  Copyright © 2017 Chris Patterson. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase
import FirebaseStorage
import SDWebImage
import FirebaseStorageUI

class FavoritesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate{

    @IBOutlet weak var emptyView: UIView!
    var ref: DatabaseReference!
    var deals = [DealData]()
    @IBOutlet weak var FavTable: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if traitCollection.forceTouchCapability == .available {
            registerForPreviewing(with: self, sourceView: view)
        } else {
            print("3D Touch Not Available")
        }

    }
    override func viewWillAppear(_ animated: Bool) {
        ref = Database.database().reference()
        deals.removeAll()
        for (_, deal) in favorites {
            deals.append(deal)
        }
        self.FavTable.reloadData()
        setupUI()
        if (deals.isEmpty){
            FavTable.isHidden = true
            emptyView.isHidden = false
        }
        else{
            FavTable.isHidden = false
            emptyView.isHidden = true
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    
    func setupUI(){
        self.navigationController?.navigationBar.tintColor = UIColor(colorLiteralRed: 73, green: 171, blue: 170, alpha: 1.0)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return favorites.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "dealCell", for: indexPath) as! DealTableViewCell
        let deal = deals[indexPath.row]
        
        // Reference to an image file in Firebase Storage
        let storage = Storage.storage()
        let storageref = storage.reference()
        // Reference to an image file in Firebase Storage
        let reference = storageref.child("rPhotos/" + deal.restrauntPhoto!)
        
        // UIImageView in your ViewController
        let imageView: UIImageView = cell.rImg
        
        // Placeholder image
        let placeholderImage = UIImage(named: "placeholder.jpg")
        
        // Load the image using SDWebImage
        imageView.sd_setImage(with: reference, placeholderImage: placeholderImage)
        cell.rName.text = deal.restrauntName
        cell.dealDesc.text = deal.dealDescription
        let start = Date(timeIntervalSince1970: deal.startTime!)
        let end = Date(timeIntervalSince1970: deal.endTime!)
        let current = Date()
        let interval  =  DateInterval(start: start as Date, end: end as Date)
        if (interval.contains(current)){
            let cal = Calendar.current
            let Components = cal.dateComponents([.day, .hour, .minute], from: current, to: end)
            cell.Countdown.text =  "Time left: " + String(describing: Components.day!) + "d " + String(describing: Components.hour!) + "h " + String(describing: Components.minute!) + "m"
        }
        else if (current > end){
            cell.Countdown.text = "Deal Ended"
        }
        else {
            let cal = Calendar.current
            let Components = cal.dateComponents([.day, .hour, .minute], from: current, to: start)
            cell.Countdown.text = "Starts in " + String(describing: Components.day!) + "days"
        }
        cell.FavButton.isHidden = true
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath){
        let cell = tableView.cellForRow(at: indexPath) as! DealTableViewCell
        tableView.deselectRow(at: indexPath, animated: true)
        let storyboard = UIStoryboard(name: "DealDetails", bundle: nil)
        let VC = storyboard.instantiateInitialViewController() as! DealViewController
        VC.hidesBottomBarWhenPushed = true
        VC.Deal = deals[indexPath.row]
        VC.fromDetails = false
        VC.newImg = cell.rImg.image
        self.navigationController?.pushViewController(VC, animated: true)
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        let deal = deals[indexPath.row]
        if (editingStyle == UITableViewCellEditingStyle.delete) {
            favorites.removeValue(forKey:  deal.dealID!)
        }
        tableView.reloadData()
        if (favorites.isEmpty){
            FavTable.isHidden = true
            emptyView.isHidden = false
        }
        else{
            FavTable.isHidden = false
            emptyView.isHidden = true
        }
    }

   

}
