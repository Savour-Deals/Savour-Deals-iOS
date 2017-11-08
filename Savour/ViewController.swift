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
    var storage: Storage!
    var ref: DatabaseReference!
    var FavdealIDs: [String:String] = Dictionary<String, String>()
    var justOpened = true
    var searchBar: UISearchBar!
    var alreadyGoing = false
    var instantiated = false
    var statusBar: UIView!

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
        alreadyGoing = false
        ref = Database.database().reference()
        ref.keepSynced(true)
        self.loadData(sender: "main")
        self.setupUI()
        self.DealsTable.dataSource = self
        self.DealsTable.delegate = self

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
        }){ (error) in
            print(error.localizedDescription)
        }
        
    }
    
    func setupUI(){
        self.navigationController?.navigationBar.tintColor = UIColor.white
        self.navigationController?.view.backgroundColor = UIColor.white
        
        let gradientLayer = CAGradientLayer()
        
        statusBar = UIApplication.shared.value(forKey: "statusBar") as! UIView
        statusBar.backgroundColor = #colorLiteral(red: 0.2848863602, green: 0.6698332429, blue: 0.6656947136, alpha: 1)
        gradientLayer.frame = self.view.bounds
        gradientLayer.colors = [#colorLiteral(red: 0.2848863602, green: 0.6698332429, blue: 0.6656947136, alpha: 0.2524079623).cgColor, #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1).cgColor]
        self.view.layer.insertSublayer(gradientLayer, at: 0)

        self.navigationController?.setNavigationBarHidden(false, animated: true)
        self.tabBarController?.tabBar.isHidden = false
        self.refreshControl.tintColor = UIColor.white

        ref.keepSynced(true)
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
        refreshControl.attributedTitle = NSAttributedString(string: "Fetching Deals", attributes: [NSAttributedStringKey.foregroundColor: UIColor.white])
        refreshControl.addTarget(self, action: #selector(refreshData(_:)), for: .valueChanged)
        setupSearchBar()
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        handle = Auth.auth().addStateDidChangeListener { (auth, user) in}
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.navigationItem.title = ""
        UIApplication.shared.statusBarStyle = .lightContent
        statusBar = UIApplication.shared.value(forKey: "statusBar") as! UIView
        statusBar.backgroundColor = #colorLiteral(red: 0.2848863602, green: 0.6698332429, blue: 0.6656947136, alpha: 1)
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
                   self.DealsTable.reloadData()
                }
            })
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
            var oldDeals = [DealData]()
            if sender == "refresh" || sender == "main"{
                oldDeals = UnfilteredDeals
                UnfilteredDeals.removeAll()
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
                            UnfilteredDeals.append(temp)
                        }
                        else if sender == "null" {
                            for deal in oldDeals{
                                if (deal.dealID == temp.dealID) && (deal.redeemed != nil){
                                   temp.redeemed = deal.redeemed
                                }
                            }
                            UnfilteredDeals.append(temp)
                        }
                        else if sender == "favs" && UnfilteredDeals.count > 0{
                            if self.FavdealIDs[temp.dealID!] != nil {
                                favorites[temp.dealID!] = temp
                            }
                            for i in 0 ... (UnfilteredDeals.count-1){
                                if UnfilteredDeals[i].dealID == temp.dealID{
                                    FavMainIndex[temp.dealID!] = i
                                }
                            }
                        }
                    }
                }
                if UnfilteredDeals.count > 0 && sender != "favs"{
                    self.loadData(sender: "favs")
                }

                if UnfilteredDeals.count > 0 && sender == "favs"{
                    self.loadRedeemed()
                }

            }){ (error) in
                print(error.localizedDescription)
            }
    }
   
    func loadRedeemed(){
        let ref = Database.database().reference()
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            if snapshot.hasChild("Redeemed"){
                let redeemedSnap = snapshot.childSnapshot(forPath: "Redeemed")
                for i in 0 ... (UnfilteredDeals.count-1){
                    if redeemedSnap.childSnapshot(forPath: UnfilteredDeals[i].dealID!).hasChild((Auth.auth().currentUser?.uid)!){
                        let snap = redeemedSnap.childSnapshot(forPath: UnfilteredDeals[i].dealID!)
                        let redeemers = snap.value as! NSDictionary
                        UnfilteredDeals[i].redeemed = true
                        UnfilteredDeals[i].redeemedTime = redeemers.value(forKey: (Auth.auth().currentUser?.uid)!) as? Double
                    }
                    else{
                        UnfilteredDeals[i].redeemed = false
                    }
                    let deal = UnfilteredDeals[i]
                    if favorites[deal.dealID!] != nil{
                        favorites[deal.dealID!]?.redeemed = deal.redeemed
                        favorites[deal.dealID!]?.redeemedTime = deal.redeemedTime
                    }
                }
            }
            if UnfilteredDeals[0].redeemed == nil{
                for i in 0 ... (UnfilteredDeals.count-1){
                    UnfilteredDeals[i].redeemed = false
                }
            }
            if self.DealsTable.dataSource == nil{
                self.DealsTable.dataSource = self
            }
            if notificationDeal != nil && UnfilteredDeals.count > 0{
                for i in 0..<UnfilteredDeals.count{
                    if UnfilteredDeals[i].dealID == notificationDeal && !self.alreadyGoing{
                        self.alreadyGoing = true
                        notificationDeal = nil
                        self.dealDetails(deal: UnfilteredDeals[i],index: i)
                    }
                }
                
            }
            filteredDeals.removeAll()
            for deal in UnfilteredDeals{
                if !deal.redeemed!{
                    filteredDeals.append(deal)
                }
            }
            self.DealsTable.reloadData()
        })
    }
    
        
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredDeals.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: "dealCell", for: indexPath) as! DealTableViewCell
        let deal = filteredDeals[indexPath.row]
        cell.deal = deal
        if favorites[deal.dealID!] == nil{
            let image = #imageLiteral(resourceName: "icons8-like").withRenderingMode(.alwaysTemplate)
            cell.likeButton.setImage(image, for: .normal)
            cell.likeButton.tintColor = UIColor.red
        }
        else{
            let image = #imageLiteral(resourceName: "icons8-like_filled.png").withRenderingMode(.alwaysTemplate)
            cell.likeButton.setImage(image, for: .normal)
            cell.likeButton.tintColor = UIColor.red
            
        }
        let photo = deal.restrauntPhoto!
        if photo != ""{
            // Reference to an image file in Firebase Storage
            let storage = Storage.storage()
            let storageref = storage.reference(forURL: photo)

            // UIImageView in your ViewController
            let imageView: UIImageView = cell.rImg

            // Placeholder image
            let placeholderImage = UIImage(named: "placeholder.jpg")

            // Load the image using SDWebImage
            imageView.sd_setImage(with: storageref, placeholderImage: placeholderImage)
        }
            cell.rName.text = deal.restrauntName
            cell.dealDesc.text = deal.dealDescription
            
            if deal.redeemed! {
                cell.Countdown.text = "Deal Already Redeemed!"
                cell.Countdown.textColor = UIColor.red
                cell.validHours.text = ""

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
                    if (current > end){
                        cell.Countdown.text = "Deal Ended"
                        cell.validHours.text = ""
                    }
                    else if (current<start){
                        var startingTime = " "
                        if Components.day! != 0{
                            startingTime = startingTime + String(describing: Components.day!) + " days"
                        }
                        else{
                            startingTime = startingTime + String(describing: Components.hour!) + "h "
                            startingTime = startingTime + String(describing: Components.minute!) + "m"
                        }
                        cell.Countdown.text = "Starts in " + startingTime
                    }
                    else {
                        var leftTime = " "
                        if Components.day! != 0{
                            leftTime = leftTime + String(describing: Components.day!) + " days"
                        }
                        else{
                            leftTime = leftTime + String(describing: Components.hour!) + "h "
                            leftTime = leftTime + String(describing: Components.minute!) + "m"
                        }
                        cell.Countdown.text = "Time left: " + leftTime
                    }
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
                        cell.validHours.text = "Valid Between: \(hour):0\(minute)\(component)-"
                    }
                    else{
                        cell.validHours.text = "Valid Between: \(hour):\(minute)\(component)-"
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
                    }

                }
                
            }
        cell.tagImg.image = cell.tagImg.image!.withRenderingMode(.alwaysTemplate)
        cell.tagImg.tintColor = cell.Countdown.textColor
        
        return cell

        
    }
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        if velocity.y>0{
            UIView.animate(withDuration: 2.5, delay: 0,  options: UIViewAnimationOptions(), animations: {
                self.navigationController?.setNavigationBarHidden(true, animated: true)
            }, completion: nil)
        }
        else{
            UIView.animate(withDuration: 2.5, delay: 0,  options: UIViewAnimationOptions(), animations: {
                self.navigationController?.setNavigationBarHidden(false, animated: true)
            }, completion: nil)
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath){
        //let cell = tableView.cellForRow(at: indexPath) as! DealTableViewCell
        tableView.deselectRow(at: indexPath, animated: true)
        dealDetails(deal: filteredDeals[indexPath.row],index: indexPath.row)
    }
    
    func dealDetails(deal: DealData, index: Int){
        
        if self.navigationController != nil{
            let storyboard = UIStoryboard(name: "DealDetails", bundle: nil)
            let VC = storyboard.instantiateInitialViewController() as! DealViewController
            VC.hidesBottomBarWhenPushed = true
            VC.Deal = deal
            VC.fromDetails = false
            VC.photo = VC.Deal?.restrauntPhoto
            VC.index = index
            VC.from = "deals"
            //cleanup searchbar
            if self.searchBar != nil{
                self.searchBar.resignFirstResponder()
                self.searchBar.showsCancelButton = false
            }
            self.navigationController?.setNavigationBarHidden(false, animated: true)
            self.navigationController?.pushViewController(VC, animated: true)
            
        }
        else{
            self.navigationController?.setNavigationBarHidden(false, animated: true)
            self.performSegue(withIdentifier: "dealView", sender: ["deal":deal, "index":index])
        }
    }
    
 
    
    func tableView(_ tableView: UITableView,heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
   
    
    
    
    //SearchBar functions
    func setupSearchBar(){
        // Setup the Search Controller
        self.searchBar = UISearchBar()
        searchBar.showsCancelButton = false
        searchBar.placeholder = "Search Restaurants"
        searchBar.delegate = self
        self.navigationItem.titleView = searchBar
        if #available(iOS 11.0, *) {
            searchBar.heightAnchor.constraint(equalToConstant: 44).isActive = true
        }
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchBar.text! == "" {
            filteredDeals = UnfilteredDeals
        } else {
            // Filter the results
            filteredDeals = UnfilteredDeals.filter { ($0.restrauntName?.lowercased().contains(searchBar.text!.lowercased()))! }
        }
        DealsTable.reloadData()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        searchBar.showsCancelButton = false
        if searchBar.text! == "" {
            filteredDeals = UnfilteredDeals
        } else {
            // Filter the results
            filteredDeals = UnfilteredDeals.filter { ($0.restrauntName?.lowercased().contains(searchBar.text!.lowercased()))! }
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

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "dealView"{
            let VC = segue.destination as! DealViewController
            VC.hidesBottomBarWhenPushed = true
            let dict = sender as! Dictionary<String,Any>
            VC.Deal = dict["deal"] as? DealData
            VC.fromDetails = false
            VC.photo = VC.Deal?.restrauntPhoto
            VC.index = dict["index"] as! Int
            VC.from = "deals"
        }
    }
   
}
