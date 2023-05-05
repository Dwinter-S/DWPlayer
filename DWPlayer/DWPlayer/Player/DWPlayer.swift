//
//  DWPlayer.swift
//  DWPlayer
//
//  Created by dwinters on 2023/4/18.
//

import Foundation
import AVFoundation
import MediaPlayer

protocol DWPlayerDelegate: AnyObject {
    func didReadyToPlay(_ playerItem: AVPlayerItem?)
    func didFailPlay(_ playerItem: AVPlayerItem?, error: Error?)
    func playerItem(_ playerItem: AVPlayerItem?, durationDidLoad duration: CGFloat)
    func playerItem(_ playerItem: AVPlayerItem?, timeDidChanged time: CGFloat)
    func playerItem(_ playerItem: AVPlayerItem?, loadedTimeRangesChanged timeRanges:[CMTimeRange])
    func playerItem(_ playerItem: AVPlayerItem?, stateDidChanged state: DWPlayer.State)
    func startBuffering(_ playerItem: AVPlayerItem?)
    func endBuffering(_ playerItem: AVPlayerItem?)
    func didPlayToEnd(_ playerItem: AVPlayerItem?)
}

class DWPlayer: NSObject {
    
    enum State {
        case playing
        case paused
        case stopped
        
        var name: String {
            switch self {
            case .playing: return "播放"
            case .paused: return "暂停"
            case .stopped: return "停止"
            }
        }
    }
    
    var currentTime: Double {
        let timeSecond = CMTimeGetSeconds(player.currentTime())
        return timeSecond
    }
    
    var assetURL: URL? {
        return (player.currentItem?.asset as? AVURLAsset)?.url
    }
    
    var isLooping: Bool = false
    
    weak var delegate: DWPlayerDelegate?
    
    private(set) var state: State = .stopped {
        didSet {
            invokeOnMainThread {
                self.delegate?.playerItem(self.player.currentItem, stateDidChanged: self.state)
            }
        }
    }
    private(set) var duration: Double = 0
    private(set) var currentRate: Float = 0
    private(set) var player = AVPlayer()
    
    private var playerItemContext = 0
    private var playerContext = 1
    private var timeObserver: Any?
    private var rate: Float = 1
    private var isPlayToEnd: Bool {
        return currentTime == duration
    }
    private var loadedTimeRanges: [CMTimeRange] = []
    private var playThrottler = Throttler(seconds: 0.5)
//    private let requiredAssetKeys = [
//        "playable",
//        "hasProtectedContent"
//    ]
    
    override init() {
        super.init()
        setupPlayer()
        setupRemoteTransportControls()
    }
    
    deinit {
        removeTimeObserver()
        removePlayerObservers()
        if let playerItem = player.currentItem {
            removePlayerItemObserver(for: playerItem)
        }
    }
    
    private func replacePlayerItem(with playerItem: AVPlayerItem?) {
        if let preItem = player.currentItem {
            removePlayerItemObserver(for: preItem)
        }
        if let currentItem = playerItem {
            addPlayerItemObserver(for: currentItem)
            delegate?.startBuffering(currentItem)
        } else {
            state = .stopped
        }
        loadedTimeRanges = []
        player.replaceCurrentItem(with: playerItem)
    }
    
    private func setupPlayer() {
        player.actionAtItemEnd = .pause
        addTimeObserver()
        addPlayerObservers()
    }
    
    private func resetPlayer() {
        removeTimeObserver()
        removePlayerObservers()
        if let playerItem = player.currentItem {
            removePlayerItemObserver(for: playerItem)
        }
        player = AVPlayer()
        setupPlayer()
    }
    
