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
import GeoFire

class Deals{
    private var unfilteredDeals = [DealData]()
    private let ref = Database.database().reference()
    private let userid = Auth.auth().currentUser?.uid
    private var monitoredRegions = [CLCircularRegion]()
    var filteredDeals = [DealData]()
    var favoriteIDs = Dictionary<String, String>()

    func getDeals(byLocation location: CLLocation, table: UITableView, dealType: String? = "All") -> [DealData]{
        let currentUnix = Date().timeIntervalSince1970
        let group = DispatchGroup()
        let locationManager = CLLocationManager()
       // let plusDay = currentUnix + 86400
        let expiredUnix = currentUnix
        unfilteredDeals.removeAll()
        ref.keepSynced(true)
        ref.child("Users").child(userid!).child("Favorites").observeSingleEvent(of: .value, with: { (snapshot) in
            for entry in snapshot.children{
                let snap = entry as! DataSnapshot
                let value = snap.key
                self.favoriteIDs[value] = value
            }
            var nearby = [restaurant]()
            nearby = getRestaurants(byLocation: locationManager.location!)
            nearby = nearby.sorted(by:{ (d1, d2) -> Bool in
                if d1.distanceMiles! <= d2.distanceMiles! {
                    return true
                }else if  d1.distanceMiles! > d2.distanceMiles! {
                    return false
                }
                return false
            })
            for region in self.monitoredRegions{
                //remove all currently monitored locations
                locationManager.stopMonitoring(for: region)
            }
            self.monitoredRegions.removeAll()
            for place in nearby{
                if self.monitoredRegions.count < 20{
                    //monitor nearest 20 places
                    // Your coordinates go here (lat, lon)
                    let geofenceRegionCenter = place.location?.coordinate
                    
                    /* Create a region centered on desired location,
                     choose a radius for the region (in meters)
                     choose a unique identifier for that region */
                    let geofenceRegion = CLCircularRegion(center: geofenceRegionCenter!,radius: 20,identifier: place.restrauntID!)
                    geofenceRegion.notifyOnEntry = true
                    geofenceRegion.notifyOnExit = false
                    locationManager.startMonitoring(for: geofenceRegion)
                    self.monitoredRegions.append(geofenceRegion)
                }
                group.enter()
                self.ref.child("Deals").queryOrdered(byChild: "rID").queryEqual(toValue: place.restrauntID).observeSingleEvent(of: .value, with: { (snapshot) in
                    for entry in snapshot.children {
                        let snap = entry as! DataSnapshot
                        let temp = DealData(snap: snap, ID: self.userid!)
                        if !self.unfilteredDeals.contains(where: {$0.dealID  == temp.dealID }){
                            //if the deal is not expired or redeemed less than half an hour ago, show it
                            if temp.endTime! > expiredUnix && !temp.redeemed! && temp.valid{
                                self.unfilteredDeals.append(temp)
                            }else if let time = temp.redeemedTime{
                                if (Date().timeIntervalSince1970 - time) < 1800{
                                    self.unfilteredDeals.append(temp)
                                }
                            }
                        }
                    }
                    group.leave()
                }){ (error) in
                    print(error.localizedDescription)
                }
            }
        })
        group.wait()
        for deal in self.unfilteredDeals{
            if let _ = self.favoriteIDs[deal.dealID!]{
                deal.fav = true
            }
        }
        self.filter(byTitle: dealType!)
        self.sortDeals()
        return self.filteredDeals
    }

