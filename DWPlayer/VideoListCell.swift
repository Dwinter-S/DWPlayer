//
//  VideoListCell.swift
//  DWPlayer
//
//  Created by dwinters on 2023/4/19.
//

import UIKit

class VideoListCell: UITableViewCell {

    let playerView = ListVideoPlayerView()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        backgroundColor = .white
        contentView.addSubview(playerView)
        playerView.dwc.addConstraints {
            $0.edges.equalToSuperview()
        }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
