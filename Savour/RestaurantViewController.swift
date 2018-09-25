//
//  RestaurantViewController.swift
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
import FirebaseStorage
import OneSignal
import AVFoundation
import GTProgressBar
import SafariServices
import FirebaseFunctions



class RestaurantViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    var handle: AuthStateDidChangeListenerHandle?
    var ref: DatabaseReference!
    var storage: Storage!
    var dealsData: DealsData!
    var activeDeals = [DealData]()
    var inactiveDeals = [DealData]()
    var indices = [Int]()
    var cachedImageViewSize: CGRect!
    var cachedTextPoint: CGPoint!
    var loyaltyCode: String!
    var thisVendor: VendorData!
    var loyaltyRedemptions: Int!
    var redemptionTime: Double!
    var expandedCells: [Bool] = [false, false]
    var followButton: UIButton!
    lazy var functions = Functions.functions()
    
    @IBOutlet weak var overview: UIView!
    @IBOutlet weak var ContentView: UIView!
    @IBOutlet weak var restaurantTable: UITableView!
    @IBOutlet weak var rImg: UIImageView!
    @IBOutlet weak var rName: UILabel!
    var menu: String!
    var followString: String!
    var request: URLRequest?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tabBarController?.tabBar.isHidden = true
        ref = Database.database().reference()
        storage = Storage.storage()
        loadData()
        
        self.thisVendor.updateDistance()
        
        restaurantTable.rowHeight = UITableView.automaticDimension
        restaurantTable.estimatedRowHeight = 45
        self.cachedImageViewSize = self.rImg.frame
        self.cachedTextPoint = self.rName.center
        let footerView = UIView()
        footerView.backgroundColor = #colorLiteral(red: 0.2848863602, green: 0.6698332429, blue: 0.6656947136, alpha: 0)
        self.restaurantTable.tableFooterView = footerView
        self.restaurantTable.sectionHeaderHeight = self.rImg.frame.height

        
        self.navigationController?.navigationBar.tintColor = UIColor.white
        let imageView = UIImageView(image: UIImage(named: "Savour_White"))
        imageView.contentMode = UIView.ContentMode.scaleAspectFit
        let titleView = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 40))
        imageView.frame = titleView.bounds
        titleView.addSubview(imageView)
        if #available(iOS 11.0, *) {
            restaurantTable.contentInsetAdjustmentBehavior = .never
        }
        self.navigationItem.titleView = titleView
        self.navigationItem.backBarButtonItem?.title = ""
    }
    
 
    override func viewDidAppear(_ animated: Bool) {
        self.tabBarController?.tabBar.isHidden = true
        ref.child("Users").child((Auth.auth().currentUser?.uid)!).observeSingleEvent(of: .value, with: { (snapshot) in
            if snapshot.childSnapshot(forPath: "following").hasChild((self.thisVendor.id)!){
                self.followString = "Following"
            }
            else{
                self.followString = "Follow"
            }
            self.restaurantTable.reloadData()
        })
    }
    
    @IBAction func backSwipe(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    func loadData(){
        //Set overall restraunt info TODO: COMBINE THESE
        ref.child("Users").child((Auth.auth().currentUser?.uid)!).child("loyalty").child((thisVendor.id)!).child("redemptions").observeSingleEvent(of: .value, with: { (snapshot) in
            if snapshot.exists(){
                let value = snapshot.value as? NSDictionary
                self.loyaltyRedemptions = value?["count"] as? Int ?? 0
                self.redemptionTime = value?["time"] as? Double ?? 0.0
            }else{
                self.loyaltyRedemptions = 0
                self.redemptionTime = 0.0
            }
            self.reloadTable()
        }){ (error) in
            print(error.localizedDescription)
        }
        ref.child("Users").child((Auth.auth().currentUser?.uid)!).observeSingleEvent(of: .value, with: { (snapshot) in
            //let value = snapshot.value as? NSDictionary
            if snapshot.childSnapshot(forPath: "following").hasChild((self.thisVendor.id)!){
                self.followString = "Following"
            }
            else{
                self.followString = "Follow"
            }
            self.reloadTable()
        })
        ref.child("Vendors").child((thisVendor.id)!).observeSingleEvent(of: .value, with: { (snapshot) in
            self.rName.text = self.thisVendor.name
            
            if self.thisVendor.photo != ""{
                // UIImageView in your ViewController
                let imageView: UIImageView = self.rImg
        
                // Placeholder image
                let placeholderImage = UIImage(named: "placeholder.jpg")
        
                // Load the image using SDWebImage
                imageView.sd_setImage(with: URL(string: self.thisVendor.photo!), placeholderImage: placeholderImage)
            }
            self.reloadTable()
        }){ (error) in
            print(error.localizedDescription)
        }
        (activeDeals,inactiveDeals) = dealsData.getDeals(forRestaurant: self.thisVendor.id!)
        self.reloadTable()
    }
    
    func reloadTable(){
        if loyaltyRedemptions != nil && followString != nil {
            self.restaurantTable.delegate = self
            self.restaurantTable.dataSource = self
            self.restaurantTable.reloadData()
            self.restaurantTable.isHidden = false
        }
    }
    
    func tableView(_ tableView: UITableView,heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == 0{
            return 100
        }else if indexPath.row == 1{
            return UITableView.automaticDimension
        }else if indexPath.row == 2{
//            if self.thisVendor.hoursArray.count > 0{
//                if expandedCells[1]{
//                    return UITableViewAutomaticDimension
//                }else {
//                    return 60
//                }
//            }else{
                return 0
//            }
        }else if indexPath.row == 3{
            if self.thisVendor.loyalty.loyaltyCount > 0{
                return UITableView.automaticDimension
            }
            else{
                return 0
            }
            
        }
        else if indexPath.row == 5{
            if self.activeDeals.count + self.inactiveDeals.count > 0{
                return 150
            }else{
                return 0
            }
        }
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 6
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.row == 0{
            let cell = tableView.dequeueReusableCell(withIdentifier: "buttonCell", for: indexPath) as! buttonCell
            cell.followButton.setTitle(self.followString, for: .normal)
            cell.mainView = self
            if self.thisVendor.loyalty.loyaltyCount > 0 {
                cell.hasLoyalty = true
            }
            if self.followString == "Follow"{
                self.redemptionTime = 0
                cell.followButton.backgroundColor = #colorLiteral(red: 0.6666666865, green: 0.6666666865, blue: 0.6666666865, alpha: 1)
            }else{
                cell.followButton.backgroundColor = #colorLiteral(red: 0.2848863602, green: 0.6698332429, blue: 0.6656947136, alpha: 1)
            }
            cell.followButton.setTemplateImg(Img: #imageLiteral(resourceName: "follow"))
            cell.menuButton.setTemplateImg(Img: #imageLiteral(resourceName: "menu"))
            cell.directionsButton.setTemplateImg(Img: #imageLiteral(resourceName: "directions"))
            cell.followButton.layer.cornerRadius = 20
            cell.menuButton.layer.cornerRadius = 20
            cell.directionsButton.layer.cornerRadius = 20
            cell.request = self.request
            cell.menu = self.thisVendor.menu
            cell.rID = self.thisVendor.id
            cell.rAddress = self.thisVendor.address!
            self.followButton = cell.followButton
            return cell
        }
        else if indexPath.row == 1{
            let cell = tableView.dequeueReusableCell(withIdentifier: "descCell", for: indexPath) as! aboutCell
            cell.label.text = "\n" +  self.thisVendor.description!
            cell.address.text = thisVendor.address!
            if thisVendor.dailyHours.count == 7{
                cell.todayHours.text = thisVendor.dailyHours[Date().dayNumberOfWeek()!-1]
            }else{
                cell.todayHours.text = "Not Available"
            }
            if expandedCells[0]{
                cell.label.numberOfLines = 0
                cell.label.lineBreakMode = .byWordWrapping
                cell.show.text = "Show less..."
            }else{
                cell.label.numberOfLines = 3
                cell.label.lineBreakMode = .byTruncatingTail
                cell.show.text = "Show more..."
            }
            return cell
        }
        else if indexPath.row == 2{
            let cell = tableView.dequeueReusableCell(withIdentifier: "hoursCell", for: indexPath) as! happyHourCell
//            if self.thisVendor.hoursArray.count > 0{
//                let thisHoursArray = self.thisVendor.hoursArray
//                let mutableAttributedString = NSMutableAttributedString()
//                let leftAlign = NSMutableParagraphStyle()
//                leftAlign.alignment = .left
//                let attrs = [NSAttributedStringKey.font : UIFont.systemFont(ofSize: 20, weight: UIFont.Weight.heavy), NSAttributedStringKey.paragraphStyle: leftAlign]
//                let header = NSMutableAttributedString(string:"Happy Hours\n", attributes:attrs)
//                var hours = "Monday: " + thisHoursArray[0] + "\n"
//                hours = hours + "Tuesday: " + thisHoursArray[1] + "\n"
//                hours = hours + "Wednesday: " + thisHoursArray[2] + "\n"
//                hours = hours + "Thursday: " + thisHoursArray[3] + "\n"
//                hours = hours + "Friday: " + thisHoursArray[4] + "\n"
//                hours = hours + "Saturday: " + thisHoursArray[5] + "\n"
//                hours = hours + "Sunday: " + thisHoursArray[6] + "\n"
//                let center = NSMutableParagraphStyle()
//                center.alignment = .center
//                let attrs1 = [NSAttributedStringKey.foregroundColor : UIColor.darkGray, NSAttributedStringKey.paragraphStyle: center, NSAttributedStringKey.font : UIFont.systemFont(ofSize: 15, weight: UIFont.Weight.regular)]
//                let hourCenter = NSMutableAttributedString(string:hours, attributes:attrs1)
//                mutableAttributedString.append(header)
//                mutableAttributedString.append(hourCenter)
//                cell.happyhours.attributedText = mutableAttributedString
//                if expandedCells[1]{
//                    cell.show.text = "Hide hours..."
//                }else{
//                    cell.show.text = "Show hours..."
//                }
//            }
            return cell
        }
        else if indexPath.row == 3{
            let cell = tableView.dequeueReusableCell(withIdentifier: "loyaltyCell", for: indexPath) as! loyaltyCell
            if self.thisVendor.loyalty.loyaltyCount > 0 {
                cell.checkin.layer.cornerRadius = cell.checkin.frame.height/2
                cell.progressBar.isHidden = false
                if thisVendor.loyalty.loyaltyCount <= loyaltyRedemptions{
                    cell.animate()
                    cell.checkin.setTitle("Reedeem", for: .normal)
                    cell.loyaltyLabel.text = "You're ready to redeem your \(thisVendor.loyalty.loyaltyDeal)!"
                }else{
                    cell.loyaltyLabel.text = "Today: +\(thisVendor.loyalty.loyaltyPoints[Date().dayNumberOfWeek()!-1])\n Reach points goal and recieve: a \(thisVendor.loyalty.loyaltyDeal)!"
                    if cell.isAnimating{
                        cell.stopAnimate()
                    }
                }
                cell.checkin.addTarget(self, action: #selector(self.checkin(_:)), for: .touchUpInside)
                cell.progressBar.progress = CGFloat(Float(loyaltyRedemptions)/Float(thisVendor.loyalty.loyaltyCount))
                
                cell.marker.text = "\(loyaltyRedemptions!)/\(thisVendor.loyalty.loyaltyCount)"
            }else{
                cell.checkin.isHidden = true
                cell.loyaltyLabel.isHidden = true
                cell.marker.isHidden = true
            }
            return cell
        }
        else if indexPath.row == 4{
            let cell = tableView.dequeueReusableCell(withIdentifier: "labelCell", for: indexPath) as! labelCell
            cell.label.text = "Current Offers"
            if activeDeals.count + inactiveDeals.count <= 0 {
                cell.label.text = "No Current Offers"
            }
            return cell
        }
        else{
           let  cell = tableView.dequeueReusableCell(withIdentifier: "dealCell", for: indexPath)
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath){
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.row == 1 || indexPath.row == 2{
            expandedCells[indexPath.row-1] = !expandedCells[indexPath.row-1]
            tableView.reloadData()
        }else if indexPath.row > 4{
            let storyboard = UIStoryboard(name: "DealDetails", bundle: nil)
            let VC = storyboard.instantiateInitialViewController() as! DealViewController
            VC.hidesBottomBarWhenPushed = true
            VC.Deal = activeDeals[indexPath.row - 5]
            VC.photo = VC.Deal?.photo
            VC.fromDetails = true
            self.title = ""
            self.navigationController?.pushViewController(VC, animated: true)
        }
    }
  
    @objc func checkin(_ sender:UIButton!){
        if self.thisVendor.distanceMiles! < 0.2 {
            self.thisVendor.updateDistance()
            if self.loyaltyRedemptions >= self.thisVendor.loyalty.loyaltyCount{
                if (redemptionTime + 10800) < Date().timeIntervalSince1970 {
                    let redeemAlert = UIAlertController(title: "Confirm Redemption!", message: "If you wish to redeem this loyalty deal now, show this message to the server. If you wish to save this deal for later, hit CANCEL.", preferredStyle: .alert)
                    redeemAlert.addAction(UIAlertAction(title: "Redeem", style: .default, handler: {(_) in
                        self.loyaltyRedemptions = self.loyaltyRedemptions - self.thisVendor.loyalty.loyaltyCount
                        self.redemptionTime = Date().timeIntervalSince1970
                        //Call Firebase cloud functions to increment stripe counter
                        self.functions.httpsCallable("incrementStripe").call(["subscription_id":self.thisVendor!.subscriptionId ?? "", "vendor_id":self.thisVendor?.id ?? "", "deal_type":1]) { (result, error) in
                            if let _ = error as NSError? {
                                //error handle
                            }
                            if let text = (result?.data as? [String: Any])?["text"] as? String {
                                print(text)
                            }
                            self.ref.child("Users").child((Auth.auth().currentUser?.uid)!).child("loyalty").child((self.thisVendor.id)!).updateChildValues(["redemptions": ["count" : self.loyaltyRedemptions, "time" : self.redemptionTime]])
                            sender.setTitle("Loyalty Check-In", for: .normal)
                            self.restaurantTable.reloadData()
                        }
                    }))
                    redeemAlert.addAction(UIAlertAction(title: "Cancel", style: .destructive, handler: nil))
                    self.present(redeemAlert, animated: true)
                }else{
                    let erroralert = UIAlertController(title: "Too Soon!", message: "Come back tomorrow to redeem your points!", preferredStyle: .alert)
                    erroralert.addAction(UIAlertAction(title: "Okay", style: .default, handler: nil))
                    self.present(erroralert, animated: true)
                }
                
            }else{
                if (redemptionTime + 10800) < Date().timeIntervalSince1970 {
                    performSegue(withIdentifier: "QRsegue", sender: self)
                }else{
                    let erroralert = UIAlertController(title: "Too Soon!", message: "Come back tomorrow to get another loyalty visit!", preferredStyle: .alert)
                    erroralert.addAction(UIAlertAction(title: "Okay", style: .default, handler: nil))
                    self.present(erroralert, animated: true)
                }
            }
        }else{
            let erroralert = UIAlertController(title: "Too far away!", message: "Go to location to use their loyalty program!", preferredStyle: .alert)
            erroralert.addAction(UIAlertAction(title: "Okay", style: .default, handler: nil))
            self.present(erroralert, animated: true)
        }
    }
    
    func checkCode(code: String){
        if code == self.thisVendor.loyalty.loyaltyCode{
            self.loyaltyRedemptions = self.loyaltyRedemptions + self.thisVendor.loyalty.loyaltyPoints[Date().dayNumberOfWeek()!-1]
            let uID = Auth.auth().currentUser?.uid
            let status: OSPermissionSubscriptionState = OneSignal.getPermissionSubscriptionState()
            //Redundant following for user and rest
            Database.database().reference().child("Vendors").child((self.thisVendor.id)!).child("followers").child(uID!).setValue(status.subscriptionStatus.userId)
            Database.database().reference().child("Users").child(uID!).child("following").child(self.thisVendor.id!).setValue(true)
            let successAlert = UIAlertController(title: "Success!", message: "Successfully checked in", preferredStyle: .alert)
            successAlert.addAction(UIAlertAction(title: "Okay", style: .default, handler: {(_) in
                OneSignal.sendTags([(self.thisVendor.id)! : "true"])
                self.redemptionTime = Date().timeIntervalSince1970
                self.ref.child("Users").child((Auth.auth().currentUser?.uid)!).child("loyalty").child((self.thisVendor.id)!).updateChildValues(["redemptions": ["count" : self.loyaltyRedemptions, "time" : self.redemptionTime]])
                self.followString = "Following"
                self.restaurantTable.reloadData()
            }))
            self.present(successAlert, animated: true)
        }else{
            let erroralert = UIAlertController(title: "Incorrect code!", message: "The Check-In QRcode you used was incorrect. Please try again.", preferredStyle: .alert)
            erroralert.addAction(UIAlertAction(title: "Okay", style: .default, handler: nil))
            self.present(erroralert, animated: true)
        }
    }

    func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let y = scrollView.contentOffset.y
        if y < 0 {
            var scale = 1.0 + abs(scrollView.contentOffset.y)  / scrollView.frame.size.height
            
            //Cap the scaling between zero and 1
            scale = max(0.0, scale)
            
            // Set the scale to the imageView
            self.rImg.transform = CGAffineTransform(scaleX: scale, y: scale)
            self.overview.transform = CGAffineTransform(scaleX: scale, y: scale)
            self.rImg.frame = CGRect(x: 0, y: scrollView.contentOffset.y, width: self.rImg.frame.size.width, height: self.rImg.frame.size.height)
            self.overview.frame = CGRect(x: 0, y: scrollView.contentOffset.y, width: self.rImg.frame.size.width, height: self.rImg.frame.size.height)
            self.rImg.frame.size.height = -y + self.cachedImageViewSize.height
            self.overview.frame.size.height = -y + self.cachedImageViewSize.height
        }
    }
    
    //function to set our collection view delegate
    func tableView(_ tableView: UITableView,
                            willDisplay cell: UITableViewCell,
                            forRowAt indexPath: IndexPath) {
        
        if indexPath.row == 5{
            guard let tableViewCell = cell as? CollectionTableViewCell  else { return }
            tableViewCell.setCollectionViewDataSourceDelegate(dataSourceDelegate: self, forRow: indexPath.row)
        }
    }
}

class aboutCell: UITableViewCell {
    
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var show: UILabel!
    @IBOutlet weak var borderView: UIView!
    @IBOutlet weak var address: UILabel!
    @IBOutlet weak var todayHours: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        if let view = self.borderView{
            view.borders(for: [.top,.bottom], width: 1.0, color: UIColor.lightGray)
            view.layer.cornerRadius = 10
            label.borders(for: [.top], width: 1.0, color: UIColor.lightText)
        }
    }
}

class labelCell: UITableViewCell {
    
    @IBOutlet weak var label: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
    }
}

class happyHourCell: UITableViewCell {
    
    @IBOutlet weak var happyhours: UITextView!
    @IBOutlet weak var show: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
}
class loyaltyCell: UITableViewCell {
    
    @IBOutlet weak var checkin: UIButton!
    @IBOutlet weak var loyaltyLabel: UILabel!
    var isAnimating = false
    
    @IBOutlet weak var progressBar: GTProgressBar!
    @IBOutlet weak var marker: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func animate(){
        let pulse = CASpringAnimation(keyPath: "transform.scale")
        pulse.duration = 0.3
        pulse.fromValue = 0.95
        pulse.toValue = 1.0
        pulse.autoreverses = true
        pulse.repeatCount = 10000
        pulse.initialVelocity = 0.5
        pulse.damping = 1.0
        self.checkin.layer.add(pulse, forKey: "pulse")
        isAnimating = true

    }
    func stopAnimate(){
        self.checkin.layer.removeAnimation(forKey: "pulse")
        isAnimating = false
    }
}


class buttonCell: UITableViewCell {
    
    var mainView: RestaurantViewController!
    @IBOutlet weak var followButton: UIButton!
    @IBOutlet weak var directionsButton: UIButton!
    @IBOutlet weak var menuButton: UIButton!
    var request: URLRequest?
    var menu: String!
    var rID: String?
    var rAddress: String = ""
    var hasLoyalty = false

    override func awakeFromNib() {
        super.awakeFromNib()
        
    }
    
    @IBAction func openMenu(_ sender: Any) {
        menuButton.isEnabled = false
        if menu != ""{
            let svc = SFSafariViewController(url: URL(string:menu)!)
            svc.modalTransitionStyle = UIModalTransitionStyle.coverVertical
            self.parentViewController?.present(svc, animated: true, completion: nil)
        }else{
            let alert = UIAlertController(title: "Sorry!", message: "Looks like this vendor has not yet made their menu avaliable to us! Sorry for the inconvenience.", preferredStyle: .alert)
            let approveAction = UIAlertAction(title: "😢 Okay", style: .default) { (alert: UIAlertAction!) -> Void in

            }
            alert.addAction(approveAction)
            self.parentViewController?.present(alert, animated: true, completion:nil)
        }
        menuButton.isEnabled = true
    }
    
    @IBAction func directionsPressed(_ sender: Any) {
        if (UIApplication.shared.canOpenURL(URL(string:"comgooglemaps://")!)) {
            let optionMenu = UIAlertController(title: nil, message: "Open With", preferredStyle: .actionSheet)
            let googleAction = UIAlertAction(title: "Google Maps", style: .default, handler: {
                (alert: UIAlertAction!) -> Void in
                self.openInGoogleMaps()
            })
            let appleAction = UIAlertAction(title: "Apple Maps", style: .default, handler: {
                (alert: UIAlertAction!) -> Void in
                self.openInAppleMaps()
            })
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: {
                (alert: UIAlertAction!) -> Void in
            })
            optionMenu.addAction(googleAction)
            optionMenu.addAction(appleAction)
            optionMenu.addAction(cancelAction)

            self.parentViewController?.present(optionMenu, animated: true, completion: nil)
        }else{
            self.openInAppleMaps()
        }
    }
    
    func openInGoogleMaps(){
        let baseUrl: String = "comgooglemaps://?saddr="
        let encodedName = rAddress.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        let finalUrl = baseUrl + encodedName
        if let url = URL(string: finalUrl){
            UIApplication.shared.openURL(url)
        }

    }
    
    func openInAppleMaps(){
        let baseUrl: String = "http://maps.apple.com/?q="
        let encodedName = rAddress.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        let finalUrl = baseUrl + encodedName
        if let url = URL(string: finalUrl){
            UIApplication.shared.openURL(url)
        }
    }

    @IBAction func followPressed(_ sender: Any) {
        followButton.isEnabled = false
        if self.followButton.currentTitle == "Follow"{
            let uID = Auth.auth().currentUser?.uid
            let status: OSPermissionSubscriptionState = OneSignal.getPermissionSubscriptionState()
            //Redundant following for user and rest
            Database.database().reference().child("Vendors").child(rID!).child("followers").child(uID!).setValue(status.subscriptionStatus.userId)
            Database.database().reference().child("Users").child(uID!).child("following").child(rID!).setValue(true)
            OneSignal.sendTags([(rID)! : "true"])
            self.mainView.followString = "Following"
            self.mainView.restaurantTable.reloadData()
        }else{
            if hasLoyalty{
                let alert = UIAlertController(title: "Notice!", message: "By unfollowing this restaurant you will lose all your loyalty check-ins!", preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "Cancel", style: .destructive) { (alert: UIAlertAction!) -> Void in
                    
                }
                let approveAction = UIAlertAction(title: "OK", style: .default) { (alert: UIAlertAction!) -> Void in
                    let uID = Auth.auth().currentUser?.uid
                    let loyaltyRef = Database.database().reference().child("Users").child(uID!).child(self.rID!)
                    loyaltyRef.removeValue()
                    self.unfollow()
                }
                alert.addAction(cancelAction)
                alert.addAction(approveAction)
                self.parentViewController?.present(alert, animated: true, completion:nil)
            }else{
                self.unfollow()
            }
        }
        followButton.isEnabled = true
    }
    
    func unfollow(){
        let uID = Auth.auth().currentUser?.uid
        //Redundant unfollowing for user and rest
        Database.database().reference().child("Vendors").child(rID!).child("followers").child(uID!).removeValue()
        Database.database().reference().child("Users").child(uID!).child("following").child(rID!).removeValue()
        OneSignal.sendTags([rID! : "false"])
        self.mainView.followString = "Follow"
        self.followButton.backgroundColor = #colorLiteral(red: 0.6666666865, green: 0.6666666865, blue: 0.6666666865, alpha: 1)
        self.mainView.loyaltyRedemptions = 0
        self.mainView.restaurantTable.reloadData()
    }
}

class CenteredButton: UIButton
{
    //For centered x-axis images in buttons
    override func titleRect(forContentRect contentRect: CGRect) -> CGRect {
        let rect = super.titleRect(forContentRect: contentRect)
        let imageRect = super.imageRect(forContentRect: contentRect)
        
        return CGRect(x: 0, y: imageRect.maxY + 10,
                      width: contentRect.width, height: rect.height)
    }
    
    override func imageRect(forContentRect contentRect: CGRect) -> CGRect {
        let rect = super.imageRect(forContentRect: contentRect)
        let titleRect = self.titleRect(forContentRect: contentRect)
        
        return CGRect(x: contentRect.width/2.0 - rect.width/2.0,
                      y: (contentRect.height - titleRect.height)/2.0 - rect.height/2.0,
                      width: rect.width, height: rect.height)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        centerTitleLabel()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        centerTitleLabel()
    }
    
    private func centerTitleLabel() {
        self.titleLabel?.textAlignment = .center
    }
}

fileprivate extension UIButton {
    //Sets Img template and corrects title offsets
    func setTemplateImg(Img: UIImage) {
        let image = Img.withRenderingMode(.alwaysTemplate)
        self.setImage(image, for: .normal)
        self.tintColor = UIColor.white
        
        let imageSize = self.imageView!.frame.size
        let titleSize = self.titleLabel!.frame.size
        let totalHeight = imageSize.height + titleSize.height + 6

        self.imageEdgeInsets = UIEdgeInsets(
            top: -(totalHeight - imageSize.height),
            left: 0,
            bottom: 0,
            right: -titleSize.width
        )

        self.titleEdgeInsets = UIEdgeInsets(
            top: 0,
            left: -imageSize.width,
            bottom: -(totalHeight - titleSize.height),
            right: 0
        )
    }
}

fileprivate extension UIView {
    func borders(for edges:[UIRectEdge], width:CGFloat = 1, color: UIColor = .black) {
        
        if edges.contains(.all) {
            layer.borderWidth = width
            layer.borderColor = color.cgColor
        } else {
            let allSpecificBorders:[UIRectEdge] = [.top, .bottom, .left, .right]
            
            for edge in allSpecificBorders {
                if let v = viewWithTag(Int(edge.rawValue)) {
                    v.removeFromSuperview()
                }
                
                if edges.contains(edge) {
                    let v = UIView()
                    v.tag = Int(edge.rawValue)
                    v.backgroundColor = color
                    v.translatesAutoresizingMaskIntoConstraints = false
                    addSubview(v)
                    
                    var horizontalVisualFormat = "H:"
                    var verticalVisualFormat = "V:"
                    
                    switch edge {
                    case UIRectEdge.bottom:
                        horizontalVisualFormat += "|-(0)-[v]-(0)-|"
                        verticalVisualFormat += "[v(\(width))]-(0)-|"
                    case UIRectEdge.top:
                        horizontalVisualFormat += "|-(0)-[v]-(0)-|"
                        verticalVisualFormat += "|-(0)-[v(\(width))]"
                    case UIRectEdge.left:
                        horizontalVisualFormat += "|-(0)-[v(\(width))]"
                        verticalVisualFormat += "|-(0)-[v]-(0)-|"
                    case UIRectEdge.right:
                        horizontalVisualFormat += "[v(\(width))]-(0)-|"
                        verticalVisualFormat += "|-(0)-[v]-(0)-|"
                    default:
                        break
                    }
                    
                    self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: horizontalVisualFormat, options: .directionLeadingToTrailing, metrics: nil, views: ["v": v]))
                    self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: verticalVisualFormat, options: .directionLeadingToTrailing, metrics: nil, views: ["v": v]))
                }
            }
        }
    }
}

