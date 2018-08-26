//
//  Tutor.swift
//  Center-iOS
//
//  Created by Apollo Zhu on 8/26/18.
//  Copyright © 2018 OHS The Center. All rights reserved.
//

import Foundation

struct Tutor { }

extension Tutor {
    enum Role: String, CaseIterable {
        case center = "Center Tutor"
        case travel = "Travel Tutor"
        case p2p = "P2P Only"

        static let map: [AnyHashable: String] = [
            center.rawValue: "center",
            travel.rawValue: "travel",
            p2p.rawValue: "p2p",
            center: "center",
            travel: "travel",
            p2p: "p2p",
            "center": center.rawValue,
            "travel": travel.rawValue,
            "p2p": p2p.rawValue
        ]
    }
}

