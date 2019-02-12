//
//  FavoritesViewController.swift
//  Savour
//
//  Created by Chris Patterson on 8/6/17.
//  Copyright © 2017 Chris Patterson. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase
import SDWebImage
import FirebaseAuth
import CoreLocation

class FavoritesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate{
    private var user: String!
    @IBOutlet weak var FavTable: UITableView!

    private var locationManager: CLLocationManager!

    @IBOutlet weak var locationText: UILabel!
    private var sv: UIView!
    private var statusBar: UIView!
    @IBOutlet weak var heartImg: UIImageView!
    @IBOutlet weak var emptyView: UIView!
    
    private var ref: DatabaseReference!
    private var dealsData: DealsData!
    private var vendorsData: VendorsData!
    private var favDeals =  [DealData]()
    
    private var count = 0
    private let placeholderImgs = ["Savour_Cup", "Savour_Fork", "Savour_Spoon"]
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        if traitCollection.forceTouchCapability == .available {
            registerForPreviewing(with: self, sourceView: self.FavTable)
        } else {
            print("3D Touch Not Available")
        }
        
        locationManager = CLLocationManager()
        sv = UIViewController.displaySpinner(onView: self.view, color: #colorLiteral(red: 0.2862745098, green: 0.6705882353, blue: 0.6666666667, alpha: 1))
        statusBar = UIApplication.shared.value(forKey: "statusBar") as? UIView
        
        //Allow us to refresh when opened from background
        NotificationCenter.default.addObserver(self, selector: #selector(self.checkLocationAccess), name:UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.checkLocationAccess), name:NSNotification.Name.NotificationDealIsAvailable, object: nil)
        checkLocationAccess()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        statusBar.backgroundColor = #colorLiteral(red: 0.2848863602, green: 0.6698332429, blue: 0.6656947136, alpha: 1)
        checkLocationAccess()
        self.navigationController?.navigationItem.title = "Favorites"
        self.navigationController?.navigationBar.tintColor = UIColor(red: 73/255, green: 171/255, blue: 170/255, alpha: 1.0)
    }
    
    @objc func checkLocationAccess(){
        let status = CLLocationManager.authorizationStatus()
        if status == .authorizedAlways || status == .authorizedWhenInUse  {
            DispatchQueue.main.asyncAfter(deadline: .now() + 10) { // Display message if loading is slow
                if let _ = self.dealsData{
                    if !self.dealsData.isComplete(){
                        Toast.showNegativeMessage(message: "Favorites seem to be taking a while to load. Check your internet connection to make sure you're online.")
                    }
                }
            }
            if dealsData == nil{
                dealsData = DealsData(radiusMiles: geoFireRadius)
            }
            if vendorsData == nil{
                vendorsData = VendorsData(radiusMiles: geoFireRadius)
            }
            self.dealsData.startDealUpdates(completion: { (success) in
                if self.dealsData.isComplete(){
                    UIViewController.removeSpinner(spinner: self.sv)
                    self.locationEnabled()
                }
            })
            self.vendorsData.startVendorUpdates(completion: { (success) in
            })
        }else{
            self.locationDisabled()
            UIViewController.removeSpinner(spinner: sv)
        }
    }
    
    deinit { //Remove background observer
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func requestLocationAccess() {
        let status = CLLocationManager.authorizationStatus()
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            self.locationManager!.startUpdatingLocation()
            self.locationEnabled()
        case .denied, .restricted:
            locationDisabled()
        default:
            performSegue(withIdentifier: "tutorial", sender: self)
        }
    }
    
    func locationEnabled(){
        locationText.isHidden = true
        heartImg.image = self.heartImg.image?.withRenderingMode(.alwaysTemplate)
        heartImg.tintColor = UIColor.red

        FavTable.isHidden = false
        var activeFav = [DealData]()
        var inactiveFav = [DealData]()

        dealsData.updateDistances()
        (activeFav,inactiveFav) = dealsData.getFavorites()
        dealsData.sortDeals(array: &activeFav)
        dealsData.sortDeals(array: &inactiveFav)

        favDeals = activeFav + inactiveFav
        
        if favDeals.isEmpty{
            emptyView.isHidden = false
        }else{
            emptyView.isHidden = true
        }
        
        self.FavTable.reloadData()
        FavTable.tableFooterView = UIView()
    }
    
    func locationDisabled(){
        FavTable.isHidden = true
        locationText.isHidden = false
        dealsData = nil
        vendorsData = nil
        heartImg.image = self.heartImg.image?.withRenderingMode(.alwaysTemplate)
        heartImg.tintColor = UIColor.red
        statusBar = UIApplication.shared.value(forKey: "statusBar") as? UIView
        statusBar.backgroundColor = #colorLiteral(red: 0.2848863602, green: 0.6698332429, blue: 0.6656947136, alpha: 1)

        self.favDeals.removeAll()

        self.FavTable.reloadData()
        FavTable.tableFooterView = UIView()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return favDeals.count
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
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "dealCell", for: indexPath) as! DealTableViewCell
        cell.deal = favDeals[indexPath.row]
        cell.tempImg.image = UIImage(named: placeholderImgs[count])
        count = count + 1
        if count > 2{
            count = 0
        }
        let photo = cell.deal?.photo!
        if photo != ""{
            // UIImageView in ViewController
            let imageView: UIImageView = cell.rImg
            cell.tempImg.image = UIImage(named: placeholderImgs[count])
            
            // Load the image using SDWebImage
            imageView.sd_setImage(with: URL(string:photo!), completed: { (img, err, typ, ref) in
                cell.tempImg.isHidden = true
            })
        }
        cell.likeButton.addTarget(self,action: #selector(removePressed(sender:event:)),for:UIControl.Event.touchUpInside)
        cell.setupUI()
        return cell
    }
    
    @IBAction func removePressed(sender: UIButton, event: UIEvent){
        let touches = event.touches(for: sender)
        if let touch = touches?.first{
            let point = touch.location(in: FavTable)
            if let indexPath = FavTable.indexPathForRow(at: point) {
                let cell = FavTable.cellForRow(at: indexPath) as? DealTableViewCell
                let user = Auth.auth().currentUser?.uid
                Database.database().reference().child("Users").child(user!).child("favorites").child((cell?.deal.id!)!).removeValue()
                favDeals.remove(at: indexPath.item)
                self.FavTable.reloadData()
                if favDeals.count < 2 && favDeals.count > 0{
                    let indexPath = IndexPath(row: 0, section: 0)
                    self.FavTable.scrollToRow(at: indexPath, at: .top, animated: true)
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath){
        tableView.deselectRow(at: indexPath, animated: true)
        let storyboard = UIStoryboard(name: "DealDetails", bundle: nil)
        let VC = storyboard.instantiateInitialViewController() as! DealViewController
        VC.hidesBottomBarWhenPushed = true
        VC.Deal = favDeals[indexPath.row]
        VC.dealsData = self.dealsData
        VC.fromDetails = false
        VC.photo = VC.Deal?.photo
        if let vendor = vendorsData.getVendorsByID(id: VC.Deal.rID!){
            VC.thisVendor = vendor
            self.navigationController?.setNavigationBarHidden(false, animated: true)
            self.navigationController?.pushViewController(VC, animated: true)
        }else {
            let alert = UIAlertController(title: "Oops!", message: "Sorry! We could not get information about this deal at this time. We are working on this!", preferredStyle: .alert)
            let approveAction = UIAlertAction(title: "Okay", style: .default) { (alert: UIAlertAction!) -> Void in}
            alert.addAction(approveAction)
            self.present(alert, animated: true, completion:nil)
        }

    }

    func tableView(_ tableView: UITableView,heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        return UITableView.automaticDimension
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        self.navigationController?.setNavigationBarHidden(false, animated: true)
    }
}

extension FavoritesViewController: UIViewControllerPreviewingDelegate {
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        
        guard let indexPath = FavTable.indexPathForRow(at: location),
            let cell = FavTable.cellForRow(at: indexPath) as? DealTableViewCell else {
                return nil }
        let storyboard = UIStoryboard(name: "DealDetails", bundle: nil)
        let VC = storyboard.instantiateInitialViewController() as! DealViewController
        VC.hidesBottomBarWhenPushed = true
        VC.Deal = favDeals[indexPath.row]
        VC.fromDetails = false
        VC.dealsData = self.dealsData
        if let vendor = vendorsData.getVendorsByID(id: VC.Deal.rID!){
            VC.thisVendor = vendor
        }else{
            let alert = UIAlertController(title: "Oops!", message: "Sorry! We could not get information about this deal at this time. We are working on this!", preferredStyle: .alert)
            let approveAction = UIAlertAction(title: "Okay", style: .default) { (alert: UIAlertAction!) -> Void in}
            alert.addAction(approveAction)
            self.present(alert, animated: true, completion:nil)
        }
        VC.photo = VC.Deal?.photo
        VC.preferredContentSize =
            CGSize(width: 0.0, height: 600)
        previewingContext.sourceRect = cell.frame
        return VC
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        show(viewControllerToCommit, sender: self)
    }
}
