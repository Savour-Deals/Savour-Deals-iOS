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
                self.dailyHours.append(hoursSnapshot?["sun"] as? String ?? "Not Available")
                self.dailyHours.append(hoursSnapshot?["mon"] as? String ?? "Not Available")
                self.dailyHours.append(hoursSnapshot?["tues"] as? String ?? "Not Available")
                self.dailyHours.append(hoursSnapshot?["wed"] as? String ?? "")
                self.dailyHours.append(hoursSnapshot?["thurs"] as? String ?? "Not Available")
                self.dailyHours.append(hoursSnapshot?["fri"] as? String ?? "Not Available")
                self.dailyHours.append(hoursSnapshot?["sat"] as? String ?? "Not Available")
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
            self.name = "Savour Deals"
            self.id = "SVRDEALS"
            self.photo = "https://firebasestorage.googleapis.com/v0/b/savour-deals.appspot.com/o/Vendors%2FSVRFARGO%2FSVRFARGO?alt=media&token=ace82feb-656c-4622-ae4d-9b16464ca0df"
            self.description = "Savour Deals is a daily deals and loyalty rewards app allowing local bars, cafes, and restaurants to create their own customized deals and deliver them right to you. You are able to follow your favorite vendors and you will receive alerts when the post a new deal. We will also alert you if you are near multiple deals!\n\nIf you have a knack for networking or have a relationship with eateries in your area, we would love to connect with you. Our sales members receive a portion of all revenue generated through referrals to the platform. Our sales team has a flexible schedule, only working when they want to. If you would like to get involved, go to your account tab and select 'contact us' and let us know you are interested in learning more about the sales positions!\n\nVisit our website for more information: www.savourdeals.com"
            self.address = "300 Washington Ave SE, Minneapolis, MN 55455"
            self.location = locationManager.location
            self.distanceMiles = 2.0
            self.menu = "https://www.savourdeals.com/"
            self.subscriptionId = "1234567"
            self.dailyHours.append("9:00 AM - 5:00 PM")
            self.dailyHours.append("9:00 AM - 5:00 PM")
            self.dailyHours.append("9:00 AM - 5:00 PM")
            self.dailyHours.append("9:00 AM - 5:00 PM")
            self.dailyHours.append("9:00 AM - 5:00 PM")
            self.dailyHours.append("9:00 AM - 5:00 PM")
            self.dailyHours.append("9:00 AM - 5:00 PM")
            self.loyalty = loyaltyStruct()
        }
    }
    
    func updateDistance(){
        if self.id != "SVRDEALS"{
            if let _ = self.location,let _ = locationManager.location{
                self.distanceMiles = (self.location?.distance(from: locationManager.location!))!/1609
            }else{
                print("Could not update distance. Vendor or location manager not present")
            }
        }

    }
    
}
