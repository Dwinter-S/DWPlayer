//
//  CachingPlayerItem.swift
//  DWPlayer
//
//  Created by dwinters on 2023/4/18.
//

import Foundation
import AVFoundation

protocol CachingPlayerItemDelegate: AnyObject {
    
}

class CachingPlayerItem: AVPlayerItem {
    
    weak var delegate: CachingPlayerItemDelegate?
    var loaders = [String : AssetResourceLoader]()
    
    
    /// <#Description#>
    let cacheScheme = "DWMediaCache"

    /// the media resource original url.
    let originalURL: URL
    
    /// Initializes a CachingPlayerItem with a URL, which automatically caches media resource.
    /// - Parameter url: the media resource original url.
    init(url: URL) {
        self.originalURL = url
        if url.pathExtension == "m3u8" {
            if let asset = HLSManager.shared.localAsset(with: url) {
                super.init(asset: asset, automaticallyLoadedAssetKeys: nil)
            } else {
                super.init(asset: AVURLAsset(url: url), automaticallyLoadedAssetKeys: nil)
            }
            return
        }
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let _ = components.scheme,
              let urlWithCustomScheme = url.withScheme(cacheScheme) else {
            fatalError("Urls without a scheme are not supported")
        }
        let asset = AVURLAsset(url: urlWithCustomScheme)
        super.init(asset: asset, automaticallyLoadedAssetKeys: nil)
        asset.resourceLoader.setDelegate(self, queue: DispatchQueue.main)
        canUseNetworkResourcesForLiveStreamingWhilePaused = true
    }
    
}

extension CachingPlayerItem: AVAssetResourceLoaderDelegate {
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        guard let url = loadingRequest.request.url, url.scheme == cacheScheme else {
            return false
        }
        var loader: AssetResourceLoader? = loaders[url.absoluteString]
        if loader == nil {
            loader = AssetResourceLoader(url: originalURL)
            loader?.delegate = self
            loaders[url.absoluteString] = loader
        }
        loader?.addRequest(loadingRequest)
        return true
    }
    
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, didCancel loadingRequest: AVAssetResourceLoadingRequest) {
        if let url = loadingRequest.request.url,
           let loader = loaders[url.absoluteString] {
            loader.removeRequest(loadingRequest, isCanceled: true)
        }
    }
}

extension CachingPlayerItem: AssetResourceLoaderDelegate {
    func loadingRequestDidStartProcessing() {

    }

    func loadingRequestDidEndProcessing() {

    }
}
