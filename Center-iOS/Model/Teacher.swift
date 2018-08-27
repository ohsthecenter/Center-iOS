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
}

import SwiftSoup

extension Teacher {
    static let base = "https://oaktonhs.fcps.edu/staff-directory"

    /// https://github.com/ohsthecenter/Catalog/blob/master/code/fetch_teacher_info.py
    static func fetchAllFromFCPS() {
        let task = URLSession.shared.dataTask(with: URL(string: base)!) { data,_,_ in
            guard let data = data
                , let html = String(data: data, encoding: .utf8)
                , let doc = try? SwiftSoup.parse(html)
                , let h2 = try? doc.select("h2").last()
                , let wrapped = try? h2?.text()
                , let text = wrapped
                , let index = text.lastIndex(of: " ")
                else { return }
            let start = text.index(after: index)
            let pagesCount = (Int(text[start...])! - 1) / 10
            (0...pagesCount).forEach(fetchFromFCPS)
        }
        task.resume()
    }

    private static func fetchFromFCPS(ofPage page: Int) {
        let url = URL(string: "\(base)?&page=\(page)")!
        let task = URLSession.shared.dataTask(with: url) { data,_,_ in
            guard let data = data
                , let html = String(data: data, encoding: .utf8)
                , let doc = try? SwiftSoup.parse(html)
                , let trs = try? doc.select("tr")
                else { return }
            for tr in trs.dropFirst() {
                guard let cells = try? tr.select("td").array()
                    , let nameLinks = try? cells[0].select("a").array()
                    , let lastName = try? nameLinks[0].text()
                    , let firstName = try? nameLinks[1].text()
                    , let position = try? cells[1].text()
                    , let email = try? cells[2].text()
                    else { return }
                print("\(firstName) \(lastName), \(email), \(position)")
            }
        }
        task.resume()
    }
}
