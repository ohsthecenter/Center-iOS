//
//  UpdateTutorViewController.swift
//  Center-iOS
//
//  Created by Apollo Zhu on 8/25/18.
//  Copyright © 2018 OHS The Center. All rights reserved.
//

import UIKit
import Eureka
import FirebaseFirestore
import PKHUD

class UpdateTutorViewController: FormViewController {
    public var id: Int = 0

    private lazy var idRow = IntRow("id") {
        $0.title = "Student ID"
        $0.formatter = nil
        }.onChange { [weak self] in
            guard let self = self
                , let newValue = $0.value
                , newValue != self.id
                else { return }
            self.id = newValue
            self.fillPlaceholderWithID()
    }

    private lazy var firstNameRow = NameRow("first") { $0.title = "First Name" }
    private lazy var lastNameRow = NameRow("last") { $0.title = "Last Name" }
    private lazy var roleRow = SegmentedRow("role") {
        $0.options = Tutor.Role.allCases.map { $0.description }
    }
    private lazy var emailRow = EmailRow("email") { $0.title = "Email" }
    private var subjectChanged = false
    private lazy var subjectsRow = MultipleSelectorRow<String>("subjects") {
        $0.title = "Pick all subjects comfortable tutoring"
        $0.selectorTitle = "Subjects Tutoring"
        $0.options = []
        $0.value = []
        }.onChange { [weak self] _ in
            self?.subjectChanged = true
    }

    private var isValid: Bool {
        return idRow.value != nil && idRow.value! > 0
            && (firstNameRow.value?.isEmpty == false || firstNameRow.placeholder?.isEmpty == false)
            && (lastNameRow.value?.isEmpty == false || lastNameRow.placeholder?.isEmpty == false)
            && roleRow.value != nil
            && (emailRow.placeholder?.isEmpty == false ||
                emailRow.value?.isEmpty == false && emailRow.value!.contains("@") && !emailRow.value!.hasSuffix("fcpsschools.net"))
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
        if id > 0 {
            idRow.value = id
        }
        fetchAllSubjects()
    }

    // MARK: Retrieve Info

    private func fetchAllSubjects() {
        showHUD(.labeledProgress(title: "Loading course list", subtitle: nil))
        Subject.fetchAllFromFirebase { [weak self] (list, error) in
            guard let list = list, self != nil else {
                flashHUD(.labeledError(
                    title: "Can't load courses",
                    subtitle: error?.localizedDescription)
                )
                return DispatchQueue.main.async { [weak self] in
                    self?.dismiss(animated: true)
                }
            }
            let subjects = list.flatMap { $0.value } .map { $0.shortName }
            self?.subjectsRow.options = Set(subjects).sorted()
            DispatchQueue.main.async { [weak self] in
                self?.subjectsRow.reload()
                self?.fillPlaceholderWithID()
            }
            hideHUD()
        }
    }

    private func placehold<T: _FieldCell<String>>(_ row: FieldRow<T>, with placeholder: String) {
        row.placeholder = placeholder
        /*if row.value == nil || row.value!.isEmpty {
         row.value = placeholder
         }*/
        row.reload()
    }

    private func placeholdRole(_ role: Tutor.Role) {
        guard roleRow.value == nil else { return }
        roleRow.value = Tutor.Role.map[role]
        roleRow.reload()
    }

    private func placeholdSubjects(_ subjects: [String]) {
        if subjectsRow.value == nil || subjectsRow.value!.isEmpty {
            subjectsRow.value = Set(subjects)
            subjectsRow.reload()
            subjectChanged = false
        }
    }

    private var tutor: Tutor? = nil {
        didSet {
            guard let tutor = tutor else { return }
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.placehold(self.firstNameRow, with: tutor.firstName)
                self.placehold(self.lastNameRow, with: tutor.lastName)
                self.placehold(self.emailRow, with: tutor.email)
                self.placeholdRole(tutor.role)
                self.placeholdSubjects(tutor.subjects)
            }
        }
    }

    private func fillPlaceholderWithID() {
        Tutor.ofID(id) { [weak self] (tutor, error) in
            guard let tutor = tutor else { return }
            self?.tutor = tutor
        }
    }

    // MARK: - Update Server

    private func submit() {
        guard isValid else { return }
        showHUD(.labeledProgress(title: "Updating tutor info", subtitle: nil))
        let id = "\(idRow.value!)"
        let document = db.collection("students").document(id)
        func updateExisting() {
            var data: [String: String?] = [
                "email": emailRow.value,
                "firstName": firstNameRow.value,
                "lastName": lastNameRow.value
            ]
            data["role"] = Tutor.Role.map[roleRow.value!]
            var nonNil = data.filter { $0.value != nil } as [String : Any]
            if let subjects = subjectsRow.value, subjectChanged {
                nonNil["subjects"] = Array(subjects)
            }
            document.setData(nonNil, merge: true) { [weak self] error in
                // MARK: Exit
                if let error = error {
                    flashHUD(.labeledError(
                        title: "Can't update tutor info",
                        subtitle: error.localizedDescription)
                    )
                } else {
                    guard let nav = self?.navigationController else {
                        return hideHUD()
                    }
                    #warning("Bad code. Please refactor")
                    (nav.viewControllers.dropLast().last as! TutorsTableViewController).reload()
                    nav.popViewController(animated: true)
                }
            }
        }
        // MARK: Create New
        if tutor == nil {
            let initDict: [String: Any] = [
                "totalScheduled": 0,
                "totalAttended": 0,
                "scheduled": [DocumentReference](),
                "subjects": [String]()
            ]
            document.setData(initDict) { error in
                if let error = error {
                    flashHUD(.labeledError(
                        title: "Can't create tutor",
                        subtitle: error.localizedDescription)
                    )
                } else {
                    updateExisting()
                }
            }
        }
    }
}
