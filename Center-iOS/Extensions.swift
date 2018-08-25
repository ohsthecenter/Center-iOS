//
//  Extensions.swift
//  Center-iOS
//
//  Created by Apollo Zhu on 8/25/18.
//  Copyright © 2018 OHS The Center. All rights reserved.
//

import Firebase

let db = Firestore.firestore()

let centerEmail = "ohsthecenter@gmail.com"

var signedIn: Bool {
    return Auth.auth().currentUser != nil
}

var email: String? {
    return Auth.auth().currentUser?.email
}

var identifier: String? {
    if let id = email?.split(separator: "@").first {
        return "\(id)"
    } else { return nil }
}
