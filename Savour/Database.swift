//
//  DealData.swift
//  Savour
//
//  Created by Chris Patterson on 8/1/17.
//  Copyright © 2017 Chris Patterson. All rights reserved.
//

import Foundation
import UIKit
import FirebaseDatabase
import FirebaseAuth
import MapKit

class Deals{
    private var unfilteredDeals = [DealData]()
    private let ref = Database.database().reference()
    private let userid = Auth.auth().currentUser?.uid
    var filteredDeals = [DealData]()
    
    func getDeals(table: UITableView, dealType: String? = "All"){
        //Check if deal is favorited
        var favoriteIDs = Dictionary<String, String>()
        let userid = Auth.auth().currentUser?.uid
        let ref = Database.database().reference()
        ref.child("Users").child(userid!).child("Favorites").observeSingleEvent(of: .value, with: { (snapshot) in
            for entry in snapshot.children{
                let snap = entry as! DataSnapshot
                let value = snap.key
                favoriteIDs[value] = value
            }
            //once we have the favorites, we can get the deals
            self.unfilteredDeals.removeAll()
            let currentUnix = Date().timeIntervalSince1970
            let plusDay = currentUnix + 86400
            let expiredUnix = currentUnix
            let sortedRef = self.ref.child("Deals").queryOrdered(byChild: "StartTime")
            let filteredRef = sortedRef.queryEnding(atValue: plusDay, childKey: "StartTime")
            filteredRef.observeSingleEvent(of: .value, with: { (snapshot) in
                for entry in snapshot.children {
                    let snap = entry as! DataSnapshot
                    let temp = DealData(snap: snap, ID: userid!)
                    //if the deal is not expired or redeemed less than half an hour ago, show it
                    if temp.endTime! > expiredUnix && !temp.redeemed!{
                        self.unfilteredDeals.append(temp)
                    }else if let time = temp.redeemedTime{
                        if (Date().timeIntervalSince1970 - time) < 1800{
                            self.unfilteredDeals.append(temp)
                        }
                    }
                }
                for deal in self.unfilteredDeals{
                    if let _ = favoriteIDs[deal.dealID!]{
                        deal.fav = true
                    }
                }
                self.filter(byTitle: dealType!)
                self.sortDeals()
                table.reloadData()
            }){ (error) in
                print(error.localizedDescription)
            }
        }){ (error) in
            print(error.localizedDescription)
        }
    }
    
    func getDeals(forRestaurant restaurant: String, table: UITableView){
        var favoriteIDs = Dictionary<String, Bool>()
        let userid = Auth.auth().currentUser?.uid
        let ref = Database.database().reference()
        ref.child("Users").child(userid!).child("Favorites").observeSingleEvent(of: .value, with: { (snapshot) in
            for entry in snapshot.children{
                let snap = entry as! DataSnapshot
                let value = snap.key
                favoriteIDs[value] = true
            }
            self.unfilteredDeals.removeAll()
            let expiredUnix = Date().timeIntervalSince1970 - 24*60*60
            ref.child("Deals").queryOrdered(byChild: "rID").queryEqual(toValue: restaurant).observeSingleEvent(of: .value, with: { (snapshot) in
                for entry in snapshot.children {
                    let snap = entry as! DataSnapshot
                    let temp = DealData(snap: snap, ID: userid!)
                    //if the deal is not expired or redeemed less than half an hour ago, show it
                    if temp.endTime! > expiredUnix && !temp.redeemed!{
                        self.unfilteredDeals.append(temp)
                    }else if let time = temp.redeemedTime{
                        if (Date().timeIntervalSince1970 - time) < 1800{
                            self.unfilteredDeals.append(temp)
                        }
                    }
                }
                for deal in self.unfilteredDeals{
                    if let _ = favoriteIDs[deal.dealID!]{
                        deal.fav = true
                    }
                }
                self.filteredDeals = self.unfilteredDeals
                self.sortDeals()
                table.reloadData()
            }){ (error) in
                print(error.localizedDescription)
            }
        }){ (error) in
            print(error.localizedDescription)
        }
    }
    
    func filter(byTitle title: String){
        if title == "All" {
            filteredDeals = unfilteredDeals
        }else if title == "%" || title == "$"{
            filteredDeals = unfilteredDeals.filter { ($0.dealDescription!.lowercased().contains(title.lowercased())) }
        }else if  title == "BOGO" {
            // Filter the results
            filteredDeals = unfilteredDeals.filter { ($0.dealDescription!.lowercased().contains("Buy One Get One".lowercased())) }
        } else{
            filteredDeals = unfilteredDeals.filter { ($0.dealType!.lowercased().contains(title.lowercased())) }
        }
        sortDeals()
    }
    
