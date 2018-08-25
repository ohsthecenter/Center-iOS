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

func signOut() {
    try? Auth.auth().signOut()
    GIDSignIn.sharedInstance()?.signOut()
}

class ViewController: UIViewController, GIDSignInDelegate, GIDSignInUIDelegate {
    override func viewDidLoad() {
        super.viewDidLoad()
//        signOut()
        GIDSignIn.sharedInstance()?.delegate = self
        GIDSignIn.sharedInstance()?.uiDelegate = self
        navigateAccordingly()
    }

    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        guard let email = user?.profile?.email
            , let auth = user?.authentication
            else {
                signOut()
                return print(error?.localizedDescription ?? "Failed")
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
        Auth.auth().signInAndRetrieveData(with: credential)
        { [weak self] _, error in
            if let error = error {
                signOut()
                print(error.localizedDescription)
            } else { self?.navigateAccordingly() }
        }
    }

    private func navigateAccordingly() {
        guard let email = email else { return }
        if email == centerEmail {
            performSegue(withIdentifier: "center", sender: nil)
        } else if email.hasSuffix("fcps.edu") {
            performSegue(withIdentifier: "teacher", sender: nil)
        } else if email.hasSuffix("fcpsschools.net") {
            performSegue(withIdentifier: "tutor", sender: nil)
        }
    }
}
