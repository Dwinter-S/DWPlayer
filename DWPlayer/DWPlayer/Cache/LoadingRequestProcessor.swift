//
//  LoadingRequestProcessor.swift
//  DWPlayer
//
//  Created by dwinters on 2023/4/18.
//

import Foundation
import AVFoundation
import CoreServices

protocol LoadingRequestProcessorDelegate: AnyObject {
    func processor(_ processor: LoadingRequestProcessor, didCompleteWithError error: Error?)
}

class LoadingRequestProcessor: NSObject {
    
    weak var delegate: LoadingRequestProcessorDelegate?
    let url: URL
    let loadingRequest: AVAssetResourceLoadingRequest
    let cacheProcessor: MediaCacheProcessor
    
    var loadingTasks: [LoadingTask] = []
    var cacheOffset: Int = 0
    var bufferData = Data()
    var isCancelled = false
    
    lazy var session: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 120
        configuration.timeoutIntervalForResource = 120
        let session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
        return session
    }()
    
    init(url: URL,
         loadingRequest: AVAssetResourceLoadingRequest,
         cacheProcessor: MediaCacheProcessor,
         delegate: LoadingRequestProcessorDelegate) {
        self.url = url
        self.loadingRequest = loadingRequest
        self.cacheProcessor = cacheProcessor
        self.delegate = delegate
        super.init()
        if let dataRequest = loadingRequest.dataRequest {
            var offset = Int(dataRequest.requestedOffset)
            var length = dataRequest.requestedLength
            if dataRequest.currentOffset != 0 {
                offset = Int(dataRequest.currentOffset)
            }
            if dataRequest.requestsAllDataToEndOfResource, let contentLength = loadingRequest.contentInformationRequest?.contentLength {
                length = Int(contentLength) - offset
            }
            
            let range = NSRange(location: offset, length: length)
            loadingTasks = getLoadingTasksFor(range: range)
            
        }
    }
    
    func getLoadingTasksFor(range: NSRange) -> [LoadingTask] {
        guard range.isValid else { return [] }
        let cachedFragments = cacheProcessor.cachedFileInfomation.cachedFragments
        var tasks = [LoadingTask]()
        var preEnd = range.location
        for fragment in cachedFragments {
            if let intersection = fragment.intersection(range) {
                if intersection.location > preEnd {
                    tasks.append(LoadingTask(taskType: .remote, range: NSRange(location: preEnd, length: intersection.location - preEnd)))
                }
                let maxLength = 512 * 1024
                var offset = 0
                while offset + maxLength <= intersection.length {
                    tasks.append(LoadingTask(taskType: .local, range: NSRange(location: intersection.location + offset, length: maxLength)))
                    offset += maxLength
                }
                if offset < intersection.length {
                    tasks.append(LoadingTask(taskType: .local, range: NSRange(location: intersection.location + offset, length: intersection.length - offset)))
                }
                preEnd = intersection.end
            } else {
                if fragment.location >= range.end {
                    break
                }
                continue
            }
        }
        if preEnd < range.end {
            tasks.append(LoadingTask(taskType: .remote, range: NSRange(location: preEnd, length: range.end - preEnd)))
        }
        return tasks
    }
    
    func processTasks() {
        guard !isCancelled else {
            return
        }
        guard !loadingTasks.isEmpty else {
            finishLoadingRequest(loadingRequest, error: nil)
            return
        }
        let loadingTask = loadingTasks.removeFirst()
        if loadingTask.taskType == .local {
            cacheProcessor.cachedDataFor(range: loadingTask.range) { [weak self] data in
                guard let self = self else { return }
                if let data = data {
                    self.fillInContentInformationRequest(self.loadingRequest.contentInformationRequest, response: nil)
                    self.loadingRequest.dataRequest?.respond(with: data)
                    self.processTasks()
                } else {
                    
                }
            }
        } else {
            let fromOffset = loadingTask.range.location
            let endOffset = loadingTask.range.location + loadingTask.range.length - 1
            var request = URLRequest(url: url)
            request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
            let range = "bytes=\(fromOffset)-\(endOffset)"
            request.setValue(range, forHTTPHeaderField: "Range")
            cacheOffset = loadingTask.range.location
            let dataTask = session.dataTask(with: request)
            dataTask.resume()
        }
    }
    
    func cancelTasks() {
        session.invalidateAndCancel()
        isCancelled = true
    }
    
    func fillInContentInformationRequest(_ contentInformationRequest: AVAssetResourceLoadingContentInformationRequest?, response: URLResponse?) {
        guard let contentInformationRequest = contentInformationRequest else { return }
        guard contentInformationRequest.contentType == nil else { return }
        if let contentInfomation = cacheProcessor.cachedFileInfomation.contentInfomation {
            setContentInfomation(contentInfomation)
            return
        }
        if let httpResponse = response as? HTTPURLResponse {
            let contentInfomation = ResourceContentInfomation()
            let acceptRange = httpResponse.allHeaderFields["Accept-Ranges"] as? String
            contentInfomation.isByteRangeAccessSupported = acceptRange == "bytes"
            var contentLength = 0
            var contentRange = httpResponse.allHeaderFields["content-range"] as? String
            contentRange = contentRange ?? httpResponse.allHeaderFields["Content-Range"] as? String
            if let last = contentRange?.components(separatedBy: "/").last {
                contentLength = Int(last)!
            }
            if contentLength == 0 {
                contentLength = Int(httpResponse.expectedContentLength)
            }
            contentInfomation.contentLength = contentLength
            if let mimeType = httpResponse.mimeType {
                let contentType = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, mimeType as CFString, nil)
                if let takeUnretainedValue = contentType?.takeUnretainedValue() {
                    contentInfomation.contentType = takeUnretainedValue as String
                }
            }
            cacheProcessor.setContentInfomation(contentInfomation)
            setContentInfomation(contentInfomation)
        }
        
        func setContentInfomation(_ contentInfomation: ResourceContentInfomation) {
            contentInformationRequest.isByteRangeAccessSupported = contentInfomation.isByteRangeAccessSupported
            contentInformationRequest.contentType = contentInfomation.contentType
            contentInformationRequest.contentLength = Int64(contentInfomation.contentLength)
        }
    }
    
    func finishLoadingRequest(_ loadingRequest: AVAssetResourceLoadingRequest?, error: Error?) {
        guard let loadingRequest = loadingRequest else { return }
        if error != nil {
            loadingRequest.finishLoading(with: error)
        } else {
            loadingRequest.finishLoading()
        }
        delegate?.processor(self, didCompleteWithError: error)
    }
    
    func handleBufferData() {
        let range = NSRange(location: cacheOffset, length: bufferData.count)
        cacheProcessor.cacheData(bufferData, for: range)
        cacheOffset += bufferData.count
        cacheProcessor.save()
        loadingRequest.dataRequest?.respond(with: bufferData)
        bufferData = Data()
    }
    
}


extension LoadingRequestProcessor: URLSessionDataDelegate {
    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        completionHandler(.useCredential, URLCredential(trust: challenge.protectionSpace.serverTrust!))
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        fillInContentInformationRequest(loadingRequest.contentInformationRequest, response: response)
        bufferData = Data()
        completionHandler(.allow)
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        bufferData.append(data)
        guard bufferData.count > 1024 * 1024 else {
            return
        }
        handleBufferData()
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        handleBufferData()
        if (error as? NSError)?.code == NSURLErrorCancelled {
            return
        }
        if error != nil {
            finishLoadingRequest(loadingRequest, error: nil)
        } else {
            processTasks()
        }
    }
    
}
