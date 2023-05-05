//
//  MediaCacheProcessor.swift
//  DWPlayer
//
//  Created by dwinters on 2023/4/18.
//

import Foundation

extension Notification.Name {
    public static let CachedPercentRangesDidChanged = NSNotification.Name("CachedPercentRangesDidChanged")
}

class MediaCacheProcessor {
    let url: URL
    let cachedFileURL: URL
    let cachedFileInfomation: CachedFileInfomation
    
    private var fileManager = FileManager.default
    private var writeFileHandle: FileHandle?
    private var readFileHandle: FileHandle?
    private let ioQueue: DispatchQueue
    private var bufferData = Data()

    init(url: URL) {
        self.url = url
        let cacheDirectory = MediaCache.default.diskCache.directory
        let urlMd5 = url.absoluteString.md5
        self.cachedFileURL = cacheDirectory.appendingPathComponent(urlMd5).appendingPathExtension(url.pathExtension)
        if let value = MediaCache.default.localCache(with: url) {
            self.cachedFileInfomation = value
        } else {
            self.cachedFileInfomation = CachedFileInfomation(url: url)
        }
        self.ioQueue = DispatchQueue(label: "com.dwinters.CachingPlayerItem.MediaCache.ioQueue.\(urlMd5)")
    }
    
    deinit {
        save()
        writeFileHandle?.closeFile()
        readFileHandle?.closeFile()
    }

    func cacheData(_ data: Data, for range: NSRange, completion handler: ((Bool)->())? = nil) {
        guard data.count > 0, range.isValid else {
            handler?(false)
            return
        }
        if !fileManager.fileExists(atPath: cachedFileURL.path) {
            fileManager.createFile(atPath: cachedFileURL.path, contents: nil)
        }
        do {
            if writeFileHandle == nil {
                writeFileHandle = try FileHandle(forWritingTo: cachedFileURL)
            }
            ioQueue.async { [weak self] in
                self?.writeFileHandle?.seek(toFileOffset: UInt64(range.location))
                self?.writeFileHandle?.write(data)
                self?.cachedFileInfomation.addCacheFragment(range)
                handler?(true)
            }
        } catch {
            handler?(false)
        }
    }

    func cachedDataFor(range: NSRange, completion handler: @escaping ((Data?)->())) {
        if !fileManager.fileExists(atPath: cachedFileURL.path) {
            handler(nil)
            return
        }
        do {
            if readFileHandle == nil {
                readFileHandle = try FileHandle(forReadingFrom: cachedFileURL)
            }
            ioQueue.async { [weak self] in
                self?.readFileHandle?.seek(toFileOffset: UInt64(range.location))
                let data = self?.readFileHandle?.readData(ofLength: range.length)
                handler(data)
            }
        } catch {
            handler(nil)
        }
    }

    func setContentInfomation(_ contentInfomation: ResourceContentInfomation) {
        cachedFileInfomation.contentInfomation = contentInfomation
        ioQueue.async { [weak self] in
            self?.writeFileHandle?.truncateFile(atOffset: UInt64(contentInfomation.contentLength))
            self?.writeFileHandle?.synchronizeFile()
        }
    }

    func startWritting() {

    }

    func finishWritting() {

    }

    func save() {
        ioQueue.async { [weak self] in
            guard let self = self else { return }
            self.writeFileHandle?.synchronizeFile()
            do {
              try MediaCache.default.db?.insertCachedFileInfo(info: self.cachedFileInfomation)
                NotificationCenter.default.post(name: Notification.Name.CachedPercentRangesDidChanged, object: nil, userInfo: ["url": self.url.absoluteString, "ranges" : self.cachedFileInfomation.cachedPercentRanges])
                print("?????CachedPercentRangesDidChanged \(self.cachedFileInfomation.cachedPercentRanges)")
            } catch {
                print("保存数据库失败\(error)")
            }
        }
    }
}