class CollectionTableViewCell: UITableViewCell {
    
    //@IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet private weak var collectionView: UICollectionView!
    @IBOutlet weak var insetView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
//        if traitCollection.forceTouchCapability == .available {
//          //  registerForPreviewing(with: self, sourceView: collectionView)
//        } else {
//            print("3D Touch Not Available")
//        }
        
    }

    func setCollectionViewDataSourceDelegate<D: UICollectionViewDataSource & UICollectionViewDelegate>(dataSourceDelegate: D, forRow row: Int) {
        collectionView.delegate = dataSourceDelegate
        collectionView.dataSource = dataSourceDelegate
        collectionView.tag = row
        collectionView.reloadData()
    }
}

class CollectionDealCell: UICollectionViewCell{
   
    @IBOutlet weak var validHours: UILabel!
    @IBOutlet weak var dealImg: UIImageView!
    var deal: DealData!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var dealDescription: UILabel!
    @IBOutlet weak var insetView: UIView!
    @IBOutlet weak var FavButton: UIButton!

    override func awakeFromNib() {
        super.awakeFromNib()
        insetView.layer.cornerRadius = 10
        let maskPath = UIBezierPath(roundedRect: self.bounds,byRoundingCorners: [.topLeft, .topRight, .bottomLeft, .bottomRight],cornerRadii: CGSize(width: 10.0, height: 10.0))
        let shape = CAShapeLayer()
        shape.path = maskPath.cgPath
        self.dealImg.layer.mask = shape
        self.dealImg.clipsToBounds = true
    }
    
