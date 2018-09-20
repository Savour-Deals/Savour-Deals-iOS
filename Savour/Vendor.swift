//
//  Vendor.swift
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

class VendorData{
    var name: String?
    var id: String!
    var photo: String?
    var description: String?
    var address: String?
    var location: CLLocation?
    var distanceMiles: Double?
    var menu: String?
    var subscriptionId: String?
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
                self.loyaltyPoints.append(dict["sun"] as? Int ?? 0)
                self.loyaltyPoints.append(dict["mon"] as? Int ?? 0)
                self.loyaltyPoints.append(dict["tues"] as? Int ?? 0)
                self.loyaltyPoints.append(dict["wed"] as? Int ?? 0)
                self.loyaltyPoints.append(dict["thurs"] as? Int ?? 0)
                self.loyaltyPoints.append(dict["fri"] as? Int ?? 0)
                self.loyaltyPoints.append(dict["sat"] as? Int ?? 0)
            }
        }
    }
    
    var loyalty: loyaltyStruct
    init(snap: DataSnapshot? = nil, ID: String, location: CLLocation? = nil, myLocation: CLLocation? = nil) {
        if let value = snap?.value as? NSDictionary{
            self.id = ID
            self.name = value["name"] as? String ?? ""
            self.photo = value["photo"] as? String ?? ""
            self.description = value["description"] as? String ?? ""
            self.address = value["address"] as? String ?? ""
            self.menu = value["menu"] as? String ?? ""
            self.subscriptionId = value["subscription_id"] as? String ?? ""
            if (snap?.childSnapshot(forPath: "daily_hours").childrenCount)! > 0 {
                let hoursSnapshot = snap?.childSnapshot(forPath: "daily_hours").value as? NSDictionary
                self.dailyHours.append(hoursSnapshot?["sun"] as? String ?? "")
                self.dailyHours.append(hoursSnapshot?["mon"] as? String ?? "")
                self.dailyHours.append(hoursSnapshot?["tues"] as? String ?? "")
                self.dailyHours.append(hoursSnapshot?["wed"] as? String ?? "")
                self.dailyHours.append(hoursSnapshot?["thurs"] as? String ?? "")
                self.dailyHours.append(hoursSnapshot?["fri"] as? String ?? "")
                self.dailyHours.append(hoursSnapshot?["sat"] as? String ?? "")
            }
            if (snap?.childSnapshot(forPath: "loyalty/loyalty_deal").exists())!{
                let loyaltySnapshot = snap?.childSnapshot(forPath: "loyalty").value as? NSDictionary
                let code = loyaltySnapshot!["loyalty_code"] as? String ?? ""
                let deal = loyaltySnapshot!["loyalty_deal"] as? String ?? ""
                let count = loyaltySnapshot!["loyalty_count"] as? Int ?? -1
                let pointsDict = loyaltySnapshot!["loyalty_points"] as? NSDictionary
                loyalty = loyaltyStruct(code: code, deal: deal, count: count, dict: pointsDict!)
            }else{
                loyalty = loyaltyStruct()
            }
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
    
    func updateDistance(){
        if let _ = self.location,let _ = locationManager.location{
            self.distanceMiles = (self.location?.distance(from: locationManager.location!))!/1609
        }else{
            print("Could not update distance. Vendor or location manager not present")
        }
    }
    
}
