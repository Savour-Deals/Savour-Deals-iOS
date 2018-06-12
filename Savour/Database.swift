//
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
import GeoFire

class DealsData{
    private let locationManager = CLLocationManager()
    private let ref = Database.database().reference()
    private let userid = Auth.auth().currentUser?.uid
    
    private var activeDeals = Dictionary<String,DealData>()
    private var inactiveDeals = Dictionary<String,DealData>()

    var vendorsData:VendorsData!
    
    private var favoriteIDs = Dictionary<String, String>()
    
    private var favoritesLoaded = false
    private var dealsLoaded = false
    var loadingComplete = false
    
    init(completion: @escaping (Bool) -> Void){
        let currentUnix = Date().timeIntervalSince1970
        let group1 = DispatchGroup()
        let group2 = DispatchGroup()
        let expiredUnix = currentUnix
        vendorsData = VendorsData(completion: { (success) in
            if success{
                self.ref.keepSynced(true)

                self.ref.child("Users").child(self.userid!).child("Favorites").observe(.value, with: { (snapshot) in
                    for entry in snapshot.children{
                        let snap = entry as! DataSnapshot
                        let key = snap.key
                        if let _ = snap.value{
                            //Get Favorites
                            self.favoriteIDs[key] = key
                        }else{
                            //Remove Favorite
                            self.favoriteIDs.removeValue(forKey: key)
                        }
                    }
                    self.dealsLoaded = true
                    if self.favoritesLoaded && self.dealsLoaded{
                        self.loadingComplete = true
                    }
                }){ (error) in
                    print(error.localizedDescription)
                }
                group1.notify(queue: .main) {
                    print("Finished gathering favorites.")
                }
                //Get Deals
                let vendors = self.vendorsData.getVendors()
                for vendor in vendors{
                    self.ref.child("Deals").queryOrdered(byChild: "rID").queryEqual(toValue: vendor.id).observe(.value, with: { (snapshot) in
                        for entry in snapshot.children {
                            group2.enter()
                            let snap = entry as! DataSnapshot
                            if let _ = snap.value{
                                let temp = DealData(snap: snap, ID: self.userid!)
                                if self.favoriteIDs[temp.id!] != nil{
                                    temp.favorited = true
                                }else{
                                    temp.favorited = false
                                }
                                //if the deal is not expired or redeemed less than half an hour ago, show it
                                if temp.endTime! > expiredUnix && !temp.redeemed!{
                                    if temp.active{
                                        self.activeDeals[temp.id!] = temp
                                    }else{
                                        self.inactiveDeals[temp.id!] = temp
                                    }
                                }else if let time = temp.redeemedTime{
                                    if (Date().timeIntervalSince1970 - time) < 1800{
                                        self.activeDeals[temp.id!] = temp
                                    }
                                }
                            }else{
                                let snap = entry as! DataSnapshot
                                let key = snap.key
                                self.activeDeals.removeValue(forKey: key)
                                self.inactiveDeals.removeValue(forKey: key)
                            }
                            group2.leave()
                        }
                    }){ (error) in
                        print(error.localizedDescription)
                    }
                    group2.notify(queue: .main) {
                        print("Finished gathering deals.")
                        completion(true)
                    }
                }
            }else{
                //error initializing vendorsData
                completion(false)
            }
        })
        
    }

    
    //Check if these return by reference
    func getDeals(dealType: String? = "All") -> ([DealData],[DealData]){
        var active = Array(activeDeals.values)
        var inactive = Array(inactiveDeals.values)
        sortDeals(array: &active)
        sortDeals(array: &inactive)
        return (active,inactive)
    }
    
    func getDeals(forRestaurant restaurant: String) -> ([DealData],[DealData]){
        var active = Array(activeDeals.values).filter { $0.rID == restaurant }
        var inactive = Array(inactiveDeals.values).filter { $0.rID == restaurant }
        sortDeals(array: &active)
        sortDeals(array: &inactive)
        return (active,inactive)
    }
    
    func getFavorites() -> ([DealData],[DealData]){
        let active = Array(activeDeals.values).filter { $0.favorited == true }
        let inactive = Array(inactiveDeals.values).filter { $0.favorited == true }
        return (active,inactive)
    }
   
