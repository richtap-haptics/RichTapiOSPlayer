//
//  RSPlayer.swift
//  RichTapVideoPlayer
//
//  Created by RichTap-coder on 2022/6/1.
//


import UIKit
import AVFoundation

class RSPlayer: UIView {
    
    /** playerLayer */
    var playerLayer : AVPlayerLayer!
    /** player */
    var player : AVPlayer!
    /** playerItem */
    var playerItem : AVPlayerItem!
    /** 播放进度条 */
    var playTimeSlider : UISlider!
    /** 播放时间 */
    var timeLabel : UILabel!
    /** 总时间 */
    var allTimeLabel : UILabel!
    /** 播放*/
    var playOrPauseBtn : UIButton!
    /** 暂停*/
    var stopBtn : UIButton!
    /** rate滑动条 */
    var playRateSlider : UISlider!
    /** 最小rate */
    var minRateLabel : UILabel!
    /** 最大rate */
    var maxRateLabel : UILabel!
    /** currentRate */
    var currentRateLabel : UILabel!
    /** slider定时器 */
    var progressTimer : Timer!
    // 记录播放结束
    var isPlayEnd : Bool = false
    // 当前Rate，默认1.0
    var currentRate : Float = 1.0
    // 当前振动Id
    var playId = 0

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.defaultBackgroundColor
        // 初始化player和playerLayer
        self.initPlayerConfig()
        // view布局
        self.viewLayout()
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /** 监听播放状态 */
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        let playerItem = object as! AVPlayerItem
        if keyPath == "status" {
            if playerItem.status == .readyToPlay {
                
            } else {
                
            }
        }
    }
    
    func setupTimer() {
        progressTimer?.invalidate()
        progressTimer = Timer.scheduledTimer(timeInterval: 0.002, target: self, selector: #selector(updateProgressInfo), userInfo: nil, repeats: true)
        progressTimer?.fireDate = Date()
    }
    
    // 开始播放
    func startPlay() {
        player.play()
        player.rate = currentRate
        setupTimer()
        // RichTap SDK会根据播放器时间进行同步，需要在回调中传入播放器的当前时间
        var error: NSError?
        playId = RichTapHapticUtils.playHaptic(Bundle.main.path(forResource: "richlogo", ofType: "he")!, amplitude: 255, freq: 0, playProgress: {
            if (self.player != nil) {
                return CMTimeGetSeconds((self.player!.currentTime()))
            } else {
                return 0
            }
        }, error: &error)
        if error != nil {
            print("error = \(error.debugDescription)")
        }
        // 设置RichTap SDK的播放rate，与播放器保持一致
        do {
            try RichTapHapticUtils.setSpeed(currentRate, playID: playId)
        } catch {
        }
    }
    
    // 停止播放
    func stopPlay() {
        player.pause()
        playOrPauseBtn.isSelected = false
        playOrPauseBtn.setTitle("Play", for: .normal)
        progressTimer.fireDate = Date.distantFuture
        isPlayEnd = true
        // 播放完毕后需要停止振动，再次播放重新开启
        do {
            try RichTapHapticUtils.stop(playId)
        } catch {
        }
        
    }

    /** 更新slider和timeLabel */
    @objc func updateProgressInfo() {
        guard let playerItem = playerItem else { return }
        // 视频当前的播放进度
        if playerItem.duration.timescale != 0 {
            let currentTime = CMTimeGetSeconds(self.player!.currentTime())
            let totalTime = TimeInterval(playerItem.duration.value) / TimeInterval(playerItem.duration.timescale)
            playTimeSlider.value = Float(currentTime) / Float(totalTime)
            timeLabel.text = self.timeToStringWithTimeInterval(interval: currentTime) as String
            allTimeLabel.text = self.timeToStringWithTimeInterval(interval: totalTime) as String
        }
    }
    
    /** 转换播放时间和总时间的方法 */
    func timeToStringWithTimeInterval(interval: TimeInterval) -> NSString {
        let min = interval / 60
        let sec = interval.truncatingRemainder(dividingBy: 60)
        let intervalString = NSString.init(format: "%02.0f:%02.0f", min,sec)
        return intervalString as NSString
    }

    /** 移除slider定时器 */
    func removeProgressTimer() {
        progressTimer.fireDate = Date.distantFuture // 暂停timer
        // 销毁定时器
        guard let aTimer = self.progressTimer else {
            return
        }
        aTimer.invalidate()
    }
    
    /** 移除和销毁播放器 */
    func playerDealloc() {
        playerItem.removeObserver(self, forKeyPath: "status")
        self.removeProgressTimer()
        player.pause()
        playerLayer.removeFromSuperlayer()
        self.removeFromSuperview()
    }
}

