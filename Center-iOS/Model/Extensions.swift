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

enum AccountType {
    case center, tutor, teacher
}

extension String {
    var emailToAccount: String? {
        if let id = split(separator: "@").first {
            return "\(id)"
        } else { return nil }
    }

    var emailToAccountType: AccountType? {
        if self == centerEmail {
            return .center
        } else if hasSuffix("@fcps.edu") {
            return .teacher
        } else if hasSuffix("@fcpsschools.net") && Int(emailToAccount!) != nil {
            return .tutor
        }
        return nil
    }
}

var identifier: String? {
    return email?.emailToAccount
}

var accountType: AccountType? {
    return email?.emailToAccountType
}

import GoogleSignIn

func signOut() {
    do {
        try Auth.auth().signOut()
    } catch {
        logError(error.localizedDescription)
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

func logError(_ why: String) {
    print("ERROR: \(why)")
}
