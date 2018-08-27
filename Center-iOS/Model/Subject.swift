//
//  Subject.swift
//  Center-iOS
//
//  Created by Apollo Zhu on 8/25/18.
//  Copyright © 2018 OHS The Center. All rights reserved.
//

import Foundation

typealias SubjectList = [String: [Subject]]

struct Subject: Hashable {
    let id: Int
    /// All Caps
    let fullName: String
    let shortName: String
}

// MARK: - From FCPS

extension Subject {
    /// This url should not change that often, but you can always get the most
    /// up to date one from oakton website, course offerings.
    static let url = "https://insys.fcps.edu/CourseCatOnline/server/services/CourseCatOnlineData.cfc?method=getPanelMenuData"

    static func fetchAllFromFCPS(then process: @escaping (SubjectList?, Error?) -> Void) {
        var request = URLRequest(url: URL(string: url)!)
        request.httpMethod = "POST"
        request.addValue("application/json;charset=UTF-8", forHTTPHeaderField: "Content-Type")
        struct Payload: Codable {
            let LocationId = "458"
            let GradeA = "0"
            let GradeB = "0"
            let GradeC = "0"
            let CourseMenuMainID = "reportPanelSideNav"
        }
        request.httpBody = try! JSONEncoder().encode(Payload())
        let task = URLSession.shared.dataTask(with: request) { (data, res, err) in
            guard let data = data, data.count > 0 else {
                return process(nil, err)
            }
            do {
                let decoded = try JSONDecoder().decode(Wrapper.self, from: data)
                var result: SubjectList = [:]
                for groups in decoded.TDATA.stCourseList.CourseGroups {
                    for group in groups.CourseGroup {
                        result[group.CourseGroupNav] = group.Courses.map {
                            Subject(id: $0.CourseNum,
                                    fullName: $0.CourseName,
                                    shortName: $0.ShortCourseName
                            )
                        }
                    }
                }
                process(result, nil)
                DispatchQueue.global(qos: .userInitiated).async {
                    uploadList(result)
                }
            } catch {
                process(nil, error)
            }
        }
        task.resume()
    }

    private struct Wrapper: Codable {
        struct TDATA: Codable {
            struct stCourseList: Codable {
                struct CourseGroups: Codable {
                    struct CourseGroup: Codable {
                        let CourseGroupNav: String
                        // let CourseGroupNavShort: String
                        // let CourseGroup_ID: Int
                        struct Courses: Codable {
                            let CourseName: String
                            let CourseNum: Int
                            let ShortCourseName: String
                        }
                        let Courses: [Courses]
                    }
                    let CourseGroup: [CourseGroup]
                    // let CourseMenuMain_ID: Int
                }
                let CourseGroups: [CourseGroups]
            }
            let stCourseList: stCourseList
        }
        let TDATA: TDATA
    }
}

// MARK: To Firebase

import Firebase

extension Subject {
    private static let subjectsDocument = db.collection("info").document("subjects")
    private static let all = subjectsDocument.collection("all")
    private static let categorized = subjectsDocument.collection("categorized")

    static var hasCache = false
    static var list = SubjectList()
    static var map = [Int: Subject]()

    static func uploadList(_ list: SubjectList) {
        subjectsDocument.delete() // Remove All
        for (category, courses) in list {
            let courseIDs: [Int] = courses.map { course in
                all.document("\(course.id)").setData([
                    "fullName": course.fullName,
                    "shortName": course.shortName]
                )
                return course.id
            }
            categorized.document(category).setData(["courses": courseIDs])
        }
    }

    static func fetchAllFromFirebase(useCache: Bool = true,
                                     then process: @escaping (SubjectList?, Error?) -> Void) {
        if useCache && hasCache {
            return DispatchQueue.global().async {
                process(list, nil)
            }
        }
        categorized.getDocuments { (snapshot, error) in
            guard let snapshot = snapshot else {
                return process(nil, error)
            }
            all.getDocuments { (allSubjects, error) in
                guard let allSubjects = allSubjects else {
                    return process(nil, error)
                }
                var allCourses = [Int: Subject]()
                for document in allSubjects.documents {
                    let id = Int(document.documentID)!
                    allCourses[id] = Subject(
                        id: id,
                        fullName: document.get("fullName") as! String,
                        shortName: document.get("shortName") as! String
                    )
                }
                var list = SubjectList()
                for document in snapshot.documents {
                    let ids = document.get("courses") as! [Int]
                    list[document.documentID] = ids.map { allCourses[$0]! }
                }
                Subject.map = allCourses
                Subject.list = list
                Subject.hasCache = true
                process(list, nil)
            }
        }
    }

    static func ofID(_ id: Int, useCache: Bool = true,
                     then process: @escaping (Subject?, Error?) -> Void) {
        if useCache && hasCache {
            return DispatchQueue.global().async {
                process(map[id], nil)
            }
        }
        all.document("\(id)").getDocument { (snapshot, error) in
            guard let data = snapshot?.data() else {
                return process(nil, error)
            }
            process(Subject(id: id,
                            fullName: data["fullName"] as! String,
                            shortName: data["shortName"] as! String), nil)
        }
    }
}
