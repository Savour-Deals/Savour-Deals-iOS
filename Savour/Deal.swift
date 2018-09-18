//
//  Deal.swift
//  Savour
//
//  Created by Chris Patterson on 9/18/18.
//  Copyright © 2018 Chris Patterson. All rights reserved.
//


import Foundation
import UIKit
import FirebaseDatabase
import FirebaseAuth
import MapKit
import GeoFire

fileprivate let locationManager = CLLocationManager()

class DealData{
    var name: String?
    var id: String?
    var rID: String?
    var photo: String?
    var dealDescription: String?
    var startTime: Double?
    var endTime: Double?
    var favorited: Bool?
    var redeemed: Bool?
    var redeemedTime: Double?
    var type: String?
    var code: String?
    var activeHours: String?
    var inactiveString: String?
    var activeDays = [Bool]()
    var active: Bool
    var countdown: String?
    var daysLeft: Int?
    var distanceMiles: Double?
    
    init(snap: DataSnapshot? = nil, ID: String, vendors: Dictionary<String,VendorData>) {
        if ID == ""{
            self.rID = ""
            self.name = ""
            self.dealDescription = ""
            self.photo = ""
            self.endTime = 0
            self.startTime = 0
            self.type = ""
            self.id = ""
            self.favorited = false
            self.code = ""
            self.redeemed = false
            self.redeemedTime = 0
            self.activeHours = ""
            self.inactiveString = ""
            self.active = false
            self.distanceMiles = 0.0
            for _ in 0...6{
                self.activeDays.append(false)
            }
        }
        else{
            let value = snap?.value as! NSDictionary
            self.rID = value["vendor_id"] as? String ?? ""
            self.name = value["vendor_name"] as? String ?? ""
            self.dealDescription = value["deal_description"] as? String ?? ""
            self.photo = value["photo"] as? String ?? ""
            self.endTime = value["end_time"] as? Double
            self.startTime = value["start_time"] as? Double
            self.type = value["filter"] as? String ?? ""
            self.id = snap?.key
            self.code = value["code"] as? String ?? ""
            if let redeemValue = value["redeemed"] as? NSDictionary{
                if let time = redeemValue[ID] as? Double{
                    if Date().timeIntervalSince1970 - time > 60*60*24*7*2 {
                        //If redeemed 2 weeks ago, allow user to use deal again - Should be changed in the future
                        let randStr = String.random(length: 10)
                        let ref = Database.database().reference().child("Deals").child(self.id!).child("redeemed")
                        ref.child(ID).removeValue()
                        ref.child("\(ID)-\(randStr)").setValue(time)
                        self.redeemed = false
                        self.redeemedTime = 0
                    }else{
                        self.redeemed = true
                        self.redeemedTime = time
                    }
                }else{
                    self.redeemed = false
                    self.redeemedTime = 0
                }
            }else{
                self.redeemed = false
                self.redeemedTime = 0
            }
            //set distance from location
            self.distanceMiles = (vendors[self.rID!]?.location?.distance(from: locationManager.location!))!/1609
            //set days deal is active
            let activeSnapshot = snap?.childSnapshot(forPath: "active_days").value as? NSDictionary
            self.activeDays.append(activeSnapshot?["sun"] as? Bool ?? false)
            self.activeDays.append(activeSnapshot?["mon"] as? Bool ?? false)
            self.activeDays.append(activeSnapshot?["tues"] as? Bool ?? false)
            self.activeDays.append(activeSnapshot?["wed"] as? Bool ?? false)
            self.activeDays.append(activeSnapshot?["thur"] as? Bool ?? false)
            self.activeDays.append(activeSnapshot?["fri"] as? Bool ?? false)
            self.activeDays.append(activeSnapshot?["sat"] as? Bool ?? false)
            let start = Date(timeIntervalSince1970: self.startTime!)
            let end = Date(timeIntervalSince1970: self.endTime!)
            var calendar = Calendar.current
            calendar.timeZone = .current
            let startTimeComponent = DateComponents(calendar: calendar, hour: calendar.component(.hour, from: start), minute: calendar.component(.minute, from: start))
            let endTimeComponent = DateComponents(calendar: calendar, hour: calendar.component(.hour, from: end), minute: calendar.component(.minute, from: end))
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.dateFormat = "h:mm a"
            formatter.amSymbol = "AM"
            formatter.pmSymbol = "PM"
            let now = Date()
            let nowHour = DateComponents(calendar: calendar, hour: calendar.component(.hour, from: now))
            var startOfToday: Date!
            if nowHour.hour! < 5{//To solve problem with checking for deals after midnight... might have better way
                startOfToday = calendar.startOfDay(for: calendar.date(byAdding: .day, value: -1, to: now)!)
            }else{
                startOfToday = calendar.startOfDay(for: now)
            }
            let startTime = calendar.date(byAdding: startTimeComponent, to: startOfToday)!
            var endTime = calendar.date(byAdding: endTimeComponent, to: startOfToday)!
            if startTime > endTime {
                //Deal goes past midnight (might be typical of bar's drink deals)
                endTime = calendar.date(byAdding: .day, value: 1, to: endTime)!
            }
            if self.activeDays[startTime.dayNumberOfWeek()!-1]{//Active today
                if now > startTime && now < endTime{
                    self.activeHours = "valid until " + formatter.string(from: endTime)
                    self.active = true
                }else if startTime == endTime{
                    self.activeHours = ""//"active all day!"
                    self.active = true
                }else{
                    self.activeHours = ""//"valid from " + formatter.string(from: startTime) + " to " + formatter.string(from: endTime)
                    self.inactiveString = "from " + formatter.string(from: startTime) + " to " + formatter.string(from: endTime)
                    self.active = false
                }
            }else{//Not Active today
                self.inactiveString = ""
                for i in 1...6{
                    if self.activeDays[i]{
                        if self.inactiveString != ""{
                            self.inactiveString = self.inactiveString! + " "
                        }
                        self.inactiveString = self.inactiveString! + ["Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"][i]
                    }
                }
                if self.activeDays[0]{
                    self.inactiveString = self.inactiveString! + " " + "Sunday"
                }
                self.inactiveString = (self.inactiveString?.replacingOccurrences(of: " ", with: ", "))!
                self.active = false
            }
            
            //Get countdown string and days left
            var isInInterval = false
            if #available(iOS 10.0, *) {
                let interval  =  DateInterval(start: start as Date, end: end as Date)
                isInInterval = interval.contains(now)
            } else {
                isInInterval = now.timeIntervalSince1970 > start.timeIntervalSince1970 && now.timeIntervalSince1970 < end.timeIntervalSince1970
            }
            self.daysLeft = calendar.dateComponents([.day, .hour, .minute], from: Date().startOfDay, to: end).day
            if startTimeComponent == endTimeComponent{
                if daysLeft! > 1{
                    self.countdown = "\(daysLeft!) days left"
                }else if daysLeft! == 1{
                    self.countdown = "Deal expires tomorrow!"
                }else{
                    self.countdown = "Deal expires today!"
                }
            }else if (isInInterval){
                if (now < end && now > start){
                    if daysLeft! > 1{
                        self.countdown = "\(daysLeft!) days left"
                    }else if daysLeft! == 1{
                        self.countdown = "Deal expires tomorrow!"
                    }else{
                        self.countdown = "Deal expires today!"
                    }
                }
            }else{
                self.countdown = "Deal expires today!"
                self.daysLeft = 0
            }
        }
    }
    
    func updateTimes(){
        let start = Date(timeIntervalSince1970: self.startTime!)
        let end = Date(timeIntervalSince1970: self.endTime!)
        let calendar = Calendar.current
        let startTimeComponent = DateComponents(calendar: calendar, hour: calendar.component(.hour, from: start), minute: calendar.component(.minute, from: start))
        let endTimeComponent = DateComponents(calendar: calendar, hour: calendar.component(.hour, from: end), minute: calendar.component(.minute, from: end))
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "h:mm a"
        formatter.amSymbol = "AM"
        formatter.pmSymbol = "PM"
        let now = Date()
        let nowHour = DateComponents(calendar: calendar, hour: calendar.component(.hour, from: now))
        var startOfToday: Date!
        if nowHour.hour! < 5{//To solve problem with checking for deals after midnight... might have better way
            startOfToday = calendar.startOfDay(for: calendar.date(byAdding: .day, value: -1, to: now)!)
        }else{
            startOfToday = calendar.startOfDay(for: now)
        }
        let startTime    = calendar.date(byAdding: startTimeComponent, to: startOfToday)!
        var endTime      = calendar.date(byAdding: endTimeComponent, to: startOfToday)!
        if startTime > endTime {
            //Deal goes past midnight (might be typical of bar's drink deals)
            endTime = calendar.date(byAdding: .day, value: 1, to: endTime)!
        }
        
        
        if now > startTime && now < endTime{
            self.activeHours = "valid until " + formatter.string(from: endTime)
            self.active = true
        }
        if self.activeDays[startTime.dayNumberOfWeek()!-1]{//Active today
            if now > startTime && now < endTime{
                self.activeHours = "valid until " + formatter.string(from: endTime)
                self.active = true
            }else if startTime == endTime{
                self.activeHours = ""//"active all day!"
                self.active = true
            }else{
                self.activeHours = "valid from " + formatter.string(from: startTime) + " to " + formatter.string(from: endTime)
                self.inactiveString = " from " + formatter.string(from: startTime) + " to " + formatter.string(from: endTime)
                self.active = false
            }
        }else{//Not Active today
            self.inactiveString = ""
            for i in 1...6{
                if self.activeDays[i]{
                    if self.inactiveString != ""{
                        self.inactiveString = self.inactiveString! + " "
                    }
                    self.inactiveString = self.inactiveString! + ["Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"][i]
                }
            }
            if self.activeDays[0]{
                self.inactiveString = self.inactiveString! + " " + "Sunday"
            }
            self.inactiveString = (self.inactiveString?.replacingOccurrences(of: " ", with: ", "))!
            self.active = false
        }
        
        //Get countdown string and days left
        var isInInterval = false
        if #available(iOS 10.0, *) {
            let interval  =  DateInterval(start: start as Date, end: end as Date)
            isInInterval = interval.contains(now)
        } else {
            isInInterval = now.timeIntervalSince1970 > start.timeIntervalSince1970 && now.timeIntervalSince1970 < end.timeIntervalSince1970
        }
        self.daysLeft = calendar.dateComponents([.day, .hour, .minute], from: Date().startOfDay, to: end).day
        if startTimeComponent == endTimeComponent{
            if daysLeft! > 1{
                self.countdown = "\(daysLeft!) days left"
            }else if daysLeft! == 1{
                self.countdown = "Deal expires tomorrow!"
            }else{
                self.countdown = "Deal expires today!"
            }
        }else if (isInInterval){
            if (now < end && now > start){
                if daysLeft! > 1{
                    self.countdown = "\(daysLeft!) days left"
                }else if daysLeft! == 1{
                    self.countdown = "Deal expires tomorrow!"
                }else{
                    self.countdown = "Deal expires today!"
                }
            }
        }else{
            self.countdown = "Deal expires today!"
            self.daysLeft = 0
        }
    }
    
    func updateDistance(vendor: VendorData){
        if let _ = vendor.location,let _ = locationManager.location{
            self.distanceMiles = (vendor.location?.distance(from: locationManager.location!))!/1609
        }else{
            print("Could not update distance. Vendor or location manager not present")
        }
    }
}
