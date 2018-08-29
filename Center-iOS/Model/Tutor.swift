//
//  Tutor.swift
//  Center-iOS
//
//  Created by Apollo Zhu on 8/26/18.
//  Copyright © 2018 OHS The Center. All rights reserved.
//

import Foundation
import FirebaseFirestore

typealias TutorList = [Int: Tutor]

struct Tutor {
    let id: Int
    let email: String
    let firstName: String
    let lastName: String
    let role: Role
    let subjects: [String]
    let totalScheduled: Int
    let totalAttended: Int
    let scheduled: [DocumentReference]
}

extension Tutor {
    enum Role: String, CaseIterable, CustomStringConvertible {
        case center = "center"
        case travel = "travel"
        case p2p = "p2p"

        var description: String {
            switch self {
            case .center: return "Center Tutor"
            case .travel: return "Travel Tutor"
            case .p2p: return "P2P Only"
            }
        }

        static let map: [AnyHashable: String] = [
            // Instances
            center: center.description,
            travel: travel.description,
            p2p   : p2p.description,
            // Raw values
            center.rawValue: center.description,
            travel.rawValue: travel.description,
            p2p.rawValue   : p2p.description,
            // Human readables
            center.description: center.rawValue,
            travel.description: travel.rawValue,
            p2p.description   : p2p.rawValue
        ]
    }
}

extension Tutor {
    init?(id: Int, firData data: [String: Any]) {
        guard let firstName = data["firstName"] as? String
            , let lastName = data["lastName"] as? String
            , let email = data["email"] as? String
            , let rawRole = data["role"] as? String
            , let role = Role(rawValue: rawRole)
            , let subjects = data["subjects"] as? [String]
            , let scheduled = data["scheduled"] as? [DocumentReference]
            , let totalScheduled = data["totalScheduled"] as? Int
            , let totalAttended = data["totalAttended"] as? Int
            else { return nil }
        self.init(
            id: id,
            email: email,
            firstName: firstName,
            lastName: lastName,
            role: role,
            subjects: subjects,
            totalScheduled: totalScheduled,
            totalAttended: totalAttended,
            scheduled: scheduled
        )
    }
}

// MARK: Methods

extension Tutor {
    static func ofID(_ id: Int, useCache: Bool = true,
                     then process: @escaping (Tutor?, Error?) -> Void) {
        guard id > 0 else {
            return DispatchQueue.global().async {
                process(nil, nil)
            }
        }
        if hasCache && useCache { return process(list[id], nil) }
        db.collection("students").document("\(id)").getDocument { (snapshot, err) in
            guard let data = snapshot?.data()
                , let tutor = Tutor(id: id, firData: data)
                else { return process(nil, err) }
            process(tutor, nil)
        }
    }

    private static var hasCache = false
    private static var list: TutorList = [:]

    static func fetchAll(useCache: Bool = true,
                         then process: @escaping (TutorList?, Error?) -> Void) {
        if hasCache && useCache {
            return DispatchQueue.global().async {
                process(list, nil)
            }
        }
        db.collection("students").getDocuments { (snapshot, error) in
            guard let documents = snapshot?.documents else {
                return process(nil, error)
            }
            hasCache = false
            list = [:]
            for document in documents {
                guard let id = Int(document.documentID)
                    , let tutor = Tutor(id: id, firData: document.data())
                    else {
                        print("Error: Tutor #\(document.documentID) is ill formed")
                        continue
                }
                list[id] = tutor
            }
            hasCache = true
            process(list, nil)
        }
    }
}
