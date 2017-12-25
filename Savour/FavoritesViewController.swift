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
    @IBOutlet weak var heartImg: UIImageView!
    @IBOutlet weak var emptyView: UIView!
    var deals = [DealData]()
    var user: String!
    @IBOutlet weak var FavTable: UITableView!
    var ref: DatabaseReference!
    var statusBar: UIView!
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        if traitCollection.forceTouchCapability == .available {
            registerForPreviewing(with: self, sourceView: self.FavTable)
        } else {
            print("3D Touch Not Available")
        }
    }
    override func viewWillAppear(_ animated: Bool) {
        statusBar = UIApplication.shared.value(forKey: "statusBar") as! UIView
        statusBar.backgroundColor = #colorLiteral(red: 0.2848863602, green: 0.6698332429, blue: 0.6656947136, alpha: 1)
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
        self.navigationController?.navigationItem.title = "Favorites"
        self.navigationController?.navigationBar.tintColor = UIColor(red: 73/255, green: 171/255, blue: 170/255, alpha: 1.0)
        heartImg.image = self.heartImg.image?.withRenderingMode(.alwaysTemplate)
        heartImg.tintColor = UIColor.red

    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return favorites.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "dealCell", for: indexPath) as! DealTableViewCell
        cell.deal = deals[indexPath.row]
        //cell.likeButton.frame.size = CGSize(width: 300, height: 40)
        cell.likeButton.addTarget(self,action: #selector(removePressed(sender:event:)),for:UIControlEvents.touchUpInside)
        let image = #imageLiteral(resourceName: "icons8-like_filled.png").withRenderingMode(.alwaysTemplate)
        cell.likeButton.setImage(image, for: .normal)
        cell.likeButton.tintColor = UIColor.red
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
        cell.validHours.text = ""
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
                if (current > end){
                    cell.Countdown.text = "Deal Ended"
                    cell.validHours.text = ""
                }
                else if (current<start){
                    var startingTime = " "
                    if Components.day! != 0{
                        startingTime = startingTime + String(describing: Components.day!) + " days"
                    }
                    else if Components.hour! != 0{
                        startingTime = startingTime + String(describing: Components.hour!) + "hours"
                    }else{
                        startingTime = startingTime + String(describing: Components.minute!) + "minutes"
                    }
                    cell.Countdown.text = "Starts in " + startingTime
                }
                else {
                    var leftTime = ""
                    if Components.day! != 0{
                        leftTime = leftTime + String(describing: Components.day!) + " days left"
                    }
                    else if Components.hour! != 0{
                        leftTime = leftTime + String(describing: Components.hour!) + "hours left"
                    }else{
                        leftTime = leftTime + String(describing: Components.minute!) + "minutes left"
                    }
                    cell.Countdown.text = leftTime
                }
                /*For setting the time left for a deal which is not currently used
                let startD = Date(timeIntervalSince1970: cell.deal.startTime!)
                let endD = Date(timeIntervalSince1970: cell.deal.endTime!)
                let calendar = NSCalendar.current
                var hour = calendar.component(.hour, from: startD)
                var minute = calendar.component(.minute, from: startD)
                var component = "AM"
                if hour > 12{
                    component = "PM"
                    hour = hour - 12
                }
                if minute < 10 {
                    cell.validHours.text = "Valid \(hour):0\(minute)\(component) to "
                }
                else{
                    cell.validHours.text = "Valid \(hour):\(minute)\(component) to "
                }
                hour = calendar.component(.hour, from: endD)
                minute = calendar.component(.minute, from: endD)
                component = "AM"
                if hour > 12{
                    component = "PM"
                    hour = hour - 12
                }
                if minute < 10 {
                    cell.validHours.text = cell.validHours.text! + "\(hour):0\(minute)\(component)"
                }
                else{
                    cell.validHours.text = cell.validHours.text! + "\(hour):\(minute)\(component)"
                }*/
                
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
        if deals.isEmpty{
            FavTable.isHidden = true
            emptyView.isHidden = false
        }
        
    }
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        if velocity.y>0{
            UIView.animate(withDuration: 2.5, delay: 0,  options: UIViewAnimationOptions(), animations: {
                self.navigationController?.setNavigationBarHidden(true, animated: true)
                //self.navigationController?.setToolbarHidden(true, animated: true)
            }, completion: nil)
        }
        else{
            UIView.animate(withDuration: 2.5, delay: 0,  options: UIViewAnimationOptions(), animations: {
                self.navigationController?.setNavigationBarHidden(false, animated: true)
               // self.navigationController?.setToolbarHidden(false, animated: true)
            }, completion: nil)
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath){
        //let cell = tableView.cellForRow(at: indexPath) as! DealTableViewCell
        tableView.deselectRow(at: indexPath, animated: true)
        let storyboard = UIStoryboard(name: "DealDetails", bundle: nil)
        let VC = storyboard.instantiateInitialViewController() as! DealViewController
        VC.hidesBottomBarWhenPushed = true
        VC.Deal = deals[indexPath.row]
        VC.fromDetails = false
        VC.photo = VC.Deal?.restrauntPhoto
        VC.index = FavMainIndex[deals[indexPath.row].dealID!]!
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        self.navigationController?.pushViewController(VC, animated: true)
    }

    func tableView(_ tableView: UITableView,heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        return UITableViewAutomaticDimension
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        self.navigationController?.setNavigationBarHidden(false, animated: true)
    }
    

   

}
