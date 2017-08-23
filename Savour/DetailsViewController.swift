//
//  DetailsViewController.swift
//  Savour
//
//  Created by Chris Patterson on 8/9/17.
//  Copyright © 2017 Chris Patterson. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase
import FirebaseStorage
import SDWebImage
import FirebaseStorageUI

class DetailsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    var Deal: DealData?
    var handle: AuthStateDidChangeListenerHandle?
    var ref: DatabaseReference!
    var Deals = [DealData]()
    var rAddress: String = ""
    
    @IBOutlet weak var DealsTable: UITableView!
    @IBOutlet weak var rDesc: UITextView!
    @IBOutlet weak var rImg: UIImageView!
    @IBOutlet weak var rName: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tabBarController?.tabBar.isHidden = true
        ref = Database.database().reference()
        loadData()
        
        if traitCollection.forceTouchCapability == .available {
            registerForPreviewing(with: self, sourceView: view)
        } else {
            print("3D Touch Not Available")
        }
    }
    override func viewDidAppear(_ animated: Bool) {
        self.tabBarController?.tabBar.isHidden = true
        self.DealsTable.reloadData()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    func loadData(){
        //Set overall restraunt info
        let id = Deal?.restrauntID?.description
        ref.child("Restaurants").child(id!).observeSingleEvent(of: .value, with: { (snapshot) in
            
            let value = snapshot.value as? NSDictionary
                self.rName.text = value?["Name"] as? String ?? ""
                self.rAddress = value?["Address"] as? String ?? ""
                self.rDesc.text = value?["Desc"] as? String ?? ""
                let photo = value?["Photo"] as? String ?? ""
                // Reference to an image file in Firebase Storage
                let storage = Storage.storage()
                let storageref = storage.reference()
                // Reference to an image file in Firebase Storage
                let reference = storageref.child("rPhotos/" + photo)
                
                // UIImageView in your ViewController
                let imageView: UIImageView = self.rImg
                
                // Placeholder image
                let placeholderImage = UIImage(named: "placeholder.jpg")
                
                // Load the image using SDWebImage
                imageView.sd_setImage(with: reference, placeholderImage: placeholderImage)
            
        }){ (error) in
            print(error.localizedDescription)
        }
        ref.child("Deals").queryOrdered(byChild: "rID").queryEqual(toValue: Deal?.restrauntID).observeSingleEvent(of: .value, with: { (snapshot) in
            // Get user value
            for entry in snapshot.children {
                let snap = entry as! DataSnapshot
                let temp = DealData(snap: snap) // convert my snapshot into my type
                self.Deals.append(temp)
            }
            self.DealsTable.reloadData()
            
        }) { (error) in
            print(error.localizedDescription)
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Deals.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "dealCell", for: indexPath) as! RDealsTableViewCell
        let deal = Deals[indexPath.row]
        cell.deal = deal
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
        if let _ = favorites[deal.dealID!]{
            cell.FavButton.setTitle("Unfavorite", for: .normal )
        }
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath){
        tableView.deselectRow(at: indexPath, animated: true)
        let storyboard = UIStoryboard(name: "DealDetails", bundle: nil)
        let VC = storyboard.instantiateInitialViewController() as! DealViewController
        VC.hidesBottomBarWhenPushed = true
        VC.Deal = Deals[indexPath.row]
        VC.newImg = rImg.image
        VC.fromDetails = true
        self.navigationController?.pushViewController(VC, animated: true)
    }

    @IBAction func directionsPressed(_ sender: Any) {
        let baseUrl: String = "http://maps.apple.com/?q="
        let encodedName = rAddress.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        let finalUrl = baseUrl + encodedName
        if let url = URL(string: finalUrl)
        {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }


}