    func getDeals(table: UITableView, dealType: String? = "All"){
        //Check if deal is favorited
        let userid = Auth.auth().currentUser?.uid
        let ref = Database.database().reference()
        ref.child("Users").child(userid!).child("Favorites").observeSingleEvent(of: .value, with: { (snapshot) in
            for entry in snapshot.children{
                let snap = entry as! DataSnapshot
                let value = snap.key
                self.favoriteIDs[value] = value
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
                    if temp.endTime! > expiredUnix && !temp.redeemed! && temp.valid{
                        self.unfilteredDeals.append(temp)
                    }else if let time = temp.redeemedTime{
                        if (Date().timeIntervalSince1970 - time) < 1800{
                            self.unfilteredDeals.append(temp)
                        }
                    }
                }
                for deal in self.unfilteredDeals{
                    if let _ = self.favoriteIDs[deal.dealID!]{
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
        let userid = Auth.auth().currentUser?.uid
        let ref = Database.database().reference()
        ref.child("Users").child(userid!).child("Favorites").observeSingleEvent(of: .value, with: { (snapshot) in
            for entry in snapshot.children{
                let snap = entry as! DataSnapshot
                let value = snap.key
                self.favoriteIDs[value] = value
            }
            self.unfilteredDeals.removeAll()
            let expiredUnix = Date().timeIntervalSince1970 - 24*60*60
            ref.child("Deals").queryOrdered(byChild: "rID").queryEqual(toValue: restaurant).observeSingleEvent(of: .value, with: { (snapshot) in
                for entry in snapshot.children {
                    let snap = entry as! DataSnapshot
                    let temp = DealData(snap: snap, ID: userid!)
                    //if the deal is not expired or redeemed less than half an hour ago, show it
                    if temp.endTime! > expiredUnix && !temp.redeemed! && temp.valid{
                        self.unfilteredDeals.append(temp)
                    }else if let time = temp.redeemedTime{
                        if (Date().timeIntervalSince1970 - time) < 1800{
                            self.unfilteredDeals.append(temp)
                        }
                    }
                }
                for deal in self.unfilteredDeals{
                    if let _ = self.favoriteIDs[deal.dealID!]{
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
    var startDay: Double?
    var endDay: Double?
    var likes: Int?
    var dealID: String?
    var fav: Bool?
    var redeemed: Bool?
    var redeemedTime: Double?
    var dealType: String?
    var dealCode: String?
    var validHours: String?
    var valid: Bool
    var countdown: String?

    
    
    init(snap: DataSnapshot? = nil, ID: String) {
        if ID == ""{
            self.restrauntID = ""
            self.likes = 0
            self.restrauntName = ""
            self.dealDescription = ""
            self.restrauntPhoto = ""
            self.endTime = 0
            self.startTime = 0
            self.endDay = 0
            self.startDay = 0
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
            self.endDay = value["EndDay"] as? Double
            self.startDay = value["StartDay"] as? Double
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
                self.validHours = "Valid until " + formatter.string(from: endTime)
                self.valid = true
            }else if startTime == endTime{
                self.validHours = "Valid all day!"
                self.valid = true
            }else{
                self.validHours = "Valid from " + formatter.string(from: startTime) + " to " + formatter.string(from: endTime)
                self.valid = false
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
    var location: CLLocation?
    var distanceMiles: Double?
    var menu: String?
    var followers: Int?
    var hoursArray = [String]()
    var dailyHours = [String]()
    var Deals = [DealData]()
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
            self.restrauntID = ID
            self.restrauntName = value["Name"] as? String ?? ""
            self.restrauntPhoto = value["Photo"] as? String ?? ""
            self.description = value["Desc"] as? String ?? ""
            self.address = value["Address"] as? String ?? ""
            self.menu = value["Menu"] as? String ?? ""
            self.restrauntPhoto = value["Photo"] as? String ?? ""
            if location != nil{
                self.location = location
                self.distanceMiles = (location?.distance(from: myLocation!))!/1609
            }
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
        }else{
            self.restrauntID = ID
            self.restrauntName = ""
            self.restrauntPhoto = ""
            self.description = ""
            self.address = ""
            self.menu = ""
            self.restrauntPhoto = ""
            self.loyalty = loyaltyStruct()
        }
        
    }
    
}


func getRestaurants(byLocation location: CLLocation) -> [restaurant]{
    var nearby = [String]()
    var restaurants = [restaurant]()
    let ref = Database.database().reference().child("Restaurants")
    let geofireRef = Database.database().reference().child("Restaurants_Location")
    let geoFire = GeoFire(firebaseRef: geofireRef).query(at: location, withRadius: 80.5)
    let group = DispatchGroup()
    geoFire.observe(.keyEntered, with: { (key: String!, thislocation: CLLocation!) in //50 miles
        if !nearby.contains(key){
            nearby.append(key)
        }
    })
    geoFire.observeReady {
        for key in nearby{
            group.enter()
            ref.queryOrderedByKey().queryEqual(toValue: key).observeSingleEvent(of: .value, with: { (snapshot) in
                for child in snapshot.children{
                    let snap = child as! DataSnapshot
                    let temp = restaurant(snap: snap, ID: key, location: location, myLocation: location)
                    if !restaurants.contains(where: { $0.restrauntID  == temp.restrauntID }){
                        restaurants.append(temp)
                    }
                    group.leave()
                }
                
            })
        }
        
    }
    group.wait()
    if restaurants.count > 0{
        restaurants.sort(by: { (r1, r2) -> Bool in
            if r1.distanceMiles! < r2.distanceMiles!{
                return true
            }else{
                return false
            }
        })
    }
    return restaurants
}










class addresseClass{
    var address: String?
    var ID: String?
    init(add: String = "", id: String = ""){
        self.address = add
        self.ID = id
    }
}
var addresses = [addresseClass]()
var geocoder = CLGeocoder()  //Configure the geocoder as needed.



func setLocation(){

    let ref = Database.database().reference()
    ref.child("Restaurants").observeSingleEvent(of: .value, with: { (snapshot) in
        for entry in snapshot.children{
            let snap = entry as! DataSnapshot
            let value = snap.key
            let data = snap.value as! NSDictionary
            let temp = addresseClass.init(add: data["Address"] as? String ?? "", id: value)
            addresses.append(temp)
        }
        doGeoCoding()
    })

}
func doGeoCoding(){
    let geofireRef = Database.database().reference().child("Restaurants_Location")
    let geoFire = GeoFire(firebaseRef: geofireRef)
    if addresses.count > 0{
        let temp = addresses.popLast()
        geocoder.geocodeAddressString((temp?.address!)!) { (placemarks, error) -> Void in
            if((error) != nil){
                print("Error", error ?? "")
            }
            if let placemark = placemarks?.first {
                let Location = placemark.location
                geoFire.setLocation(Location!, forKey: (temp?.ID!)!)
            }
            doGeoCoding()
        }
    }
}

