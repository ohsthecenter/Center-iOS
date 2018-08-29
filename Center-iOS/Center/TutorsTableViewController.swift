//
//  TutorsTableViewController.swift
//  Center-iOS
//
//  Created by Apollo Zhu on 8/25/18.
//  Copyright © 2018 OHS The Center. All rights reserved.
//

import UIKit

class TutorsTableViewController: UITableViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        reload(useCache: true)
    }
    
    func reload(useCache: Bool = false) {
        showHUD(.labeledProgress(title: "Loading tutor list", subtitle: nil))
        Tutor.fetchAll(useCache: useCache) { [weak self] (list, error) in
            guard let list = list, let self = self else {
                return flashHUD(.labeledError(
                    title: "Can't fetch tutor list",
                    subtitle: error?.localizedDescription)
                )
            }
            flashHUD(.success)
            self.tutorList = list
        }
    }
    
    private var tutorList: TutorList = [:] {
        didSet {
            categorized = Dictionary(grouping: tutorList.values) { $0.role }
                .map { (
                    Tutor.Role.map[$0.key]!,
                    $0.value.sorted { $0.lastName < $1.lastName }
                    )
            }
        }
    }
    
    private var categorized: [(role: String, tutors: [Tutor])] = [] {
        didSet {
            tableView.reloadData()
        }
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return categorized.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return categorized[section].role
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return categorized[section].tutors.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "tutor", for: indexPath)
        let tutor = categorized[indexPath.section].tutors[indexPath.row]
        cell.textLabel?.text = "\(tutor.firstName) \(tutor.lastName)"
        cell.detailTextLabel?.text = tutor.email
        return cell
    }
    
    // MARK: - Navigation
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let tutor = categorized[indexPath.section].tutors[indexPath.row]
        performSegue(withIdentifier: "updateTutorInfo", sender: tutor)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let tutor = sender as? Tutor
            , let vc = segue.destination as? UpdateTutorViewController
            , segue.identifier == "updateTutorInfo"
            else { return }
        vc.id = tutor.id
    }
}
