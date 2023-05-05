//
//  MediaListCell.swift
//  DWPlayer
//
//  Created by dwinters on 2023/5/5.
//

import UIKit

class MediaListCell: UITableViewCell {

    lazy var titleLabel: UILabel = {
        let lb = UILabel()
        lb.textColor = .black
        lb.font = .systemFont(ofSize: 16)
        return lb
    }()
    let cacheProgresssView = CacheProgresssView()
    private var media: Media?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        cacheProgresssView.backgroundColor = .lightGray
        contentView.addSubview(titleLabel)
        contentView.addSubview(cacheProgresssView)
        titleLabel.dwc.addConstraints {
            $0.top.left.right.equalToSuperview().insets(10)
        }
        cacheProgresssView.dwc.addConstraints {
            $0.top.equalTo(titleLabel.dwc.bottom).offset(10)
            $0.left.right.bottom.equalToSuperview().insets(10)
            $0.height.equalTo(3)
        }
        NotificationCenter.default.addObserver(self, selector: #selector(cachedRangesChanged), name: .CachedPercentRangesDidChanged, object: nil)
    }
    
    func setMediaInfo(_ media: Media) {
        self.media = media
        titleLabel.text = "\(media.name ?? "")(\(media.type))"
        if let url = URL(string: media.url ?? ""),
            let cacheInfo = MediaCache.default.localCache(with: url) {
            cacheProgresssView.setCacheRanges(cacheInfo.cachedPercentRanges)
        } else {
            cacheProgresssView.setCacheRanges([])
        }
    }
    
    @objc func cachedRangesChanged(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let url = userInfo["url"] as? String, url == media?.url, let ranges = userInfo["ranges"] as? [Range<CGFloat>] else {
            return
        }
        cacheProgresssView.setCacheRanges(ranges)
    }

}

class CacheProgresssView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    func commonInit() {
        
    }
    
    
    
    func setCacheRanges(_ ranges: [Range<CGFloat>]) {
        subviews.forEach({ $0.removeFromSuperview() })
        for range in ranges {
            let view = UIView()
            view.backgroundColor = .red
            addSubview(view)
            let left = bounds.width * range.lowerBound
            let fragmentWidth = bounds.width * (range.upperBound - range.lowerBound)
            view.frame = CGRect(x: left, y: 0, width: fragmentWidth, height: bounds.height)
        }
    }
}
