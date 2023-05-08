//
//  AssetResourceLoader.swift
//  DWPlayer
//
//  Created by dwinters on 2023/4/18.
//

import Foundation
import AVFoundation

protocol AssetResourceLoaderDelegate: AnyObject {
    func loadingRequestDidStartProcessing()
    func loadingRequestDidEndProcessing()
}

class AssetResourceLoader: NSObject {
    
    let url: URL
    let cacheProcessor: MediaCacheProcessor
    var requestProcessors = Set<LoadingRequestProcessor>()
    weak var delegate: AssetResourceLoaderDelegate?
    
    init(url: URL) {
        self.url = url
        self.cacheProcessor = MediaCacheProcessor(url: url)
    }
    
    deinit {
        cancel()
    }
        
    func addRequest(_ loadingRequest: AVAssetResourceLoadingRequest) {
        if let _ = loadingRequest.dataRequest {
            let requestProcessor = LoadingRequestProcessor(url: url,
                                                           loadingRequest: loadingRequest,
                                                           cacheProcessor: cacheProcessor,
                                                           delegate: self)
            requestProcessors.insert(requestProcessor)
            delegate?.loadingRequestDidStartProcessing()
            requestProcessor.processTasks()
        }
    }
    
    func removeRequest(_ request: AVAssetResourceLoadingRequest, isCanceled: Bool) {
        if let processor = requestProcessors.first(where: ({ $0.loadingRequest == request })) {
            requestProcessors.remove(processor)
            if isCanceled {
                processor.cancelTasks()
                request.finishLoading(with: NSError(domain: NSURLErrorDomain, code: NSURLErrorCancelled))
            }
            delegate?.loadingRequestDidEndProcessing()
        }
    }
    
    func cancel() {
        requestProcessors.forEach({ $0.cancelTasks() })
    }
    
}

extension AssetResourceLoader: LoadingRequestProcessorDelegate {
    func processor(_ processor: LoadingRequestProcessor, didCompleteWithError error: Error?) {
        invokeOnMainThread {
            self.removeRequest(processor.loadingRequest, isCanceled: false)
        }
    }
}
