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
    var rAddress: String = ""
    var cachedImageViewSize: CGRect!
    var cachedTextPoint: CGPoint!
    var rDesc: String!
    var hoursArray = [String]()
    
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
        ref.child("Restaurants").child(id!).observeSingleEvent(of: .value, with: { (snapshot) in
            
            let value = snapshot.value as? NSDictionary
            if snapshot.childSnapshot(forPath: "Followers").hasChild((Auth.auth().currentUser?.uid)!){
                self.followString = "Unfollow"
            }
            else{
                self.followString = "  Follow"
            }
                self.menu = value?["Menu"] as? String ?? ""
                self.rName.text = value?["Name"] as? String ?? ""
                self.rAddress = value?["Address"] as? String ?? ""
                self.rDesc = value?["Desc"] as? String ?? ""
                if snapshot.childSnapshot(forPath: "HappyHours").childrenCount > 0 {
                    let hoursSnapshot = snapshot.childSnapshot(forPath: "HappyHours").value as? NSDictionary
                    self.hoursArray.append(hoursSnapshot?["Mon"] as? String ?? "No Happy Hour")
                    self.hoursArray.append(hoursSnapshot?["Tues"] as? String ?? "No Happy Hour")
                    self.hoursArray.append(hoursSnapshot?["Wed"] as? String ?? "No Happy Hour")
                    self.hoursArray.append(hoursSnapshot?["Thurs"] as? String ?? "No Happy Hour")
                    self.hoursArray.append(hoursSnapshot?["Fri"] as? String ?? "No Happy Hour")
                    self.hoursArray.append(hoursSnapshot?["Sat"] as? String ?? "No Happy Hour")
                    self.hoursArray.append(hoursSnapshot?["Sun"] as? String ?? "No Happy Hour")
            }
                let photo = value?["Photo"] as? String ?? ""
                if photo != ""{
                    // Reference to an image file in Firebase Storage
                    let storage = Storage.storage()
                    let storageref = storage.reference(forURL: photo)
                    // Reference to an image file in Firebase Storage
                    let reference = storageref
            
                    // UIImageView in your ViewController
                    let imageView: UIImageView = self.rImg
            
                    // Placeholder image
                    let placeholderImage = UIImage(named: "placeholder.jpg")
            
                    // Load the image using SDWebImage
                    imageView.sd_setImage(with: reference, placeholderImage: placeholderImage)
            }
        }){ (error) in
            print(error.localizedDescription)
        }
        for i in 0 ... (UnfilteredDeals.count-1){
            if self.rID == UnfilteredDeals[i].restrauntID{
                self.Deals.append((UnfilteredDeals[i]))
                self.indices.append(i)
            }
        }
        DealsTable.reloadData()
        self.DealsTable.isHidden = false
    }
    
    func tableView(_ tableView: UITableView,heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == 2{
            return 100
        }
        if indexPath.row == 1{
            if self.hoursArray.count > 0{
                return UITableViewAutomaticDimension
            }
            else{
                return 0
            }
            
        }
        return UITableViewAutomaticDimension
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Deals.count + 4
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0{
            let cell = tableView.dequeueReusableCell(withIdentifier: "descCell", for: indexPath) as! labelCell
            cell.label.text = self.rDesc
            cell.contentView.borders(for: [.bottom], width: 2.0, color: UIColor.darkGray)
            return cell
        }
        else if indexPath.row == 1{
            let cell = tableView.dequeueReusableCell(withIdentifier: "hoursCell", for: indexPath) as! happyHourCell
            if hoursArray.count > 0{
                //cell.contentView.borders(for: [.bottom], width: 2.0, color: UIColor.darkGray)
                let mutableAttributedString = NSMutableAttributedString()
                let leftAlign = NSMutableParagraphStyle()
                leftAlign.alignment = .left
                let attrs = [NSAttributedStringKey.font : UIFont.systemFont(ofSize: 20, weight: UIFont.Weight.heavy), NSAttributedStringKey.paragraphStyle: leftAlign]
                let header = NSMutableAttributedString(string:"Happy Hours:\n", attributes:attrs)
                var hours = "Monday: " + hoursArray[0] + "\n"
                hours = hours + "Tuesday: " + hoursArray[1] + "\n"
                hours = hours + "Wednesday: " + hoursArray[2] + "\n"
                hours = hours + "Thursday: " + hoursArray[3] + "\n"
                hours = hours + "Friday: " + hoursArray[4] + "\n"
                hours = hours + "Saturday: " + hoursArray[5] + "\n"
                hours = hours + "Sunday: " + hoursArray[6] + "\n"
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
            cell.followButton.alignContentVerticallyByCenter(Img: #imageLiteral(resourceName: "follow"))
            cell.menuButton.alignContentVerticallyByCenter(Img: #imageLiteral(resourceName: "menu"))
            cell.directionsButton.alignContentVerticallyByCenter(Img: #imageLiteral(resourceName: "directions"))
            cell.request = self.request
            cell.menu = self.menu
            cell.rID = self.rID
            cell.rAddress = self.rAddress
            //cell.contentView.borders(for: [.bottom], width: 2.0, color: UIColor.darkGray)
            return cell
        }
        else if indexPath.row == 3{
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
            let deal = Deals[indexPath.row - 4]
            cell.deal = deal
            cell.dealDesc.text = deal.dealDescription
            if deal.redeemed! {
                cell.Countdown.text = "Deal Already Redeemed!"
                cell.validHours.text = ""
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
                    cell.Countdown.text =  "Time left: " + String(describing: Components.day!) + "d " + String(describing: Components.hour!) + "h " + String(describing: Components.minute!) + "m"
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
                    }
                    
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
        if self.followButton.currentTitle == "  Follow"{
            let uID = Auth.auth().currentUser?.uid
            let followRef = Database.database().reference().child("Restaurants").child((self.rID)!).child("Followers").child(uID!)
            followRef.setValue(signalID)
            OneSignal.sendTags([(rID)! : "true"])
            self.followButton.imageView?.center = CGPoint(x: self.followButton.center.x, y: (self.followButton.imageView?.center.y)!)
            self.followButton.setTitle("Unfollow", for: .normal)
        }
        else{
            let uID = Auth.auth().currentUser?.uid
            let followRef = Database.database().reference().child("Restaurants").child((self.rID)!).child("Followers").child(uID!)
            followRef.removeValue()
            OneSignal.sendTags([(rID)! : "false"])
            self.followButton.setTitle("  Follow", for: .normal)
            
        }
        followButton.isEnabled = true
    }
        
    
}

fileprivate extension UIButton {
    
    func alignContentVerticallyByCenter(padding:CGFloat = 6, Img: UIImage) {
        let image = Img.withRenderingMode(.alwaysTemplate)
        self.setImage(image, for: .normal)
        self.tintColor = UIColor.white
        
        let imageSize = self.imageView!.frame.size
        let titleSize = self.titleLabel!.frame.size
        let totalHeight = imageSize.height + titleSize.height + padding
        
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

