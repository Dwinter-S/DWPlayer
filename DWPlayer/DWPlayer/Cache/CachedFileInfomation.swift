//
//  CachedContent.swift
//  DWPlayer
//
//  Created by dwinters on 2023/4/18.
//

import Foundation

class ResourceContentInfomation: Codable {
    var contentType: String = ""
    var contentLength: Int = 0
    var isByteRangeAccessSupported: Bool = false
}

class CachedFileInfomation: Codable {
    
    private var _cachedFragments = [NSRange]()
    private let writeReadQueue = DispatchQueue(label: "com.dwinters.CachingPlayerItem.cachedFragments", attributes: .concurrent)
    
    let url: URL
    let urlMd5: String
    var contentInfomation: ResourceContentInfomation?
    var cachedFragments: [NSRange] {
        get {
            var res: [NSRange] = []
            writeReadQueue.sync { [unowned self] in
                res = self._cachedFragments
            }
            return res
        }
        set {
            writeReadQueue.async(group: nil, qos: .default, flags: .barrier) { [unowned self] in
                self._cachedFragments = newValue
            }
        }
    }
    
    var cachedPercentsString: String {
//        guard let contentInfomation = contentInfomation else { return "" }
//        let contentLength = CGFloat(contentInfomation.contentLength)
//        var percentStrs = [String]()
//        for cachedFragment in cachedFragments {
//            let startPercent = CGFloat(cachedFragment.location) / contentLength
//            let endPercent = CGFloat(cachedFragment.end) / contentLength
//            percentStrs.append("\(startPercent.formatToPercent())-\(endPercent.formatToPercent())")
//        }
//        return "[\(percentStrs.joined(separator: "\n"))]"
        return cachedPercentRanges.map({ "\($0.lowerBound.formatToPercent())-\($0.upperBound.formatToPercent())" }).joined(separator: "\n")
    }
    
    var cachedPercentRanges: [Range<CGFloat>] {
        guard let contentInfomation = contentInfomation else { return [] }
        let contentLength = CGFloat(contentInfomation.contentLength)
        var percentRanges = [Range<CGFloat>]()
        for cachedFragment in cachedFragments {
            let startPercent = CGFloat(cachedFragment.location) / contentLength
            let endPercent = CGFloat(cachedFragment.end) / contentLength
            percentRanges.append(startPercent..<endPercent)
        }
        return percentRanges
    }
    
    
    init(url: URL) {
        self.url = url
        self.urlMd5 = url.absoluteString.md5
    }
    
    func addCacheFragment(_ fragment: NSRange) {
        guard fragment.isValid else {
            return
        }
        var cachedFragments = self.cachedFragments
        let startIndex = cachedFragments.firstIndex(where: { $0.intersection(fragment) != nil || $0.end == fragment.location })
        let endIndex = cachedFragments.lastIndex(where: { $0.intersection(fragment) != nil || $0.location == fragment.end })
        if startIndex == nil && endIndex == nil {
            let insertIndex = cachedFragments.firstIndex(where: { fragment.location > $0.end }) ?? 0
            cachedFragments.insert(fragment, at: insertIndex)
        } else {
            let replaceSubrange = (startIndex ?? endIndex!)...(endIndex ?? startIndex!)
            var unionRange = fragment
            for range in cachedFragments[replaceSubrange] {
                unionRange.formUnion(range)
            }
            cachedFragments.replaceSubrange(replaceSubrange, with: [unionRange])
        }
        self.cachedFragments = cachedFragments.sorted(by: { $0.location < $1.location })
        print("addCache range: \(fragment)")
        print("cachedPercents:\n\(cachedPercentsString)")
    }
    
    func writeToFile(_ fileURL: URL) {
        if !FileManager.default.fileExists(atPath: fileURL.path) {
            FileManager.default.createFile(atPath: fileURL.path, contents: nil)
        }
        do {
            let data = try JSONEncoder().encode(self)
            try data.write(to: fileURL)
        } catch { }
    }
    
    enum CodingKeys: String, CodingKey {
        case _cachedFragments
        case contentInfomation
        case url
        case urlMd5
    }
    
    func toJson() -> String? {
        do {
            let data = try JSONEncoder().encode(self)
            return String(data: data, encoding: .utf8)
        } catch { }
        return nil
    }
    
    required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        _cachedFragments = try values.decode([NSRange].self, forKey: ._cachedFragments)
        url = try values.decode(URL.self, forKey: .url)
        contentInfomation = try values.decodeIfPresent(ResourceContentInfomation.self, forKey: .contentInfomation)
        urlMd5 = try values.decode(String.self, forKey: .urlMd5)
        print("LocalCache url: \(url)")
        print("cachedPercents:\n\(cachedPercentsString)")
    }
    
}

extension CachedFileInfomation: SQLTable {
    static var createStatement: String {
        return """
    CREATE TABLE CachedFileInfomation(
      URL Text NOT NULL UNIQUE,
      CacheInfo Text NOT NULL
    );
    """
    }
}

extension CGFloat {
    
    func formatToPercent(numberOfDecimalPlaces: Int = 2) -> String {
        let format = NumberFormatter()
        format.numberStyle = .percent
        format.minimumFractionDigits = 0
        format.maximumFractionDigits = numberOfDecimalPlaces
        format.formatterBehavior = .default
        format.roundingMode = .down
        return format.string(from: NSNumber(floatLiteral: self)) ?? ""
    }
    
}
