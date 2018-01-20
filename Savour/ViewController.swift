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
    var hasRefreshed = false
//    var alreadyGoing = false
    var statusBar: UIView!
    var count = 0
    let placeholderImgs = ["Savour_Cup", "Savour_Fork", "Savour_Spoon"]
    var deals = Deals()

    
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
        //alreadyGoing = false
        ref = Database.database().reference()
        ref.keepSynced(true)
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
        refreshControl.addTarget(self, action: #selector(refreshData(_:)), for: .valueChanged)
        setupSearchBar()
        self.setupUI()
        self.DealsTable.dataSource = self
        self.DealsTable.delegate = self

    }
    
    func setupUI(){
        self.navigationController?.navigationBar.tintColor = UIColor.white
        self.navigationController?.view.backgroundColor = UIColor.white
        self.navigationController?.navigationItem.title = ""
        
        UIApplication.shared.statusBarStyle = .lightContent
        
        refreshControl.attributedTitle = NSAttributedString(string: "Fetching Deals", attributes: [NSAttributedStringKey.foregroundColor: #colorLiteral(red: 0.2848863602, green: 0.6698332429, blue: 0.6656947136, alpha: 1)])
        refreshControl.tintColor = #colorLiteral(red: 0.2848863602, green: 0.6698332429, blue: 0.6656947136, alpha: 1)
        
        statusBar = UIApplication.shared.value(forKey: "statusBar") as! UIView
        statusBar.backgroundColor = #colorLiteral(red: 0.2848863602, green: 0.6698332429, blue: 0.6656947136, alpha: 1)

        self.navigationController?.setNavigationBarHidden(false, animated: true)
        self.tabBarController?.tabBar.isHidden = false
        
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
    
    func refreshUI(){
        hasRefreshed = true
        self.navigationController?.navigationBar.tintColor = UIColor.white
        self.navigationController?.view.backgroundColor = UIColor.white
        self.navigationController?.navigationItem.title = ""
        
        UIApplication.shared.statusBarStyle = .lightContent
        
        refreshControl.attributedTitle = NSAttributedString(string: "Fetching Deals", attributes: [NSAttributedStringKey.foregroundColor: #colorLiteral(red: 0.2848863602, green: 0.6698332429, blue: 0.6656947136, alpha: 1)])
        refreshControl.tintColor = #colorLiteral(red: 0.2848863602, green: 0.6698332429, blue: 0.6656947136, alpha: 1)
        
        statusBar = UIApplication.shared.value(forKey: "statusBar") as! UIView
        statusBar.backgroundColor = #colorLiteral(red: 0.2848863602, green: 0.6698332429, blue: 0.6656947136, alpha: 1)
        
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        self.tabBarController?.tabBar.isHidden = false
        
        //Filter by any buttons the user pressed.
        var title = ""
        for subview in self.buttonsView.subviews as [UIView] {
            if let button = subview as? UIButton {
                if button.backgroundColor == UIColor.white{
                    title = button.title(for: .normal)!
                    break
                }
            }
        }
        deals.getDeals(table: self.DealsTable, dealType: title)
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        handle = Auth.auth().addStateDidChangeListener { (auth, user) in}
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
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
                    self.refreshUI()
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
        hasRefreshed = true
        var title = ""
        for subview in self.buttonsView.subviews as [UIView] {
            if let button = subview as? UIButton {
                if button.backgroundColor == UIColor.white{
                    title = button.title(for: .normal)!
                    break
                }
            }
        }
        deals.getDeals(table: self.DealsTable, dealType: title)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //check if user clicked a notification and segue if they did
        if !hasRefreshed{
            //If a user clicked a deal notification, segue to that deal
            if let notiDeal = deals.getNotificationDeal(dealID: notificationDeal){
                self.dealDetails(deal: notiDeal)
            }
        }
        //take care of any loading animations
        if refreshControl.isRefreshing{
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { () -> Void in
                self.refreshControl.endRefreshing()
            }
        }
        loading.stopAnimating()
        return deals.filteredDeals.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "dealCell", for: indexPath) as! DealTableViewCell
        let deal = deals.filteredDeals[indexPath.row]
        cell.deal = deal
        cell.tempImg.image = UIImage(named: placeholderImgs[count])
        count = count + 1
        if count > 2{
            count = 0
        }
        if !cell.deal.fav!{
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
            }, completion: nil)
        }
        else{
            UIView.animate(withDuration: 2.5, delay: 0,  options: UIViewAnimationOptions(), animations: {
                self.navigationController?.setNavigationBarHidden(false, animated: true)
            }, completion: nil)
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath){
        tableView.deselectRow(at: indexPath, animated: true)
        dealDetails(deal: deals.filteredDeals[indexPath.row])
    }
    
    func dealDetails(deal: DealData){
        if self.navigationController != nil{
            let storyboard = UIStoryboard(name: "DealDetails", bundle: nil)
            let VC = storyboard.instantiateInitialViewController() as! DealViewController
            VC.hidesBottomBarWhenPushed = true
            VC.Deal = deal
            VC.fromDetails = false
            VC.photo = VC.Deal?.restrauntPhoto
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
            self.performSegue(withIdentifier: "dealView", sender: ["deal":deal])
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
        let Title = button.currentTitle
        deals.filter(byTitle: Title!)
        if deals.filteredDeals.count < 1 {
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
        deals.filter(byName: searchBar.text!)
        if deals.filteredDeals.count < 1 {
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
        deals.filter(byName: searchBar.text!)
        if deals.filteredDeals.count < 1 {
            self.DealsTable.isHidden = true
            self.noDeals.isHidden = false
        }else{
            self.DealsTable.isHidden = false
            self.noDeals.isHidden = true
        }
        DealsTable.reloadData()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.endEditing(true)
        searchBar.showsCancelButton = false
        if deals.filteredDeals.count < 1 {
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
            VC.from = "deals"
        }
    }
}

extension ViewController:     UIViewControllerPreviewingDelegate {
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        guard let indexPath = DealsTable.indexPathForRow(at: location),
            let cell = DealsTable.cellForRow(at: indexPath) as? DealTableViewCell else {
                return nil }
        let storyboard = UIStoryboard(name: "DealDetails", bundle: nil)
        let VC = storyboard.instantiateInitialViewController() as! DealViewController
        VC.hidesBottomBarWhenPushed = true
        VC.Deal = deals.filteredDeals[indexPath.row]
        VC.fromDetails = false
        VC.photo = VC.Deal?.restrauntPhoto
        VC.preferredContentSize = CGSize(width: 0.0, height: 600)
        previewingContext.sourceRect = cell.frame
        return VC
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        show(viewControllerToCommit, sender: self)
    }
}
