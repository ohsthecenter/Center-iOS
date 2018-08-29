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
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "logout" {
            signOut()
        }
    }
}
