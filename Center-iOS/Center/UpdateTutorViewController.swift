//
//  UpdateTutorViewController.swift
//  Center-iOS
//
//  Created by Apollo Zhu on 8/25/18.
//  Copyright © 2018 OHS The Center. All rights reserved.
//

import UIKit
import Eureka
import Firebase
import PKHUD

class UpdateTutorViewController: FormViewController {
    public var id: Int = 0 {
        didSet {
            guard id != oldValue else { return }
            fillPlaceholderWithID()
        }
    }

    private lazy var idRow = IntRow("id") {
        $0.title = "Student ID"
        $0.formatter = nil
        }.onChange { [weak self] in
            self?.id = $0.value ?? self?.id ?? 0
    }

    private lazy var firstNameRow = NameRow("first") { $0.title = "First Name" }
    private lazy var lastNameRow = NameRow("last") { $0.title = "Last Name" }
    private lazy var roleRow = SegmentedRow("role") {
        $0.options = Tutor.Role.allCases.map { $0.rawValue }
    }
    private lazy var emailRow = EmailRow("email") { $0.title = "Email" }
    private lazy var subjectsRow = MultipleSelectorRow<String>("subjects") {
        $0.title = "Pick all subjects comfortable tutoring"
        $0.selectorTitle = "Subjects Tutoring"
        $0.options = []
        $0.value = []
    }

    private var isValid: Bool {
        return idRow.value != nil && idRow.value! > 0
            && (emailRow.value?.isEmpty != false
                || emailRow.value!.contains("@")
                && !emailRow.value!.hasSuffix("fcpsschools.net"))
    }

    private lazy var submitButton = ButtonRow() {
        $0.title = "Submit"
        $0.disabled = Condition.function(["id", "first", "last", "role", "email"])
        { [weak self] _ in self?.isValid != true }
        }.onCellSelection { [weak self] _, _ in self?.submit() }

    override func viewDidLoad() {
        super.viewDidLoad()
        form +++ Section()
            <<< idRow
            <<< firstNameRow
            <<< lastNameRow
            <<< roleRow
            <<< emailRow
            <<< subjectsRow
            +++ submitButton
        fetchAllSubjects()
        fillPlaceholderWithID()
    }

    // MARK: Retrieve Info

    private func fetchAllSubjects() {
        showHUD(.labeledProgress(title: "Loading course list", subtitle: nil))
        Subject.fetchAllFromFirebase { [weak self] (list, error) in
            guard let list = list else {
                return flashHUD(.labeledError(
                    title: "Can't load courses",
                    subtitle: error?.localizedDescription)
                )
            }
            let subjects = list.flatMap { $0.value } .map { $0.shortName }
            self?.subjectsRow.options = Set(subjects).sorted()
            DispatchQueue.main.async {
                self?.subjectsRow.reload()
                HUD.hide()
            }
        }
    }

    private func placehold<T>(_ row: FieldRow<T>, with placeholder: Any?) {
        guard let string = placeholder as? String else { return }
        row.placeholder = string
        guard row.value == nil else { return }
        row.reload()
    }

    private func placeholdRole(_ role: Any?) {
        guard roleRow.value == nil, let role = role as? String else { return }
        roleRow.value = Tutor.Role.map[role]
        roleRow.reload()
    }

    private func placeholdSubjects(_ subjects: Any?) {
        guard subjectsRow.value == nil
            , let value = subjects as? [String]
            else { return }
        subjectsRow.value = Set(value)
        subjectsRow.reload()
    }

    private func fillPlaceholderWithID() {
        guard id > 0 else { return }
        db.collection("students").document("\(id)").getDocument { [weak self] (snapshot, _) in
            guard let self = self, let data = snapshot?.data() else { return }
            self.placehold(self.firstNameRow, with: data["first_name"])
            self.placehold(self.lastNameRow, with: data["last_name"])
            self.placehold(self.emailRow, with: data["email"])
            self.placeholdRole(data["role"])
            self.placeholdSubjects(data["subjects"])
        }
    }

    // MARK: Update Server

    private func submit() {
        var data: [String: String?] = [
            "email": emailRow.value,
            "first_name": firstNameRow.value,
            "last_name": lastNameRow.value
        ]
        data["role"] = Tutor.Role.map[roleRow.value]
        let id = "\(idRow.value!)"
        var nonNil = data.filter { $0.value != nil } as [String : Any]
        if let subjects = subjectsRow.value {
            nonNil["subjects"] = Array(subjects)
        }
        let merge = Array(nonNil.keys)
        nonNil["total_scheduled"] = 0
        // Update old if needed
        db.collection("students").document(id).getDocument { [weak self] (snapshot, _) in
            if let tmp = data["role"], let newRole = tmp {
                if let oldRole = snapshot?.data()?["role"] as? String,
                    oldRole != newRole {
                    db.collection("schedules").document("tutors")
                        .collection(oldRole).document(id).delete()
                }
                db.collection("schedules").document("tutors")
                    .collection(newRole).document(id).setData([:])
            }
            // Insert New
            db.collection("students").document(id).setData(nonNil, mergeFields: merge)
            self?.navigationController?.popViewController(animated: true)
        }
    }
}
