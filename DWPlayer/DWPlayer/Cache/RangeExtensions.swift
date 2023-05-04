//
//  RangeExtensions.swift
//  DWPlayer
//
//  Created by dwinters on 2023/4/18.
//

import Foundation

extension NSRange {
    var isValid: Bool {
        return location != NSNotFound && length != 0
    }
    var end: Int {
        return location + length
    }
}
