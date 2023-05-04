//
//  VideoPlayerView.swift
//  DWPlayer
//
//  Created by dwinters on 2023/4/23.
//

import UIKit

class VideoPlayerView: DWVideoPlayerView {
    
    let toolView = DWVideoPlayerToolView()

    override func commonInit() {
        super.commonInit()
        
        addSubview(toolView)
        toolView.dwc.addConstraints {
            $0.edges.equalToSuperview()
        }
    }

}