    func filter(byTitle title: String) -> ([DealData],[DealData]){
        var inactive = [DealData]()
        var active = [DealData]()
        if title == "All" {
            active = Array(activeDeals.values)
            inactive = Array(inactiveDeals.values)
        }else if title == "%" || title == "$"{
            active = Array(activeDeals.values).filter { ($0.dealDescription!.lowercased().contains(title.lowercased())) }
            inactive = Array(inactiveDeals.values).filter  { ($0.dealDescription!.lowercased().contains(title.lowercased())) }
        }else if  title == "BOGO" {
            // Filter the results
            active = Array(activeDeals.values).filter { ($0.dealDescription!.lowercased().contains("Buy One Get One".lowercased())) }
            inactive = Array(inactiveDeals.values).filter { ($0.dealDescription!.lowercased().contains("Buy One Get One".lowercased())) }
        } else{
            active = Array(activeDeals.values).filter { ($0.dealDescription!.lowercased().contains(title.lowercased())) }
            inactive = Array(inactiveDeals.values).filter { ($0.dealDescription!.lowercased().contains(title.lowercased())) }
        }
        sortDeals(array: &active)
        sortDeals(array: &inactive)
        return (active,inactive)
    }
    
    func filter(byName name: String) -> ([DealData],[DealData]){
        var inactive = [DealData]()
        var active = [DealData]()
        if name == "" {
            active = Array(activeDeals.values)
            inactive = Array(inactiveDeals.values)
        } else {
            // Filter the results
            active = Array(activeDeals.values).filter { ($0.name?.lowercased().contains(name.lowercased()))! }
            inactive = Array(inactiveDeals.values).filter { ($0.name?.lowercased().contains(name.lowercased()))! }
        }
        return (active,inactive)
    }
    
    func sortDeals(array: inout [DealData]){
        array = array.sorted(by:{ (d1, d2) -> Bool in
            return CGFloat(d1.endTime!) < CGFloat(d2.endTime!)
        })
    }
    
    func getNotificationDeal(dealID: String?) -> DealData?{
        if dealID != nil && activeDeals.count > 0{
            return activeDeals[dealID!]
        }
        return nil
    }
}

class VendorsData{
    var vendors = Dictionary<String,VendorData>()
    private var geoFire: GFCircleQuery!
    private let locationManager = CLLocationManager()
    
    init(completion: @escaping (Bool) -> Void){
        locationManager.startUpdatingLocation()
        let ref = Database.database().reference().child("Restaurants")
        let geofireRef = Database.database().reference().child("Restaurants_Location")
        var count = 0
        if let location = locationManager.location{
            geoFire = GeoFire(firebaseRef: geofireRef).query(at: locationManager.location!, withRadius: 80.5)
            geoFire.observe(.keyEntered, with: { (key: String!, thislocation: CLLocation!) in //50 miles
                count = count + 1
                ref.queryOrderedByKey().queryEqual(toValue: key).observe(.value, with: { (snapshot) in
                    for child in snapshot.children{
                        let snap = child as! DataSnapshot
                        self.vendors[key] = VendorData(snap: snap, ID: key, location: thislocation, myLocation: location)
                    }
                    count = count - 1
                    if count == 0{
                        completion(true)
                    }
                })
            })
            geoFire.observe(.keyExited, with: { (key: String!, thislocation: CLLocation!) in //50 miles
                self.vendors.removeValue(forKey: key)
            })
        }else{
            //could not get location!!
            print("Vendors Failed to load. Location error!")
            completion(false)
        }
    }
    
    func getVendors() -> [VendorData]{
        return Array(vendors.values)
    }
    
    func getVendorsByID(id: String) -> (VendorData?){
        if let _ = vendors[id]{
            return vendors[id]!
        }
        //If here, could not find vendor. Do something for this issue
        return VendorData(ID: "")
    }
    
