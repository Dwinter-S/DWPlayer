//
//  MediaManager.swift
//  DWPlayer
//
//  Created by dwinters on 2023/5/4.
//

import Foundation

class MediaManager {
    static let shared = MediaManager()
    
    var allMedias: [Media] {
        return mp3Medias + mp4Medias
    }
    
    let mp3Medias: [Media]
    let mp4Medias: [Media]
    
    private init() {
        let url = Bundle.main.url(forResource: "MediaList", withExtension: "plist")!
        if let data = try? Data(contentsOf: url),
           let dict = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String : [[String : String]]] {
            mp3Medias = getMeidas(dict: dict, key: "mp3")
            mp4Medias = getMeidas(dict: dict, key: "mp4")
        } else {
            mp3Medias = []
            mp4Medias = []
        }
        
        func getMeidas(dict: [String : [[String : String]]], key: String) -> [Media] {
            let arr = dict[key] ?? []
            return arr.map({ Media(name: $0["name"], url: $0["url"]) })
        }
    }
}

struct Media {
    let name: String?
    let url: String?
    
    var type: String {
        return URL(string: url ?? "")?.pathExtension ?? ""
    }
}
