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
import OneSignal
import LCUIComponents

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate{

    var searchBar: UISearchBar!
    @IBOutlet var redeemedView: UIView!
    var handle: AuthStateDidChangeListenerHandle?
    var ref: DatabaseReference!
    var hasRefreshed = false
    var statusBar: UIView!
    var count = 0
    let placeholderImgs = ["Savour_Cup", "Savour_Fork", "Savour_Spoon"]
    var dealsData: DealsData!
    var vendorsData: VendorsData!
    var searchbarData: [LCTuple<Double>] = []

    
    @IBOutlet weak var locationText: UILabel!
    var activeDeals = [DealData]()
    var inactiveDeals = [DealData]()
    var locationManager: CLLocationManager!
    var initialLoaded = false
    var sv: UIView!
    var onboardCallbackFlag = false
    
    @IBOutlet weak var buttonsView: UIView!
    @IBOutlet weak var scrollFilter: UIScrollView!
    @IBOutlet weak var noDeals: UILabel!
    private let refreshControl = UIRefreshControl()

    @IBOutlet weak var DealsTable: UITableView!
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // User not verified or not signed in. We want to send them back to the login page
        if !isUserVerified(user: Auth.auth().currentUser){
            let storyboard = UIStoryboard(name: "Onboarding", bundle: nil)
            let OnboardVC = storyboard.instantiateViewController(withIdentifier: "OnNav") as! UINavigationController
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            appDelegate.window!.rootViewController = OnboardVC
        }
        
        for i in 1...10 {
            searchbarData.append((key: Double(i*5), value: "\(i*5) miles"))
        }
        for i in 1...10 {
            searchbarData.append((key: Double(i*100), value: "\(i*100) miles"))
        }
        
        dealsData = DealsData(radiusMiles: geoFireRadius)
        vendorsData = VendorsData(radiusMiles: geoFireRadius)
        
        //Setup loading deals
        locationManager = CLLocationManager()

        locationText.text = "To use this app, you must turn on location in:\n\n Settings -> Savour -> Location"
        sv = UIViewController.displaySpinner(onView: self.view, color: #colorLiteral(red: 0.2862745098, green: 0.6705882353, blue: 0.6666666667, alpha: 1))
        
        ref = Database.database().reference()
        ref.keepSynced(true)
        self.setup()
        
        //Determine if user has allowed location
        if CLLocationManager.locationServicesEnabled() {
            checkLocationStatus(status: CLLocationManager.authorizationStatus())
        } else {
            //User has global location services turned off
            locationDisabled()
        }
        
        //Allow us to refresh when opened from background
        NotificationCenter.default.addObserver(self, selector: #selector(self.requestLocationAccess), name:UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.requestLocationAccess), name:NSNotification.Name.NotificationDealIsAvailable, object: nil)
    }
    
    private func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        //callback to know when the user accepts or denies location services
        checkLocationStatus(status: status)
    }
    
    @objc func requestLocationAccess() {
        checkLocationStatus(status: CLLocationManager.authorizationStatus())
    }
    
    func onboardCallback(){
        onboardCallbackFlag = true
        checkLocationStatus(status: CLLocationManager.authorizationStatus())
    }
    
    func checkLocationStatus(status: CLAuthorizationStatus){
        switch status {
        case .notDetermined:
            //Not prompted, might as well send them to the onboarding page
            performSegue(withIdentifier: "tutorial", sender: self)
        case .authorizedAlways, .authorizedWhenInUse:
            //Location approved. Setup Deal Data for entire app
            if !onboardCallbackFlag{
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) { // Prompt for notifications if we never have
                    OneSignal.promptForPushNotifications { (accepted) in
                        if accepted{
                            print("accepted")
                        }else{
                            print("Not accepted")
                        }
                    }
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 10) { // Display message if loading is slow
                if !self.dealsData.isComplete(){
                    Toast.showNegativeMessage(message: "Deals seem to be taking a while to load. Check your internet connection to make sure you're online.")
                }
            }
            DispatchQueue.global(qos: .background).async {
                self.dealsData.startDealUpdates(completion: { (success) in
                    if self.dealsData.isComplete(){
                        self.finishLoad()
                    }
                })
                self.vendorsData.startVendorUpdates(completion: { (success) in
                })
            }
        case .restricted, .denied:
            //Sadly user won't give us location. Tell them how to turn on
            locationDisabled()
        }
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .lightContent
    }
    
    deinit { //Remove background observer
        NotificationCenter.default.removeObserver(self)
    }
    
    func removeSubview(){
        if let viewWithTag = self.view.viewWithTag(100) {
            viewWithTag.removeFromSuperview()
        }
    }
    
    func finishLoad(){
        //Finish view setup
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        if let tabBarController = appDelegate.window?.rootViewController as? TabBarViewController{
            tabBarController.tabBar.isUserInteractionEnabled = true
        }
        initialLoaded = true
        self.locationEnabled()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let user = Auth.auth().currentUser
        if user != nil {
            if self.initialLoaded{
                //Ask for notification access to catch anyone we missed in onboarding
                OneSignal.promptForPushNotifications { (userResponse) in }
                
                self.navigationController?.setNavigationBarHidden(false, animated: true)
                self.navigationController?.navigationBar.tintColor = UIColor.white
                self.navigationController?.view.backgroundColor = UIColor.white
                self.navigationController?.navigationItem.title = ""
                
                self.refreshControl.attributedTitle = NSAttributedString(string: "Fetching Deals", attributes: [NSAttributedString.Key.foregroundColor: #colorLiteral(red: 0.2848863602, green: 0.6698332429, blue: 0.6656947136, alpha: 1)])
                self.refreshControl.tintColor = #colorLiteral(red: 0.2862745098, green: 0.6705882353, blue: 0.6666666667, alpha: 1)
                
                self.statusBar = UIApplication.shared.value(forKey: "statusBar") as? UIView
                self.statusBar.backgroundColor = #colorLiteral(red: 0.2848863602, green: 0.6698332429, blue: 0.6656947136, alpha: 1)
                
                self.self.tabBarController?.tabBar.isHidden = false
                
                self.searchBar.endEditing(true)
                self.searchBar.showsCancelButton = false
                self.searchBar.text = ""
                self.refresh()
            }
        }else {
            // No user is signed in.
            self.performSegue(withIdentifier: "Onboarding", sender: self)
        }
    }
    
    
    func locationDisabled(){
        self.searchBar.isUserInteractionEnabled = false
        buttonsView.isUserInteractionEnabled = false
        self.locationText.isHidden = false
        self.DealsTable.isHidden = true
        UIViewController.removeSpinner(spinner: sv)
    }
    
    func locationEnabled(){
        DispatchQueue.main.async {
            if let _ = self.view.viewWithTag(100){
                self.view.viewWithTag(100)?.removeFromSuperview()
            }
            self.DealsTable.isHidden = false
            self.locationText.isHidden = true
            self.searchBar.isUserInteractionEnabled = true
            self.buttonsView.isUserInteractionEnabled = true
            self.locationManager!.startUpdatingLocation()
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
            (self.activeDeals, self.inactiveDeals) = self.dealsData.getDeals(byType: title)
            if self.activeDeals.isEmpty && self.inactiveDeals.isEmpty{
                self.noDeals.isHidden = false
            }else{
                self.noDeals.isHidden = true
            }
            self.DealsTable.reloadData()
            UIViewController.removeSpinner(spinner: self.sv)
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
        
//        UIApplication.shared.statusBarStyle = .lightContent
        
        refreshControl.attributedTitle = NSAttributedString(string: "Fetching Deals", attributes: [NSAttributedString.Key.foregroundColor: #colorLiteral(red: 0.2848863602, green: 0.6698332429, blue: 0.6656947136, alpha: 1)])
        refreshControl.tintColor = #colorLiteral(red: 0.2848863602, green: 0.6698332429, blue: 0.6656947136, alpha: 1)
        
        statusBar = UIApplication.shared.value(forKey: "statusBar") as? UIView
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
                    button.setTitleColor(#colorLiteral(red: 0.2848863602, green: 0.6698332429, blue: 0.6656947136, alpha: 1), for: UIControl.State.normal)
                }
            }
        }
    }
    
    
    //These two functions prevent jitter of tableview when popping back to this view
    var cellHeights: [IndexPath : CGFloat] = [:]

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cellHeights[indexPath] = cell.frame.size.height
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let height = cellHeights[indexPath] else { return 70.0 }
        return height
    }
    
    @objc func refresh(){
        hasRefreshed = true
        self.dealsData.updateRadius(rad: geoFireRadius)
        self.vendorsData.updateRadius(rad: geoFireRadius)
        //dont call requestlocation or the user can get into a loop here
        let status = CLLocationManager.authorizationStatus()
        if status == CLAuthorizationStatus.denied {
            locationDisabled()
        } else if status == .authorizedAlways || status == .authorizedWhenInUse  {
            if self.activeDeals.count + inactiveDeals.count<1{
                locationEnabled()
            }
        }
        refreshData(self)
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
        if searchBar.text != ""{
            (self.activeDeals, self.inactiveDeals) = self.dealsData.getDeals(byName: searchBar.text)
        }else{
            (self.activeDeals, self.inactiveDeals) = self.dealsData.getDeals(byType: title)
        }
        dealsData.updateDistances()
        dealsData.sortDeals(array: &self.activeDeals)
        dealsData.sortDeals(array: &self.inactiveDeals)
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
        }else{
            if self.activeDeals.isEmpty && self.inactiveDeals.isEmpty{
                self.noDeals.isHidden = false
                
            }else{
                self.noDeals.isHidden = true
            }
        }
        self.DealsTable.reloadData()
    }
    
    @objc func showNotificationDeal(){
        //check if user clicked a notification and segue if they did
        if notificationDeal != ""{
            if let _ = dealsData{
                //If a user clicked a deal notification, segue to that deal
                //If cold start, this wont work from the custom notification
                if let notiDeal = dealsData.getNotificationDeal(dealID: notificationDeal){
                    self.dealDetails(deal: notiDeal)
                    notificationDeal = ""
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        showNotificationDeal()
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
            if let url = URL(string:(photo!)){
                imageView.sd_setImage(with: url, completed: { (img, err, typ, ref) in
                    cell.tempImg.isHidden = true
                })
            }
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
        return UITableView.automaticDimension
    }
    
   
    @objc func filterWithButtons(button: UIButton){
        for view in self.buttonsView.subviews as [UIView] {
            if let btn = view as? UIButton {
                btn.backgroundColor = #colorLiteral(red: 0.2848863602, green: 0.6698332429, blue: 0.6656947136, alpha: 1)
                btn.setTitleColor(UIColor.white, for: UIControl.State.normal)
            }
        }
        searchBar.endEditing(true)
        searchBar.showsCancelButton = false
        searchBar.text = ""
        button.backgroundColor = UIColor.white
        button.setTitleColor(#colorLiteral(red: 0.2848863602, green: 0.6698332429, blue: 0.6656947136, alpha: 1), for: UIControl.State.normal)
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
        searchBar.placeholder = "Search Deals"
        searchBar.delegate = self
        searchBar.showsBookmarkButton = true
        searchBar.setImage(UIImage(named: "distance"), for: .bookmark, state: .normal)
        
        searchBar.setPositionAdjustment(UIOffset(horizontal: 0, vertical: 0), for: .bookmark)
        

        self.navigationItem.titleView = searchBar
        if #available(iOS 11.0, *) {
            searchBar.heightAnchor.constraint(equalToConstant: 44).isActive = true
        }
    }
    
    func searchBarBookmarkButtonClicked(_ searchBar: UISearchBar) {
        let popover = LCPopover<Double>(for: searchBar, title: "Search Radius") { tuple in
            // Use of the selected tuple
            guard let value = tuple?.key else { return }
            print(value)
            geoFireRadius = value
            self.dealsData.updateRadius(rad: value)
            self.vendorsData.updateRadius(rad: value)
            self.DealsTable.reloadData()
            
        }
        // Assign data to the dataList
        popover.dataList = searchbarData
        
        popover.backgroundColor = #colorLiteral(red: 0.2848863602, green: 0.6698332429, blue: 0.6656947136, alpha: 1)
        popover.borderColor = #colorLiteral(red: 0.2848863602, green: 0.6698332429, blue: 0.6656947136, alpha: 1)
        popover.borderWidth = 2
        popover.titleColor = .white
        popover.textColor = .black
        // Present the popover
        present(popover, animated: true, completion: nil)
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchBar.showsBookmarkButton = false

        (self.activeDeals, self.inactiveDeals) = dealsData.filter(byText: searchBar.text!)
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
        searchBar.showsBookmarkButton = true
        searchBar.showsCancelButton = false
        (activeDeals, inactiveDeals) = dealsData.filter(byText: searchBar.text!)
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
        searchBar.showsBookmarkButton = true
        searchBar.endEditing(true)
        searchBar.showsCancelButton = false
        (activeDeals,inactiveDeals) = self.dealsData.getDeals(byName: searchBar.text)
        DealsTable.reloadData()
    }
    
    func selectAllButton(){
        (activeDeals,inactiveDeals) = self.dealsData.getDeals()
        if activeDeals.count + inactiveDeals.count < 1 {
            self.noDeals.isHidden = false
        }else{
            self.noDeals.isHidden = true
        }
        DealsTable.reloadData()
        for subview in self.buttonsView.subviews as [UIView] {
            if let button = subview as? UIButton {
                button.backgroundColor = #colorLiteral(red: 0.2848863602, green: 0.6698332429, blue: 0.6656947136, alpha: 1)
                button.setTitleColor(UIColor.white, for: UIControl.State.normal)
                if button.title(for: .normal) == "All"{
                    button.backgroundColor = UIColor.white
                    if activeDeals.count + inactiveDeals.count>0{
                        DealsTable.scrollToRow(at: IndexPath(row:0,section:0), at: .top, animated: false)
                    }
                    button.setTitleColor(#colorLiteral(red: 0.2848863602, green: 0.6698332429, blue: 0.6656947136, alpha: 1), for: UIControl.State.normal)
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

extension ViewController: UIViewControllerPreviewingDelegate {
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
