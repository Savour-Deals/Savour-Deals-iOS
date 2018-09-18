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
    var vendors = Dictionary<String,VendorData>()
    private var geoFire: GFCircleQuery!
    private var initialLoaded = false
    
    init(completion: @escaping (Bool) -> Void){
        locationManager.startUpdatingLocation()
        let ref = Database.database().reference().child("Vendors")
        let geofireRef = Database.database().reference().child("Vendors_Location")
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
                    if count == 0 && !self.initialLoaded{
                        self.initialLoaded = true
                        print("Vendors Loaded")
                        completion(true)
                    }
                })
            })
            geoFire.observe(.keyExited, with: { (key: String!, thislocation: CLLocation!) in //50 miles
                self.vendors.removeValue(forKey: key)
            })
            geoFire.observeReady {
                if !self.initialLoaded{
                    print("No vendors found")
                    completion(true)
                }
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
    }
}

func updateDistance(location: CLLocation, vendor: VendorData) -> (VendorData){
    vendor.distanceMiles = (vendor.location?.distance(from: location))!/1609
    return vendor
}
