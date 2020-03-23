//
//  GlobalUser.swift
//  InvenTree
//
//  Created by Nirbhay Singh on 21/02/20.
//  Copyright © 2020 Nirbhay Singh. All rights reserved.
//

import Foundation

class GlobalUser {
    var name:String!
    var email:String!
    var photoUrl:String!
    var treesPlanted:Int!
    var givenName:String!
    init(name:String,email:String,photoUrl:String,treesPlanted:Int,givenName:String) {
        self.name = name
        self.email = email
        self.photoUrl = photoUrl
        self.treesPlanted = treesPlanted
        self.givenName = givenName
    }
}
