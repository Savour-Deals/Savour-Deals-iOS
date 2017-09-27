//
//  ViewController.swift
//  Savour
//
//  Created by Chris Patterson on 8/1/17.
//  Copyright © 2017 Chris Patterson. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseStorage
import SDWebImage
import FirebaseStorageUI
import FirebaseAuth



class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate{

    @IBOutlet var redeemedView: UIView!
    var handle: AuthStateDidChangeListenerHandle?
    var ref: DatabaseReference!
    var filteredDeals = [DealData]()
    var unfilteredDeals = [DealData]()
    var FavdealIDs: [String:String] = Dictionary<String, String>()
    var justOpened = true
    var searchBar: UISearchBar!

    private let refreshControl = UIRefreshControl()

    
    @IBOutlet weak var DealsTable: UITableView!
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func GetFavs()  {
        let userid = Auth.auth().currentUser?.uid
        let ref = Database.database().reference()
        ref.child("Users").child(userid!).child("Favorites").observeSingleEvent(of: .value, with: { (snapshot) in
            // Get user value
            for entry in snapshot.children {
                let snap = entry as! DataSnapshot
                let value = snap.key
                self.FavdealIDs[value] = value
            }
            self.loadData(sender: "favs")
        }){ (error) in
            print(error.localizedDescription)
        }
        
    }

    
    func setupUI(){
        self.navigationController?.navigationBar.tintColor = UIColor(red: 73, green: 171, blue: 170, alpha: 1.0)
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        self.tabBarController?.tabBar.isHidden = false
        mainVC = self
        ref.keepSynced(true)
        DealsTable.delegate = self
        GetFavs()
        //Check if forcetouch is available
        if traitCollection.forceTouchCapability == .available {
            registerForPreviewing(with: self, sourceView: self.DealsTable)
        } else {
            print("3D Touch Not Available")
        }
        // Add Refresh Control to Table View
        if #available(iOS 10.0, *) {
            DealsTable.refreshControl = refreshControl
        } else {
            DealsTable.addSubview(refreshControl)
        }
        // Configure Refresh Control
        refreshControl.attributedTitle = NSAttributedString(string: "Fetching Deals")
        refreshControl.addTarget(self, action: #selector(refreshData(_:)), for: .valueChanged)
        setupSearchBar()
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        handle = Auth.auth().addStateDidChangeListener { (auth, user) in
        }
        if Auth.auth().currentUser != nil {
            // User is signed in.
        }
        else {
            self.performSegue(withIdentifier: "Onboarding", sender: self)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        ref = Database.database().reference()
        self.title = ""
        UIApplication.shared.statusBarStyle = .lightContent
        let user = Auth.auth().currentUser
        if user != nil {
            // User is signed in.
            self.ref.child("Users").child((user?.uid)!).child("type").observeSingleEvent(of: .value, with: { (snapshot) in
                // Get user value
                let type = snapshot.value as? String ?? ""
                if type == "Vendor"{
                    self.navigationController?.navigationBar.isHidden = true
                    self.tabBarController?.tabBar.isHidden = true
                    self.performSegue(withIdentifier: "Vendor", sender: self)
                }
                else{
                    if self.unfilteredDeals.isEmpty{
                        self.setupUI()
                    }
                }
            })
            //unfilteredDeals.removeAll()
            refreshData("main")
        }
        else {
            // No user is signed in.
            self.performSegue(withIdentifier: "Onboarding", sender: self)
        }
    }
    
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // [START remove_auth_listener]
        Auth.auth().removeStateDidChangeListener(handle!)
        // [END remove_auth_listener]
    }
    
    @objc private func refreshData(_ sender: Any) {
        // Fetch Data
        loadData(sender: "refresh")
        self.refreshControl.endRefreshing()

    }

    func loadData(sender: String){
       DispatchQueue.main.async {
            var oldDeals = [DealData]()
            if sender == "refresh"{
                oldDeals = self.unfilteredDeals
                self.unfilteredDeals.removeAll()
            }
            let currentUnix = Date().timeIntervalSince1970
            let plusDay = currentUnix + 86400
            let expiredUnix = currentUnix
            let sortedRef = self.ref.child("Deals").queryOrdered(byChild: "StartTime")
            let filteredRef = sortedRef.queryEnding(atValue: plusDay, childKey: "StartTime")
            filteredRef.observeSingleEvent(of: .value, with: { (snapshot) in
                // Get user value
                for entry in snapshot.children {
                    let snap = entry as! DataSnapshot
                    let temp = DealData(snap: snap, ID: (Auth.auth().currentUser?.uid)!) // convert my snapshot into my type
                    if temp.endTime! > expiredUnix {
                        if sender == "main" || sender == "refresh"{
                            self.unfilteredDeals.append(temp)
                        }
                        else if sender == "null" {
                            for deal in oldDeals{
                                if (deal.dealID == temp.dealID) && (deal.redeemed != nil){
                                    temp.redeemed = deal.redeemed
                                }
                            }
                            self.unfilteredDeals.append(temp)
                        }
                        else if sender == "favs" {
                            if self.FavdealIDs[temp.dealID!] != nil {
                                favorites[temp.dealID!] = temp
                            }
                            for i in 0 ... (self.unfilteredDeals.count-1){
                                if self.unfilteredDeals[i].dealID == temp.dealID{
                                    FavMainIndex[temp.dealID!] = i
                                }
                            }
                        }
                        else{
                            print("loadData() was called with an unkown sender")
                        }
                    }
                }
                self.loadRedeemed()
            }){ (error) in
                print(error.localizedDescription)
            }
        }
    }
   
