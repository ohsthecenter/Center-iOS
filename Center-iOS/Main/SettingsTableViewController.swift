//
//  SettingsTableViewController.swift
//  Center-iOS
//
//  Created by Apollo Zhu on 8/26/18.
//  Copyright © 2018 OHS The Center. All rights reserved.
//

import UIKit

class SettingsTableViewController: UITableViewController {
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        if segue.identifier == "logout" {
            signOut()
        }
    }
}
