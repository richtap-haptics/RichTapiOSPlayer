//
//  ViewController.swift
//  RichTapVideoPlayer
//
//  Created by RichTap-coder on 2022/6/1.
//

import UIKit
import AVFoundation
class ViewController: UIViewController {

    var playView : RSPlayer!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        //创建播放器
        playView = RSPlayer.init(frame: CGRect.init(x: 0, y: 0, width: ScreenWidth, height: ScreenHeight))
        self.view.addSubview(playView)
    }
    
    deinit {
        // If use the slide to back, remember to call this method
        // 销毁播放器
        playView.playerDealloc()
    }

}

