//
//  DealsViewController.swift
//  Savour
//
//  Created by Chris Patterson on 10/4/17.
//  Copyright © 2017 Chris Patterson. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseStorage
import SDWebImage
import FirebaseAuth

struct Group {
    var status: String!
    var deals: [DealData]!
    var expanded: Bool!
    
    init(status: String, deals: [DealData], expanded: Bool) {
        self.status = status
        self.deals = deals
        self.expanded = expanded
    }
}
class DealsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, ExpandableHeaderViewDelegate {
  
    @IBOutlet weak var tableView: UITableView!
    
    var chosenDeal: DealData!
    var storage: Storage!
    var ref: DatabaseReference!
    var handle: AuthStateDidChangeListenerHandle?

    var activeDeals = [DealData]()
    var expiredDeals = [DealData]()
    var upcomingDeals = [DealData]()
    var groups = [Group]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.ref = Database.database().reference()
        handle = Auth.auth().addStateDidChangeListener { (auth, user) in}
        loadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        //loadData()
    }
    
    func loadData(){
        self.activeDeals.removeAll()
        self.expiredDeals.removeAll()
        self.upcomingDeals.removeAll()
        let sortedRef = self.ref.child("Deals").queryOrdered(byChild: "StartTime")
        let currentUnix = Date().timeIntervalSince1970
        sortedRef.observeSingleEvent(of: .value, with: { (snapshot) in
            // Get user value
            for entry in snapshot.children {
                let snap = entry as! DataSnapshot
                let temp = DealData(snap: snap, ID: (Auth.auth().currentUser?.uid)!) // convert my snapshot into my type
                if temp.restrauntID == Auth.auth().currentUser?.uid{
                    if currentUnix < temp.endTime! && currentUnix > temp.startTime! {
                        self.activeDeals.append(temp)
                    }
                    if currentUnix > temp.endTime!{
                        self.expiredDeals.append(temp)
                    }
                    if currentUnix < temp.startTime!{
                        self.upcomingDeals.append(temp)
                    }
                }
            }
            self.groups = [ Group(status: "Active Deals", deals: self.activeDeals, expanded: true), Group(status: "Upcoming Deals", deals: self.upcomingDeals, expanded: false), Group(status: "Expired Deals", deals: self.expiredDeals, expanded: false)]
            
            self.tableView.dataSource = self
            self.tableView.delegate = self
            self.tableView.reloadData()

        })
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return groups.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return groups[section].deals.count
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if (groups[indexPath.section].expanded) {
            return 143
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 2
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = ExpandableHeaderView()
        if groups[section].deals.count > 0 {
            header.customInit(title: groups[section].status, section: section, delegate: self)
        }
        else{
            header.customInit(title: "No \(groups[section].status!)", section: section, delegate: self)
        }
        return header
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "dealCell")! as! VendorDealCell
        cell.deal = groups[indexPath.section].deals[indexPath.row]
        let photo = cell.deal.restrauntPhoto!
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
        cell.rName.text = cell.deal.restrauntName
        cell.dealDesc.text = cell.deal.dealDescription
        if groups[indexPath.section].status == "Active Deals"{
            cell.Countdown.textColor = #colorLiteral(red: 0.9443297386, green: 0.5064610243, blue: 0.3838719726, alpha: 1)
            let start = Date(timeIntervalSince1970: cell.deal.startTime!)
            let end = Date(timeIntervalSince1970: cell.deal.endTime!)
            let current = Date()
            var isInInterval = false
            if #available(iOS 10.0, *) {
                let interval  =  DateInterval(start: start as Date, end: end as Date)
                isInInterval = interval.contains(current)
            } else {
                isInInterval = current.timeIntervalSince1970 > start.timeIntervalSince1970 && current.timeIntervalSince1970 < end.timeIntervalSince1970
            }
            if (isInInterval){
                let cal = Calendar.current
                let Components = cal.dateComponents([.day, .hour, .minute], from: current, to: end)
                cell.Countdown.text =  "Time left: " + String(describing: Components.day!) + "d " + String(describing: Components.hour!) + "h " + String(describing: Components.minute!) + "m"
            }
        }
        else if groups[indexPath.section].status == "Upcoming Deals"{
            let cal = Calendar.current
            let start = Date(timeIntervalSince1970: cell.deal.startTime!)
            let current = Date()
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
        else{
            cell.Countdown.text = "Deal Ended"
        }
        return cell
    }
    
    func toggleSection(header: ExpandableHeaderView, section: Int) {
        groups[section].expanded = !groups[section].expanded
        
        tableView.reloadData()
        //tableView.beginUpdates()
        //for i in 0 ..< groups[section].deals.count {
        //    tableView.reloadRows(at: [IndexPath(row: i, section: section)], with: .fade)
       // }
        //tableView.endUpdates()
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath){
        let cell = tableView.cellForRow(at: indexPath) as! VendorDealCell
        tableView.deselectRow(at: indexPath, animated: true)
        chosenDeal = cell.deal
        performSegue(withIdentifier: "DealInfo", sender: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "DealInfo" {
            let VC = segue.destination as! ChartView
            VC.deal = self.chosenDeal
        }
    }

}








protocol ExpandableHeaderViewDelegate {
    func toggleSection(header: ExpandableHeaderView, section: Int)
}

class ExpandableHeaderView: UITableViewHeaderFooterView {
    var delegate: ExpandableHeaderViewDelegate?
    var section: Int!
    
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        self.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(selectHeaderAction)))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func selectHeaderAction(gestureRecognizer: UITapGestureRecognizer) {
        let cell = gestureRecognizer.view as! ExpandableHeaderView
        delegate?.toggleSection(header: self, section: cell.section)
    }
    
    func customInit(title: String, section: Int, delegate: ExpandableHeaderViewDelegate) {
        self.textLabel?.text = title
        self.section = section
        self.delegate = delegate
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.textLabel?.textColor = UIColor.white
        self.contentView.backgroundColor = #colorLiteral(red: 0.2848863602, green: 0.6698332429, blue: 0.6656947136, alpha: 1)
    }
}

