//
//  TradeCACertificationPlayViewController.swift
//  FutureBull
//
//  Created by IronMan on 2021/1/20.
//  Copyright © 2021 wuyanwei. All rights reserved.
//

import UIKit
import AVKit
class TradeCACertificationPlayViewController: AVPlayerViewController {
    var avPlayer: AVPlayer!
    override func viewDidLoad() {
        super.viewDidLoad()
        playVideo()
    }
    
    func playVideo() {
        let filepath: String? = NSHomeDirectory() + "/Documents" + "/ca_certification.mp4"
        let fileURL = URL.init(fileURLWithPath: filepath!)
        
        avPlayer = AVPlayer(url: fileURL)
        self.player = avPlayer
        self.view.frame = CGRect(x: 0, y: kNavFrameH, width: kScreenW, height: kScreenH - kNavFrameH)
        self.showsPlaybackControls = true
        self.player?.play()
    }
}
