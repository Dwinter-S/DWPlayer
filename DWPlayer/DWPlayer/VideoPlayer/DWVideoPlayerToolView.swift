//
//  DWVideoPlayerswift
//  DWPlayer
//
//  Created by dwinters on 2023/4/19.
//

import UIKit

class DWVideoPlayerToolView: UIView {
    lazy var playBtn: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "play"), for: .normal)
        button.setImage(UIImage(named: "pause"), for: .selected)
        return button
    }()
    
    let loadingIndicator = UIActivityIndicatorView(style: .white)

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    func commonInit() {
        backgroundColor = UIColor.black.withAlphaComponent(0.4)
        addSubview(playBtn)
        addSubview(loadingIndicator)
        playBtn.dwc.addConstraints {
            $0.width.height.equalTo(40)
            $0.center.equalToSuperview()
        }
        loadingIndicator.dwc.addConstraints {
            $0.center.equalToSuperview()
        }
    }
    
    func setState(_ state: DWPlayer.State) {
        switch state {
        case .playing:
            playBtn.isSelected = true
            playBtn.isHidden = true
        case .paused:
            playBtn.isSelected = false
            playBtn.isHidden = false
        case .stopped:
            ()
        }
    }
    
    func setIsBuffering(_ isBuffering: Bool) {
        isBuffering ? loadingIndicator.startAnimating() : loadingIndicator.stopAnimating()
    }

}
