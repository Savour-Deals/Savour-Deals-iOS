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
                self.menu = value?["Menu"] as? String ?? ""
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
        for i in 0 ... ((mainVC?.unfilteredDeals.count)!-1){
            if self.Deal?.restrauntID == mainVC?.unfilteredDeals[i].restrauntID{
                self.Deals.append((mainVC?.unfilteredDeals[i])!)
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
        // Create a reference to the file you want to download
        let PDFRef = storage.reference(withPath: "Menus/" + menu)
        // Fetch the download URL
        PDFRef.downloadURL { url, error in
            if error != nil {
                // Handle any errors
            } else {
                
                self.request = URLRequest(url: url!)
                self.navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.white]
                self.performSegue(withIdentifier: "menu", sender: self)
                
            }
        }

        
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "menu" {
            if let pdfVC = segue.destination as? MenuViewController {
                pdfVC.title = self.rName.text! + " Menu"
                pdfVC.request = self.request

            }
        }
    }

}