    // MARK: - Observers
    private func addPlayerObservers() {
        player.addObserver(self, forKeyPath: #keyPath(AVPlayer.status), options: .new, context: &playerContext)
        player.addObserver(self, forKeyPath: #keyPath(AVPlayer.timeControlStatus), options: .new, context: &playerContext)
        player.addObserver(self, forKeyPath: #keyPath(AVPlayer.reasonForWaitingToPlay), options: .new, context: &playerContext)
        player.addObserver(self, forKeyPath: #keyPath(AVPlayer.rate), options: .new, context: &playerContext)
    }
    
    private func removePlayerObservers() {
        player.removeObserver(self, forKeyPath: #keyPath(AVPlayer.timeControlStatus), context: &playerContext)
        player.removeObserver(self, forKeyPath: #keyPath(AVPlayer.reasonForWaitingToPlay), context: &playerContext)
        player.removeObserver(self, forKeyPath: #keyPath(AVPlayer.status), context: &playerContext)
        player.removeObserver(self, forKeyPath: #keyPath(AVPlayer.rate), context: &playerContext)
    }
    
    private func addPlayerItemObserver(for playerItem: AVPlayerItem) {
        playerItem.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), options: [.old, .new], context: &playerItemContext)
        playerItem.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.duration), options: .new, context: &playerItemContext)
        playerItem.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.loadedTimeRanges), options: .new, context: &playerItemContext)
        playerItem.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.isPlaybackLikelyToKeepUp), options: .new, context: &playerItemContext)
        playerItem.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.isPlaybackBufferEmpty), options: .new, context: &playerItemContext)
        NotificationCenter.default.addObserver(self, selector: #selector(playerItemDidPlayToEndTime), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: playerItem)
        NotificationCenter.default.addObserver(self, selector: #selector(playerItemNewErrorLog), name: NSNotification.Name.AVPlayerItemNewErrorLogEntry, object: playerItem)
        NotificationCenter.default.addObserver(self, selector: #selector(playerItemFailedToPlayToEndTime), name: NSNotification.Name.AVPlayerItemFailedToPlayToEndTime, object: playerItem)
        
    }
    
    private func removePlayerItemObserver(for playerItem: AVPlayerItem) {
        playerItem.cancelPendingSeeks()
        playerItem.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), context: &playerItemContext)
        playerItem.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.duration), context: &playerItemContext)
        playerItem.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.loadedTimeRanges), context: &playerItemContext)
        playerItem.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.isPlaybackLikelyToKeepUp), context: &playerItemContext)
        playerItem.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.isPlaybackBufferEmpty), context: &playerItemContext)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: playerItem)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVPlayerItemNewErrorLogEntry, object: playerItem)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVPlayerItemFailedToPlayToEndTime, object: playerItem)
    }
    
    private func addTimeObserver() {
        removeTimeObserver()
        let interval = CMTime(seconds: 0.1, preferredTimescale: 10)
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self = self else { return }
            let timeSecond = CMTimeGetSeconds(time)
            self.delegate?.playerItem(self.player.currentItem, timeDidChanged: timeSecond)
        }
    }
    
    private func removeTimeObserver() {
        guard let observer = timeObserver else { return }
        player.removeTimeObserver(observer)
        timeObserver = nil
    }
    
    private func setupRemoteTransportControls() {
        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.playCommand.addTarget { [unowned self] event in
            if self.player.rate == 0.0 {
                self.play()
                return .success
            }
            return .commandFailed
        }
        
        commandCenter.pauseCommand.addTarget { [unowned self] event in
            if self.player.rate == 1.0 {
                self.player.pause()
                return .success
            }
            return .commandFailed
        }
    }
    
    private func setAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            if audioSession.category != .playAndRecord {
                try audioSession.setCategory(AVAudioSession.Category.playAndRecord, options: [.defaultToSpeaker, .allowBluetooth, .allowBluetoothA2DP])
            }
            try audioSession.setActive(true)
        } catch { }
    }
    
    @objc private func playerItemDidPlayToEndTime(notification: Notification) {
        guard let playerItem = notification.object as? AVPlayerItem else {
            return
        }
        delegate?.didPlayToEnd(playerItem)
        if isLooping {
            replay()
        }
    }
    
    @objc private func playerItemNewErrorLog(notification: Notification) {
        guard let playerItem = notification.object as? AVPlayerItem else {
            return
        }
        guard let errorLog: AVPlayerItemErrorLog = playerItem.errorLog() else {
            return
        }
        for event in errorLog.events {
            print("AVPlayerItemErrorLog: \(event.errorComment ?? "")")
        }
    }
    
    @objc private func playerItemFailedToPlayToEndTime(notification: Notification) {
        if let error = notification.userInfo?["AVPlayerItemFailedToPlayToEndTimeErrorKey"] as? NSError {
            let errorInfo = "AVPlayerItemFailedToPlayToEndTimeError: \(error.description)"
            print(errorInfo)
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard let keyPath = keyPath, let change = change else { return }
        let newValue = change[.newKey]
        print("????????\(keyPath) \(newValue)")
        if context == &playerItemContext {
            if keyPath == #keyPath(AVPlayerItem.duration) {
                if let newDuration = newValue as? CMTime {
                    let seconds = CMTimeGetSeconds(newDuration)
                    if !seconds.isNaN {
                        duration = seconds
                        delegate?.playerItem(player.currentItem, durationDidLoad: seconds)
                    }
                }
            }
            
            if keyPath == #keyPath(AVPlayerItem.status) {
                if let newValue = newValue as? Int,
                   let newStatus = AVPlayerItem.Status(rawValue: newValue) {
                    switch newStatus {
                    case .unknown: ()
                    case .readyToPlay:
                        delegate?.didReadyToPlay(player.currentItem)
                        play()
                    case .failed:
                        var error: Error
                        if let err = player.currentItem?.error {
                            error = err
                        } else {
                            error = NSError(domain: "kDMPlayerErrorDomain", code: 0, userInfo: [NSLocalizedDescriptionKey : "unknown player error, status == AVPlayerItemStatusFailed"])
                        }
                        let nserror = error as NSError
                        let errorInfo = "playerItemError: description = \(nserror.description)"
                        print("Video playerItem Status Failed: error = \(errorInfo)")
                        delegate?.didFailPlay(player.currentItem, error: nserror)
                    @unknown default: ()
                    }
                }
            }
            
            if keyPath == #keyPath(AVPlayerItem.loadedTimeRanges) {
                if let loadedTimeRanges = newValue as? [CMTimeRange] {
                    for timeRange in loadedTimeRanges where timeRange.duration != .zero {
                        self.addLoadedTimeRange(timeRange)
                    }
                    for timeRange in self.loadedTimeRanges {
                        print("loadedTimeRanges:(\(formatSecondsToString(timeRange.start.seconds, isDisplayHour: false))-\(formatSecondsToString(timeRange.end.seconds, isDisplayHour: false))) ")
                    }
                }
                delegate?.playerItem(player.currentItem, loadedTimeRangesChanged: player.currentItem?.loadedTimeRanges.map({ $0.timeRangeValue }) ?? [])
            }
            
            if keyPath == #keyPath(AVPlayerItem.isPlaybackBufferEmpty) {