    func loadRedeemed(){
        let ref = Database.database().reference()
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            if snapshot.hasChild("Redeemed"){
                let redeemedSnap = snapshot.childSnapshot(forPath: "Redeemed")
                for i in 0 ... (self.unfilteredDeals.count-1){
                    if redeemedSnap.childSnapshot(forPath: self.unfilteredDeals[i].dealID!).hasChild((Auth.auth().currentUser?.uid)!){
                        let snap = redeemedSnap.childSnapshot(forPath: self.unfilteredDeals[i].dealID!)
                        let redeemers = snap.value as! NSDictionary
                        self.unfilteredDeals[i].redeemed = true
                        let timeString = redeemers.value(forKey: (Auth.auth().currentUser?.uid)!) as! String
                        self.unfilteredDeals[i].redeemedTime = Double(timeString)
                    }
                    else{
                        self.unfilteredDeals[i].redeemed = false
                    }
                    let deal = self.unfilteredDeals[i]
                    if favorites[deal.dealID!] != nil{
                        favorites[deal.dealID!]?.redeemed = deal.redeemed
                        favorites[deal.dealID!]?.redeemedTime = deal.redeemedTime
                    }
                }
            }
            if self.unfilteredDeals[0].redeemed == nil{
                for i in 0 ... (self.unfilteredDeals.count-1){
                    self.unfilteredDeals[i].redeemed = false
                }
            }
            if self.DealsTable.dataSource == nil{
                self.DealsTable.dataSource = self
            }
            self.filteredDeals = self.unfilteredDeals
            self.DealsTable.reloadData()
        })


    }
    
        
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredDeals.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

            let cell = tableView.dequeueReusableCell(withIdentifier: "dealCell", for: indexPath) as! DealTableViewCell
            let deal = self.filteredDeals[indexPath.row]
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
                    var startingTime = " "
                    if Components.day! != 0{
                        startingTime = startingTime + String(describing: Components.day!) + "d "
                    }
                    if Components.hour! != 0{
                        startingTime = startingTime + String(describing: Components.hour!) + "h "
                    }
                    startingTime = startingTime + String(describing: Components.minute!) + "m"
                    cell.Countdown.text = "Starts in " + startingTime
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
        VC.Deal = filteredDeals[indexPath.row]
        VC.fromDetails = false
        VC.newImg = cell.rImg.image
        VC.index = indexPath.row
        VC.from = "deals"
        //cleanup searchbar
        self.searchBar.resignFirstResponder()
        self.searchBar.showsCancelButton = false
        
        self.navigationController?.pushViewController(VC, animated: true)
    }
    
    // extend buttons
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
       let favorite: UITableViewRowAction!
        if favorites[filteredDeals[indexPath.row].dealID!] == nil{
            favorite = UITableViewRowAction(style: .normal, title: "  Favorite  ") { (action, index) -> Void in
                
                tableView.isEditing = false
                favorites[self.filteredDeals[indexPath.row].dealID!] = self.filteredDeals[indexPath.row]
                print("favorite")
                
            }
            favorite.backgroundColor = UIColor.green
        }
        else{
            favorite = UITableViewRowAction(style: .normal, title: "  UnFavorite  ") { (action, index) -> Void in
                
                tableView.isEditing = false
                print("unfavorite")
                favorites.removeValue(forKey: self.filteredDeals[indexPath.row].dealID!)
            }
            favorite.backgroundColor = UIColor.red
        }
        
        
        // return buttons
        return [favorite]
    }
    
    //SearchBar functions
    func setupSearchBar(){
        // Setup the Search Controller
        self.searchBar = UISearchBar()
        searchBar.showsCancelButton = false
        searchBar.placeholder = "Search Restaurants"
        searchBar.delegate = self
        self.navigationItem.titleView = searchBar
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchBar.text! == "" {
            filteredDeals = unfilteredDeals
        } else {
            // Filter the results
            filteredDeals = unfilteredDeals.filter { ($0.restrauntName?.lowercased().contains(searchBar.text!.lowercased()))! }
        }
        DealsTable.reloadData()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        searchBar.showsCancelButton = false
        if searchBar.text! == "" {
            filteredDeals = unfilteredDeals
        } else {
            // Filter the results
            filteredDeals = unfilteredDeals.filter { ($0.restrauntName?.lowercased().contains(searchBar.text!.lowercased()))! }
        }
        DealsTable.reloadData()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        //searchBar.resignFirstResponder()
        searchBar.endEditing(true)
        searchBar.showsCancelButton = false
    }
 
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.showsCancelButton = true
    }


    
   
}
