//
//  MediaCache.swift
//  DWPlayer
//
//  Created by dwinters on 2023/4/18.
//

import Foundation

class MediaCache {
    static let `default` = MediaCache(diskConfig: DiskConfig(name: "default", maxSize: 1024 * 1024 * 80))
    let diskCache: DiskCache
    var db: SQLiteDatabase? {
        return diskCache.db
    }
    init(diskConfig: DiskConfig) {
        self.diskCache = DiskCache(config: diskConfig)
    }
    
    func localCache(with url: URL) -> CachedFileInfomation? {
        return db?.cachedFileInfomation(url: url.absoluteString.md5)
    }
    
}

class DiskCache {
    let config: DiskConfig
    var directory: URL
    let fileManager = FileManager.default
    let ioQueue: DispatchQueue
    var db: SQLiteDatabase?
    init(config: DiskConfig) {
        self.config = config
        self.directory = config.directory ?? self.fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!.appendingPathComponent("com.dwinters.CachingPlayerItem.MediaCache.\(config.name)")
        if !fileManager.fileExists(atPath: directory.path) {
            do {
                try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
            } catch {
                
            }
        }
        self.ioQueue = DispatchQueue(label: "com.dwinters.CachingPlayerItem.MediaCache.ioQueue.\(config.name)")
        openDB()
    }
    
    private func openDB() {
        let dbURL = self.directory.appendingPathComponent("cache.sqlite")
        if !FileManager.default.fileExists(atPath: dbURL.absoluteString) {
            FileManager.default.createFile(atPath: dbURL.absoluteString, contents: nil)
        }
        do {
            self.db = try SQLiteDatabase.open(path: dbURL.absoluteString)
            try db?.createTable(table: CachedFileInfomation.self)
        } catch {
        }
    }
    
    func clearDiskCache(completion handler: (()->())? = nil) {
        ioQueue.async {
            do {
                try self.fileManager.removeItem(at: self.directory)
                try self.fileManager.createDirectory(at: self.directory, withIntermediateDirectories: true)
                self.openDB()
            } catch {}
            
            if let handler = handler {
                DispatchQueue.main.async {
                    handler()
                }
            }
        }
    }
    
    func cleanExpiredDiskCache(completion handler: (()->())? = nil) {
        ioQueue.async {
            var (totalDiskCacheByteCount, cachedFiles) = self.fetchCachedFilesInfo(excludedFileExtensions: ["sqlite"])
            print("本地缓存: \(self.byteCountFormatter(byteCount: totalDiskCacheByteCount, byteCountFormatterUnit: [.useMB]))")
            var expiredDate: Date
            switch self.config.expiry {
            case .never:
                expiredDate = Date(timeIntervalSinceNow: -60 * 60 * 24 * 365 * 68)
            case .seconds(let seconds):
                expiredDate = Date(timeIntervalSinceNow: -seconds)
            case .date(let date):
                expiredDate = date
            }
            for (fileURL, resourceValues) in cachedFiles {
                if let lastAccessDate = resourceValues.contentAccessDate,
                    (lastAccessDate as NSDate).timeIntervalSince(expiredDate) < 0 {
                    do {
                        try self.fileManager.removeItem(at: fileURL)
                        try self.db?.deleteCachedFileInfomation(url: fileURL.deletingPathExtension().lastPathComponent)
                        let fileSize = (resourceValues.totalFileAllocatedSize ?? resourceValues.totalFileSize) ?? 0
                        totalDiskCacheByteCount -= fileSize
                        print("删除过期文件: \(fileURL) 大小：\(self.byteCountFormatter(byteCount: fileSize, byteCountFormatterUnit: [.useMB])) 上次访问时间:\(lastAccessDate)")
                    } catch {
                        print("删除过期文件失败:\(error)")
                    }
                }
            }
            if totalDiskCacheByteCount > self.config.maxSize {
                let targetSize = self.config.maxSize / 2
                let sortedCachedFiles = cachedFiles.sorted { file1, file2 in
                    if let date1 = file1.value.contentAccessDate,
                       let date2 = file2.value.contentAccessDate
                    {
                        return date1.compare(date2) == .orderedAscending
                    }
                    return true
                }
                for (fileURL, resourceValues) in sortedCachedFiles {
                    do {
                        try self.fileManager.removeItem(at: fileURL)
                        try self.db?.deleteCachedFileInfomation(url: fileURL.deletingPathExtension().lastPathComponent)
                        let fileSize = (resourceValues.totalFileAllocatedSize ?? resourceValues.totalFileSize) ?? 0
                        totalDiskCacheByteCount -= fileSize
                        print("删除文件: \(fileURL) 大小：\(self.byteCountFormatter(byteCount: fileSize, byteCountFormatterUnit: [.useMB]))")
                        if totalDiskCacheByteCount < targetSize {
                            break
                        }
                    } catch {
                        print("删除文件失败:\(error)")
                    }
                }
            }
            handler?()
            print("删除本地缓存结束: \(self.byteCountFormatter(byteCount: totalDiskCacheByteCount, byteCountFormatterUnit: [.useMB]))")
        }
    }
    
