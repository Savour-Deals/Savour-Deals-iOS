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
import OneSignal

class DetailsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    var rID: String?
    var handle: AuthStateDidChangeListenerHandle?
    var ref: DatabaseReference!
    var storage: Storage!
    var Deals = [DealData]()
    var indices = [Int]()
    var cachedImageViewSize: CGRect!
    var cachedTextPoint: CGPoint!
    var loyaltyCode: String!
    var thisRestaurant: restaurant!
    var loyaltyRedemptions: Int!
    
    @IBOutlet weak var overview: UIView!
    @IBOutlet weak var curr: UILabel!
    @IBOutlet weak var ContentView: UIView!
    @IBOutlet weak var DealsTable: UITableView!
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
        
        if traitCollection.forceTouchCapability == .available {
            registerForPreviewing(with: self, sourceView: view)
        } else {
            print("3D Touch Not Available")
        }
        DealsTable.rowHeight = UITableViewAutomaticDimension
        DealsTable.estimatedRowHeight = 45
        self.cachedImageViewSize = self.rImg.frame
        self.cachedTextPoint = self.rName.center
        let footerView = UIView()
        footerView.backgroundColor = #colorLiteral(red: 0.2848863602, green: 0.6698332429, blue: 0.6656947136, alpha: 0)
        self.DealsTable.tableFooterView = footerView
        self.DealsTable.sectionHeaderHeight = self.rImg.frame.height
    }
    
 
    override func viewDidAppear(_ animated: Bool) {
        self.tabBarController?.tabBar.isHidden = true
        self.DealsTable.reloadData()
    }
    
    @IBAction func backSwipe(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    func loadData(){
        //Set overall restraunt info
        let id = rID
        ref.child("Users").child((Auth.auth().currentUser?.uid)!).child(rID!).observeSingleEvent(of: .value, with: { (snapshot) in
            if snapshot.exists(){
                let value = snapshot.value as? NSDictionary
                self.loyaltyRedemptions = value?["redemptions"] as? Int ?? 0
            }else{
                self.loyaltyRedemptions = 0
            }
        }){ (error) in
            print(error.localizedDescription)
        }
        ref.child("Restaurants").child(id!).observeSingleEvent(of: .value, with: { (snapshot) in
            
            //let value = snapshot.value as? NSDictionary
            self.thisRestaurant = restaurant(snap: snapshot, ID: self.rID!)
            if snapshot.childSnapshot(forPath: "Followers").hasChild((Auth.auth().currentUser?.uid)!){
                self.followString = "Click to Unfollow"
            }
            else{
                self.followString = "Click to Follow"
            }
            
//            self.menu = value?["Menu"] as? String ?? ""
            self.rName.text = self.thisRestaurant.restrauntName
//            self.rAddress = value?["Address"] as? String ?? ""
//            self.rDesc = value?["Desc"] as? String ?? ""
//            self.loyaltyCode = value?["loayltyCode"] as? String ?? ""
//            if snapshot.childSnapshot(forPath: "HappyHours").childrenCount > 0 {
//                let hoursSnapshot = snapshot.childSnapshot(forPath: "HappyHours").value as? NSDictionary
//                self.hoursArray.append(hoursSnapshot?["Mon"] as? String ?? "No Happy Hour")
//                self.hoursArray.append(hoursSnapshot?["Tues"] as? String ?? "No Happy Hour")
//                self.hoursArray.append(hoursSnapshot?["Wed"] as? String ?? "No Happy Hour")
//                self.hoursArray.append(hoursSnapshot?["Thurs"] as? String ?? "No Happy Hour")
//                self.hoursArray.append(hoursSnapshot?["Fri"] as? String ?? "No Happy Hour")
//                self.hoursArray.append(hoursSnapshot?["Sat"] as? String ?? "No Happy Hour")
//                self.hoursArray.append(hoursSnapshot?["Sun"] as? String ?? "No Happy Hour")
//            }
            if self.thisRestaurant.restrauntPhoto != ""{
                // Reference to an image file in Firebase Storage
                let storage = Storage.storage()
                let storageref = storage.reference(forURL: self.thisRestaurant.restrauntPhoto!)
                // Reference to an image file in Firebase Storage
                let reference = storageref
        
                // UIImageView in your ViewController
                let imageView: UIImageView = self.rImg
        
                // Placeholder image
                let placeholderImage = UIImage(named: "placeholder.jpg")
        
                // Load the image using SDWebImage
                imageView.sd_setImage(with: reference, placeholderImage: placeholderImage)
            }
            self.DealsTable.delegate = self
            self.DealsTable.dataSource = self
            self.DealsTable.reloadData()
            self.DealsTable.isHidden = false
        }){ (error) in
            print(error.localizedDescription)
        }
        if UnfilteredDeals.count > 0 {
            for i in 0 ... (UnfilteredDeals.count-1){
                if self.rID == UnfilteredDeals[i].restrauntID{
                    self.Deals.append((UnfilteredDeals[i]))
                    self.indices.append(i)
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView,heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == 2{
            return 100
        }
        if indexPath.row == 1{
            if self.thisRestaurant.hoursArray.count > 0{
                return UITableViewAutomaticDimension
            }
            else{
                return 0
            }
        }
        if indexPath.row == 3{
            if self.thisRestaurant.loyalty.loyaltyCount > 0{
                return 128
            }
            else{
                return 0
            }
            
        }
        return UITableViewAutomaticDimension
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Deals.count + 5
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0{
            let cell = tableView.dequeueReusableCell(withIdentifier: "descCell", for: indexPath) as! labelCell
            cell.label.text = self.thisRestaurant.description
            cell.contentView.borders(for: [.bottom], width: 1.0, color: UIColor.darkGray)
            return cell
        }
        else if indexPath.row == 1{
            let cell = tableView.dequeueReusableCell(withIdentifier: "hoursCell", for: indexPath) as! happyHourCell
            if self.thisRestaurant.hoursArray.count > 0{
                let thisHoursArray = self.thisRestaurant.hoursArray
                cell.contentView.borders(for: [.bottom], width: 1.0, color: UIColor.darkGray)
                let mutableAttributedString = NSMutableAttributedString()
                let leftAlign = NSMutableParagraphStyle()
                leftAlign.alignment = .left
                let attrs = [NSAttributedStringKey.font : UIFont.systemFont(ofSize: 20, weight: UIFont.Weight.heavy), NSAttributedStringKey.paragraphStyle: leftAlign]
                let header = NSMutableAttributedString(string:"Happy Hours:\n", attributes:attrs)
                var hours = "Monday: " + thisHoursArray[0] + "\n"
                hours = hours + "Tuesday: " + thisHoursArray[1] + "\n"
                hours = hours + "Wednesday: " + thisHoursArray[2] + "\n"
                hours = hours + "Thursday: " + thisHoursArray[3] + "\n"
                hours = hours + "Friday: " + thisHoursArray[4] + "\n"
                hours = hours + "Saturday: " + thisHoursArray[5] + "\n"
                hours = hours + "Sunday: " + thisHoursArray[6] + "\n"
                let center = NSMutableParagraphStyle()
                center.alignment = .center
                let attrs1 = [NSAttributedStringKey.foregroundColor : UIColor.darkGray, NSAttributedStringKey.paragraphStyle: center, NSAttributedStringKey.font : UIFont.systemFont(ofSize: 15, weight: UIFont.Weight.regular)]
                            let hourCenter = NSMutableAttributedString(string:hours, attributes:attrs1)
                mutableAttributedString.append(header)
                mutableAttributedString.append(hourCenter)
                cell.happyhours.attributedText = mutableAttributedString
            }
            return cell
        }
        else if indexPath.row == 2{
            let cell = tableView.dequeueReusableCell(withIdentifier: "buttonCell", for: indexPath) as! buttonCell
            cell.followButton.setTitle(self.followString, for: .normal)
            if self.followString == "Click to Follow"{
                cell.followButton.backgroundColor = #colorLiteral(red: 0.6666666865, green: 0.6666666865, blue: 0.6666666865, alpha: 1)
            }else{
                cell.followButton.backgroundColor = #colorLiteral(red: 0.2848863602, green: 0.6698332429, blue: 0.6656947136, alpha: 1)
            }
            cell.followButton.setTemplateImg(Img: #imageLiteral(resourceName: "follow"))
            cell.menuButton.setTemplateImg(Img: #imageLiteral(resourceName: "menu"))
            cell.directionsButton.setTemplateImg(Img: #imageLiteral(resourceName: "directions"))
            cell.request = self.request
            cell.menu = self.thisRestaurant.menu
            cell.rID = self.rID
            cell.rAddress = self.thisRestaurant.address!
            //cell.contentView.borders(for: [.bottom], width: 2.0, color: UIColor.darkGray)
            return cell
        }
        
        else if indexPath.row == 3{
            let cell = tableView.dequeueReusableCell(withIdentifier: "loyaltyCell", for: indexPath) as! loyaltyCell
            if self.thisRestaurant.loyalty.loyaltyCount > 0 {
                let visitsLeft =  thisRestaurant.loyalty.loyaltyCount - loyaltyRedemptions
                if visitsLeft == 0{
                    cell.checkin.setTitle("Reedeem", for: .normal)
                    cell.loyaltyLabel.text = "You're ready to redeem your \(thisRestaurant.loyalty.loyaltyDeal)!"
                }else{
                    cell.loyaltyLabel.text = "Visit \(visitsLeft) more times for a \(thisRestaurant.loyalty.loyaltyDeal)!"
                }
                cell.checkin.addTarget(self, action: #selector(self.checkin(_:)), for: .touchUpInside)
                cell.contentView.borders(for: [.top, .bottom], width: 1.0, color: UIColor.darkGray)
                var loyaltyMarks = ""
                if loyaltyRedemptions > 0 {
                    for _ in 1...loyaltyRedemptions{
                        loyaltyMarks += "x    "
                    }
                }
                if loyaltyRedemptions < thisRestaurant.loyalty.loyaltyCount{
                    for _ in 1...visitsLeft{
                        loyaltyMarks += "•    "
                    }
                }
                
                let trimmedString = loyaltyMarks.trimmingCharacters(in: .whitespacesAndNewlines)
                cell.marker.text = trimmedString
            }

            return cell
        }
        else if indexPath.row == 4{
            let cell = tableView.dequeueReusableCell(withIdentifier: "labelCell", for: indexPath) as! labelCell
            cell.label.text = "Current Offers"
            if Deals.count <= 0 {
                cell.label.text = "No Current Offers"
            }
            cell.contentView.borders(for: [.bottom], width: 1.0, color: UIColor.lightGray)
            return cell
        }
        else{
           let  cell = tableView.dequeueReusableCell(withIdentifier: "dealCell", for: indexPath) as! RDealsTableViewCell
            let deal = Deals[indexPath.row - 5]
            cell.deal = deal
            cell.validHours.text = ""
            cell.dealDesc.text = deal.dealDescription
            if deal.redeemed! {
                cell.Countdown.text = "Deal Already Redeemed!"
                cell.Countdown.textColor = UIColor.red
                cell.FavButton.isHidden = true
            }
            else{
                cell.Countdown.textColor = #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)
                
                let start = Date(timeIntervalSince1970: deal.startTime!)
                let end = Date(timeIntervalSince1970: deal.endTime!)
                let current = Date()
                let interval  =  DateInterval(start: start as Date, end: end as Date)
                if (interval.contains(current)){
                    let cal = Calendar.current
                    let Components = cal.dateComponents([.day, .hour, .minute], from: current, to: end)
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
                    /*Section for getting valid hours which is not currently used
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
                        cell.validHours.text = "Valid \(hour):0\(minute)\(component) to "
                    }
                    else{
                        cell.validHours.text = "Valid \(hour):\(minute)\(component) to "
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
                    }*/
                    
                }
                else if (current > end){
                    cell.Countdown.text = "Deal Ended"
                    cell.validHours.text = ""
                }
                else {
                    let cal = Calendar.current
                    let Components = cal.dateComponents([.day, .hour, .minute], from: current, to: start)
                    cell.Countdown.text = "Starts in " + String(describing: Components.day!) + "days"
                }
                if favorites[deal.dealID!] != nil{
                    favorites[deal.dealID!] = deal
                    let image = #imageLiteral(resourceName: "icons8-like_filled.png").withRenderingMode(.alwaysTemplate)
                    cell.FavButton.setImage(image, for: .normal)
                    cell.FavButton.tintColor = UIColor.red
                }
                else{
                    favorites.removeValue(forKey: deal.dealID!)
                    let image = #imageLiteral(resourceName: "icons8-like").withRenderingMode(.alwaysTemplate)
                    cell.FavButton.setImage(image, for: .normal)
                    cell.FavButton.tintColor = UIColor.red
                }
            }
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath){
        if indexPath.row > 3{
            tableView.deselectRow(at: indexPath, animated: true)
            let storyboard = UIStoryboard(name: "DealDetails", bundle: nil)
            let VC = storyboard.instantiateInitialViewController() as! DealViewController
            VC.hidesBottomBarWhenPushed = true
            VC.Deal = Deals[indexPath.row - 4]
            VC.photo = VC.Deal?.restrauntPhoto
            VC.fromDetails = true
            VC.index = indices[indexPath.row - 4]
            self.title = ""
            self.navigationController?.pushViewController(VC, animated: true)
        }
    }
  
    @objc func checkin(_ sender:UIButton!)
    {
        if self.loyaltyRedemptions == self.thisRestaurant.loyalty.loyaltyCount{
            self.loyaltyRedemptions = 0
            let redeemAlert = UIAlertController(title: "Confirm Redemption!", message: "If you wish to redeem this loyalty deal now, show this message to the server. If you wish to save this deal for later, hit CANCEL.", preferredStyle: .alert)
            redeemAlert.addAction(UIAlertAction(title: "Redeem", style: .default, handler: {(_) in
                self.ref.child("Users").child((Auth.auth().currentUser?.uid)!).child(self.rID!).updateChildValues(["redemptions": self.loyaltyRedemptions])
                sender.setTitle("Loyalty Check-In", for: .normal)
                self.DealsTable.reloadData()
            }))
            redeemAlert.addAction(UIAlertAction(title: "Cancel", style: .destructive, handler: nil))
            self.present(redeemAlert, animated: true)

        }else{
            //1. Create the alert controller.
            let alert = UIAlertController(title: "Check-In", message: "Enter Check-In Code", preferredStyle: .alert)
            
            //2. Add the text field. You can configure it however you need.
            alert.addTextField { (textField) in
                textField.placeholder = "Enter Code"
            }
            
            // 3. Grab the value from the text field, and print it when the user clicks OK.
            alert.addAction(UIAlertAction(title: "Submit", style: .default, handler: { [weak alert] (_) in
                let textField = alert?.textFields![0] // Force unwrapping because we know it exists.
                if textField?.text == self.thisRestaurant.loyalty.loyaltyCode{
                    self.loyaltyRedemptions = self.loyaltyRedemptions + 1
                self.ref.child("Users").child((Auth.auth().currentUser?.uid)!).child(self.rID!).updateChildValues(["redemptions": self.loyaltyRedemptions])
                    if self.loyaltyRedemptions == self.thisRestaurant.loyalty.loyaltyCount{
                        //sender.setTitle("Redeem", for: .normal)
                    }
                    self.DealsTable.reloadData()
                }
                else{
                    let erroralert = UIAlertController(title: "Incorrect code!", message: "The Check-In code you entered was incorrect. Please try again.", preferredStyle: .alert)
                    erroralert.addAction(UIAlertAction(title: "Okay", style: .default, handler: nil))
                    self.present(erroralert, animated: true)
                }
            }))
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .destructive, handler: nil))

            
            // 4. Present the alert.
            self.present(alert, animated: true, completion: nil)
        }
    }

   
    
    func preferredStatusBarStyle() -> UIStatusBarStyle {
        
        return UIStatusBarStyle.lightContent
    }
    
    
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let y = scrollView.contentOffset.y
        
        // this is just a demo method on how to compute the scale factor based on the current contentOffset
        if y < 0 {
            var scale = 1.0 + fabs(scrollView.contentOffset.y)  / scrollView.frame.size.height
            
            //Cap the scaling between zero and 1
            scale = max(0.0, scale)
            
            // Set the scale to the imageView
            self.rImg.transform = CGAffineTransform(scaleX: scale, y: scale)
            self.overview.transform = CGAffineTransform(scaleX: scale, y: scale)
            self.rImg.frame = CGRect(x: 0, y: scrollView.contentOffset.y, width: self.rImg.frame.size.width, height: self.rImg.frame.size.height)
            self.overview.frame = CGRect(x: 0, y: scrollView.contentOffset.y, width: self.rImg.frame.size.width, height: self.rImg.frame.size.height)
            self.rImg.frame.size.height = -y + self.cachedImageViewSize.height + 20
            self.overview.frame.size.height = -y + self.cachedImageViewSize.height + 20
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
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
}
class loyaltyCell: UITableViewCell {
    
    @IBOutlet weak var checkin: UIButton!
    @IBOutlet weak var loyaltyLabel: UILabel!
    
    @IBOutlet weak var marker: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
    }
}


class buttonCell: UITableViewCell {
    
    @IBOutlet weak var followButton: UIButton!
    @IBOutlet weak var directionsButton: UIButton!
    @IBOutlet weak var menuButton: UIButton!
    var request: URLRequest?
    var menu: String!
    var rID: String?
    var rAddress: String = ""

    
    override func awakeFromNib() {
        super.awakeFromNib()
        followButton.borders(for: [.left, .right], width: 3, color: UIColor.groupTableViewBackground)
        
    }
    
    
    @IBAction func openMenu(_ sender: Any) {
        menuButton.isEnabled = false
        UIApplication.shared.open(URL(string: menu)!, options: [:], completionHandler: nil)
        menuButton.isEnabled = true
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

    @IBAction func followPressed(_ sender: Any) {
        followButton.isEnabled = false
        if self.followButton.currentTitle == "Click to Follow"{
            let uID = Auth.auth().currentUser?.uid
            let followRef = Database.database().reference().child("Restaurants").child((self.rID)!).child("Followers").child(uID!)
            followRef.setValue(signalID)
            OneSignal.sendTags([(rID)! : "true"])
            self.followButton.imageView?.center = CGPoint(x: self.followButton.center.x, y: (self.followButton.imageView?.center.y)!)
            self.followButton.setTitle("Click to Unfollow", for: .normal)
            self.followButton.backgroundColor = #colorLiteral(red: 0.2848863602, green: 0.6698332429, blue: 0.6656947136, alpha: 1)

        }
        else{
            let uID = Auth.auth().currentUser?.uid
            let followRef = Database.database().reference().child("Restaurants").child((self.rID)!).child("Followers").child(uID!)
            followRef.removeValue()
            OneSignal.sendTags([(rID)! : "false"])
            self.followButton.setTitle("Click to Follow", for: .normal)
            self.followButton.backgroundColor = #colorLiteral(red: 0.6666666865, green: 0.6666666865, blue: 0.6666666865, alpha: 1)
            
        }
        followButton.isEnabled = true
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