    @IBAction func FavoriteToggled(_ sender: Any) {
        //If favorite star was hit, add or remove to favorites
        if deal.favorited!{
            deal.favorited = false
            Database.database().reference().child("Users").child((Auth.auth().currentUser?.uid)!).child("favorites").child(deal.id!).removeValue()
            let image = #imageLiteral(resourceName: "icons8-like").withRenderingMode(.alwaysTemplate)
            FavButton.setImage(image, for: .normal)
            FavButton.tintColor = UIColor.red
        }
        else{
            deal.favorited = true
            Database.database().reference().child("Users").child((Auth.auth().currentUser?.uid)!).child("favorites").child(deal.id!).setValue(deal.id!)
            let image = #imageLiteral(resourceName: "icons8-like_filled.png").withRenderingMode(.alwaysTemplate)
            FavButton.setImage(image, for: .normal)
            FavButton.tintColor = UIColor.red
        }
    }
}

extension RestaurantViewController: UICollectionViewDelegate,UICollectionViewDataSource{
    func collectionView(_ collectionView: UICollectionView,numberOfItemsInSection section: Int) -> Int {
        return activeDeals.count + inactiveDeals.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "dealCell",for: indexPath) as! CollectionDealCell
        if indexPath.row < activeDeals.count{
            cell.deal = activeDeals[indexPath.row]
        }else{
            cell.deal = inactiveDeals[indexPath.row-activeDeals.count]
        }
        cell.dealDescription.text = cell.deal.dealDescription
        if cell.deal.redeemed! {
            cell.timeLabel.text = "Deal Already Redeemed!"
            cell.timeLabel.textAlignment = .center
            cell.FavButton.isHidden = true
        }else{
            cell.timeLabel.textAlignment = .left
            cell.FavButton.isHidden = false
            if cell.deal.daysLeft! < 8{
                cell.timeLabel.isHidden = false
                cell.timeLabel.text = cell.deal.countdown
            }else{
                cell.timeLabel.isHidden = true
            }
        }
        cell.validHours.text = cell.deal.activeHours
        if cell.deal.favorited!{
            let image = #imageLiteral(resourceName: "icons8-like_filled.png").withRenderingMode(.alwaysTemplate)
            cell.FavButton.setImage(image, for: .normal)
            cell.FavButton.tintColor = UIColor.red
        }else{
            let image = #imageLiteral(resourceName: "icons8-like").withRenderingMode(.alwaysTemplate)
            cell.FavButton.setImage(image, for: .normal)
            cell.FavButton.tintColor = UIColor.red
        }
        if cell.deal.photo != ""{            
            // UIImageView in your ViewController
            let imageView: UIImageView = cell.dealImg
            
            // Placeholder image
            let placeholderImage = UIImage(named: "placeholder.jpg")
            
            // Load the image using SDWebImage
            imageView.sd_setImage(with: URL(string: cell.deal.photo!), placeholderImage: placeholderImage)
        }
        if let viewWithTag = cell.insetView.viewWithTag(300){
            viewWithTag.removeFromSuperview()
        }
        if !cell.deal.active{
            let view = UIView(frame: CGRect(x: cell.insetView.frame.origin.x, y: cell.insetView.frame.origin.y, width: cell.insetView.frame.width, height: cell.insetView.frame.height))
            view.backgroundColor = UIColor.gray.withAlphaComponent(0.7)
            view.tag = 300
            view.layer.cornerRadius = 10
            let label = UILabel(frame: CGRect(x: cell.insetView.frame.origin.x, y: cell.insetView.frame.origin.y, width: cell.insetView.frame.width-40, height: cell.insetView.frame.height))
            label.textAlignment = NSTextAlignment.center
            label.numberOfLines = 0
            label.center = view.center
            label.baselineAdjustment = .alignCenters
            label.lineBreakMode = NSLineBreakMode.byWordWrapping
            label.text = "Deal unavailable"
            label.textColor = UIColor.white
            view.addSubview(label)
            cell.insetView.addSubview(view)
            cell.insetView.bringSubviewToFront(cell.FavButton)
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let storyboard = UIStoryboard(name: "DealDetails", bundle: nil)
        let VC = storyboard.instantiateInitialViewController() as! DealViewController
        VC.hidesBottomBarWhenPushed = true
        if indexPath.row < activeDeals.count{
            VC.Deal = activeDeals[indexPath.row]
        }else{
            VC.Deal = inactiveDeals[indexPath.row-activeDeals.count]
        }
        VC.photo = VC.Deal?.photo
        VC.fromDetails = true
        VC.thisVendor = self.thisVendor
        self.title = ""
        self.navigationController?.pushViewController(VC, animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "QRsegue"{
            let VC = segue.destination as? QRViewController
            VC?.parentVC = self
        }
    }
    
}

extension UIView {
    var parentViewController: UIViewController? {
        var parentResponder: UIResponder? = self
        while parentResponder != nil {
            parentResponder = parentResponder!.next
            if parentResponder is UIViewController {
                return parentResponder as! UIViewController?
            }
        }
        return nil
    }
}


/*extension CollectionTableViewCell:  UIViewControllerPreviewingDelegate {
    
    
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        
        guard let indexPath = collectionView.indexPathForRow(at: location),
            let cell = restaurantTable.cellForRow(at: indexPath) as? DealTableViewCell else {
                return nil }
        let storyboard = UIStoryboard(name: "DealDetails", bundle: nil)
        let VC = storyboard.instantiateInitialViewController() as! DealViewController
        VC.hidesBottomBarWhenPushed = true
        VC.Deal = Deals[indexPath.row]
        VC.fromDetails = true
        VC.photo = VC.Deal?.photo
        VC.preferredContentSize =
            CGSize(width: 0.0, height: 600)
        
        previewingContext.sourceRect = cell.frame
        
        return VC
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        show(viewControllerToCommit, sender: self)
    }
    
    
}*/

class QRViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
   
    
    @IBOutlet weak var textView: UILabel!
    @IBOutlet var topbar: UIView!
    
