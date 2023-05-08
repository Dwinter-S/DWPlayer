//
//  ListVideoPlayerView.swift
//  DWPlayer
//
//  Created by dwinters on 2023/4/23.
//

import UIKit

class ListVideoPlayerView: DWVideoPlayerView {

    let loadingIndicator = UIActivityIndicatorView(style: .white)
    
    override func commonInit() {
        super.commonInit()
        loadingIndicator.color = .red
        addSubview(loadingIndicator)
        loadingIndicator.dwc.addConstraints {
            $0.center.equalToSuperview()
        }
    }
    
    func setIsBuffering(_ isBuffering: Bool) {
        isBuffering ? loadingIndicator.startAnimating() : loadingIndicator.stopAnimating()
    }

}
