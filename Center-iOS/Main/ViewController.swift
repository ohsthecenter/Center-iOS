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

class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        GIDSignIn.sharedInstance()?.delegate = self
        GIDSignIn.sharedInstance()?.uiDelegate = self
        navigateAccordingly()
    }

    private func navigateAccordingly() {
        switch accountType {
        case nil: return
        case .center?: performSegue(withIdentifier: "center", sender: nil)
        case .tutor?: performSegue(withIdentifier: "tutor", sender: nil)
        case .teacher?: performSegue(withIdentifier: "teacher", sender: nil)
        }
    }
}

extension ViewController: GIDSignInDelegate, GIDSignInUIDelegate {
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!,
              withError error: Error!) {
        showHUD(.labeledProgress(title: "Verifying", subtitle: nil))
        guard let email = user?.profile?.email
            , let auth = user?.authentication
            else {
                flashHUD(.labeledError(title:
                    error?.localizedDescription ?? "Not signed in", subtitle: nil)
                )
                return signOut()
        }
        guard email.emailToAccountType != nil else {
            flashHUD(.labeledError(title: "Not FCPS Account", subtitle: nil))
            return signOut()
        }
        let credential = GoogleAuthProvider.credential(
            withIDToken: auth.idToken, accessToken: auth.accessToken
        )
        Auth.auth().signInAndRetrieveData(with: credential)
        { [weak self] _, error in
            if let error = error {
                flashHUD(.labeledError(
                    title: "Can't sign in",
                    subtitle: error.localizedDescription)
                )
                return signOut()
            } else {
                self?.register()
            }
        }
    }

    private func register() {
        guard let type = accountType
            , let username = identifier
            , let uid = Auth.auth().currentUser?.uid
            else { fatalError("Registering but not logged in") }
        showHUD(.labeledProgress(title: "Updating", subtitle: nil))
        let collectionID: String
        switch type {
        case .center: return
        case .tutor: collectionID = "students"
        case .teacher: collectionID = "teachers"
        }
        let doc = db.collection(collectionID).document(username)
        db.collection("uid").document(uid).setData(["ref": doc, "id": username])
        doc.setData(["uid": uid], merge: true) { [weak self] in
            if let error = $0 {
                flashHUD(.labeledError(
                    title: "Please try again",
                    subtitle: error.localizedDescription)
                )
                logError("Can't associated account uid")
                signOut()
            } else {
                flashHUD(.success)
                self?.navigateAccordingly()
            }
        }
    }
}
