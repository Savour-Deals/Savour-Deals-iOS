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
    var storage: Storage!
    @IBOutlet weak var emptyView: UIView!
    var deals = [DealData]()
    var user: String!
    @IBOutlet weak var FavTable: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if traitCollection.forceTouchCapability == .available {
            registerForPreviewing(with: self, sourceView: self.FavTable)
        } else {
            print("3D Touch Not Available")
        }

    }
    override func viewWillAppear(_ animated: Bool) {
        
        deals.removeAll()
        let expiredUnix = Date().timeIntervalSince1970 - 24*60*60
        for (_, deal) in favorites {
            if deal.endTime! > expiredUnix{
                deals.append(deal)
            }
            else{
                favorites.removeValue(forKey: deal.dealID!)
            }
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
        FavTable.tableFooterView = UIView()

    }
    
    
    

    
    func setupUI(){
        self.navigationController?.navigationBar.tintColor = UIColor(red: 73/255, green: 171/255, blue: 170/255, alpha: 1.0)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return favorites.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "dealCell", for: indexPath) as! DealTableViewCell
        let deal = deals[indexPath.row]
        
        let photo = deal.restrauntPhoto!
        // Reference to an image file in Firebase Storage
        let storage = Storage.storage()
        let storageref = storage.reference(forURL: photo)
        
        // UIImageView in your ViewController
        let imageView: UIImageView = cell.rImg
        
        // Placeholder image
        let placeholderImage = UIImage(named: "placeholder.jpg")
        
        // Load the image using SDWebImage
        imageView.sd_setImage(with: storageref, placeholderImage: placeholderImage)
        cell.rName.text = deal.restrauntName
        cell.dealDesc.text = deal.dealDescription
        if deal.redeemed! {
            cell.Countdown.text = "Deal Already Redeemed!"
            cell.Countdown.textColor = UIColor.red
        }
        else{
            cell.Countdown.textColor = #colorLiteral(red: 0.9443297386, green: 0.5064610243, blue: 0.3838719726, alpha: 1)

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
        }
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
        VC.index = FavMainIndex[deals[indexPath.row].dealID!]!
        self.navigationController?.pushViewController(VC, animated: true)
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        let deal = deals[indexPath.row]
        if (editingStyle == UITableViewCellEditingStyle.delete) {
            
            favorites.removeValue(forKey:  deal.dealID!)
            tableView.beginUpdates()
            FavTable.deleteRows(at: [indexPath], with: .automatic)
            tableView.endUpdates()

            deals.removeAll()
            for (_, deal) in favorites {
                deals.append(deal)
            }
            //self.FavTable.reloadData()
        }
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