    func cachedFileURLWith(url: URL) -> URL {
        return directory.appendingPathComponent(url.absoluteString.md5).appendingPathExtension(url.pathExtension)
    }
    
    func cachedContentInfoURLWith(url: URL) -> URL {
        return directory.appendingPathComponent(url.absoluteString.md5).appendingPathExtension("cfi")
    }
    
    func calculateDiskCacheByteCount(completion handler: @escaping ((_ size: Int) -> Void)) {
        ioQueue.async {
            let cachedFilesInfo = self.fetchCachedFilesInfo(excludedFileExtensions: ["sqlite"])
            DispatchQueue.main.async {
                handler(cachedFilesInfo.totalDiskCacheByteCount)
            }
        }
    }
    
    func calculateDiskCacheSize(byteCountFormatterUnit: ByteCountFormatter.Units = [.useKB, .useMB], completion handler: @escaping ((_ size: String) -> Void)) {
        calculateDiskCacheByteCount { byteCount in
            handler(self.byteCountFormatter(byteCount: byteCount, byteCountFormatterUnit: byteCountFormatterUnit))
        }
    }
    
    func byteCountFormatter(byteCount: Int, byteCountFormatterUnit: ByteCountFormatter.Units) -> String {
        let bcf = ByteCountFormatter()
        bcf.allowedUnits = byteCountFormatterUnit
        bcf.countStyle = .file
        return bcf.string(fromByteCount: Int64(byteCount))
    }
    
    func fetchCachedFilesInfo(excludedFileExtensions: [String] = []) -> (totalDiskCacheByteCount: Int, cachedFiles: [URL: URLResourceValues]) {
        let resourceKeys = Set<URLResourceKey>([.totalFileSizeKey, .totalFileAllocatedSizeKey, .isRegularFileKey, .nameKey, .contentAccessDateKey])
        let fileURLs = (try? fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: Array(resourceKeys), options: .skipsHiddenFiles)) ?? []
        var totalDiskCacheByteCount = 0
        var cachedFiles = [URL: URLResourceValues]()
        for fileURL in fileURLs {
            do {
                guard !excludedFileExtensions.contains(fileURL.pathExtension) else {
                    continue
                }
                let resourceValues = try fileURL.resourceValues(forKeys: resourceKeys)
                guard resourceValues.isRegularFile ?? false else {
                    continue
                }
                let fileSize = (resourceValues.totalFileAllocatedSize ?? resourceValues.totalFileSize) ?? 0
                totalDiskCacheByteCount += fileSize
                cachedFiles[fileURL] = resourceValues
            } catch {
                
            }
        }
        return (totalDiskCacheByteCount, cachedFiles)
    }
    
}

struct DiskConfig {
  let name: String
  let expiry: Expiry
  let maxSize: UInt
  let directory: URL?
  init(name: String, expiry: Expiry = .never,
              maxSize: UInt = 0, directory: URL? = nil) {
    self.name = name
    self.expiry = expiry
    self.maxSize = maxSize
    self.directory = directory
  }
}

enum Expiry {
    case never
    case seconds(TimeInterval)
    case date(Date)
}
