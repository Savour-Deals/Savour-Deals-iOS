//
//  AppDelegate.swift
//  Savour
//
//  Created by Chris Patterson on 7/30/17.
//  Copyright © 2017 Chris Patterson. All rights reserved.
//

import UIKit
import Firebase
import FBSDKCoreKit
import OneSignal
import CoreLocation
import UserNotifications


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, OSSubscriptionObserver {
    var handle: AuthStateDidChangeListenerHandle?
    var window: UIWindow?
    var ref: DatabaseReference!
    var locationManager: CLLocationManager?
    var nearbyCount = 0
    var monitoredRegions = [VendorData]()
    var vendors = [VendorData]()
    var entered = [CLCircularRegion]()
    var vendorsData: VendorsData!
    var canSendNoti = true
    var locationUpdatesActive = false

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        
        let notificationOpenedBlock: OSHandleNotificationActionBlock = { result in
            let payload: OSNotificationPayload = result!.notification.payload
            print("Payload contains all of properties in notif is : " , payload)
            if let additionalData = payload.additionalData{
                print("Payload additionalData : " , payload.additionalData)
                let dict = additionalData as! Dictionary<String, String>
                if let payloadDeal = dict["deal"]{
                    notificationDeal = payloadDeal
                    NotificationCenter.default.post(name: .NotificationDealIsAvailable, object: nil)
                }
            }
        }
        let onesignalInitSettings = [kOSSettingsKeyAutoPrompt: false]
        
        OneSignal.initWithLaunchOptions(launchOptions,
                                        appId: "f1c64902-ab03-4674-95e9-440f7c8f33d0",//"1038c26b-d1cf-4311-b616-d9fb8f9719e5",
                                        handleNotificationAction: notificationOpenedBlock,
                                        settings: onesignalInitSettings)
        
        OneSignal.inFocusDisplayType = OSNotificationDisplayType.notification;
        OneSignal.add(self as OSSubscriptionObserver)
        
        // Sync hashed email if you have a login system or collect it.
        //   Will be used to reach the user at the most optimal time of day.
        // OneSignal.syncHashedEmail(userEmail)
        FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
        UINavigationBar.appearance().barStyle = .blackOpaque
        UINavigationBar.appearance().barStyle = .blackOpaque
        
        if #available(iOS 10.0, *) {
            let center = UNUserNotificationCenter.current()
            center.delegate = self
        }//if not ios >=10, dont worry. just wont put user in vendors tab
        
        if launchOptions?[UIApplication.LaunchOptionsKey.location] != nil {
            vendorsData = VendorsData(radiusMiles: 20)
            vendorsData.startVendorUpdates(completion: { (success) in
                if success{
                    self.vendors = self.vendorsData.getVendors()
                }else{
                    //error getting vendors
                }
            })
            self.locationManager?.delegate = self
            locationManager?.startUpdatingLocation()
        } else {
            vendorsData = VendorsData(radiusMiles: 20)
            vendorsData.startVendorUpdates(completion: { (success) in
                if success{
                    self.locationUpdatesActive = true
                    self.vendors = self.vendorsData.getVendors()
                }else{
                    //we could not get user's location to start up geoFire. Can try again later
                    self.locationUpdatesActive = false
                }
            })
            self.locationManager = CLLocationManager()
            self.locationManager!.delegate = self
            if locationManager?.location != nil{
                locationManager?.startUpdatingLocation()
            }
           
            if isUserVerified(user: Auth.auth().currentUser){
                // User is signed in and verified.
                if let tabVC = self.window!.rootViewController as? UITabBarController{
                    tabVC.selectedIndex = 0
                }else{
                    let storyboard = UIStoryboard(name: "Main", bundle: nil)
                    let tabVC = storyboard.instantiateViewController(withIdentifier: "tabMain") as! UITabBarController
                    tabVC.selectedIndex = 0
                    self.window!.rootViewController = tabVC
                }
            }else{
                let storyboard = UIStoryboard(name: "Onboarding", bundle: nil)
                let OnboardVC = storyboard.instantiateViewController(withIdentifier: "OnNav") as! UINavigationController
                self.window!.rootViewController = OnboardVC
            }
        }
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
 
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        if isUserVerified(user: Auth.auth().currentUser){
            // User is signed in and verified.
            if let tabVC = self.window!.rootViewController as? UITabBarController{
                self.window!.rootViewController = tabVC
            }else{
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let tabVC = storyboard.instantiateViewController(withIdentifier: "tabMain") as! UITabBarController
                tabVC.selectedIndex = 0
                self.window!.rootViewController = tabVC
            }
        }else{
            let storyboard = UIStoryboard(name: "Onboarding", bundle: nil)
            let OnboardVC = storyboard.instantiateViewController(withIdentifier: "OnNav") as! UINavigationController
            self.window!.rootViewController = OnboardVC
        }
        
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.        
    }
   
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        let handled = FBSDKApplicationDelegate.sharedInstance().application(app, open: url, sourceApplication: options[UIApplication.OpenURLOptionsKey.sourceApplication] as! String?, annotation: options[UIApplication.OpenURLOptionsKey.annotation])
        return handled
    }
    
    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        //App entered through Forcetouch quick action
        if isUserVerified(user: Auth.auth().currentUser){
            // User is signed in and verified.
            var tabVC: UITabBarController?
            if let _ = self.window!.rootViewController as? UITabBarController{
                //Tabview already instantiated
                tabVC = self.window!.rootViewController as? UITabBarController
            }else{
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                tabVC = storyboard.instantiateViewController(withIdentifier: "tabMain") as? UITabBarController
            }
            
            switch (shortcutItem.localizedTitle){
            case "Favorites" :
                //Favorites was selected
                tabVC?.selectedIndex = 1
                self.window!.rootViewController = tabVC
            default:
                break
            }
            completionHandler(true)
        }else{
            let storyboard = UIStoryboard(name: "Onboarding", bundle: nil)
            let OnboardVC = storyboard.instantiateViewController(withIdentifier: "OnNav") as! UINavigationController
            self.window!.rootViewController = OnboardVC
        }

        
        
    }
    
    // After you add the observer on didFinishLaunching, this method will be called when the notification subscription property changes.
    func onOSSubscriptionChanged(_ stateChanges: OSSubscriptionStateChanges!) {
        if !stateChanges.from.subscribed && stateChanges.to.subscribed {
            signalID = " "
            print("Subscribed for OneSignal push notifications!")
        }
        print("SubscriptionStateChange: \n\(String(describing: stateChanges))")
        
        //The player id is inside stateChanges. But be careful, this value can be nil if the user has not granted you permission to send notifications.
        if let playerId = stateChanges.to.userId {
            signalID = playerId
            print("Current playerId \(playerId)")
        }
    }
}