    func filter(byName name: String){
        if name == "" {
            filteredDeals = unfilteredDeals
        } else {
            // Filter the results
            filteredDeals = unfilteredDeals.filter { ($0.restrauntName?.lowercased().contains(name.lowercased()))! }
        }
    }
    
    func sortDeals(){
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
    
    func getNotificationDeal(dealID: String?) -> DealData?{
        if dealID != nil && unfilteredDeals.count > 0{
            for i in 0..<unfilteredDeals.count{
                if unfilteredDeals[i].dealID == notificationDeal {//}&& !self.alreadyGoing{
                    //self.alreadyGoing = true
                    return unfilteredDeals[i]
                }
            }
        }
        return nil
    }
}

class Favorites{
    private var unfilteredDeals = [DealData]()
    var favoriteDeals = [DealData]()
    private let ref = Database.database().reference()
    private let userid = Auth.auth().currentUser?.uid

    func getFavorites(table: UITableView){
        let group = DispatchGroup()
        var favoriteIDs = [String]()
        let userid = Auth.auth().currentUser?.uid
        let ref = Database.database().reference()
        ref.child("Users").child(userid!).child("Favorites").observeSingleEvent(of: .value, with: { (snapshot) in
            for entry in snapshot.children{
                let snap = entry as! DataSnapshot
                let value = snap.key
                favoriteIDs.append(value)
            }
            self.unfilteredDeals.removeAll()
            let expiredUnix = Date().timeIntervalSince1970 - 24*60*60
            for favoriteID in favoriteIDs{
                group.enter()
                ref.child("Deals").queryOrderedByKey().queryEqual(toValue: favoriteID).observeSingleEvent(of: .value, with: { (snapshot) in
                    for child in snapshot.children{
                        let snap = child as! DataSnapshot
                        let temp = DealData(snap: snap, ID: userid!)
                        temp.fav = true
                        //if the deal is not expired or redeemed less than half an hour ago, show it
                        if temp.endTime! > expiredUnix && !temp.redeemed!{
                            self.unfilteredDeals.append(temp)
                        }else if let time = temp.redeemedTime{
                            if (Date().timeIntervalSince1970 - time) < 1800{
                                self.unfilteredDeals.append(temp)
                            }
                        }else{
                            //if the deal is no longer active or was redeemed, we can remove the favorite
                            ref.child("Users").child(userid!).child("Favorites").child(temp.restrauntID!).removeValue()
                        }
                    }
                    group.leave()
                }){ (error) in
                    print(error.localizedDescription)
                }
            }
            group.notify(queue: DispatchQueue.main) {
                self.favoriteDeals = self.unfilteredDeals
                self.sortDeals()
                table.reloadData()
            }
        }){ (error) in
            print(error.localizedDescription)
        }
    }
    
