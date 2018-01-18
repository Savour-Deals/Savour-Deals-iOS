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
            self.fav = false
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
