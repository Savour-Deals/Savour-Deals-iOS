//
//  Globals.swift
//  Savour
//
//  Created by Chris Patterson on 8/13/17.
//  Copyright © 2017 Chris Patterson. All rights reserved.
//

import Foundation
import Firebase



var signalID = ""
var notificationDeal = ""

var geoFireRadius = 50.0

func isUserVerified(user: User?) -> Bool{
    if let user = user,let firUser = Auth.auth().currentUser{
        if (firUser.providerData[0].providerID == "facebook.com" ||  user.isEmailVerified){
            return true
        }
    }
    return false
}