    func sortDeals(){
        favoriteDeals = favoriteDeals.sorted(by:{ (d1, d2) -> Bool in
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
}

class DealData{
    var restrauntName: String?
    var restrauntID: String?
    var restrauntPhoto: String?
    var dealDescription: String?
    var startTime: Double?
    var endTime: Double?
    var likes: Int?
    var dealID: String?
    var fav: Bool?
    var redeemed: Bool?
    var redeemedTime: Double?
    var dealType: String?
    var dealCode: String?
    var validHours: String?
    var valid: Bool

    
    
    init(snap: DataSnapshot? = nil, ID: String) {
        if ID == ""{
            self.restrauntID = ""
            self.likes = 0
            self.restrauntName = ""
            self.dealDescription = ""
            self.restrauntPhoto = ""
            self.endTime = 0
            self.startTime = 0
            self.dealType = ""
            self.dealID = ""
            self.fav = false
            self.dealCode = ""
            self.redeemed = false
            self.redeemedTime = 0
            self.validHours = ""
            self.valid = false
        }
        else{
            let value = snap?.value as! NSDictionary
            if let rID = value["rID"] {
                self.restrauntID = "\(rID)"
            }
            else {
                self.restrauntID = ""
            }
            self.likes = value["likes"] as? Int ?? 0
            self.restrauntName = value["rName"] as? String ?? ""
            self.dealDescription = value["dealDesc"] as? String ?? ""
            self.restrauntPhoto = value["rPhotoLoc"] as? String ?? ""
            self.endTime = value["EndTime"] as? Double
            self.startTime = value["StartTime"] as? Double
            self.dealType = value["Filter"] as? String ?? ""
            self.dealID = snap?.key
            self.dealCode = value["code"] as? String ?? ""
            if let redeemValue = value["redeemed"] as? NSDictionary{
                if let time = redeemValue[ID]{
                    self.redeemed = true
                    self.redeemedTime = time as? Double
                }else{
                    self.redeemed = false
                    self.redeemedTime = 0
                }
            }else{
                self.redeemed = false
                self.redeemedTime = 0
            }
            let startD = Date(timeIntervalSince1970: self.startTime!)
            let endD = Date(timeIntervalSince1970: self.endTime!)
            let calendar = Calendar.current
            let startTimeComponent = DateComponents(calendar: calendar, hour: calendar.component(.hour, from: startD), minute: calendar.component(.minute, from: startD))
            let endTimeComponent = DateComponents(calendar: calendar, hour: calendar.component(.hour, from: endD), minute: calendar.component(.minute, from: endD))
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.dateFormat = "h:mm a"
            formatter.amSymbol = "AM"
            formatter.pmSymbol = "PM"
            let now = Date()
            let startOfToday = calendar.startOfDay(for: now)
            let startTime    = calendar.date(byAdding: startTimeComponent, to: startOfToday)!
            let endTime      = calendar.date(byAdding: endTimeComponent, to: startOfToday)!
            if now > startTime && now < endTime{
                self.validHours = "Valid until " + formatter.string(from: endTime)
                self.valid = true
            }
            else{
                self.validHours = "Valid from " + formatter.string(from: startTime) + " to " + formatter.string(from: endTime)
                self.valid = false
            }
            
            //favorites are set during the firebase calls
            self.fav = false
        }
    }
}

class restaurant{
    var restrauntName: String?
    var restrauntID: String?
    var restrauntPhoto: String?
    var description: String?
    var address: String?
    var coordinates: CLLocationCoordinate2D?
    var distanceMiles: Double?
    var menu: String?
    var followers: Int?
    var hoursArray = [String]()
    var Deals = [DealData]()
    struct loyaltyStruct{
        var loyaltyCode: String
        var loyaltyCount: Int
        var loyaltyDeal: String
        
        init(code: String = "", deal: String = "", count: Int = -1) {
            self.loyaltyCount = count
            self.loyaltyCode = code
            self.loyaltyDeal = deal
        }
    }
    var loyalty: loyaltyStruct
    init(snap: DataSnapshot? = nil, ID: String) {
        let value = snap?.value as! NSDictionary
        self.restrauntID = ID
        self.restrauntName = value["Name"] as? String ?? ""
        self.restrauntPhoto = value["Photo"] as? String ?? ""
        self.description = value["Desc"] as? String ?? ""
        self.address = value["Address"] as? String ?? ""
        self.menu = value["Menu"] as? String ?? ""
        self.restrauntPhoto = value["Photo"] as? String ?? ""
        
        if (snap?.childSnapshot(forPath: "HappyHours").childrenCount)! > 0 {
            let hoursSnapshot = snap?.childSnapshot(forPath: "HappyHours").value as? NSDictionary
            self.hoursArray.append(hoursSnapshot?["Mon"] as? String ?? "No Happy Hour")
            self.hoursArray.append(hoursSnapshot?["Tues"] as? String ?? "No Happy Hour")
            self.hoursArray.append(hoursSnapshot?["Wed"] as? String ?? "No Happy Hour")
            self.hoursArray.append(hoursSnapshot?["Thurs"] as? String ?? "No Happy Hour")
            self.hoursArray.append(hoursSnapshot?["Fri"] as? String ?? "No Happy Hour")
            self.hoursArray.append(hoursSnapshot?["Sat"] as? String ?? "No Happy Hour")
            self.hoursArray.append(hoursSnapshot?["Sun"] as? String ?? "No Happy Hour")
        }
        if (snap?.childSnapshot(forPath: "loyalty").exists())!{
            let loyaltySnapshot = snap?.childSnapshot(forPath: "loyalty").value as? NSDictionary
            let code = loyaltySnapshot!["loyaltyCode"] as? String ?? ""
            let deal = loyaltySnapshot!["loyaltyDeal"] as? String ?? ""
            let count = loyaltySnapshot!["loyaltyCount"] as? Int ?? -1
            loyalty = loyaltyStruct(code: code, deal: deal, count: count)
        }else{loyalty = loyaltyStruct()}
    }
    
}
