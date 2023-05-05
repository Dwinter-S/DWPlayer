//
//  ViewController.swift
//  DWPlayer
//
//  Created by dwinters on 2023/4/18.
//

import UIKit
import AVFoundation
import SQLite3

class ViewController: UIViewController {

    @IBOutlet weak var playBtn: UIButton!
    @IBOutlet weak var slider: UISlider!
    @IBOutlet weak var currentTimeLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var playerView: ListVideoPlayerView!
    
    @IBOutlet weak var mediaListTableView: UITableView!
    
    var rates: [Float] = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0]
    var curRateIndex = 2
    var curIndex = 0
    var isDraggingSlider = false
    
    let medias = MediaManager.shared.allMedias
    
    lazy var player = DWPlayer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupPlayer()
        setupSlider()
        test()
        MediaCache.default.diskCache.clearDiskCache()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        player.pause()
    }
    
    func setupPlayer() {
        playerView.setPlayer(player)
        player.delegate = self
    }
    
    func setupSlider() {
        slider.addTarget(self, action: #selector(startDraggingSlider), for: .touchDown)
        slider.addTarget(self, action: #selector(endDraggingSlider), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        slider.addTarget(self, action: #selector(sliderValueChanged), for: .valueChanged)
    }

    @IBAction func playNext(_ sender: Any) {
        let count = medias.count
        var nextIndex = curIndex + 1
        if nextIndex == count {
            nextIndex = 0
        }
        play(at: nextIndex)
    }
    
    @IBAction func playPre(_ sender: Any) {
        var preIndex = curIndex - 1
        if preIndex == -1 {
            preIndex = medias.count - 1
        }
        play(at: preIndex)
    }
    
    @IBAction func playOrPause(_ sender: Any) {
        if player.state == .paused {
            player.resume()
        } else {
            player.pause()
        }
    }
    
    @IBAction func switchRate(_ sender: UIButton) {
        if curRateIndex == rates.count - 1 {
            curRateIndex = 0
        } else {
            curRateIndex += 1
        }
        sender.setTitle("rate: \(rates[curRateIndex])", for: .normal)
        player.setRate(rates[curRateIndex])
    }
    
    func play(at index: Int) {
        let media = medias[index]
        guard let url = URL(string: media.url ?? "") else { return }
        curIndex = index
        player.play(url: url)
    }
    
    @objc func startDraggingSlider(_ slider: UISlider) {
        isDraggingSlider = true
    }
    
    @objc func endDraggingSlider(_ slider: UISlider) {
        player.seekTo(time: Double(slider.value)) { [weak self] _ in
            self?.isDraggingSlider = false
        }
    }
    
    @objc func sliderValueChanged(_ slider: UISlider) {
        currentTimeLabel.text = "\(formatSecondsToString(CGFloat(slider.value)))"
    }
    
    func test() {
        let sqlite3 = SQLite3()
        sqlite3.open(path: "/Users/xxxxx/test.sqlite3")

        sqlite3.exec("""
        CREATE TABLE T_TEST (
            IntField  INTEGER NOT NULL,
            TextField TEXT    NOT NULL,
            PRIMARY KEY (IntField)
        )
        """)

        sqlite3.prepare("INSERT INTO T_TEST VALUES (?, ?)")

        for i in 1...5 {
            sqlite3.bindInt(index: 1, value: i)
            sqlite3.bindText(index: 2, value: String("number\(i)"))

            if sqlite3.step() != SQLITE_DONE {
                print("error: INSERT")
            }

            sqlite3.resetStatement()
        }

        sqlite3.prepare("SELECT * FROM T_TEST WHERE IntField > ?")
        sqlite3.bindInt(index: 1, value: 3)

        while sqlite3.step() == SQLITE_ROW {
            let intField = sqlite3.columnInt(index: 0)
            let textField = sqlite3.columnText(index: 1)
            print("IntField:\(intField), TextField:\(textField)")
        }

        sqlite3.close()
    }
    
}

extension ViewController: DWPlayerDelegate {
    func startBuffering(_ playerItem: AVPlayerItem?) {
        playerView.setIsBuffering(true)
    }
    
    func endBuffering(_ playerItem: AVPlayerItem?) {
        playerView.setIsBuffering(false)
    }
    
    func didReadyToPlay(_ playerItem: AVPlayerItem?) {
        
    }
    
    func didFailPlay(_ playerItem: AVPlayerItem?, error: Error?) {
        
    }
    
    func playerItem(_ playerItem: AVPlayerItem?, durationDidLoad duration: CGFloat) {
        durationLabel.text = "\(formatSecondsToString(duration))"
        slider.maximumValue = Float(duration)
    }
    
    func playerItem(_ playerItem: AVPlayerItem?, timeDidChanged time: CGFloat) {
        if !isDraggingSlider {
            currentTimeLabel.text = "\(formatSecondsToString(time))"
            slider.value = Float(time)
        }
    }
    
    func playerItem(_ playerItem: AVPlayerItem?, loadedTimeRangesChanged timeRanges: [CMTimeRange]) {
        
    }
    
    func playerItem(_ playerItem: AVPlayerItem?, stateDidChanged state: DWPlayer.State) {
        playBtn.setTitle(state == .playing ? "pasue" : "play", for: .normal)
    }
    
    func didPlayToEnd(_ playerItem: AVPlayerItem?) {
        
    }
}

func timing(_ closure: () -> ()) -> Double {
    let start = CFAbsoluteTimeGetCurrent()
    closure()
    print("用时：\(CFAbsoluteTimeGetCurrent() - start)")
    return CFAbsoluteTimeGetCurrent() - start
}

extension ViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return medias.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Playback List"
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "mediaInfo", for: indexPath) as! MediaListCell
        let media = medias[indexPath.row]
        cell.setMediaInfo(media)
        cell.titleLabel.textColor = curIndex == indexPath.row ? .red : .black
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        play(at: indexPath.row)
        tableView.reloadData()
    }
}
