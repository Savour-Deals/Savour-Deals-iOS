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



@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, OSSubscriptionObserver {

    var handle: AuthStateDidChangeListenerHandle?

    var window: UIWindow?
    var ref: DatabaseReference!


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        let notificationOpenedBlock: OSHandleNotificationActionBlock = { result in
            let payload: OSNotificationPayload = result!.notification.payload
            
            print("Payload contains all of properties in notif is : " , payload)
            print("Payload additionalData : " , payload.additionalData)
            let dict = payload.additionalData! as! Dictionary<String, String>
            notificationDeal = dict["deal"]!
        }
        let onesignalInitSettings = [kOSSettingsKeyAutoPrompt: false]
        
        // Replace 'YOUR_APP_ID' with your OneSignal App ID.
        OneSignal.initWithLaunchOptions(launchOptions,
                                        appId: "f1c64902-ab03-4674-95e9-440f7c8f33d0",
                                        handleNotificationAction: notificationOpenedBlock,
                                        settings: onesignalInitSettings)
        
        OneSignal.inFocusDisplayType = OSNotificationDisplayType.notification;
        OneSignal.add(self as OSSubscriptionObserver)

        
        
        
        // Sync hashed email if you have a login system or collect it.
        //   Will be used to reach the user at the most optimal time of day.
        // OneSignal.syncHashedEmail(userEmail)
        FirebaseApp.configure()
        FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
        //Database.database().isPersistenceEnabled = true
        UINavigationBar.appearance().barStyle = .blackOpaque

        //Setup Searchbar UI
        UISearchBar.appearance().barTintColor = #colorLiteral(red: 0.2848863602, green: 0.6698332429, blue: 0.6656947136, alpha: 1)
        //UISearchBar.appearance().tintColor = .white
        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).tintColor = #colorLiteral(red: 0.2848863602, green: 0.6698332429, blue: 0.6656947136, alpha: 1)
        handle = Auth.auth().addStateDidChangeListener { (auth, user) in}
        if Auth.auth().currentUser != nil {
            // User is signed in.
            let user = Auth.auth().currentUser
            self.ref = Database.database().reference()
            self.ref.child("Users").child((user?.uid)!).child("type").observeSingleEvent(of: .value, with: { (snapshot) in
                // Get user value
                let type = snapshot.value as? String ?? ""
                if type == "Vendor"{
                    let storyboard = UIStoryboard(name: "VendorHome", bundle: nil)
                    let VenVC = storyboard.instantiateViewController(withIdentifier: "VenNav") as! UINavigationController
                    self.window!.rootViewController = VenVC
                }
                else{
                    let storyboard = UIStoryboard(name: "Main", bundle: nil)
                    let tabVC = storyboard.instantiateViewController(withIdentifier: "tabMain") as! UITabBarController
                    tabVC.selectedIndex = 0
                    self.window!.rootViewController = tabVC
                }
            })
        
        }
        else {
            let storyboard = UIStoryboard(name: "Onboarding", bundle: nil)
            let OnboardVC = storyboard.instantiateViewController(withIdentifier: "OnNav") as! UINavigationController
            self.window!.rootViewController = OnboardVC

        }
        UIApplication.shared.isStatusBarHidden = false
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
 
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.        
    }
   
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        let handled = FBSDKApplicationDelegate.sharedInstance().application(app, open: url, sourceApplication: options[UIApplicationOpenURLOptionsKey.sourceApplication] as! String!, annotation: options[UIApplicationOpenURLOptionsKey.annotation])
        
        return handled
    }
    
    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        //App entered through Forcetouch quick action
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let tabVC = storyboard.instantiateViewController(withIdentifier: "tabMain") as! UITabBarController
        
        switch (shortcutItem.localizedTitle){
        case "Favorites" :
            //Favorites was selected
            tabVC.selectedIndex = 1
            self.window!.rootViewController = tabVC
        default:
            break
    }
    completionHandler(true)
}
    
    // After you add the observer on didFinishLaunching, this method will be called when the notification subscription property changes.
    func onOSSubscriptionChanged(_ stateChanges: OSSubscriptionStateChanges!) {
        if !stateChanges.from.subscribed && stateChanges.to.subscribed {
            signalID = " "
            print("Subscribed for OneSignal push notifications!")
        }
        print("SubscriptionStateChange: \n\(stateChanges)")
        
        //The player id is inside stateChanges. But be careful, this value can be nil if the user has not granted you permission to send notifications.
        if let playerId = stateChanges.to.userId {
            signalID = playerId
            print("Current playerId \(playerId)")
        }
    }
    
    


}

