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
        reload(useCache: true)
    }
    
    func reload(useCache: Bool = false) {
        showHUD(.labeledProgress(title: "Loading Classes", subtitle: nil))
        Subject.fetchAllFromFirebase(useCache: useCache) { [weak self] (list, error) in
            if let list = list, list.count > 0 {
                flashHUD(.success)
                self?.list = list
            } else {
                self?.refetchAllSubjectsFromFCPS("")
            }
        }
    }
    
    @IBAction private func refetchAllSubjectsFromFCPS(_ sender: Any) {
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
    
    // MARK: - Table view data source
    
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
        let subject = subjects[indexPath.section].value[indexPath.row]
        let fullName = subject.fullName.capitalized
        let identifier = subject.shortName == fullName ? "subjectBasic" : "subjectSubtitle"
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath)
        cell.textLabel?.text = "\(subject.id) - \(subject.shortName)"
        cell.detailTextLabel?.text = fullName
        return cell
    }
}
