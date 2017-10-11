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

    @IBOutlet weak var followButton: UIButton!
    @IBOutlet weak var directionsButton: UIButton!
    @IBOutlet weak var menuButton: UIButton!
    var Deal: DealData?
    var handle: AuthStateDidChangeListenerHandle?
    var ref: DatabaseReference!
    var storage: Storage!
    var Deals = [DealData]()
    var indices = [Int]()
    var rAddress: String = ""
    
    @IBOutlet weak var DealsTable: UITableView!
    @IBOutlet weak var rDesc: UITextView!
    @IBOutlet weak var rImg: UIImageView!
    @IBOutlet weak var rName: UILabel!
    var menu: String!
    var request: URLRequest?

  
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tabBarController?.tabBar.isHidden = true
        ref = Database.database().reference()
        storage = Storage.storage()
        loadData()
        
        if traitCollection.forceTouchCapability == .available {
            registerForPreviewing(with: self, sourceView: view)
        } else {
            print("3D Touch Not Available")
        }
        DealsTable.rowHeight = UITableViewAutomaticDimension
        DealsTable.estimatedRowHeight = 45
        followButton.layer.borderWidth = 1.0
        followButton.layer.borderColor = #colorLiteral(red: 0.2848863602, green: 0.6698332429, blue: 0.6656947136, alpha: 1)
        directionsButton.layer.borderWidth = 1.0
        directionsButton.layer.borderColor = #colorLiteral(red: 0.2848863602, green: 0.6698332429, blue: 0.6656947136, alpha: 1)
        menuButton.layer.borderWidth = 1.0
        menuButton.layer.borderColor = #colorLiteral(red: 0.2848863602, green: 0.6698332429, blue: 0.6656947136, alpha: 1)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.title = Deal?.restrauntName
    }
    override func viewDidAppear(_ animated: Bool) {
        self.tabBarController?.tabBar.isHidden = true
        self.DealsTable.reloadData()
        menuButton.isEnabled = true
    }
    
    @IBAction func backSwipe(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    func loadData(){
        //Set overall restraunt info
        let id = Deal?.restrauntID?.description
        ref.child("Restaurants").child(id!).observeSingleEvent(of: .value, with: { (snapshot) in
            
            let value = snapshot.value as? NSDictionary
            if snapshot.childSnapshot(forPath: "Followers").hasChild((Auth.auth().currentUser?.uid)!){
                self.followButton.setTitle("Unfollow", for: .normal)
            }
            else{
                self.followButton.setTitle("Follow", for: .normal)

            }
                self.menu = value?["Menu"] as? String ?? ""
                self.rName.text = value?["Name"] as? String ?? ""
                self.rAddress = value?["Address"] as? String ?? ""
                self.rDesc.text = value?["Desc"] as? String ?? ""
                let photo = value?["Photo"] as? String ?? ""
                if photo != ""{
                    // Reference to an image file in Firebase Storage
                    let storage = Storage.storage()
                    let storageref = storage.reference(forURL: photo)
                    // Reference to an image file in Firebase Storage
                    let reference = storageref
            
                    // UIImageView in your ViewController
                    let imageView: UIImageView = self.rImg
            
                    // Placeholder image
                    let placeholderImage = UIImage(named: "placeholder.jpg")
            
                    // Load the image using SDWebImage
                    imageView.sd_setImage(with: reference, placeholderImage: placeholderImage)
            }
        }){ (error) in
            print(error.localizedDescription)
        }
        for i in 0 ... (UnfilteredDeals.count-1){
            if self.Deal?.restrauntID == UnfilteredDeals[i].restrauntID{
                self.Deals.append((UnfilteredDeals[i]))
                self.indices.append(i)
            }
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
        if deal.redeemed! {
            cell.Countdown.text = "Deal Already Redeemed!"
            cell.Countdown.textColor = UIColor.red
            cell.FavButton.isHidden = true
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
            if favorites[deal.dealID!] != nil{ 
                cell.FavButton.setTitle("Unfavorite", for: .normal )
            }
            else{
                cell.FavButton.setTitle("Favorite", for: .normal)
            }
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
        VC.index = indices[indexPath.row]
        self.title = ""
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

    @IBAction func openMenu(_ sender: Any) {
        menuButton.isEnabled = false
        UIApplication.shared.open(URL(string: menu)!, options: [:], completionHandler: nil)
        menuButton.isEnabled = true
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        self.title = ""
        //menu storyboard removed as menus are externally linked
       /* if segue.identifier == "menu" {
            if let pdfVC = segue.destination as? MenuViewController {
                pdfVC.title = self.rName.text! + " Menu"
                pdfVC.request = self.request

            }
        }*/
    }
    
    func preferredStatusBarStyle() -> UIStatusBarStyle {
        
        return UIStatusBarStyle.lightContent
    }
    
    @IBAction func followPressed(_ sender: Any) {
        followButton.isEnabled = false
        if self.followButton.currentTitle == "Follow"{
            let currTime = Date().timeIntervalSince1970
            let uID = Auth.auth().currentUser?.uid
            let followRef = Database.database().reference().child("Restaurants").child((self.Deal?.restrauntID)!).child("Followers").child(uID!)
            followRef.setValue(currTime)
            self.followButton.setTitle("Unfollow", for: .normal)
        }
        else{
            let uID = Auth.auth().currentUser?.uid
            let followRef = Database.database().reference().child("Restaurants").child((self.Deal?.restrauntID)!).child("Followers").child(uID!)
            followRef.removeValue()
            self.followButton.setTitle("Follow", for: .normal)

        }
        followButton.isEnabled = true
    }
    

}
