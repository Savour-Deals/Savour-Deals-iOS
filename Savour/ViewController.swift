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

    var searchBar: UISearchBar!
    @IBOutlet weak var loading: UIActivityIndicatorView!
    @IBOutlet var redeemedView: UIView!
    var handle: AuthStateDidChangeListenerHandle?
    var storage: Storage!
    var ref: DatabaseReference!
    var FavdealIDs: [String:String] = Dictionary<String, String>()
    var justOpened = true
    var alreadyGoing = false
    var statusBar: UIView!
    var count = 0
    let placeholderImgs = ["Savour_Cup", "Savour_Fork", "Savour_Spoon"]

    
    @IBOutlet weak var buttonsView: UIView!
    @IBOutlet weak var scrollFilter: UIScrollView!
    @IBOutlet weak var noDeals: UILabel!
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
        loading.startAnimating()
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
        
        statusBar = UIApplication.shared.value(forKey: "statusBar") as! UIView
        statusBar.backgroundColor = #colorLiteral(red: 0.2848863602, green: 0.6698332429, blue: 0.6656947136, alpha: 1)

        self.navigationController?.setNavigationBarHidden(false, animated: true)
        self.tabBarController?.tabBar.isHidden = false

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
        refreshControl.attributedTitle = NSAttributedString(string: "Fetching Deals", attributes: [NSAttributedStringKey.foregroundColor: #colorLiteral(red: 0.2848863602, green: 0.6698332429, blue: 0.6656947136, alpha: 1)])
        refreshControl.tintColor = #colorLiteral(red: 0.2848863602, green: 0.6698332429, blue: 0.6656947136, alpha: 1)
        refreshControl.addTarget(self, action: #selector(refreshData(_:)), for: .valueChanged)
        setupSearchBar()
        for subview in self.buttonsView.subviews as [UIView] {
            if let button = subview as? UIButton {
                button.layer.borderColor = UIColor.white.cgColor
                button.layer.borderWidth = 1
                button.layer.cornerRadius = 5
                button.addTarget(self, action: #selector(filterWithButtons(button:)), for: .touchUpInside)
                if button.title(for: .normal) == "All"{
                    button.backgroundColor = UIColor.white
                    button.setTitleColor(#colorLiteral(red: 0.2848863602, green: 0.6698332429, blue: 0.6656947136, alpha: 1), for: UIControlState.normal)
                }
            }
        }
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        handle = Auth.auth().addStateDidChangeListener { (auth, user) in}
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.navigationItem.title = ""
        UIApplication.shared.statusBarStyle = .lightContent
        statusBar = UIApplication.shared.value(forKey: "statusBar") as! UIView
        statusBar.backgroundColor = #colorLiteral(red: 0.2862745098, green: 0.6705882353, blue: 0.6666666667, alpha: 1)
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
        
    }
    
    func endRefresh(){
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { () -> Void in
            // When done requesting/reloading/processing invoke endRefreshing, to close the control
            self.refreshControl.endRefreshing()
        }
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
                    let temp = DealData(snap: snap, ID: (Auth.auth().currentUser?.uid)!)
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
                if notificationDeal != nil && UnfilteredDeals.count > 0{
                    for i in 0..<UnfilteredDeals.count{
                        if UnfilteredDeals[i].dealID == notificationDeal && !self.alreadyGoing{
                            self.alreadyGoing = true
                            notificationDeal = nil
                            self.dealDetails(deal: UnfilteredDeals[i],index: i)
                        }
                    }
                    
                }
                if UnfilteredDeals.count > 0 && sender != "favs"{
                    self.loadData(sender: "favs")
                }else{
                    filteredDeals.removeAll()
                    let temp = UnfilteredDeals
                    UnfilteredDeals.removeAll()
                    for deal in temp{
                        if !deal.redeemed!{
                            UnfilteredDeals.append(deal)
                        }else if let time = deal.redeemedTime{
                            if (Date().timeIntervalSince1970 - time) < 1800{
                                UnfilteredDeals.append(deal)
                            }
                        }
                    }
                    for subview in self.buttonsView.subviews as [UIView] {
                        if let button = subview as? UIButton {
                            if button.backgroundColor == UIColor.white{
                                button.sendActions(for: .touchUpInside)
                                break
                            }
                        }
                    }
                    filteredDeals = filteredDeals.sorted(by:{ (d1, d2) -> Bool in
                        if d1.valid && !d2.valid {
                            return true
                        }else if !d1.valid && d2.valid{
                            return false
                        }
                        else if d1.valid == d2.valid {
                            return CGFloat(d1.endTime!) < CGFloat(d2.endTime!)
                        }
                        return false
                    })
                }
                if self.refreshControl.isRefreshing{
                    self.endRefresh()
                }
                if self.loading.isAnimating{
                    self.loading.stopAnimating()
                }
            }){ (error) in
                print(error.localizedDescription)
            }
        
    }

    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredDeals.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "dealCell", for: indexPath) as! DealTableViewCell
        let deal = filteredDeals[indexPath.row]
        cell.deal = deal
        cell.tempImg.image = UIImage(named: placeholderImgs[count])
        count = count + 1
        if count > 2{
            count = 0
        }
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
            imageView.sd_setImage(with: storageref, placeholderImage: placeholderImage, completion: { (img, err, typ, ref) in
                cell.tempImg.isHidden = true
            })
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
            cell.validHours.text = ""
            if (interval.contains(current)){
                let cal = Calendar.current
                let Components = cal.dateComponents([.day, .hour, .minute], from: current, to: end)
                if (current > end){
                    cell.Countdown.text = "Deal Ended"
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
                cell.validHours.text = deal.validHours
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
                //self.scrollFilter.isHidden = true
            }, completion: nil)
        }
        else{
            UIView.animate(withDuration: 2.5, delay: 0,  options: UIViewAnimationOptions(), animations: {
                self.navigationController?.setNavigationBarHidden(false, animated: true)
                //self.scrollFilter.isHidden = false
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
    
   
    @objc func filterWithButtons(button: UIButton){
        for view in self.buttonsView.subviews as [UIView] {
            if let btn = view as? UIButton {
                btn.backgroundColor = #colorLiteral(red: 0.2848863602, green: 0.6698332429, blue: 0.6656947136, alpha: 1)
                btn.setTitleColor(UIColor.white, for: UIControlState.normal)
            }
        }
        button.backgroundColor = UIColor.white
        button.setTitleColor(#colorLiteral(red: 0.2848863602, green: 0.6698332429, blue: 0.6656947136, alpha: 1), for: UIControlState.normal)
        let title = button.currentTitle
        if title == "All" {
            filteredDeals = UnfilteredDeals
        }else if title == "%" || title == "$"{
            filteredDeals = UnfilteredDeals.filter { ($0.dealDescription!.lowercased().contains(title!.lowercased())) }
        }else if  title == "BOGO" {
            // Filter the results
            filteredDeals = UnfilteredDeals.filter { ($0.dealDescription!.lowercased().contains("Buy One Get One".lowercased())) }
        } else{
            filteredDeals = UnfilteredDeals.filter { ($0.dealType!.lowercased().contains(title!.lowercased())) }
        }
        filteredDeals.sort { CGFloat($0.endTime!) < CGFloat($1.endTime!) }
        if filteredDeals.count < 1 {
            self.DealsTable.isHidden = true
            self.noDeals.isHidden = false
        }else{
            self.DealsTable.isHidden = false
            self.noDeals.isHidden = true
        }
        DealsTable.reloadData()
    }
    
    
    //SearchBar functions
    func setupSearchBar(){
        // Setup the Search Controller
        searchBar = UISearchBar()
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
        if filteredDeals.count < 1 {
            self.DealsTable.isHidden = true
            self.noDeals.isHidden = false
        }else{
            self.DealsTable.isHidden = false
            self.noDeals.isHidden = true
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
        if filteredDeals.count < 1 {
            self.DealsTable.isHidden = true
            self.noDeals.isHidden = false
        }else{
            self.DealsTable.isHidden = false
            self.noDeals.isHidden = true
        }
        DealsTable.reloadData()
       
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        //searchBar.resignFirstResponder()
        searchBar.endEditing(true)
        searchBar.showsCancelButton = false
        if filteredDeals.count < 1 {
            self.DealsTable.isHidden = true
            self.noDeals.isHidden = false
        }else{
            self.DealsTable.isHidden = false
            self.noDeals.isHidden = true
        }
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
