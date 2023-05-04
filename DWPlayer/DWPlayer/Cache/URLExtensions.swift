//
//  URLExtensions.swift
//  DWPlayer
//
//  Created by dwinters on 2023/4/18.
//

import Foundation

extension URL {
    func withScheme(_ scheme: String) -> URL? {
        var components = URLComponents(url: self, resolvingAgainstBaseURL: false)
        components?.scheme = scheme
        return components?.url
    }
}