extension AppDelegate: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if locationUpdatesActive{
            updateNearbyVendors()
        }else{
            vendorsData.startVendorUpdates(completion: { (success) in
                self.locationUpdatesActive = true
                self.updateNearbyVendors()
            })
        }
        
    }
    
    func updateNearbyVendors(){
        vendorsData.updateLocation(location: (locationManager?.location)!)
        vendors = self.vendorsData.getVendors()
        if vendors.count > 0{
            vendorsData.updateDistances(location: (locationManager?.location)!)
            var rest = vendorsData.getVendors()
            rest = rest.sorted(by:{ (d1, d2) -> Bool in
                if d1.distanceMiles! <= d2.distanceMiles! {
                    return true
                }else{
                    return false
                }
            })
            var nearby = rest.prefix(20)
            if let _ = nearby[0].distanceMiles{
                if nearby[0].distanceMiles! > 50.0{
                    //update restaurants from firebase for the next pass if the nearest is too far away
                    self.vendors = vendorsData.getVendors()
                }
            }
            for place in monitoredRegions{
                if !nearby.contains(where: { $0 === place }){
                    self.locationManager?.stopMonitoring(for: CLCircularRegion(center: (place.location?.coordinate)!,radius: 100,identifier: place.id!))
                }
            }
            for place in nearby{
                if self.monitoredRegions.count < 20 && !self.monitoredRegions.contains(where: { $0 === place }){
                    //monitor nearest 20 places
                    let geofenceRegionCenter = place.location?.coordinate
                    
                    /* Create a region centered on desired location,
                     choose a radius for the region (in meters)
                     choose a unique identifier for that region */
                    let geofenceRegion = CLCircularRegion(center: geofenceRegionCenter!,radius: 250,identifier: place.id!)
                    geofenceRegion.notifyOnEntry = true
                    geofenceRegion.notifyOnExit = true
                    self.locationManager?.startMonitoring(for: geofenceRegion)
                    self.monitoredRegions.append(place)
                }
            }
        }
    }
    
    // called when user Enters a monitored region
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        if region is CLCircularRegion && !entered.contains(where: {$0===region}){
            nearbyCount = nearbyCount + 1 //Increment if we are in range of a location
            if nearbyCount > 2{
                if self.canSendNoti{
                    self.canSendNoti = false
                    self.handleEvent()
                    locationManager?.stopUpdatingLocation() //Dont update if we dont need it
                    DispatchQueue.main.asyncAfter(deadline: .now() + 86400) {
                        //after they're gone and left, we want to be able to send another notification
                        self.locationManager?.startUpdatingLocation()
                        self.canSendNoti = true
                        self.nearbyCount = 0
                        self.entered.removeAll()
                    }
                }
            }
        }
    }
    
    //called when user exits a monitored region
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
//        nearbyCount = nearbyCount - 1 //decrement if left range of location
    }
    
    func handleEvent() {
        //send notification of nearby restaurants
        let localNotification = UILocalNotification()
        localNotification.timeZone = NSTimeZone.local
        localNotification.soundName = UILocalNotificationDefaultSoundName
        localNotification.category = "Message"
        localNotification.alertBody = "Look at all the current deals nearby!"
        localNotification.alertBody = "\(localNotification.alertBody ?? "") Don't forget to check-in for loyalty points!"
        localNotification.alertTitle = "Woah You're Near Some Hot Deals!"
        localNotification.fireDate = Date()
        localNotification.userInfo = ["info": 2]
        UIApplication.shared.scheduleLocalNotification(localNotification)
    }
}