//MARK: init ui PlayerConfig
extension RSPlayer {
    
    func viewLayout() {
        
        playerLayer.frame = CGRect.init(x: 0, y: 100, width: self.width, height: 200)
        // 添加playerLayer
        self.layer.addSublayer(playerLayer)
        
        timeLabel = UILabel.init(frame: CGRect.init(x: 0, y: 320, width: 56, height: 30))
        timeLabel.font = UIFont.systemFont(ofSize: 14)
        timeLabel.textAlignment = .center
        timeLabel.textColor = UIColor.gray
        timeLabel.text = "00:00"
        self.addSubview(timeLabel)
        
        allTimeLabel = UILabel.init(frame: CGRect.init(x: self.width-timeLabel.width, y: timeLabel.top, width: timeLabel.width, height: timeLabel.height))
        allTimeLabel.font = UIFont.systemFont(ofSize: 14)
        allTimeLabel.textColor = UIColor.gray
        allTimeLabel.text = "00:00"
        allTimeLabel.textAlignment = .center
        self.addSubview(allTimeLabel)

        playTimeSlider = UISlider.init(frame: CGRect.init(x: timeLabel.right, y: timeLabel.top, width: self.width-timeLabel.right-allTimeLabel.width, height: timeLabel.height))
        playTimeSlider.tintColor = UIColor.themeColor
        playTimeSlider.addTarget(self, action: #selector(touchDownPlayTimeSlider(sender:)), for: .touchDown)
        playTimeSlider.addTarget(self, action: #selector(valueChangedPlayTimeSlider(sender:)), for: .valueChanged)
        playTimeSlider.addTarget(self, action: #selector(playTimeSliderTouchUpInside(sender:)), for: .touchUpInside)
        self.addSubview(playTimeSlider)
 
        playOrPauseBtn = UIButton.init(type: .custom)
        playOrPauseBtn.frame = CGRect.init(x: self.width/2 - 85, y: allTimeLabel.bottom + 10, width: 80, height: 40)
        playOrPauseBtn.setTitle("Play", for: .normal)
        playOrPauseBtn.backgroundColor = UIColor.themeColor
        playOrPauseBtn.layer.masksToBounds = true
        playOrPauseBtn.layer.cornerRadius = 5
        playOrPauseBtn.addTarget(self, action: #selector(playOrPauseBtnClick(sender:)), for: .touchUpInside)
        self.addSubview(playOrPauseBtn)
        
        stopBtn = UIButton.init(type: .custom)
        stopBtn.frame = CGRect.init(x: self.width/2 + 5, y: playOrPauseBtn.top, width: 80, height: 40)
        stopBtn.setTitle("Stop", for: .normal)
        stopBtn.backgroundColor = UIColor.themeColor
        stopBtn.layer.masksToBounds = true
        stopBtn.layer.cornerRadius = 5
        stopBtn.addTarget(self, action: #selector(stopBtnClick(sender:)), for: .touchUpInside)
        self.addSubview(stopBtn)
        
        minRateLabel = UILabel.init(frame: CGRect.init(x: 0, y: playOrPauseBtn.bottom+30, width: 80, height: 30))
        minRateLabel.font = UIFont.systemFont(ofSize: 14)
        minRateLabel.textColor = UIColor.gray
        minRateLabel.textAlignment = .center
        minRateLabel.text = "Speed:0.5X"
        self.addSubview(minRateLabel)
        
        maxRateLabel = UILabel.init(frame: CGRect.init(x: self.width-50, y: minRateLabel.top, width: 50, height: minRateLabel.height))
        maxRateLabel.font = UIFont.systemFont(ofSize: 14)
        maxRateLabel.textColor = UIColor.gray
        maxRateLabel.textAlignment = .center
        maxRateLabel.text = "2.0X"
        self.addSubview(maxRateLabel)
        
        currentRateLabel = UILabel.init(frame: CGRect.init(x: minRateLabel.left, y: minRateLabel.bottom, width: 80, height: minRateLabel.height))
        currentRateLabel.font = UIFont.systemFont(ofSize: 14)
        currentRateLabel.textColor = UIColor.gray
        currentRateLabel.textAlignment = .center
        currentRateLabel.text = "1.0X"
        self.addSubview(currentRateLabel)
        
        playRateSlider = UISlider.init(frame: CGRect.init(x: minRateLabel.right, y: minRateLabel.top, width: self.width-minRateLabel.right-maxRateLabel.width, height: minRateLabel.height))
        playRateSlider.maximumValue = 2
        playRateSlider.minimumValue = 0.5
        playRateSlider.tintColor = UIColor.themeColor
        playRateSlider.addTarget(self, action: #selector(valueChangedPlayRateSlider(sender:)), for: .valueChanged)
        self.addSubview(playRateSlider)
    }
    
    func initPlayerConfig() {
        playerItem = AVPlayerItem.init(url: URL.init(fileURLWithPath: Bundle.main.path(forResource: "richlogo", ofType: "mp4")!))
        playerItem.addObserver(self, forKeyPath: "status", options: .new, context: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(moviePlayDidEnd),
                                               name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
                                               object: playerItem)
        
        player = AVPlayer.init(playerItem: playerItem)
        playerLayer = AVPlayerLayer.init(player: player)
        playerLayer.videoGravity = .resize
    }
}

//MARK: related click methods
extension RSPlayer {
    /** playTimeSlider拖动和点击事件 */
    @objc func touchDownPlayTimeSlider(sender: UISlider) {
        progressTimer.fireDate = Date.distantFuture
    }
    
    @objc func valueChangedPlayTimeSlider(sender: UISlider) {
        // 计算slider拖动的点对应的播放时间
        let currentTime = CMTimeGetSeconds((player.currentItem?.duration)!) * Double(sender.value)
        timeLabel.text = self.timeToStringWithTimeInterval(interval: currentTime) as String
    }
    
    @objc func playTimeSliderTouchUpInside(sender: UISlider) {
        progressTimer.fireDate = Date.distantPast
        // 计算当前slider拖动对应的播放时间
        let currentTime = CMTimeGetSeconds((player.currentItem?.duration)!) * 1000 * Double(sender.value)
        // 播放器跳到新的时间点
        self.player.seek(to: CMTimeMakeWithSeconds(currentTime, preferredTimescale: Int32(NSEC_PER_SEC)), toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero) {
            [unowned self] (isFinish) in
            if isFinish{
                self.player.play()
                self.player.rate = self.currentRate
                // 通过seek方法将振动与播放器同步
                let millisecond = CMTimeGetSeconds((self.player.currentTime())) * 1000
                do {
                    try RichTapHapticUtils.seek(to: Int32(millisecond), playID: playId)
                } catch let error{
                    print(error)
                }
            }
        }
    }
    
    @objc func valueChangedPlayRateSlider(sender: UISlider) {
        // 播放器rate切换
        currentRate = Float(sender.value)
        currentRateLabel.text = String.init(format: "%.2fX", currentRate)
    }
    
    @objc func playOrPauseBtnClick(sender: UIButton) {
        // 播放状态按钮selected为true,暂停状态selected为false
        sender.isSelected = !sender.isSelected
        if sender.isSelected == false {
            player.pause()
            playOrPauseBtn.setTitle("Play", for: .normal)
            // 暂停振动
            do {
                try RichTapHapticUtils.pause(playId)
            } catch {
            }
            progressTimer.fireDate = Date.distantFuture
        }else{
            playOrPauseBtn.setTitle("Pause", for: .normal)
            if isPlayEnd {
                self.player.seek(to: CMTime(value:0, timescale: 1)) { isFinish in
                    self.isPlayEnd = false
                    self.playTimeSlider.value = 0
                    self.startPlay()
                }
            } else {
                startPlay()
            }
        }
    }
    
    /** stop按钮点击 */
    @objc func stopBtnClick(sender: UIButton) {
        self.playTimeSlider.value = 0
        stopPlay()
    }
    
    // MARK: - Notification Event
    @objc fileprivate func moviePlayDidEnd() {
        stopPlay()
    }
}


