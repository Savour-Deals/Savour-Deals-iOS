//
//  Globals.swift
//  Savour
//
//  Created by Chris Patterson on 8/13/17.
//  Copyright © 2017 Chris Patterson. All rights reserved.
//

import Foundation
import Firebase



var favorites: [String:DealData] = Dictionary<String, DealData>()
var FavMainIndex: [String:Int] = Dictionary<String, Int>()
var filteredDeals = [DealData]()
var UnfilteredDeals = [DealData]()


class HelperFuncs{
    
    var ref: DatabaseReference!
    var handle: AuthStateDidChangeListenerHandle?
    
    func SaveFavs(){
        let user = Auth.auth().currentUser?.uid
        self.ref = Database.database().reference()
        
        var favs = Dictionary<String, String>()
        for member in favorites{
            favs[member.value.dealID!] = member.value.dealID
        }
        self.ref.child("Users").child(user!).child("Favorites").setValue(favs)
    }
    
    func GetFavs(sender: ViewController) -> Dictionary<String,String> {
        var IDs: [String:String] = Dictionary<String, String>()

        let userid = Auth.auth().currentUser?.uid
        let ref = Database.database().reference()
        ref.child("Users").child(userid!).child("Favorites").observeSingleEvent(of: .value, with: { (snapshot) in
            // Get user value
            for entry in snapshot.children {
                let snap = entry as! DataSnapshot
                let value = snap.key
                IDs[value] = value
            }
            sender.loadData(sender: "favs")
        }){ (error) in
            print(error.localizedDescription)
        }
        return IDs

    }
}