@available(iOS 10.0, *)
extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void){
        if let info = response.notification.request.content.userInfo["info"]{
            switch info as! Int{
            case 2: //2 = got to Vendor page
                if let tabVC = self.window!.rootViewController as? UITabBarController{
                    tabVC.selectedIndex = 2
                }else{
                    let storyboard = UIStoryboard(name: "Main", bundle: nil)
                    let tabVC = storyboard.instantiateViewController(withIdentifier: "tabMain") as! UITabBarController
                    tabVC.selectedIndex = 2
                    self.window!.rootViewController = tabVC
                }
                break
            default:
                if let tabVC = self.window!.rootViewController as? UITabBarController{
                    tabVC.selectedIndex = 0
                }else{
                    let storyboard = UIStoryboard(name: "Main", bundle: nil)
                    let tabVC = storyboard.instantiateViewController(withIdentifier: "tabMain") as! UITabBarController
                    tabVC.selectedIndex = 0
                    self.window!.rootViewController = tabVC
                }
                break
            }
        }else{
            if let tabVC = self.window!.rootViewController as? UITabBarController{
                tabVC.selectedIndex = 0
            }else{
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let tabVC = storyboard.instantiateViewController(withIdentifier: "tabMain") as! UITabBarController
                tabVC.selectedIndex = 0
                self.window!.rootViewController = tabVC
            }
        }
        completionHandler()
    }
    
    @available(iOS 10.0, *)
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void){
        completionHandler([.alert, .badge, .sound])
    }
}


