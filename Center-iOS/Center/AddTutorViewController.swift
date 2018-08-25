//
//  AddTutorViewController.swift
//  Center-iOS
//
//  Created by Apollo Zhu on 8/25/18.
//  Copyright © 2018 OHS The Center. All rights reserved.
//

import UIKit
import Eureka
import Firebase

enum TutorType: String, CaseIterable {
    case center = "Center Tutor"
    case travel = "Travel Tutor"
    case p2p = "P2P Only"
}

class AddTutorViewController: FormViewController {
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
        $0.options = TutorType.allCases.map { $0.rawValue }
    }
    private lazy var emailRow = EmailRow("email") { $0.title = "Email" }

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
            +++ submitButton
        fillPlaceholderWithID()
    }

    private func placehold<T>(_ row: FieldRow<T>, with placeholder: Any?) {
        guard let string = placeholder as? String else { return }
        row.placeholder = string
        guard row.value == nil else { return }
        row.reload()
    }

    private func fillPlaceholderWithID() {
        guard id > 0 else { return }
        db.collection("students").document("\(id)").getDocument { [weak self] (snapshot, _) in
            guard let self = self, let data = snapshot?.data() else { return }
            self.placehold(self.firstNameRow, with: data["first_name"])
            self.placehold(self.lastNameRow, with: data["last_name"])
            self.placehold(self.emailRow, with: data["email"])
            if self.roleRow.value == nil {
                switch data["role"] as? String {
                case "center"?:
                    self.roleRow.value = TutorType.center.rawValue
                case "travel"?:
                    self.roleRow.value = TutorType.travel.rawValue
                case "p2p"?:
                    self.roleRow.value = TutorType.p2p.rawValue
                default: return
                }
                self.roleRow.reload()
            }
        }
    }

    private func submit() {
        var data: [String: String?] = [
            "email": emailRow.value,
            "first_name": firstNameRow.value,
            "last_name": lastNameRow.value
        ]
        switch roleRow.value {
        case TutorType.center.rawValue?:
            data["role"] = "center"
        case TutorType.travel.rawValue?:
            data["role"] = "travel"
        case TutorType.p2p.rawValue?:
            data["role"] = "p2p"
        default:
            break
        }
        let id = "\(idRow.value!)"
        var nonNil = data.filter { $0.value != nil } as [String : Any]
        let merge = Array(nonNil.keys)
        nonNil["total_scheduled"] = 0
        // Update old if needed
        db.collection("students").document(id).getDocument
            { [weak self] (snapshot, err) in
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