    var parentVC: RestaurantViewController?
    var captureSession = AVCaptureSession()
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    var qrCodeFrameView: UIView?
    
    private let supportedCodeTypes = [AVMetadataObject.ObjectType.qr]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.isNavigationBarHidden = true
        var gotDevice = false
        var captureDevice: AVCaptureDevice!
        // Get the back-facing camera for capturing videos
        if #available(iOS 10.0, *) {
            let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: AVMediaType.video, position: .back)
            if let temp = deviceDiscoverySession.devices.first{
                captureDevice = temp
                gotDevice = true
            }
        } else {
            let devices: NSArray = AVCaptureDevice.devices() as NSArray;
            for de in devices {
                let deviceConverted = de as! AVCaptureDevice
                if(deviceConverted.position == .back){
                    captureDevice = deviceConverted
                    gotDevice = true
                    break
                }
            }
        }

        if !gotDevice{
            let label = UILabel()
            label.textColor = UIColor.black
            label.text = "Failed to get camera!"
            label.numberOfLines = 0
            label.lineBreakMode = .byWordWrapping
            label.textAlignment = .center
            view.addSubview(label)
            let centerX = NSLayoutConstraint(item: label, attribute: NSLayoutConstraint.Attribute.centerX, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self.view, attribute: NSLayoutConstraint.Attribute.centerX, multiplier: 1, constant: 0)
            let centerY = NSLayoutConstraint(item: label, attribute: NSLayoutConstraint.Attribute.centerY, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self.view, attribute: NSLayoutConstraint.Attribute.centerY, multiplier: 1, constant: 0)
            let height = NSLayoutConstraint(item: label, attribute: NSLayoutConstraint.Attribute.height, relatedBy: NSLayoutConstraint.Relation.equal, toItem: nil, attribute: NSLayoutConstraint.Attribute.notAnAttribute, multiplier: 1, constant: 22)
            label.translatesAutoresizingMaskIntoConstraints = false
            self.view.addConstraints([centerX, centerY, height])
            return
        }
        
        do {
            // Get an instance of the AVCaptureDeviceInput class using the previous device object.
            let input = try AVCaptureDeviceInput(device: captureDevice)
            
            // Set the input device on the capture session.
            captureSession.addInput(input)
            
            // Initialize a AVCaptureMetadataOutput object and set it as the output device to the capture session.
            let captureMetadataOutput = AVCaptureMetadataOutput()
            captureSession.addOutput(captureMetadataOutput)
            
            // Set delegate and use the default dispatch queue to execute the call back
            captureMetadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            captureMetadataOutput.metadataObjectTypes = supportedCodeTypes
            //            captureMetadataOutput.metadataObjectTypes = [AVMetadataObject.ObjectType.qr]
            
        } catch {
            // If any error occurs, simply print it out and don't continue any more.
            print(error)
            return
        }
        
        // Initialize the video preview layer and add it as a sublayer to the viewPreview view's layer.
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        videoPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        videoPreviewLayer?.frame = view.layer.bounds
        view.layer.addSublayer(videoPreviewLayer!)
        
        // Start video capture.
        captureSession.startRunning()
        
        // Move the message label and top bar to the front
        //view.bringSubview(toFront: messageLabel)
        view.bringSubviewToFront(topbar)
        view.bringSubviewToFront(textView)
        // Initialize QR Code Frame to highlight the QR code
        qrCodeFrameView = UIView()
        
        if let qrCodeFrameView = qrCodeFrameView {
            qrCodeFrameView.layer.borderColor = UIColor.green.cgColor
            qrCodeFrameView.layer.borderWidth = 2
            view.addSubview(qrCodeFrameView)
            view.bringSubviewToFront(qrCodeFrameView)
        }
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        // Check if the metadataObjects array is not nil and it contains at least one object.
        if metadataObjects.count == 0 {
            qrCodeFrameView?.frame = CGRect.zero
            return
        }
        
        // Get the metadata object.
        let metadataObj = metadataObjects[0] as! AVMetadataMachineReadableCodeObject
        
        if supportedCodeTypes.contains(metadataObj.type) {
            // If the found metadata is equal to the QR code metadata (or barcode) then update the status label's text and set the bounds
            let barCodeObject = videoPreviewLayer?.transformedMetadataObject(for: metadataObj)
            qrCodeFrameView?.frame = barCodeObject!.bounds
            
            if metadataObj.stringValue != nil {
                foundCode(code: metadataObj.stringValue!)
            }
        }
    }
    
    // MARK: - Helper methods
    func foundCode(code: String) {
        self.navigationController?.isNavigationBarHidden = false
        dismiss(animated: true) {
            self.parentVC?.checkCode(code: code)
        }
    }
    @IBAction func exit(_ sender: Any) {
        self.navigationController?.isNavigationBarHidden = false
        dismiss(animated: true)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
}
extension Date {
    func dayNumberOfWeek() -> Int? {
        return Calendar.current.dateComponents([.weekday], from: self).weekday
    }
}


