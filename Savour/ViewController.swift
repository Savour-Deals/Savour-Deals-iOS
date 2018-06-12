//
//  ViewController.swift
//  Savour
//
//  Created by Chris Patterson on 8/1/17.
//  Copyright © 2017 Chris Patterson. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth
import CoreLocation




class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate{

    var searchBar: UISearchBar!
    @IBOutlet weak var loading: UIActivityIndicatorView!
    @IBOutlet var redeemedView: UIView!
    var handle: AuthStateDidChangeListenerHandle?
    var ref: DatabaseReference!
    var hasRefreshed = false
    var statusBar: UIView!
    var count = 0
    let placeholderImgs = ["Savour_Cup", "Savour_Fork", "Savour_Spoon"]
    var dealsData: DealsData!
    var vendorsData: VendorsData!
    
    var activeDeals = [DealData]()
    var inactiveDeals = [DealData]()
    var showedNotiDeal = false
    var locationManager: CLLocationManager!
    var userLocation: CLLocation!
    var initialLoaded = false
    
    @IBOutlet weak var retryButton: UIButton!
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
        self.loading.startAnimating()
        let user = Auth.auth().currentUser
        if user == nil {
            // No user is signed in.
            self.performSegue(withIdentifier: "Onboarding", sender: self)
        }
        ref = Database.database().reference()
        ref.keepSynced(true)
        if CLLocationManager.locationServicesEnabled() {
            switch CLLocationManager.authorizationStatus() {
            case .notDetermined:
                self.performSegue(withIdentifier: "tutorial", sender: self)
            case .authorizedAlways, .authorizedWhenInUse, .restricted, .denied:
                //Setup Deal Data for entire app
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                let tabBarController = (appDelegate.window?.rootViewController as? TabBarViewController)!
                DispatchQueue.global().sync {
                    tabBarController.dealSetup(completion: { (success) in
                        self.setup()
                    })
                }
            }
        } else {
            self.performSegue(withIdentifier: "tutorial", sender: self)
        }
    }
    
    func removeSubview(){
        if let viewWithTag = self.view.viewWithTag(100) {
            viewWithTag.removeFromSuperview()
        }
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
                else if self.initialLoaded{
                    self.refreshUI()
                }
            })
        }
        else {
            // No user is signed in.
            self.performSegue(withIdentifier: "Onboarding", sender: self)
        }
    }
    
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        //callback to know when the user accepts or denies location services
        if status == CLAuthorizationStatus.denied {
            locationDisabled()
        }else if status == .authorizedAlways || status == .authorizedWhenInUse  {
            userLocation = CLLocation(latitude: manager.location!.coordinate.latitude, longitude: manager.location!.coordinate.longitude)
            locationEnabled()
        }
    }
    
    func requestLocationAccess() {
        let status = CLLocationManager.authorizationStatus()
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            self.locationManager!.startUpdatingLocation()
            locationEnabled()
        case .denied, .restricted:
            locationDisabled()
        default:
            performSegue(withIdentifier: "tutorial", sender: self)
        }
    }
    
    func locationDisabled(){
        self.searchBar.isUserInteractionEnabled = false
        buttonsView.isUserInteractionEnabled = false
        let label = UILabel()
        label.textAlignment = NSTextAlignment.center
        label.font = UIFont.systemFont(ofSize: 20, weight: UIFont.Weight.heavy)
        label.text = "To use this app, you must turn on location in:\n\n Settings -> Savour -> Location"
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        label.numberOfLines = 0
        label.textColor = #colorLiteral(red: 0.2848863602, green: 0.6698332429, blue: 0.6656947136, alpha: 1)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.tag = 100
        self.view.addSubview(label)
        var constraints = [NSLayoutConstraint]()
        constraints.append(NSLayoutConstraint(item: label, attribute: NSLayoutAttribute.centerX, relatedBy: NSLayoutRelation.equal, toItem: self.view, attribute: NSLayoutAttribute.centerX, multiplier: 1.0, constant: 0.0))
        constraints.append(NSLayoutConstraint(item: label, attribute: NSLayoutAttribute.centerY, relatedBy: NSLayoutRelation.equal, toItem: self.view, attribute: NSLayoutAttribute.centerY, multiplier: 1.0, constant: 0.0))
        constraints.append(NSLayoutConstraint(item: label, attribute: NSLayoutAttribute.leading, relatedBy: NSLayoutRelation.equal, toItem: self.view, attribute: NSLayoutAttribute.leadingMargin, multiplier: 1.0, constant: 5.0))
        constraints.append(NSLayoutConstraint(item: label, attribute: NSLayoutAttribute.trailing, relatedBy: NSLayoutRelation.equal, toItem: self.view, attribute: NSLayoutAttribute.trailingMargin, multiplier: 1.0, constant: -5.0))
        NSLayoutConstraint.activate(constraints)
        self.loading.stopAnimating()
    }
    
    func locationEnabled(){
        DispatchQueue.main.async {
            if let _ = self.view.viewWithTag(100){
                self.view.viewWithTag(100)?.removeFromSuperview()
            }
            self.searchBar.isUserInteractionEnabled = true
            self.buttonsView.isUserInteractionEnabled = true
            self.locationManager!.startUpdatingLocation()
            self.userLocation = self.locationManager.location!
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
            (self.activeDeals, self.inactiveDeals) = self.dealsData.getDeals(dealType: title)
            if self.activeDeals.isEmpty && self.inactiveDeals.isEmpty{
                self.noDeals.isHidden = false
                
            }else{
                self.noDeals.isHidden = true
                
            }
            self.DealsTable.reloadData()
            self.loading.stopAnimating()
        }
    }
    
    func setup(){
        //Check if forcetouch is available
        if self.traitCollection.forceTouchCapability == .available {
            self.registerForPreviewing(with: self, sourceView: self.DealsTable)
        } else {
            print("3D Touch Not Available")
        }
        // Add Refresh Control to Table View
        if #available(iOS 10.0, *) {
            self.DealsTable.refreshControl = self.refreshControl
        } else {
            self.DealsTable.addSubview(self.refreshControl)
        }
        // Configure Refresh Control
        self.refreshControl.addTarget(self, action: #selector(self.refreshData(_:)), for: .valueChanged)
        self.setupSearchBar()
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
        self.locationManager = CLLocationManager()
        self.requestLocationAccess()
        initialLoaded = true
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
        
        searchBar.endEditing(true)
        searchBar.showsCancelButton = false
        searchBar.text = ""
        //dont call requestlocation or the user can get into a loop here
        let status = CLLocationManager.authorizationStatus()
        if status == CLAuthorizationStatus.denied {
            locationDisabled()
        } else if status == .authorizedAlways || status == .authorizedWhenInUse  {
            if self.activeDeals.count + inactiveDeals.count<1{
                locationEnabled()
            }
        }
        for deal in activeDeals{
            deal.updateTimes()
        }
        for deal in inactiveDeals{
            deal.updateTimes()
        }
        if initialLoaded{
            handle = Auth.auth().addStateDidChangeListener { (auth, user) in}
            if self.activeDeals.isEmpty && self.inactiveDeals.isEmpty{
                self.noDeals.isHidden = false
            }else{
                self.noDeals.isHidden = true
                self.DealsTable.reloadData()
            }
        }
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
        (self.activeDeals, self.inactiveDeals) = self.dealsData.getDeals(dealType: title)
        //take care of any loading animations
        if self.refreshControl.isRefreshing{
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { () -> Void in
                self.refreshControl.endRefreshing()
                if self.activeDeals.isEmpty && self.inactiveDeals.isEmpty{
                    self.noDeals.isHidden = false
                    
                }else{
                    self.noDeals.isHidden = true
                }
            }
        }
        self.DealsTable.reloadData()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //check if user clicked a notification and segue if they did
        if !showedNotiDeal{
            if let _ = dealsData{
                //If a user clicked a deal notification, segue to that deal
                if let notiDeal = dealsData.getNotificationDeal(dealID: notificationDeal){
                    self.dealDetails(deal: notiDeal)
                    showedNotiDeal = true
                }
            }

        }

        return activeDeals.count + inactiveDeals.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "dealCell", for: indexPath) as! DealTableViewCell
        var deal:DealData!
        if indexPath.row < activeDeals.count{
            deal = activeDeals[indexPath.row]
        }else{
            deal = inactiveDeals[indexPath.row-activeDeals.count]
        }
        cell.deal = deal
        cell.tempImg.image = UIImage(named: placeholderImgs[count])
        let photo = deal?.photo!
        if photo != ""{
            // UIImageView in your ViewController
            let imageView: UIImageView = cell.rImg
            cell.tempImg.image = UIImage(named: placeholderImgs[count])
            
            // Load the image using SDWebImage
            imageView.sd_setImage(with: URL(string:photo!), completed: { (img, err, typ, ref) in
                cell.tempImg.isHidden = true
            })
        }
        count = count + 1
        if count > 2{
            count = 0
        }
        cell.setupUI()
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath){
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.row < activeDeals.count {
            dealDetails(deal: activeDeals[indexPath.row])
        }else{
            dealDetails(deal: inactiveDeals[indexPath.row-activeDeals.count])
        }
    }
    
    func dealDetails(deal: DealData){
        if self.navigationController != nil{
            let storyboard = UIStoryboard(name: "DealDetails", bundle: nil)
            let VC = storyboard.instantiateInitialViewController() as! DealViewController
            VC.hidesBottomBarWhenPushed = true
            VC.Deal = deal
            VC.fromDetails = false
            VC.dealsData = self.dealsData
            VC.thisVendor = vendorsData.getVendorsByID(id: VC.Deal.rID!)
            VC.photo = VC.Deal?.photo
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
        searchBar.endEditing(true)
        searchBar.showsCancelButton = false
        searchBar.text = ""
        button.backgroundColor = UIColor.white
        button.setTitleColor(#colorLiteral(red: 0.2848863602, green: 0.6698332429, blue: 0.6656947136, alpha: 1), for: UIControlState.normal)
        let Title = button.currentTitle
        (activeDeals, inactiveDeals) = dealsData.filter(byTitle: Title!)
        if activeDeals.count + inactiveDeals.count < 1 {
            self.noDeals.isHidden = false
        }else{
            self.noDeals.isHidden = true
        }
        DealsTable.reloadData()
        if activeDeals.count + inactiveDeals.count>0{
            DealsTable.scrollToRow(at: IndexPath(row:0,section:0), at: .top, animated: false)
        }

    }
    
    
    //SearchBar functions
    func setupSearchBar(){
        // Setup the Search Controller
        searchBar = UISearchBar()
        searchBar.showsCancelButton = false
        searchBar.placeholder = "Search Vendors"
        searchBar.delegate = self
        self.navigationItem.titleView = searchBar
        if #available(iOS 11.0, *) {
            searchBar.heightAnchor.constraint(equalToConstant: 44).isActive = true
        }
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        (self.activeDeals, self.inactiveDeals) = dealsData.filter(byName: searchBar.text!)
        if activeDeals.count + inactiveDeals.count < 1 {
            self.noDeals.isHidden = false
        }else{
            self.noDeals.isHidden = true
        }
        DealsTable.reloadData()
        if activeDeals.count + inactiveDeals.count>0{
            DealsTable.scrollToRow(at: IndexPath(row:0,section:0), at: .top, animated: false)
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        searchBar.showsCancelButton = false
        (activeDeals, inactiveDeals) = dealsData.filter(byName: searchBar.text!)
        if activeDeals.count + inactiveDeals.count < 1 {
            self.noDeals.isHidden = false
        }else{
            self.noDeals.isHidden = true
        }
        DealsTable.reloadData()
        if activeDeals.count + inactiveDeals.count>0{
            DealsTable.scrollToRow(at: IndexPath(row:0,section:0), at: .top, animated: false)
        }
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.endEditing(true)
        searchBar.showsCancelButton = false
        (activeDeals, inactiveDeals) = dealsData.filter(byName: "All")
        if activeDeals.count + inactiveDeals.count < 1 {
            self.noDeals.isHidden = false
        }else{
            self.noDeals.isHidden = true
        }
    }
    
    func selectAllButton(){
        for subview in self.buttonsView.subviews as [UIView] {
            if let button = subview as? UIButton {
                button.backgroundColor = #colorLiteral(red: 0.2848863602, green: 0.6698332429, blue: 0.6656947136, alpha: 1)
                button.setTitleColor(UIColor.white, for: UIControlState.normal)
                if button.title(for: .normal) == "All"{
                    button.backgroundColor = UIColor.white
                    if activeDeals.count + inactiveDeals.count>0{
                        DealsTable.scrollToRow(at: IndexPath(row:0,section:0), at: .top, animated: false)
                    }
                    button.setTitleColor(#colorLiteral(red: 0.2848863602, green: 0.6698332429, blue: 0.6656947136, alpha: 1), for: UIControlState.normal)
                }
            }
        }
    }
 
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.showsCancelButton = true
        selectAllButton()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "dealView"{
            let VC = segue.destination as! DealViewController
            VC.hidesBottomBarWhenPushed = true
            let dict = sender as! Dictionary<String,Any>
            VC.Deal = dict["deal"] as? DealData
            VC.fromDetails = false
            VC.dealsData = self.dealsData

            VC.photo = VC.Deal?.photo
            VC.from = "deals"
        }else if segue.identifier == "tutorial"{
            let VC = segue.destination as! OnboardingViewController
            VC.sender = self
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
        if indexPath.row < activeDeals.count {
            VC.Deal = activeDeals[indexPath.row]
        }else{
            VC.Deal = inactiveDeals[indexPath.row-activeDeals.count]
        }
        VC.thisVendor = vendorsData.getVendorsByID(id: VC.Deal.rID!)
        VC.fromDetails = false
        VC.dealsData = self.dealsData
        VC.photo = VC.Deal?.photo
        VC.preferredContentSize = CGSize(width: 0.0, height: 600)
        previewingContext.sourceRect = cell.frame
        return VC
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        show(viewControllerToCommit, sender: self)
    }
}
