//
//  ViewController.swift
//  Center-iOS
//
//  Created by Apollo Zhu on 8/25/18.
//  Copyright © 2018 OHS The Center. All rights reserved.
//

import UIKit
import Firebase
import GoogleSignIn

let centerEmail = "ohsthecenter@gmail.com"

func signOut() {
    try? Auth.auth().signOut()
    GIDSignIn.sharedInstance()?.signOut()
}

class ViewController: UIViewController, GIDSignInDelegate, GIDSignInUIDelegate {
    override func viewDidLoad() {
        super.viewDidLoad()
        GIDSignIn.sharedInstance()?.delegate = self
        GIDSignIn.sharedInstance()?.uiDelegate = self
        GIDSignIn.sharedInstance()?.signInSilently()
    }

    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        guard let email = user?.profile?.email
            , let auth = user?.authentication
            else {
                signOut()
                return print("Failed: \(error?.localizedDescription ?? "???")")
        }
        guard email == centerEmail
            || email.hasSuffix("fcps.edu")
            || email.hasSuffix("fcpsschools.net")
            else {
                signOut()
                return print("Ineligible account")
        }
        print(email)
        let credential = GoogleAuthProvider.credential(
            withIDToken: auth.idToken, accessToken: auth.accessToken
        )
        Auth.auth().signInAndRetrieveData(with: credential) { result, error in
            if let error = error {
                signOut()
                print(error.localizedDescription)
            } else { return }
        }
    }
}