//                delegate?.startBuffering(player.currentItem)
            }
            
            if keyPath == #keyPath(AVPlayerItem.isPlaybackLikelyToKeepUp) {
                if let isPlaybackLikelyToKeepUp = newValue as? Bool {
                    if isPlaybackLikelyToKeepUp {
                        delegate?.endBuffering(player.currentItem)
                        if state == .playing {
                            player.playImmediately(atRate: self.rate)
                        }
                    } else {
                        delegate?.startBuffering(player.currentItem)
                    }
                }
            }
        } else if context == &playerContext {
            if keyPath == #keyPath(AVPlayer.timeControlStatus) ||
                keyPath == #keyPath(AVPlayer.reasonForWaitingToPlay) {
                var newState: State?
                switch player.timeControlStatus {
                case .playing:
                    newState = .playing
                case .paused:
                    // 当automaticallyWaitsToMinimizeStalling 为 false时，isPlaybackBufferEmpty为true时timeControlStatus会变为paused，这时候界面显示为缓冲
                    if player.currentItem?.isPlaybackLikelyToKeepUp == false {
                        delegate?.startBuffering(player.currentItem)
                    } else {
                        newState = .paused
                    }
                default: ()
                }
                if let newState = newState, newState != state {
                    state = newState
                }
            }
            if keyPath == #keyPath(AVPlayer.rate) {
                currentRate = player.rate
            }
            if keyPath == #keyPath(AVPlayer.status) {
                if let newValue = newValue as? Int,
                   let newStatus = AVPlayer.Status(rawValue: newValue) {
                    if newStatus == .failed {
                        resetPlayer()
                    }
                }
            }
        }
    }
    
    private func addLoadedTimeRange(_ timeRange: CMTimeRange) {
        var loadedTimeRanges = self.loadedTimeRanges
        let startIndex = loadedTimeRanges.firstIndex(where: { $0.intersection(timeRange).duration != .zero || $0.end == timeRange.start })
        let endIndex = loadedTimeRanges.lastIndex(where: { $0.intersection(timeRange).duration != .zero || $0.start == timeRange.end })
        if startIndex == nil && endIndex == nil {
            let insertIndex = loadedTimeRanges.firstIndex(where: { timeRange.start > $0.end }) ?? 0
            loadedTimeRanges.insert(timeRange, at: insertIndex)
        } else {
            let replaceSubrange = (startIndex ?? endIndex!)...(endIndex ?? startIndex!)
            var unionRange = timeRange
            for range in loadedTimeRanges[replaceSubrange] {
                unionRange = unionRange.union(range)
            }
            loadedTimeRanges.replaceSubrange(replaceSubrange, with: [unionRange])
        }
        self.loadedTimeRanges = loadedTimeRanges.sorted(by: { $0.start < $1.start })
    }
    // MARK: - Player Operation

    /// Play media resource from URL
    /// - Parameter url: An instance of URL that references a media resource.
    func play(url: URL) {
        playThrottler.invoke { [weak self] in
            guard let self = self else { return }
            self.setAudioSession()
            var playerItem: AVPlayerItem
            if !url.isFileURL {
                self.player.automaticallyWaitsToMinimizeStalling = false
                let cachingPlayerItem = CachingPlayerItem(url: url)
                playerItem = cachingPlayerItem
            } else {
                self.player.automaticallyWaitsToMinimizeStalling = true
                let asset = AVURLAsset(url: url)
                playerItem = AVPlayerItem(asset: asset)
            }
            playerItem.audioTimePitchAlgorithm = .timeDomain
            self.replacePlayerItem(with: playerItem)
        }
    }
    
    func resume() {
        guard let currentItem = player.currentItem, currentItem.status == .readyToPlay, state == .paused else {
            return
        }
        if isPlayToEnd {
            replay()
        } else {
            play()
        }
    }
    
    private func play() {
        guard let currentItem = player.currentItem, currentItem.status == .readyToPlay else {
            return
        }
        if rate == 1 ||
            (rate > 1 && currentItem.canPlayFastForward) ||
            (rate < 1 && currentItem.canPlaySlowForward) {
            invokeOnMainThread {
                if self.state == .playing {
                    self.player.rate = self.rate
                } else {
                    self.player.playImmediately(atRate: self.rate)
                }
            }
        }
    }
    
    func pause() {
        guard let currentItem = player.currentItem, currentItem.status == .readyToPlay, state == .playing else {
            return
        }
        invokeOnMainThread {
            self.player.pause()
        }
    }
    
    func stop() {
        replacePlayerItem(with: nil)
    }
    
    func replay() {
        seekTo(time: 0, completionHandler: { [weak self] _ in
            self?.play()
        })
    }
    
    func setRate(_ rate: Float) {
        self.rate = rate
        guard let _ = player.currentItem, state == .playing else { return }
        play()
    }
    
    func duration(with urlString: String?) -> Double {
        guard let urlString = urlString else { return 0 }
        var asset: AVURLAsset
        let dic = [AVURLAssetPreferPreciseDurationAndTimingKey : false]
        if urlString.hasPrefix("http://") || urlString.hasPrefix("https://") {
            if let url = URL(string: urlString) {
                asset = AVURLAsset(url: url, options: dic)
            } else {
                return 0
            }
        } else {
            asset = AVURLAsset(url: URL(fileURLWithPath: urlString), options: dic)
        }
        let duration = asset.duration
        let seconds = CMTimeGetSeconds(duration)
        guard seconds.isNormal else {
            return 0
        }
        return seconds
    }
    
    /// seek到指定位置
    /// - Parameter time: seek到的时间
    /// - Parameter isAutoPlay: 是否seek后自动播放
    /// - Parameter completionHandler: seek完成后的回调
    func seekTo(time: Double, isAutoPlay: Bool = false, completionHandler: ((Bool) -> Void)? = nil) {
        let cmTime = CMTime(seconds: time, preferredTimescale: 600)
        guard let playerItem = player.currentItem,
              playerItem.status == .readyToPlay,
              cmTime.isValid else {
            return
        }
        if !self.canSeekToWithoutStall(cmTime) {
            delegate?.startBuffering(playerItem)
        }
        player.seek(to: cmTime, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero) { [weak self] finished in
            guard let self = self else { return }
            completionHandler?(finished)
            print("seekTo:\(time) finished\(finished)")
            if finished {
                if isAutoPlay  {
                    self.play()
                }
            }
        }
    }
    
    private func canSeekToWithoutStall(_ time: CMTime) -> Bool {
        return loadedTimeRanges.first(where: { $0.containsTime(time) }) != nil
    }
    
}

func invokeOnMainThread(_ closure: @escaping () -> ()) {
    if Thread.isMainThread {
        closure()
    } else {
        DispatchQueue.main.async {
            closure()
        }
    }
}

func formatSecondsToString(_ seconds: CGFloat, isDisplayHour: Bool = true) -> String {
    if seconds.isNaN {
        return isDisplayHour ? "00:00:00" : "00:00"
    }
    if isDisplayHour {
        let hour = Int(seconds / 3600)
        let min = Int(seconds / 60) % 60
        let sec = Int(seconds.truncatingRemainder(dividingBy: 60))
        return String(format: "%02d:%02d:%02d", hour, min, sec)
    } else {
        let min = Int(seconds / 60)
        let sec = Int(seconds.truncatingRemainder(dividingBy: 60))
        return String(format: "%02d:%02d", min, sec)
    }
}
