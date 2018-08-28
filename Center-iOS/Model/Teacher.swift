//
//  Teacher.swift
//  Center-iOS
//
//  Created by Apollo Zhu on 8/27/18.
//  Copyright © 2018 OHS The Center. All rights reserved.
//

import Foundation
import Firebase

typealias TeacherList = [String: Teacher]

struct Teacher {
    let id: String
    let firstName: String
    let lastName: String
    let role: String
    let prefix: String?
    let room: String?
    let requests: [DocumentReference]

    init(id: String, firstName: String, lastName: String, role: String,
         prefix: String? = nil, room: String? = nil,
         requests: [DocumentReference] = []) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.role = role
        self.prefix = prefix
        self.room = room
        self.requests = requests
    }
}

import SwiftSoup

protocol FCPSTeacherFetchDelegate: class {
    func onError(_ error: Error?)
    func onAbort()
    func onMerging()
    func onSuccess()
}

extension Teacher {
    private static let base = "https://oaktonhs.fcps.edu/staff-directory"

    static weak var delegate: FCPSTeacherFetchDelegate? = nil
    private static var hasError = false
    private static var count = 0 {
        didSet {
            guard count == 0 else { return }
            if hasError {
                delegate?.onAbort()
            } else {
                mergeFCPSWithFirebase()
            }
        }
    }

    /// https://github.com/ohsthecenter/Catalog/blob/master/code/fetch_teacher_info.py
    static func fetchAllFromFCPS() {
        hasCache = false
        hasError = false
        teachers = [:]
        let task = URLSession.shared.dataTask(with: URL(string: base)!) { data,_,err in
            guard let data = data
                , let html = String(data: data, encoding: .utf8)
                else {
                    delegate?.onError(err)
                    return hasError = true
            }
            do {
                let doc = try SwiftSoup.parse(html)
                let h2 = try doc.select("h2").last()
                guard let text = try h2?.text()
                    , let index = text.lastIndex(of: " ")
                    else {
                    delegate?.onError(nil)
                    return
                }
                let start = text.index(after: index)
                // If we don't have a total number last,
                // this needs refactoring
                let pagesCount = (Int(text[start...])! - 1) / 10
                count = pagesCount + 1
                teachers.reserveCapacity(count * 10)
                (0...pagesCount).forEach(fetchFromFCPS)
            } catch {
                delegate?.onError(error)
                return hasError = true
            }
        }
        task.resume()
    }

    private static func fetchFromFCPS(ofPage page: Int) {
        let url = URL(string: "\(base)?&page=\(page)")!
        let task = URLSession.shared.dataTask(with: url) { data,_,err in
            defer { count -= 1 }
            guard let data = data
                , let html = String(data: data, encoding: .utf8)
                else {
                    delegate?.onError(err)
                    return hasError = true
            }
            do {
                let doc = try SwiftSoup.parse(html)
                let trs = try doc.select("tr")
                for tr in trs.dropFirst() {
                    let cells = try tr.select("td").array()
                    let nameLinks = try cells[0].select("a").array()
                    let lastName = try nameLinks[0].text()
                    let firstName = try nameLinks[1].text()
                    let position = try cells[1].text()
                    let email = try cells[2].text()
                    // If there is @ in email address, they have some problems
                    let index = email.lastIndex(of: "@")!
                    let id = "\(email[..<index])"
                    teachers[id] = Teacher(id: id,
                                           firstName: firstName,
                                           lastName: lastName,
                                           role: position)
                }
            } catch {
                delegate?.onError(error)
                return hasError = true
            }
        }
        task.resume()
    }

    private static func mergeFCPSWithFirebase() {
        db.collection("teachers").getDocuments { (snapshot, error) in
            guard let documents = snapshot?.documents else {
                delegate?.onError(error)
                return
            }
            for document in documents {
                let ref = db.collection("teachers").document(document.documentID)
                if let teacher = teachers[document.documentID] {
                    let data = document.data()
                    let current = [
                        "firstName": teacher.firstName,
                        "lastName": teacher.lastName,
                        "role": teacher.role
                    ]
                    let updated = current.keys.filter {
                        data[$0] as? String != current[$0]
                    }
                    ref.setData(current, mergeFields: updated)
                    teachers.removeValue(forKey: document.documentID)
                } else {
                    ref.delete()
                }
            }
            for (id, teacher) in teachers {
                let ref = db.collection("teachers").document(id)
                let current = [
                    "firstName": teacher.firstName,
                    "lastName": teacher.lastName,
                    "role": teacher.role
                ]
                ref.setData(current)
            }
            teachers = [:]
            delegate?.onSuccess()
        }
    }
}

extension Teacher {
    private static var teachers: [String: Teacher] = [:]
    private static var hasCache = false

    static func fetchAll(useCache: Bool = true,
                         then process: @escaping (TeacherList?, Error?) -> Void) {
        if useCache && hasCache { return process(teachers, nil) }
        db.collection("teachers").getDocuments { (snapshot, err) in
            guard let documents = snapshot?.documents else { return process(nil, err) }
            guard documents.count > 0 else { return process([:], nil) }
            teachers = [:]
            for document in documents {
                let data = document.data()
                let id = document.documentID
                guard let firstName = data["firstName"] as? String
                    , let lastName = data["lastName"] as? String
                    , let role = data["role"] as? String
                    else {
                        print("ERROR: Can't parse \(id)")
                        continue
                }
                teachers[id] = Teacher(
                    id: id,
                    firstName: firstName,
                    lastName: lastName,
                    role: role,
                    prefix: data["prefix"] as? String,
                    room: data["room"] as? String,
                    requests: data["requests"] as? [DocumentReference] ?? []
                )
            }
            hasCache = true
            process(teachers, nil)
        }
    }
}
