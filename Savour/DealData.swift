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


class DealData{
    var restrauntName: String?
    var restrauntID: Int?
    var restrauntPhoto: String?
    var dealDescription: String?
    var startTime: Double?
    var endTime: Double?
    var likes: Int?
    var filter: String?
    var dealID: String?
    
    
    
     init(snap: DataSnapshot) {
        let value = snap.value as! NSDictionary
        self.restrauntID = value["rID"] as? Int ?? 0
        self.likes = value["likes"] as? Int ?? 0
        self.restrauntName = value["rName"] as? String ?? ""
        self.dealDescription = value["dealDesc"] as? String ?? ""
        self.restrauntPhoto = value["rPhotoLoc"] as? String ?? ""
        self.endTime = value["EndTime"] as? Double
        self.startTime = value["StartTime"] as? Double
        self.filter = value["Filter"] as? String ?? ""
        self.dealID = snap.key
    }
 
    
  
    
}
