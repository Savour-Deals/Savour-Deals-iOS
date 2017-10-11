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
import FirebaseAuth

class FavoritesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate{
    var storage: Storage!
    @IBOutlet weak var emptyView: UIView!
    var deals = [DealData]()
    var user: String!
    @IBOutlet weak var FavTable: UITableView!
    var ref: DatabaseReference!

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
        self.navigationController?.view.backgroundColor = UIColor.lightGray
        self.FavTable.backgroundColor = UIColor.lightGray
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return favorites.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "dealCell", for: indexPath) as! DealTableViewCell
        cell.deal = deals[indexPath.row]
        cell.likeButton.setTitle("Remove", for: .normal)
        cell.likeButton.setTitleColor( #colorLiteral(red: 0.2848863602, green: 0.6698332429, blue: 0.6656947136, alpha: 1), for: .normal)
        cell.likeButton.layer.borderWidth = 1
        cell.likeButton.layer.borderColor = #colorLiteral(red: 0.2848863602, green: 0.6698332429, blue: 0.6656947136, alpha: 1)
        cell.likeButton.frame.size = CGSize(width: 300, height: 40)
        cell.likeButton.addTarget(self,action: #selector(removePressed(sender:event:)),for:UIControlEvents.touchUpInside)
        let photo = cell.deal.restrauntPhoto!
        // Reference to an image file in Firebase Storage
        let storage = Storage.storage()
        let storageref = storage.reference(forURL: photo)
        
        // UIImageView in your ViewController
        let imageView: UIImageView = cell.rImg
        
        // Placeholder image
        let placeholderImage = UIImage(named: "placeholder.jpg")
        
        // Load the image using SDWebImage
        imageView.sd_setImage(with: storageref, placeholderImage: placeholderImage)
        cell.rName.text = cell.deal.restrauntName
        cell.dealDesc.text = cell.deal.dealDescription
        if cell.deal.redeemed! {
            cell.Countdown.text = "Deal Already Redeemed!"
            cell.Countdown.textColor = UIColor.red
        }
        else{
            cell.Countdown.textColor = #colorLiteral(red: 0.9443297386, green: 0.5064610243, blue: 0.3838719726, alpha: 1)

            let start = Date(timeIntervalSince1970: cell.deal.startTime!)
            let end = Date(timeIntervalSince1970: cell.deal.endTime!)
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
        cell.tagImg.image = cell.tagImg.image!.withRenderingMode(.alwaysTemplate)
        cell.tagImg.tintColor = cell.Countdown.textColor
        return cell
    }
    @IBAction func removePressed(sender: UIButton, event: UIEvent){
        let touches = event.touches(for: sender)
        if let touch = touches?.first{
            let point = touch.location(in: FavTable)
            if let indexPath = FavTable.indexPathForRow(at: point) {
                let cell = FavTable.cellForRow(at: indexPath) as? DealTableViewCell
                favorites.removeValue(forKey: (cell?.deal.dealID!)!)
                let user = Auth.auth().currentUser?.uid
                Database.database().reference().child("Users").child(user!).child("Favorites").child((cell?.deal.dealID!)!).removeValue()
                deals.removeAll()
                for fav in favorites{
                    deals.append(fav.value)
                }
                FavTable.reloadData()
            }
        }
        
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

    func tableView(_ tableView: UITableView,heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        return UITableViewAutomaticDimension
    }
    

   

}
