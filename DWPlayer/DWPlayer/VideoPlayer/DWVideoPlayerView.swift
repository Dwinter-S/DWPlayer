//
//  DWVideoPlayerView.swift
//  DWPlayer
//
//  Created by dwinters on 2023/4/19.
//

import UIKit
import AVFoundation

class DWVideoPlayerView: UIView {
    
    lazy var playerLayer: AVPlayerLayer = {
        let playerLayer = AVPlayerLayer()
        playerLayer.isHidden = true
        playerLayer.backgroundColor = UIColor.black.cgColor
        playerLayer.contentsGravity = .resizeAspect
        playerLayer.addObserver(self, forKeyPath: #keyPath(AVPlayerLayer.isReadyForDisplay), options: .new, context: nil)
        return playerLayer
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    func commonInit() {
        layer.addSublayer(playerLayer)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = bounds
    }
    
    deinit {
        playerLayer.removeObserver(self, forKeyPath: #keyPath(AVPlayerLayer.isReadyForDisplay), context: nil)
    }
    
    func setPlayer(_ player: DWPlayer?) {
        playerLayer.player = player?.player
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == #keyPath(AVPlayerLayer.isReadyForDisplay), (object as? AVPlayerLayer) == playerLayer {
            let newValue = change?[.newKey] as? Int
            playerLayer.isHidden = newValue == 0
        }
    }
    
}
