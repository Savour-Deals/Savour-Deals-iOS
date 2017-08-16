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
import FirebaseDatabase
import FirebaseStorage
import FirebaseStorageUI



@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    let path = Bundle.main.path(forResource: "FavoritesFile", ofType: "plist")
    var ref: DatabaseReference!


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
        let directories = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true) as Array
        let rootPath = directories[0] as String
        let plistPath = rootPath.appending("/FavoritesFile.plist")
        if let IDs = NSDictionary(contentsOfFile: plistPath) {
            self.ref = Database.database().reference()
            for member in IDs{
                let id = member.value as! String
                ref.child("Deals").child(id).observeSingleEvent(of: .value, with: { (snapshot) in
                    // Get user value
                        let snap = snapshot
                        let temp = DealData(snap: snap) // convert my snapshot into my type
                        favorites[temp.dealID!] = temp
                
                    
                }) { (error) in
                    print(error.localizedDescription)
                }

            }
        }
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
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
        
            
        
            let directories = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true) as Array
            let rootPath = directories[0] as String
            let plistPath = rootPath.appending("/FavoritesFile.plist")
            let filemanager = FileManager.default
            
            if (!filemanager.fileExists(atPath: plistPath)){
                do{
                    try filemanager.copyItem(atPath: path!, toPath: plistPath)
                }
                catch{
                    print("Copy Failure")
                }
            }
            else{
                do{
                    try filemanager.removeItem(atPath: plistPath)
                    try filemanager.copyItem(atPath: path!, toPath: plistPath)
                }
                catch{
                    print("Failed to delete and recreate plist")
                }
                
            }
        if (!favorites.isEmpty){
            let Dict = NSMutableDictionary()
            for deal in favorites{
                Dict.setValue(deal.value.dealID!, forKey: deal.value.dealID!)
            }
            if(Dict.write(toFile: plistPath, atomically: true)){
                print("success")
            }
            else{
                print("failed")
            }
        }
    }
   
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        let handled = FBSDKApplicationDelegate.sharedInstance().application(app, open: url, sourceApplication: options[UIApplicationOpenURLOptionsKey.sourceApplication] as! String!, annotation: options[UIApplicationOpenURLOptionsKey.annotation])
        
        return handled
    }
    
    
    


}

