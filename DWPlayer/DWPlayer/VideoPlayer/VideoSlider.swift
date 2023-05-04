//
//  VideoSlider.swift
//  ieltsbro-ios-v4
//
//  Created by Sven on 2022/3/8.
//

import UIKit

class VideoSlider: UISlider {
    
    private let displayedThumbView = UIView()
    private var thumbWidth: CGFloat
    private var thumbColor: UIColor
    private var trackHeight: CGFloat
    private var hiddenedThumbView: UIView? {
        if #available(iOS 14, *) {
            return subviews.last?.subviews.last
        } else {
            guard subviews.count > 2 else { return nil }
            return subviews[2]
        }
    }
    
    init(thumbWidth: CGFloat, thumbColor: UIColor, trackHeight: CGFloat) {
        self.thumbWidth = thumbWidth
        self.thumbColor = thumbColor
        self.trackHeight = trackHeight
        super.init(frame: .zero)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        thumbWidth = 10
        thumbColor = .white
        trackHeight = 2
        super.init(coder: coder)
        commonInit()
    }
    
    func commonInit() {
        displayedThumbView.backgroundColor = thumbColor
        displayedThumbView.layer.cornerRadius = thumbWidth / 2
    }
    
    func updateStyle(thumbWidth: CGFloat, thumbColor: UIColor, trackHeight: CGFloat) {
        self.thumbWidth = thumbWidth
        self.thumbColor = thumbColor
        self.trackHeight = trackHeight
        displayedThumbView.backgroundColor = thumbColor
        displayedThumbView.layer.cornerRadius = thumbWidth / 2
        layoutIfNeeded()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        guard hiddenedThumbView != nil else {
            return
        }
        if displayedThumbView.superview == nil {
            hiddenedThumbView?.addSubview(displayedThumbView)
            displayedThumbView.dwc.addConstraints {
                $0.center.equalToSuperview()
                $0.width.height.equalTo(thumbWidth)
            }
        }
        if displayedThumbView.bounds.width != thumbWidth {
            displayedThumbView.dwc.updateConstraints {
                $0.width.height.equalTo(thumbWidth)
            }
        }
        
    }

    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }
    
    override func trackRect(forBounds bounds: CGRect) -> CGRect {
        let rect = super.trackRect(forBounds: bounds)
        return CGRect(x: rect.origin.x, y: rect.origin.y + (rect.height - trackHeight) / 2, width: rect.width, height: trackHeight)
    }
    
    override func thumbRect(forBounds bounds: CGRect, trackRect rect: CGRect, value: Float) -> CGRect {
        return super.thumbRect(forBounds: bounds, trackRect: rect, value: value)
    }
}
