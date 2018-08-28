//
//  SubjectsTableViewController.swift
//  Center-iOS
//
//  Created by Apollo Zhu on 8/25/18.
//  Copyright © 2018 OHS The Center. All rights reserved.
//

import UIKit
import Foundation
import PKHUD

class SubjectsTableViewController: UITableViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        showHUD(.labeledProgress(title: "Loading Classes", subtitle: nil))
        Subject.fetchAllFromFirebase { [weak self] (list, error) in
            if let list = list, list.count > 0 {
                flashHUD(.success)
                self?.list = list
            } else {
                self?.fetchAllSubjects("")
            }
        }
    }

    @IBAction func fetchAllSubjects(_ sender: Any) {
        showHUD(.labeledProgress(title: "Refetching Classes", subtitle: "This may take a while"))
        Subject.fetchAllFromFCPS { [weak self] (list, error) in
            if let list = list {
                flashHUD(.success)
                self?.list = list
            } else {
                flashHUD(.labeledError(
                    title: "Can't load classes",
                    subtitle: error?.localizedDescription)
                )
            }
        }
    }

    var list: SubjectList = [:] {
        didSet {
            subjects = list.map { ($0.0, $0.1) }
                .sorted { $0.key < $1.key }
        }
    }

    private var subjects: [(key: String, value: [Subject])] = [] {
        didSet {
            tableView.reloadData()
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return subjects.count
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return subjects[section].key
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return subjects[section].value.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "subject", for: indexPath)
        let subject = subjects[indexPath.section].value[indexPath.row]
        cell.textLabel?.text = subject.shortName
        cell.detailTextLabel?.text = "\(subject.id)"
        return cell
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
}
