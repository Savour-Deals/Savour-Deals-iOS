//
//  ViewController.swift
//  Savour
//
//  Created by Chris Patterson on 8/1/17.
//  Copyright © 2017 Chris Patterson. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase
import FirebaseStorage
import SDWebImage
import FirebaseStorageUI



class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate{

    var handle: AuthStateDidChangeListenerHandle?
    var ref: DatabaseReference!
    var Deals = [DealData]()

    
    @IBOutlet weak var DealsTable: UITableView!
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if Auth.auth().currentUser != nil {
            // User is signed in.
            ref = Database.database().reference()
            loadData()

        }
        else {
            // No user is signed in.
            self.performSegue(withIdentifier: "Onboarding", sender: self)
        }
    }
    
    func setupUI(){
        self.navigationController?.navigationBar.tintColor = UIColor(colorLiteralRed: 73, green: 171, blue: 170, alpha: 1.0)
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        handle = Auth.auth().addStateDidChangeListener { (auth, user) in
        }
        if Auth.auth().currentUser != nil {
            // User is signed in.
            self.navigationController?.setNavigationBarHidden(false, animated: true)
            self.tabBarController?.tabBar.isHidden = false
            setupUI()
        }
    }
    override func viewWillAppear(_ animated: Bool) {
        DispatchQueue.main.async{
            self.DealsTable.reloadData()
        }
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // [START remove_auth_listener]
        Auth.auth().removeStateDidChangeListener(handle!)
        // [END remove_auth_listener]
    }

    func loadData(){
        DispatchQueue.main.async{

            self.ref.child("Deals").observeSingleEvent(of: .value, with: { (snapshot) in
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
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Deals.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

            let cell = tableView.dequeueReusableCell(withIdentifier: "dealCell", for: indexPath) as! DealTableViewCell
            let deal = self.Deals[indexPath.row]
            //cell.row = indexPath.row
            cell.deal = deal

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
            if let _ = favorites[deal.dealID!]{
                cell.FavButton.setTitle("Unfavorite", for: .normal )
            }
            else{
                cell.FavButton.setTitle("Favorite", for: .normal )
        }
        return cell

        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath){
        let cell = tableView.cellForRow(at: indexPath) as! DealTableViewCell
        tableView.deselectRow(at: indexPath, animated: true)
        let storyboard = UIStoryboard(name: "DealDetails", bundle: nil)
        let VC = storyboard.instantiateInitialViewController() as! DealViewController
        VC.hidesBottomBarWhenPushed = true
        VC.Deal = Deals[indexPath.row]
        VC.fromDetails = false
        VC.newImg = cell.rImg.image
        self.navigationController?.pushViewController(VC, animated: true)
    }
    
   
}
