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
    private var vendors : Dictionary<String,VendorData> = [:]
    private let geofireRef = Database.database().reference().child("Vendors_Location")
    private let vendorRef = Database.database().reference().child("Vendors")
    private var geoFire: GFCircleQuery!
    private var initialLoaded = false
    private var radius: Double
    
    init(radiusMiles: Double = 80.5){
        self.radius = radiusMiles*1.60934//to km
        locationManager.startUpdatingLocation()
//        while (locationManager.location == nil){//wait until location is available
//        }//even if the location is old, dont worry, we will update later when tabbar location update is called
        if let location = locationManager.location {
            self.geoFire = GeoFire(firebaseRef: geofireRef).query(at: location, withRadius: radius)
        }
    }
    
    func startVendorUpdates(completion: @escaping (Bool) -> Void){
        if let location = locationManager.location {
            self.geoFire = GeoFire(firebaseRef: geofireRef).query(at: location, withRadius: radius)
            geoFire.observe(.keyEntered, with: { (key: String!, thislocation: CLLocation!) in
                self.vendorRef.queryOrderedByKey().queryEqual(toValue: key).observe(.value, with: { (snapshot) in
                    for child in snapshot.children{
                        let snap = child as! DataSnapshot
                        if let location = locationManager.location{
                            self.vendors[key] = VendorData(snap: snap, ID: key, location: thislocation, myLocation: location)
                        }
                        self.initialLoaded = true
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
            }
        }else{
            //no location yet
            completion(false)
        }
    }

    func isComplete() -> Bool{
        if initialLoaded{
            return true
        }
        return false
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
