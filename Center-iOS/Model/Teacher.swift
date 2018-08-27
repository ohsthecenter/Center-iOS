//
//  Teacher.swift
//  Center-iOS
//
//  Created by Apollo Zhu on 8/27/18.
//  Copyright © 2018 OHS The Center. All rights reserved.
//

import Foundation

typealias TeacherList = [String: Teacher]

struct Teacher {
    let id: String
    let firstName: String
    let lastName: String
    let role: String
    let prefix: String?
    let room: String?
}

extension Teacher {
    func fetchRequests() { }
}

extension Teacher {
    static func fetchAllFromFCPS(then process: @escaping (TeacherList?, Error?) -> Void) {

    }
}
