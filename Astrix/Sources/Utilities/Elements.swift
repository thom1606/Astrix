//
//  VisionOS.swift
//  Astrix
//
//  Created by Thom van den Broek on 15/11/2024.
//

import Foundation

enum ElementSize {
    case small
    case medium

    var value: CGFloat {
        if self == .small { return 44 }
        return 52
    }

    var fontSize: CGFloat {
        if self == .small { return 17 }
        return 19
    }

    var iconSize: CGFloat {
        if self == .small { return 19 }
        return 24
    }
}
