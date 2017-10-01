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
