//
//  TeachersTableViewController.swift
//  Center-iOS
//
//  Created by Apollo Zhu on 8/27/18.
//  Copyright © 2018 OHS The Center. All rights reserved.
//

import UIKit
import PKHUD

class TeachersTableViewController: UITableViewController, FCPSTeacherFetchDelegate {

    // MARK: - Getting Data

    private let progress = HUDContentType.labeledProgress(
        title: "Loading teacher list", subtitle: nil
    )

    override func viewDidLoad() {
        super.viewDidLoad()
        showHUD(progress)
        fetchFromFirebase(loadFCPSIfEmpty: true)
    }

    @IBAction func reload(_ sender: Any) {
        fetchFromFCPS()
    }

    private func fetchFromFirebase(useCache: Bool = true, loadFCPSIfEmpty: Bool) {
        showHUD(.labeledProgress(
            title: "Loading teacher list",
            subtitle: (useCache ? "We're using cache to save your data" : nil))
        )
        Teacher.fetchAll(useCache: useCache) { [weak self] (list, error) in
            guard let list = list else {
                return flashHUD(.labeledError(
                    title: "Can't load teacher list",
                    subtitle: error?.localizedDescription)
                )
            }
            guard let self = self else { return }
            if list.isEmpty && loadFCPSIfEmpty {
                self.fetchFromFCPS()
            } else {
                flashHUD(.success)
                self.teachersList = list
            }
        }
    }

    private func fetchFromFCPS() {
        showHUD(.labeledProgress(title: "Reloading teacher list from FCPS", subtitle: nil))
        Teacher.delegate = self
        Teacher.fetchAllFromFCPS()
    }

    func onError(_ error: Error?) {
        DispatchQueue.main.async {
            HUD.flash(.labeledError(
                title: "Can't fetch teacher list from FCPS",
                subtitle: error?.localizedDescription
            ), delay: 0) { [weak self] in
                guard $0, let self = self else { return }
                HUD.show(self.progress)
            }
        }
    }

    func onAbort() {
        Teacher.delegate = nil
        hideHUD()
    }

    func onMerging() {
        showHUD(.labeledProgress(title: "Processing teacher list", subtitle: nil))
    }

    func onSuccess() {
        Teacher.delegate = nil
        fetchFromFirebase(loadFCPSIfEmpty: false)
    }

    // MARK: - Table view data source

    private var teachersList: TeacherList = [:] {
        didSet {
            sortedTeachers = Dictionary(grouping: teachersList.values, by: { $0.role })
                .sorted { $0.key < $1.key }
                .map { ($0.key, $0.value.sorted { $0.lastName < $1.lastName }) }
        }
    }

    private var sortedTeachers: [(key: String, value: [Teacher])] = [] {
        didSet {
            tableView.reloadData()
        }
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return sortedTeachers.count
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sortedTeachers[section].key
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sortedTeachers[section].value.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "teacher", for: indexPath)
        // Configure the cell...
        let teacher = sortedTeachers[indexPath.section].value[indexPath.row]
        if let prefix = teacher.prefix {
            cell.textLabel?.text = "\(prefix) \(teacher.firstName) \(teacher.lastName)"
        } else {
            cell.textLabel?.text = "\(teacher.firstName) \(teacher.lastName)"
        }
        cell.detailTextLabel?.text = "\(teacher.id)@fcps.edu"
        return cell
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }

}
