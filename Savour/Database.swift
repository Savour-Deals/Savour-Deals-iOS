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

class Deals{
    private var unfilteredDeals = [DealData]()
    private let ref = Database.database().reference()
    private let userid = Auth.auth().currentUser?.uid
    var filteredDeals = [DealData]()
    private var inactiveDeals = [DealData]()
    var filteredInactiveDeals = [DealData]()
    var restaurants = Dictionary<String,restaurant>()
    var favoriteIDs = Dictionary<String, String>()

    func getDeals(byLocation location: CLLocation, dealType: String? = "All", completion: @escaping (Bool) -> ()){
        let currentUnix = Date().timeIntervalSince1970
        let group = DispatchGroup()
        let locationManager = CLLocationManager()
        let expiredUnix = currentUnix
        unfilteredDeals.removeAll()
        inactiveDeals.removeAll()
        ref.keepSynced(true)
        ref.child("Users").child(userid!).child("Favorites").observeSingleEvent(of: .value, with: { (snapshot) in
            for entry in snapshot.children{
                let snap = entry as! DataSnapshot
                let value = snap.key
                self.favoriteIDs[value] = value
            }
            var nearby = [restaurant]()
            getRestaurants(byLocation: locationManager.location!,completion:{ (restaurants) in
                nearby = restaurants
                for rest in restaurants{
                    self.restaurants[rest.id!] = rest
                }
                nearby = nearby.sorted(by:{ (d1, d2) -> Bool in
                    if d1.distanceMiles! <= d2.distanceMiles! {
                        return true
                    }else if  d1.distanceMiles! > d2.distanceMiles! {
                        return false
                    }
                    return false
                })
                for place in nearby{
                    group.enter()
                    self.ref.child("Deals").queryOrdered(byChild: "rID").queryEqual(toValue: place.id).observeSingleEvent(of: .value, with: { (snapshot) in
                        for entry in snapshot.children {
                            let snap = entry as! DataSnapshot
                            let temp = DealData(snap: snap, ID: self.userid!)
                            if !self.unfilteredDeals.contains(where: {$0.id  == temp.id }) && !self.inactiveDeals.contains(where: {$0.id  == temp.id }){
                                //if the deal is not expired or redeemed less than half an hour ago, show it
                                if temp.endTime! > expiredUnix && !temp.redeemed!{
                                    if temp.active{
                                        self.unfilteredDeals.append(temp)
                                    }else{
                                        self.inactiveDeals.append(temp)
                                    }
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
                group.notify(queue: DispatchQueue.main){
                    for deal in self.unfilteredDeals{
                        if let _ = self.favoriteIDs[deal.id!]{
                            deal.favorited = true
                        }
                    }
                    self.filter(byTitle: dealType!)
                    self.sortDeals()
                    completion(true)
                }
            })
        })
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
                    if !self.unfilteredDeals.contains(where: {$0.id  == temp.id }) && !self.inactiveDeals.contains(where: {$0.id  == temp.id }){
                        //if the deal is not expired or redeemed less than half an hour ago, show it
                        if temp.endTime! > expiredUnix && !temp.redeemed!{
                            if temp.active{
                                self.unfilteredDeals.append(temp)
                            }else{
                                self.inactiveDeals.append(temp)
                            }
                        }else if let time = temp.redeemedTime{
                            if (Date().timeIntervalSince1970 - time) < 1800{
                                self.unfilteredDeals.append(temp)
                            }
                        }
                    }
                }
                for deal in self.unfilteredDeals{
                    if let _ = self.favoriteIDs[deal.id!]{
                        deal.favorited = true
                    }
                }
                self.filteredDeals = self.unfilteredDeals
                self.filteredInactiveDeals = self.inactiveDeals
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
            filteredInactiveDeals = inactiveDeals
        }else if title == "%" || title == "$"{
            filteredDeals = unfilteredDeals.filter { ($0.dealDescription!.lowercased().contains(title.lowercased())) }
            filteredInactiveDeals = inactiveDeals.filter  { ($0.dealDescription!.lowercased().contains(title.lowercased())) }
        }else if  title == "BOGO" {
            // Filter the results
            filteredDeals = unfilteredDeals.filter { ($0.dealDescription!.lowercased().contains("Buy One Get One".lowercased())) }
            filteredInactiveDeals = inactiveDeals.filter { ($0.dealDescription!.lowercased().contains("Buy One Get One".lowercased())) }
        } else{
            filteredDeals = unfilteredDeals.filter { ($0.dealDescription!.lowercased().contains(title.lowercased())) }
            filteredInactiveDeals = inactiveDeals.filter { ($0.dealDescription!.lowercased().contains(title.lowercased())) }
        }
        sortDeals()
    }
    
    func filter(byName name: String){
        if name == "" {
            filteredDeals = unfilteredDeals
            filteredInactiveDeals = inactiveDeals
        } else {
            // Filter the results
            filteredDeals = unfilteredDeals.filter { ($0.name?.lowercased().contains(name.lowercased()))! }
            filteredInactiveDeals = inactiveDeals.filter { ($0.name?.lowercased().contains(name.lowercased()))! }
        }
    }
    
    func sortDeals(){
        filteredDeals = filteredDeals.sorted(by:{ (d1, d2) -> Bool in
            if d1.active && !d2.active {
                return true
            }else if !d1.active && d2.active{
                return false
            }
            else if d1.active == d2.active {
                return CGFloat(d1.endTime!) < CGFloat(d2.endTime!)
            }
            return false
        })
    }
    
    func getNotificationDeal(dealID: String?) -> DealData?{
        if dealID != nil && unfilteredDeals.count > 0{
            for i in 0..<unfilteredDeals.count{
                if unfilteredDeals[i].id == notificationDeal {
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
    var restaurants = Dictionary<String,restaurant>()

    func getFavorites(table: UITableView){
        let group = DispatchGroup()
        var favoriteIDs = [String]()
        let userid = Auth.auth().currentUser?.uid
        let ref = Database.database().reference()
        let locationManager = CLLocationManager()
        getRestaurants(byLocation: locationManager.location!,completion:{ (restaurants) in
            for rest in restaurants{
                self.restaurants[rest.id!] = rest
            }
        })
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
                        temp.favorited = true
                        //if the deal is not expired or redeemed less than half an hour ago, show it
                        if temp.endTime! > expiredUnix && !temp.redeemed!{
                            self.unfilteredDeals.append(temp)
                        }else if let time = temp.redeemedTime{
                            if (Date().timeIntervalSince1970 - time) < 1800{
                                self.unfilteredDeals.append(temp)
                            }
                        }else{
                            //if the deal is no longer active or was redeemed, we can remove the favorite
                            ref.child("Users").child(userid!).child("Favorites").child(temp.id!).removeValue()
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
            if d1.active && !d2.active {
                return true
            }else if !d1.active && d2.active{
                return false
            }
            else if d1.active == d2.active {
                return CGFloat(d1.endTime!) < CGFloat(d2.endTime!)
            }
            return false
        })
    }
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
            if let rID = value["rID"] {
                self.rID = "\(rID)"
            }
            else {
                self.id = ""
            }
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

class restaurant{
    var name: String?
    var id: String?
    var photo: String?
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
            self.id = ID
            self.name = value["Name"] as? String ?? ""
            self.photo = value["Photo"] as? String ?? ""
            self.description = value["Desc"] as? String ?? ""
            self.address = value["Address"] as? String ?? ""
            self.menu = value["Menu"] as? String ?? ""
            self.photo = value["Photo"] as? String ?? ""
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
func updateDistance(location: CLLocation, restaurants: [restaurant])-> [restaurant]{
    for restaurant in restaurants{
        restaurant.distanceMiles = (restaurant.location?.distance(from: location))!/1609
    }
    return restaurants
}
func getRestaurants(byLocation location: CLLocation,completion: @escaping ([restaurant]) -> ()){
    var nearby = [String:CLLocation]()
    var restaurants = [restaurant]()
    let ref = Database.database().reference().child("Restaurants")
    let geofireRef = Database.database().reference().child("Restaurants_Location")
    let geoFire = GeoFire(firebaseRef: geofireRef).query(at: location, withRadius: 80.5)
    geoFire.observe(.keyEntered, with: { (key: String!, thislocation: CLLocation!) in //50 miles
        nearby[key] = thislocation
    })
    geoFire.observeReady {
        let group = DispatchGroup()
        for loc in nearby{
            group.enter()
            ref.queryOrderedByKey().queryEqual(toValue: loc.key).observeSingleEvent(of: .value, with: { (snapshot) in
                for child in snapshot.children{
                    let snap = child as! DataSnapshot
                    let temp = restaurant(snap: snap, ID: loc.key, location: loc.value, myLocation: location)
                    if !restaurants.contains(where: { $0.id  == temp.id }){
                        restaurants.append(temp)
                    }
                    group.leave()
                }
                
            })
        }
        group.notify(queue: DispatchQueue.main){
            if restaurants.count > 0{
                restaurants.sort(by: { (r1, r2) -> Bool in
                    if r1.distanceMiles! < r2.distanceMiles!{
                        return true
                    }else{
                        return false
                    }
                })
            }
            completion(restaurants)
        }
    }
}

func add_TwoMonth(){
    let ref = Database.database().reference()
    ref.child("Deals").observeSingleEvent(of: .value, with: { (snapshot) in
        for entry in snapshot.children{
            let snap = entry as! DataSnapshot
            let value = snap.key
            let data = snap.value as! NSDictionary
            let end = data["EndTime"] as? Double
            ref.child("Deals").child(value).child("EndTime").setValue(end!+5256000.0)
        }
    })
}

