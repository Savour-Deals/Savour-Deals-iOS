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

fileprivate let locationManager = CLLocationManager()

class VendorsData{
    var vendors : Dictionary<String,VendorData> = [:]
    private var geoFire: GFCircleQuery!
    private var initialLoaded = false
    private var radius = 80.5 //50 miles
    
    init(completion: @escaping (Bool) -> Void){
        locationManager.startUpdatingLocation()
        let ref = Database.database().reference().child("Vendors")
        let geofireRef = Database.database().reference().child("Vendors_Location")
        if let location = locationManager.location{
            geoFire = GeoFire(firebaseRef: geofireRef).query(at: locationManager.location!, withRadius: radius)
            geoFire.observe(.keyEntered, with: { (key: String!, thislocation: CLLocation!) in
                ref.queryOrderedByKey().queryEqual(toValue: key).observe(.value, with: { (snapshot) in
                    for child in snapshot.children{
                        let snap = child as! DataSnapshot
                        self.vendors[key] = VendorData(snap: snap, ID: key, location: thislocation, myLocation: location)
                        completion(true)
                    }
                    self.initialLoaded = true
                })
            })
            geoFire.observe(.keyExited, with: { (key: String!, thislocation: CLLocation!) in
                self.vendors.removeValue(forKey: key)
                completion(true)
            })
            geoFire.observeReady {
//                if !self.initialLoaded{
//                    print("No vendors found")
//                    completion(true)
//                }
            }
        }else{
            //could not get location!!
            print("Vendors Failed to load. Location error!")
            completion(false)
        }
    }
    
    func updateLocation(location: CLLocation){
        if let _ = geoFire{
            self.geoFire.center = location
        }
    }
    
    func updateRadius(rad: Double){
        radius = rad*1.60934//to km
        if let _ = geoFire{
            self.geoFire.radius = self.radius
        }
    }
    
    func getVendors() -> [VendorData]{
        if self.vendors.count != 0 {
            return Array(vendors.values)
        }
        let temp = VendorData(ID: "SVRDEALS")
        return [temp]
    }
    
    func getVendorsByID(id: String) -> (VendorData?){
        if id == "SVRDEALS"{
            return VendorData(ID: "SVRDEALS")
        }

        if let _ = vendors[id]{
            return vendors[id]!
        }
        //If here, could not find vendor. Do something for this issue
        return VendorData(ID: "")
    }
    
    func updateDistances(location: CLLocation){
        for vendor in vendors{
            if vendor.value.id != "SVRDEALS"{
                vendor.value.distanceMiles = (vendor.value.location?.distance(from: location))!/1609
            }
        }
    }
}

func updateDistance(location: CLLocation, vendor: VendorData) -> (VendorData){
    if vendor.id != "SVRDEALS"{
        vendor.distanceMiles = (vendor.location?.distance(from: location))!/1609
        return vendor
    }
    return vendor
}