    func updateDistances(location: CLLocation){
        for vendor in vendors{
            vendor.value.distanceMiles = (vendor.value.location?.distance(from: location))!/1609
        }
        geoFire.center = location
    }
}
func updateDistance(location: CLLocation, vendor: VendorData) -> (VendorData){
    vendor.distanceMiles = (vendor.location?.distance(from: location))!/1609
    return vendor
}

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
    var activeDays = [Bool]()
    var active: Bool
    var countdown: String?
    var daysLeft: Int?
    
    init(snap: DataSnapshot? = nil, ID: String) {
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
            self.active = false
            for _ in 0...6{
                self.activeDays.append(false)
            }
        }
        else{
            let value = snap?.value as! NSDictionary
            self.rID = value["rID"] as? String ?? ""
            self.name = value["rName"] as? String ?? ""
            self.dealDescription = value["dealDesc"] as? String ?? ""
            self.photo = value["photo"] as? String ?? ""
            self.endTime = value["EndTime"] as? Double
            self.startTime = value["StartTime"] as? Double
            self.type = value["Filter"] as? String ?? ""
            self.id = snap?.key
            self.code = value["code"] as? String ?? ""
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
            let activeSnapshot = snap?.childSnapshot(forPath: "activeDays").value as? NSDictionary
            self.activeDays.append(activeSnapshot?["Sun"] as? Bool ?? false)
            self.activeDays.append(activeSnapshot?["Mon"] as? Bool ?? false)
            self.activeDays.append(activeSnapshot?["Tues"] as? Bool ?? false)
            self.activeDays.append(activeSnapshot?["Wed"] as? Bool ?? false)
            self.activeDays.append(activeSnapshot?["Thurs"] as? Bool ?? false)
            self.activeDays.append(activeSnapshot?["Fri"] as? Bool ?? false)
            self.activeDays.append(activeSnapshot?["Sat"] as? Bool ?? false)
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
            if self.activeDays[startTime.dayNumberOfWeek()!-1]{//Active today
                if now > startTime && now < endTime{
                    self.activeHours = "valid until " + formatter.string(from: endTime)
                    self.active = true
                }else if startTime == endTime{
                    self.activeHours = ""//"active all day!"
                    self.active = true
                }else{
                    self.activeHours = ""//"valid from " + formatter.string(from: startTime) + " to " + formatter.string(from: endTime)
                    self.code = "from " + formatter.string(from: startTime) + " to " + formatter.string(from: endTime)
                    self.active = false
                }
            }else{//Not Active today
                self.code = ""
                for i in 1...6{
                    if self.activeDays[i]{
                        if self.code != ""{
                            self.code = self.code! + " "
                        }
                        self.code = self.code! + ["Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"][i]
                    }
                }
                if self.activeDays[0]{
                    self.code = self.code! + " " + "Sunday"
                }
                self.code = (self.code?.replacingOccurrences(of: " ", with: ", "))!
                self.active = false
            }
            var isInInterval = false
            if #available(iOS 10.0, *) {
                let interval  =  DateInterval(start: start as Date, end: end as Date)
                isInInterval = interval.contains(now)
            } else {
                isInInterval = now.timeIntervalSince1970 > start.timeIntervalSince1970 && now.timeIntervalSince1970 < end.timeIntervalSince1970
            }
            if (isInInterval){
                let Components = calendar.dateComponents([.day, .hour, .minute], from: now, to: end)
                if (now < end && now > start){
                    var leftTime = ""
                    self.daysLeft = Components.day
                    if Components.day! != 0{
                        leftTime = leftTime + String(describing: Components.day!) + " days left"
                    }
                    else if Components.hour! != 0{
                        leftTime = leftTime + String(describing: Components.hour!) + "hours left"
                    }else{
                        leftTime = leftTime + String(describing: Components.minute!) + "minutes left"
                    }
                    self.countdown = leftTime
                }
            }
            else{
                self.daysLeft = 0
            }
            //favorites are set during the firebase calls
            self.favorited = false
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
                self.code = " from " + formatter.string(from: startTime) + " to " + formatter.string(from: endTime)
                self.active = false
            }
        }else{//Not Active today
            self.code = ""
            for i in 1...6{
                if self.activeDays[i]{
                    if self.code != ""{
                        self.code = self.code! + " "
                    }
                    self.code = self.code! + ["Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"][i]
                }
            }
            if self.activeDays[0]{
                self.code = self.code! + " " + "Sunday"
            }
            self.code = (self.code?.replacingOccurrences(of: " ", with: ", "))!
            self.active = false
        }
        var isInInterval = false
        if #available(iOS 10.0, *) {
            let interval  =  DateInterval(start: start as Date, end: end as Date)
            isInInterval = interval.contains(now)
        } else {
            isInInterval = now.timeIntervalSince1970 > start.timeIntervalSince1970 && now.timeIntervalSince1970 < end.timeIntervalSince1970
        }
        if (isInInterval){
            let Components = calendar.dateComponents([.day, .hour, .minute], from: now, to: end)
            if (now < end && now > start){
                var leftTime = ""
                if Components.day! != 0{
                    leftTime = leftTime + String(describing: Components.day!) + " days left"
                }
                else if Components.hour! != 0{
                    leftTime = leftTime + String(describing: Components.hour!) + "hours left"
                }else{
                    leftTime = leftTime + String(describing: Components.minute!) + "minutes left"
                }
                self.countdown = leftTime
            }
        }
    }
}

class VendorData{
    var name: String?
    var id: String!
    var photo: String?
    var description: String?
    var address: String?
    var location: CLLocation?
    var distanceMiles: Double?
    var menu: String?
    var followers: Int?
    var hoursArray = [String]()
    var dailyHours = [String]()
    struct loyaltyStruct{
        var loyaltyCode: String
        var loyaltyCount: Int
        var loyaltyDeal: String
        var loyaltyPoints = [Int]()
        
