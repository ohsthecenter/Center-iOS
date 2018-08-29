//
//  Extensions.swift
//  Center-iOS
//
//  Created by Apollo Zhu on 8/25/18.
//  Copyright © 2018 OHS The Center. All rights reserved.
//

let centerEmail = "ohsthecenter@gmail.com"

import FirebaseFirestore

let db = Firestore.firestore()

import Firebase

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

import GoogleSignIn

func signOut() {
    do {
        try Auth.auth().signOut()
    } catch {
        print(error.localizedDescription)
    }
    GIDSignIn.sharedInstance()?.signOut()
}

import PKHUD

func showHUD(_ type: HUDContentType) {
    DispatchQueue.main.async {
        HUD.show(type)
    }
}

func flashHUD(_ type: HUDContentType) {
    DispatchQueue.main.async {
        HUD.flash(type)
    }
}

func hideHUD() {
    DispatchQueue.main.async {
        HUD.hide()
    }
}
