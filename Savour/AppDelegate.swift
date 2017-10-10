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




@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var handle: AuthStateDidChangeListenerHandle?

    var window: UIWindow?
    var ref: DatabaseReference!


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
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
    
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        //Save Favorites in Firebase
            let user = Auth.auth().currentUser?.uid
            self.ref = Database.database().reference()
            var favs = Dictionary<String, String>()
            for member in favorites{
                favs[member.value.dealID!] = member.value.dealID
            }
        if user != nil{
            self.ref.child("Users").child(user!).child("Favorites").setValue(favs)
        }
        
        
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
        favorites.removeAll()
        
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
    
    
    


}

