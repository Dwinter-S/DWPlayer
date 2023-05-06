//
//  HLSManager.swift
//  DWPlayer
//
//  Created by dwinters on 2023/4/18.
//

import Foundation
import AVFoundation

@available(iOS 11.0, *)
class HLSManager: NSObject {
    
    static let shared = HLSManager()
    
    var assetDownloadURLSession: AVAssetDownloadURLSession!
    var activeDownloadsMap = [AVAggregateAssetDownloadTask: URL]()
    var willDownloadToUrlMap = [AVAggregateAssetDownloadTask: URL]()
    
    override private init() {
        super.init()
        let backgroundConfiguration = URLSessionConfiguration.background(withIdentifier: "DWMediaCache-HLS")
        assetDownloadURLSession = AVAssetDownloadURLSession(configuration: backgroundConfiguration, assetDownloadDelegate: self, delegateQueue: OperationQueue.main)
    }
    
    func downloadStream(for url: URL) {
        let asset = AVURLAsset(url: url)
        guard let task = assetDownloadURLSession.aggregateAssetDownloadTask(with: asset, mediaSelections: [asset.preferredMediaSelection], assetTitle: "aaa", assetArtworkData: nil) else {
            return
        }
        activeDownloadsMap[task] = url
        task.resume()
    }
    
    func cancelDownload(for url: URL) {
        var task: AVAggregateAssetDownloadTask?

        for (taskKey, urlVal) in activeDownloadsMap where url == urlVal {
            task = taskKey
            break
        }

        task?.cancel()
    }
    
    func localAsset(with url: URL) -> AVURLAsset? {
        let userDefaults = UserDefaults.standard
        guard let localFileLocation = userDefaults.value(forKey: url.absoluteString) as? Data else { return nil }
        
        var bookmarkDataIsStale = false
        do {
            let url = try URL(resolvingBookmarkData: localFileLocation,
                                    bookmarkDataIsStale: &bookmarkDataIsStale)

            if bookmarkDataIsStale {
                return nil
            }
            return AVURLAsset(url: url)
        } catch {
            return nil
        }
    }
    
}

@available(iOS 11.0, *)
extension HLSManager: AVAssetDownloadDelegate {
    func urlSession(_ session: URLSession, aggregateAssetDownloadTask: AVAggregateAssetDownloadTask, willDownloadTo location: URL) {
        willDownloadToUrlMap[aggregateAssetDownloadTask] = location
    }
    
    func urlSession(_ session: URLSession, aggregateAssetDownloadTask: AVAggregateAssetDownloadTask, didCompleteFor mediaSelection: AVMediaSelection) {
        aggregateAssetDownloadTask.resume()
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let task = task as? AVAggregateAssetDownloadTask,
            let assetURL = activeDownloadsMap.removeValue(forKey: task) else { return }

        guard let downloadURL = willDownloadToUrlMap.removeValue(forKey: task) else { return }
        let userDefaults = UserDefaults.standard
        if let error = error as? NSError {
            switch (error.domain, error.code) {
            case (NSURLErrorDomain, NSURLErrorCancelled):
                
                guard let localFileLocation = localAsset(with: assetURL)?.url else { return }

                do {
                    try FileManager.default.removeItem(at: localFileLocation)
                    userDefaults.removeObject(forKey: assetURL.absoluteString)
                } catch {
                    
                }
            default:
                ()
            }
        } else {
            do {
                let bookmark = try downloadURL.bookmarkData()
                userDefaults.set(bookmark, forKey: assetURL.absoluteString)
            } catch {
                
            }
        }
    }
    
    func urlSession(_ session: URLSession, aggregateAssetDownloadTask: AVAggregateAssetDownloadTask, didLoad timeRange: CMTimeRange, totalTimeRangesLoaded loadedTimeRanges: [NSValue], timeRangeExpectedToLoad: CMTimeRange, for mediaSelection: AVMediaSelection) {
        var percentComplete = 0.0
        for value in loadedTimeRanges {
            let loadedTimeRange: CMTimeRange = value.timeRangeValue
            percentComplete +=
                loadedTimeRange.duration.seconds / timeRangeExpectedToLoad.duration.seconds
        }
    }
}
