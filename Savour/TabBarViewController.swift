//
//  TabBarViewController.swift
//  Savour
//
//  Created by Chris Patterson on 11/10/17.
//  Copyright © 2017 Chris Patterson. All rights reserved.
//

import UIKit
import CoreLocation

class TabBarViewController: UITabBarController, UITabBarControllerDelegate,CLLocationManagerDelegate {
    
    var deals: DealsData!
    var vendors: VendorsData!
    var finishedSetup = false
    var locationManager: CLLocationManager!
    var radius = 80.5 //50 miles

    override func viewDidLoad() {
        super.viewDidLoad()
        self.locationManager = CLLocationManager()
        self.locationManager.delegate = self
        self.locationManager.distanceFilter = 1600//about a mile
        self.locationManager.startUpdatingLocation()
        self.delegate = self
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let firstTab = self.viewControllers![0] as! UINavigationController
        let firstView = firstTab.viewControllers.first as! ViewController
        let secondTab = self.viewControllers![1] as! UINavigationController
        let secondView = secondTab.viewControllers.first as! FavoritesViewController
        let thirdTab = self.viewControllers![2] as! UINavigationController
        let thirdView = thirdTab.viewControllers.first as! VendorMapViewController
        if deals != nil{
            self.deals.updateLocation(location: locationManager.location!)
            firstView.dealsData = self.deals
            secondView.dealsData = self.deals
            thirdView.dealsData = self.deals
        }
        if vendors != nil{
            self.vendors.updateLocation(location: locationManager.location!)
            firstView.vendorsData = self.vendors
            secondView.vendorsData = self.vendors
            thirdView.vendorsData = self.vendors
        }
    }

    
    func dealSetup(completion: @escaping (Bool) -> Void){
        let firstTab = self.viewControllers![0] as! UINavigationController
        let firstView = firstTab.viewControllers.first  as! ViewController
        let secondTab = self.viewControllers![1] as! UINavigationController
        let secondView = secondTab.viewControllers.first  as! FavoritesViewController
        let thirdTab = self.viewControllers![2] as! UINavigationController
        let thirdView = thirdTab.viewControllers.first  as! VendorMapViewController
        if deals != nil && vendors != nil{
            firstView.dealsData = self.deals
            secondView.dealsData = self.deals
            thirdView.dealsData = self.deals
            firstView.vendorsData = self.vendors
            secondView.vendorsData = self.vendors
            thirdView.vendorsData = self.vendors
            self.finishedSetup = true
            completion(true)
        }else{
            self.deals = DealsData(completion: { (success) in
                self.vendors = VendorsData(completion: { (succ) in
                    firstView.dealsData = self.deals
                    secondView.dealsData = self.deals
                    thirdView.dealsData = self.deals
                    firstView.vendorsData = self.vendors
                    secondView.vendorsData = self.vendors
                    thirdView.vendorsData = self.vendors
                    self.finishedSetup = true
                    completion(true)
                })
            })
        }
    }
    
    public func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool{
        let fromView: UIView = tabBarController.selectedViewController!.view
        let toView  : UIView = viewController.view
        if fromView == toView {
            return false
        }
        
        UIView.transition(from: fromView, to: toView, duration: 0.1, options: UIView.AnimationOptions.transitionCrossDissolve) { (finished:Bool) in
            
        }
        return true
    }
}
