//
//  VideoListTableViewController.swift
//  DWPlayer
//
//  Created by dwinters on 2023/4/19.
//

import UIKit
import AVFoundation

class VideoListTableViewController: UITableViewController {
    
    let mp4URLs = ["http://ieltsbro.oss-cn-beijing.aliyuncs.com/apk/10.0.0/Emily-%E5%8F%A3%E8%AF%ADPart%201%E5%A6%82%E4%BD%95%E8%8E%B7%E5%BE%97%E8%80%83%E5%AE%98%E5%A5%BD%E6%84%9F.mp4",
                "http://ieltsbro.oss-cn-beijing.aliyuncs.com/apk/10.0.0/Emily-%E5%8F%A3%E8%AF%ADPart%201%E9%99%A4%E4%BA%86because%E8%BF%98%E8%83%BD%E5%A6%82%E4%BD%95%E6%8B%93%E5%B1%95.mp4",
                "https://static.ieltsbro.com/apk/10.0.0/%E5%8F%A3%E8%AF%AD%E5%BD%95%E8%AF%BE%EF%BC%9AP2%E4%B8%B2%E9%A2%98.mp4",
                "https://static.ieltsbro.com/apk/10.0.0/%E5%8F%A3%E8%AF%AD%E5%BD%95%E8%AF%BE%EF%BC%9AP2%E7%9A%84%E2%80%9C%E5%81%A5%E8%B0%88%E2%80%9D%E6%8A%80%E5%B7%A70827.mp4",
                "https://static.ieltsbro.com/apk/10.0.0/%E5%8F%A3%E8%AF%AD%E5%BD%95%E8%AF%BE%EF%BC%9A%E8%AF%8D%E6%B1%87%E5%A4%9A%E6%A0%B7%E6%80%A7FINALFINAL.mp4",
                "https://static.ieltsbro.com/apk/10.0.0/%E5%8F%A3%E8%AF%AD%E5%BD%95%E8%AF%BE%EF%BC%9AP3%E8%BE%A9%E8%AE%BA%E5%9E%8B%E9%97%AE%E9%A2%98FINALFINAL.mp4",
                "http://ieltsbro.oss-cn-beijing.aliyuncs.com/apk/10.0.0/Emily-%E5%8F%A3%E8%AF%ADPart%201%E7%AD%94%E9%A2%98%E6%80%9D%E8%B7%AF.mp4",
                "http://ieltsbro.oss-cn-beijing.aliyuncs.com/apk/10.0.0/Emily-%E5%8F%A3%E8%AF%AD%E8%B0%9A%E8%AF%AD.mp4",
                "http://ieltsbro.oss-cn-beijing.aliyuncs.com/apk/10.0.0/Annie-%E5%90%AC%E5%8A%9B%E5%9F%BA%E7%A1%80%E8%83%BD%E5%8A%9B%E6%8F%90%E5%8D%87%E6%96%B9%E6%B3%95.mp4",
                "http://ieltsbro.oss-cn-beijing.aliyuncs.com/apk/10.0.0/Annie-%E5%90%AC%E5%8A%9B%E5%A4%9A%E9%80%89%E9%A2%98.mp4",
                "http://ieltsbro.oss-cn-beijing.aliyuncs.com/apk/10.0.0/Annie-%E5%90%AC%E5%8A%9B%E6%B5%81%E7%A8%8B%E5%9B%BE.mp4",
                "http://ieltsbro.oss-cn-beijing.aliyuncs.com/apk/10.0.0/Annie-%E5%90%AC%E5%8A%9B%E8%A1%A8%E6%A0%BC%E9%A2%98.mp4",
                "http://ieltsbro.oss-cn-beijing.aliyuncs.com/apk/10.0.0/Annie-%E5%90%AC%E5%8A%9B%E6%84%8F%E7%BE%A4.mp4",
                "https://video.ieltsbro.com/8cb3a1cc34fa4fca8491628c40b0f71c/4493d0dbce9c486189920f288ba4d5ea-ea46f0a493bc3ae64067a35dab78407d-ld.m3u8", "http://ieltsbro.oss-cn-beijing.aliyuncs.com/apk/10.0.0/Annie-%E5%90%AC%E5%8A%9B%E5%A4%9A%E9%80%89%E9%A2%98.mp4"]
    
    let player = DWPlayer()
    
    private var curPlayingCell: VideoListCell?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        player.delegate = self
    }
    
    deinit {
        player.stop()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableViewDidScroll(tableView)
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return mp4URLs.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "videoCell", for: indexPath) as! VideoListCell

        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return tableView.bounds.width * 9 / 16
    }
    
    override func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if scrollView == tableView {
            if !decelerate {
                tableViewDidScroll(tableView)
            }
        }
    }
    override func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if scrollView == tableView {
            tableViewDidScroll(tableView)
        }
    }
    
    func tableViewDidScroll(_ tableView: UITableView) {
        guard tableView.contentOffset.y >= 0 else { return }
        let cells = tableView.visibleCells
        let midY = tableView.contentOffset.y + tableView.frame.size.height / 2
        
        if let curPlayingCell = curPlayingCell {
            if curPlayingCell.frame.maxY < tableView.contentOffset.y {
                curPlayingCell.playerView.setPlayer(nil)
            }
        }
        
        var playingCell: UITableViewCell?
        for cell in cells {
            if cell.frame.midY <= midY {
                playingCell = cell
            } else {
                break
            }
        }
        
        if let playingCell = playingCell as? VideoListCell {
            if let curPlayingCell = curPlayingCell, playingCell != curPlayingCell {
                curPlayingCell.playerView.setPlayer(nil)
            }
            playingCell.playerView.setPlayer(player)
            player.play(url: URL(string: mp4URLs[tableView.indexPath(for: playingCell)!.row])!)
            curPlayingCell = playingCell
        }
    }

}

extension VideoListTableViewController: DWPlayerDelegate {
    func startBuffering(_ playerItem: AVPlayerItem?) {
        curPlayingCell?.playerView.setIsBuffering(true)
    }
    
    func endBuffering(_ playerItem: AVPlayerItem?) {
        curPlayingCell?.playerView.setIsBuffering(false)
    }
    
    func didReadyToPlay(_ playerItem: AVPlayerItem?) {
        
    }
    
    func didFailPlay(_ playerItem: AVPlayerItem?, error: Error?) {
        
    }
    
    func playerItem(_ playerItem: AVPlayerItem?, durationDidLoad duration: CGFloat) {
        
    }
    
    func playerItem(_ playerItem: AVPlayerItem?, timeDidChanged time: CGFloat) {
        
    }
    
    func playerItem(_ playerItem: AVPlayerItem?, loadedTimeRangesChanged timeRanges: [CMTimeRange]) {
        
    }
    
    func playerItem(_ playerItem: AVPlayerItem?, stateDidChanged state: DWPlayer.State) {
        
    }
    
    func didPlayToEnd(_ playerItem: AVPlayerItem?) {
        
    }
    
}