        init(code: String = "", deal: String = "", count: Int = -1, dict: NSDictionary=NSDictionary()) {
            self.loyaltyCount = count
            self.loyaltyCode = code
            self.loyaltyDeal = deal
            if code != ""{
                self.loyaltyPoints.append(dict["Sun"] as? Int ?? 0)
                self.loyaltyPoints.append(dict["Mon"] as? Int ?? 0)
                self.loyaltyPoints.append(dict["Tues"] as? Int ?? 0)
                self.loyaltyPoints.append(dict["Wed"] as? Int ?? 0)
                self.loyaltyPoints.append(dict["Thurs"] as? Int ?? 0)
                self.loyaltyPoints.append(dict["Fri"] as? Int ?? 0)
                self.loyaltyPoints.append(dict["Sat"] as? Int ?? 0)
            }
        }
    }
    var loyalty: loyaltyStruct
    init(snap: DataSnapshot? = nil, ID: String, location: CLLocation? = nil, myLocation: CLLocation? = nil) {
        if let value = snap?.value as? NSDictionary{
            self.id = ID
            self.name = value["Name"] as? String ?? ""
            self.photo = value["Photo"] as? String ?? ""
            self.description = value["Desc"] as? String ?? ""
            self.address = value["Address"] as? String ?? ""
            self.menu = value["Menu"] as? String ?? ""
            self.photo = value["Photo"] as? String ?? ""
            
            //        if (snap?.childSnapshot(forPath: "HappyHours").childrenCount)! > 0 {
            //            let hoursSnapshot = snap?.childSnapshot(forPath: "HappyHours").value as? NSDictionary
            //            self.hoursArray.append(hoursSnapshot?["Mon"] as? String ?? "No Happy Hour")
            //            self.hoursArray.append(hoursSnapshot?["Tues"] as? String ?? "No Happy Hour")
            //            self.hoursArray.append(hoursSnapshot?["Wed"] as? String ?? "No Happy Hour")
            //            self.hoursArray.append(hoursSnapshot?["Thurs"] as? String ?? "No Happy Hour")
            //            self.hoursArray.append(hoursSnapshot?["Fri"] as? String ?? "No Happy Hour")
            //            self.hoursArray.append(hoursSnapshot?["Sat"] as? String ?? "No Happy Hour")
            //            self.hoursArray.append(hoursSnapshot?["Sun"] as? String ?? "No Happy Hour")
            //        }
            if (snap?.childSnapshot(forPath: "DailyHours").childrenCount)! > 0 {
                let hoursSnapshot = snap?.childSnapshot(forPath: "DailyHours").value as? NSDictionary
                self.dailyHours.append(hoursSnapshot?["Sun"] as? String ?? "")
                self.dailyHours.append(hoursSnapshot?["Mon"] as? String ?? "")
                self.dailyHours.append(hoursSnapshot?["Tues"] as? String ?? "")
                self.dailyHours.append(hoursSnapshot?["Wed"] as? String ?? "")
                self.dailyHours.append(hoursSnapshot?["Thurs"] as? String ?? "")
                self.dailyHours.append(hoursSnapshot?["Fri"] as? String ?? "")
                self.dailyHours.append(hoursSnapshot?["Sat"] as? String ?? "")
            }
            if (snap?.childSnapshot(forPath: "loyalty").exists())!{
                let loyaltySnapshot = snap?.childSnapshot(forPath: "loyalty").value as? NSDictionary
                let code = loyaltySnapshot!["loyaltyCode"] as? String ?? ""
                let deal = loyaltySnapshot!["loyaltyDeal"] as? String ?? ""
                let count = loyaltySnapshot!["loyaltyCount"] as? Int ?? -1
                let pointsDict = loyaltySnapshot!["loyaltyPoints"] as? NSDictionary
                loyalty = loyaltyStruct(code: code, deal: deal, count: count, dict: pointsDict!)
            }else{loyalty = loyaltyStruct()}
            if location != nil{//If we already have location from firebase
                self.location = location
                self.distanceMiles = (location?.distance(from: myLocation!))!/1609
            }else{
                let geoCoder = CLGeocoder()
                geoCoder.geocodeAddressString(self.address!) { (placemarks, error) in
                    if let location = placemarks?.first?.location{
                        self.location = location
                        self.distanceMiles = (location.distance(from: myLocation!))/1609
                    }else{
                        //error with location!
                    }
                }
            }
        }else{
            self.id = ID
            self.name = ""
            self.photo = ""
            self.description = ""
            self.address = ""
            self.menu = ""
            self.loyalty = loyaltyStruct()
        }
        
    }
    
}
