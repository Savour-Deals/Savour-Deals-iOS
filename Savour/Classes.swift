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
