//
//  TradeCACertificationViewController.swift
//  FutureBull
//
//  Created by IronMan on 2021/1/13.
//  Copyright © 2021 wuyanwei. All rights reserved.
//

import UIKit
import AVFoundation
import Photos

class TradeCACertificationViewController: UIViewController {
    
    /// CA 录视频在沙盒的地址
    fileprivate let caVideoPath: String = NSHomeDirectory() + "/Documents" + "/ca_certification.mp4"
    /// 压缩转码后的视频路径
    fileprivate let caVideoOutputPath: String = NSHomeDirectory() + "/Documents" + "/ca_certification_release.mp4"
    /// 视频捕获会话，它是input和output的桥梁，它协调着intput到output的数据传输
    let captureSession = AVCaptureSession()
    //  视频输入设备，前后摄像头
    var videoDevice: AVCaptureDevice?
    /// 音频输入设备
    let audioDevice = AVCaptureDevice.default(for: AVMediaType.audio)
    /// 将捕获到的视频输出到文件
    let fileOutput = AVCaptureMovieFileOutput()
    /// 表示当时是否在录像中
    var isRecording = false
    /// 当前录制的资源文件
    var currentOutputFileURL: URL?
    /// 录像的预览层
    lazy var videoLayer: AVCaptureVideoPreviewLayer = {
        //使用AVCaptureVideoPreviewLayer可以将摄像头的拍摄的实时画面显示在ViewController上
        let layer = AVCaptureVideoPreviewLayer(session: self.captureSession)
        layer.frame = UIScreen.main.bounds
        layer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        return layer
    }()
    /// 切换摄像头
    lazy var switchCameraButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 20 + 60 + 20, y: UIApplication.shared.statusBarFrame.height, width: 100, height: 30))
        button.setTitle("切换摄像头", for: .normal)
        button.backgroundColor = .green
        button.addTarget(self, action: #selector(changeCamera), for: .touchUpInside)
        return button
    }()
    /// 闪光灯
    lazy var flashLightButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 20 + 60 + 20 + 100 + 20, y: UIApplication.shared.statusBarFrame.height, width: 80, height: 30))
        button.setTitle("闪光灯", for: .normal)
        button.backgroundColor = .green
        button.addTarget(self, action: #selector(switchFlashLight), for: .touchUpInside)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .brown
        // 判断App的相机和麦克风的权限
        judgePermission()
    }
    
    // MARK: 判断App的相机和麦克风的权限
    func judgePermission() {
        let cameraResult = UIApplication.jk.isOpenPermission(.camera)
        let audioResult = UIApplication.jk.isOpenPermission(.audio)
        if cameraResult == false || audioResult == false {
            JKPrint("没有相机或者麦克风权限")
            let typeString = cameraResult == false ? "相机" : "麦克风"
            JKAsyncs.asyncDelay(0.3) {
            } _: {
                let alertController = UIAlertController(title: "未开启\(typeString)访问权限", message: "请在iPhone的\"设置-隐私-\(typeString)\"选项中，允许CG TRADE访问您的\(typeString)", preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "我知道了", style: .destructive) {[weak self] (action) in
                    guard let weakSelf = self else { return }
                    weakSelf.closeClick()
                }
                alertController.addAction(cancelAction)
                self.present(alertController, animated: true, completion: nil)
            }
        } else {
            initUI()
        }
    }
    
    // MARK: 创建控件
    /// 创建控件
    private func initUI() {
        // 添加视频、音频输入设备
        // 相机，默认前置
        videoDevice = cameraWithPosition(position: AVCaptureDevice.Position.front)
        // 默认是前置摄像头，所以隐藏闪光灯
        flashLightButton.isHidden = true
        let videoInput = try! AVCaptureDeviceInput(device: self.videoDevice!)
        self.captureSession.addInput(videoInput)
        let audioInput = try! AVCaptureDeviceInput(device: self.audioDevice!)
        self.captureSession.addInput(audioInput)
        // 添加视频捕获输出
        self.captureSession.addOutput(self.fileOutput)
        //使用AVCaptureVideoPreviewLayer可以将摄像头的拍摄的实时画面显示在ViewController上
        self.view.layer.addSublayer(videoLayer)
        // 创建按钮
        self.setupButton()
        // 启动session会话
        self.captureSession.startRunning()
    }
    
    // 创建按钮
    func setupButton(){
        // 添加缩略图
        self.view.addSubview(playImageView)
        // 添加播放按钮
        playButton.center = self.view.center
        self.view.addSubview(playButton)
        // 添加按钮到视图上
        self.view.addSubview(self.closeButton)
        self.view.addSubview(self.switchCameraButton)
        self.view.addSubview(self.flashLightButton)
        // 开始按钮
        self.view.addSubview(self.startButton)
        // 停止按钮
        self.view.addSubview(self.saveButton)
        self.view.addSubview(self.stopButton)
        self.view.addSubview(self.switchCameraButton)
        self.view.addSubview(self.uploadButton)
        self.view.addSubview(self.uploadButton2)
        self.view.addSubview(timeLabel)
    }
    
    // MARK: 开始按钮点击，开始录像
    // 开始按钮点击，开始录像
    @objc func onClickStartButton(_ sender: UIButton){
        if !self.isRecording {
            // 计时从 0 开始
            timeCount = 0
            // 打开定时器
            videoTimer?.fireDate = NSDate.distantPast
            // 隐藏缩略图
            playImageView.isHidden = true
            playButton.isHidden = true
            switchCameraButton.isHidden = true
            FileManager.jk.removefile(filePath: caVideoPath)
            // 镜像的设置
            if let connection = fileOutput.connection(with: .video) {
              connection.isVideoMirrored = true
              // connection.automaticallyAdjustsVideoMirroring = true
            }
            // 设置录像的保存地址（在Documents目录下，名为temp.mp4）
            let fileURL = URL(fileURLWithPath: caVideoPath)
            // 启动视频编码输出
            fileOutput.startRecording(to: fileURL, recordingDelegate: self)
            // 记录状态：录像中...
            self.isRecording = true
            // 开始、结束按钮颜色改变
            self.changeButtonColor(target: self.startButton, color: .gray)
            self.changeButtonColor(target: self.stopButton, color: .red)
        }
    }
    
    // MARK: 停止按钮点击，停止录像
    // 停止按钮点击，停止录像
    @objc func onClickStopButton(_ sender: UIButton){
        if self.isRecording {
            // 暂停定时器
            videoTimer?.fireDate = NSDate.distantFuture
            // 停止视频编码输出
            fileOutput.stopRecording()
            // 记录状态：录像结束
            self.isRecording = false
            // 开始、结束按钮颜色改变
            self.changeButtonColor(target: self.startButton, color: .red)
            self.changeButtonColor(target: self.stopButton, color: .gray)
            JKAsyncs.asyncDelay(0.5) {
            } _: { [weak self] in
                guard let weakSelf = self else { return }
                // 添加录视频的缩略图
                if let playImage = FileManager.jk.getLocalVideoImage(videoPath: weakSelf.caVideoPath) {
                    weakSelf.playImageView.isHidden = false
                    weakSelf.playImageView.image = playImage
                    weakSelf.playVideoImage = playImage
                    weakSelf.playButton.isHidden = false
                    weakSelf.switchCameraButton.isHidden = false
                }
            }
        }
    }
    
    // 修改按钮的颜色
    func changeButtonColor(target: UIButton, color: UIColor){
        target.backgroundColor = color
    }
    
    // MARK: 保存到相册
    /// 保存到相册
    @objc func saveVideo() {
        
        if self.isRecording {
            "正在录制中...".toast()
            return
        }
        guard let weakCurrentOutputFileURL = currentOutputFileURL else {
            "请点击下方开始键先进行视频录制".toast()
            return
        }
        
        let albumResult = UIApplication.jk.isOpenPermission(.album)
        if albumResult == false {
            JKPrint("没有相册权限")
            JKAsyncs.asyncDelay(0.3) {
            } _: {
                let alertController = UIAlertController(title: "未开启相册访问权限", message: "请在iPhone的\"设置-隐私-相册\"选项中，允许CG TRADE访问您的相册", preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "我知道了", style: .destructive) { (action) in
                    
                }
                alertController.addAction(cancelAction)
                self.present(alertController, animated: true, completion: nil)
            }
            return
        }
        
        // 将录制好的录像保存到照片库中
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: weakCurrentOutputFileURL)
        }, completionHandler: { (isSuccess: Bool, error: Error?) in
            var message: String = ""
            if isSuccess {
                message = "保存成功!"
            } else{
                message = "保存失败：\(error!.localizedDescription)"
            }
            DispatchQueue.main.async {
                // 弹出提示框
                let alertController = UIAlertController(title: message, message: nil, preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "确定", style: .cancel, handler: nil)
                alertController.addAction(cancelAction)
                self.present(alertController, animated: true, completion: nil)
            }
        })
    }
    
    // MARK: 上传视频
    /// 上传视频
    @objc func uploadVideoClick() {
        guard !self.isRecording else {
            "视频录制中，请停止录制后再上传".toast()
            return
        }
        guard let _ = currentOutputFileURL else {
            "请点击下方开始键进行视频录制".toast()
            return
        }
        transformMoive(inputPath: caVideoPath, outputPath: caVideoOutputPath)
    }
    
    /// 上传视频
    @objc func uploadVideoClick1() {
        guard !self.isRecording else {
            "视频录制中，请停止录制后再上传".toast()
            return
        }
        guard let url = currentOutputFileURL else {
            "请点击下方开始键进行视频录制".toast()
            return
        }
        transformMoive(inputPath: url.path, outputPath: caVideoOutputPath)
    }
    
    // MARK: 返回上个界面
    @objc func closeClick() {
        if self.isRecording {
            // 停止视频编码输出
            print("💣💣💣-----------停止视频编码输出")
            fileOutput.stopRecording()
        }
        self.dismiss(animated: true, completion: nil)
    }
    
    /// 选择摄像头
    private func cameraWithPosition(position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        let devices = AVCaptureDevice.devices(for: AVMediaType.video)
        for item in devices {
            if item.position == position {
                return item
            }
        }
        return nil
    }
    
    // MARK: 切换调整摄像头
    // 切换调整摄像头
    @objc private func changeCamera(cameraSideButton: UIButton) {
        cameraSideButton.isSelected = !cameraSideButton.isSelected
        
        captureSession.stopRunning()
      
        //  首先移除所有的 input
        if let allInputs = captureSession.inputs as? [AVCaptureDeviceInput] {
            for input in allInputs {
                captureSession.removeInput(input)
            }
        }
     
        // 切换动画
        changeCameraAnimate()
        
        //  添加音频输出
        if audioDevice != nil,
           let audioInput = try? AVCaptureDeviceInput(device: audioDevice!) {
            self.captureSession.addInput(audioInput)
        }
        
        if cameraSideButton.isSelected {
            
            //if let connection = fileOutput.connection(with: .video) {
                // connection.videoOrientation = .landscapeRight
                // connection.automaticallyAdjustsVideoMirroring = true
            //}
            
            // 后置摄像头
            videoDevice = cameraWithPosition(position: .back)
            // 显示闪光灯
            flashLightButton.isHidden = false
            if let input = try? AVCaptureDeviceInput(device: videoDevice!) {
                captureSession.addInput(input)
            }
        } else {
            // 前置摄像头
            videoDevice = cameraWithPosition(position: .front)
            // 隐藏闪光灯
            flashLightButton.isHidden = true
            if let input = try? AVCaptureDeviceInput(device: videoDevice!) {
                captureSession.addInput(input)
            }
            if flashLightButton.isSelected {
                flashLightButton.isSelected = false
            }
        }
        // 开启
        captureSession.startRunning()
    }
    
    // MARK: 切换前后摄像头的动画
    // 切换动画
    private func changeCameraAnimate() {
        let changeAnimate = CATransition()
        changeAnimate.delegate = self
        changeAnimate.duration = 0.4
        changeAnimate.type = CATransitionType(rawValue: "oglFlip")
        changeAnimate.subtype = CATransitionSubtype.fromRight
        videoLayer.add(changeAnimate, forKey: "changeAnimate")
    }
    
    // MARK: 开启闪光灯
    // 开启闪光灯
    @objc private func switchFlashLight(flashButton: UIButton) {
        if self.videoDevice?.position == AVCaptureDevice.Position.front {
            return
        }
        let camera = cameraWithPosition(position: .back)
        if camera?.torchMode == AVCaptureDevice.TorchMode.off {
            do {
                try camera?.lockForConfiguration()
            } catch let error as NSError {
                print("开启闪光灯失败 ： \(error)")
            }
            camera?.torchMode = AVCaptureDevice.TorchMode.on
            camera?.flashMode = AVCaptureDevice.FlashMode.on
            camera?.unlockForConfiguration()
            
            flashButton.isSelected = true
        } else {
            do {
                try camera?.lockForConfiguration()
            } catch let error as NSError {
                print("关闭闪光灯失败： \(error)")
            }
            camera?.torchMode = AVCaptureDevice.TorchMode.off
            camera?.flashMode = AVCaptureDevice.FlashMode.off
            camera?.unlockForConfiguration()
            flashButton.isSelected = false
        }
    }
    
    // MARK: 播放视频
    @objc func playVodeo() {
        let vc = TradeCACertificationPlayViewController()
        vc.modalPresentationStyle = .fullScreen
        self.present(vc, animated: false, completion: nil)
    }
    
    // 不能旋转
    override var shouldAutorotate: Bool {
        return false
    }
    
    // 竖屏
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return .portrait
    }

    /// 创建开始按钮
    lazy var startButton: UIButton = {
        let button = UIButton(frame: CGRect(x: kScreenW / 2 - 20 - 120, y: kScreenH - 50 - kTabbatBottom - 20, width: 120, height: 50))
        button.backgroundColor = UIColor.red
        button.layer.masksToBounds = true
        button.setTitle("开始", for: .normal)
        button.layer.cornerRadius = 20.0
        button.addTarget(self, action: #selector(onClickStartButton), for: .touchUpInside)
        return button
    }()
    /// 创建停止按钮
    lazy var stopButton: UIButton = {
        let button = UIButton(frame: CGRect(x: kScreenW / 2 + 20, y: kScreenH - 50 - kTabbatBottom - 20, width: 120, height: 50))
        button.backgroundColor = UIColor.gray
        button.layer.masksToBounds = true
        button.setTitle("停止", for: .normal)
        button.layer.cornerRadius = 20.0
        button.addTarget(self, action: #selector(onClickStopButton), for: .touchUpInside)
        return button
    }()
    /// 创建保存按钮
    lazy var saveButton: UIButton = {
        let button = UIButton(frame: CGRect(x: stopButton.jk.left, y: self.stopButton.jk.top - 20 - 50, width: 120, height: 50))
        button.backgroundColor = UIColor.gray
        button.layer.masksToBounds = true
        button.setTitle("保存", for: .normal)
        button.layer.cornerRadius = 20.0
        button.addTarget(self, action: #selector(saveVideo), for: .touchUpInside)
        return button
    }()
    /// 创建上传按钮
    lazy var uploadButton: UIButton = {
        let button = UIButton(frame: CGRect(x: saveButton.jk.left, y: self.saveButton.jk.top - 20 - 50, width: 120, height: 50))
        button.backgroundColor = UIColor.gray
        button.layer.masksToBounds = true
        button.setTitle("上传1", for: .normal)
        button.layer.cornerRadius = 20.0
        button.addTarget(self, action: #selector(uploadVideoClick), for: .touchUpInside)
        return button
    }()
    /// 创建上传按钮
    lazy var uploadButton2: UIButton = {
        let button = UIButton(frame: CGRect(x: uploadButton.jk.left, y: self.uploadButton.jk.top - 20 - 50, width: 120, height: 50))
        button.backgroundColor = UIColor.gray
        button.layer.masksToBounds = true
        button.setTitle("上传2", for: .normal)
        button.layer.cornerRadius = 20.0
        button.addTarget(self, action: #selector(uploadVideoClick1), for: .touchUpInside)
        return button
    }()
    /// 返回
    lazy var closeButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 20, y: UIApplication.shared.statusBarFrame.height, width: 60, height: 30))
        button.setTitle("返回", for: .normal)
        button.backgroundColor = .green
        button.addTarget(self, action: #selector(closeClick), for: .touchUpInside)
        return button
    }()
    /// 视频录制完毕后的预览图层
    private lazy var playImageView: UIImageView = {
        let imageView = UIImageView(frame: UIScreen.main.bounds)
        imageView.backgroundColor = .black
        imageView.isHidden = true
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    /// 播放视频的缩略图
    var playVideoImage: UIImage?
    /// 计时数字
    private var timeCount: Int = 0 {
        didSet {
            timeLabel.text = Date.jk.getFormatPlayTime(seconds: timeCount, type: .minute)
        }
    }
    /// 时间显示的label
    private lazy var timeLabel: UILabel = {
        let label = UILabel(frame: CGRect(x: self.startButton.jk.left, y: self.startButton.jk.top - 20 - 50, width: 120, height: 50))
        label.textColor = .white
        label.backgroundColor = .gray
        label.layer.cornerRadius = 9
        label.clipsToBounds = true
        label.font = UIFont.systemFont(ofSize: 18)
        label.textAlignment = .center
        label.text = "00:00"
        return label
    }()
    /// 录制视频的定时器
    fileprivate lazy var videoTimer: Timer? = {
        let timer = Timer(safeTimerWithTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let weakSelf = self else { return }
            weakSelf.timeCount += 1
        }
        RunLoop.main.add(timer, forMode: .default)
        return timer
    }()
    /// 播放按钮
    private lazy var playButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 65, height: 65))
        button.setBackgroundImage(UIImage(named: "ca_play"), for: .normal)
        button.addTarget(self, action: #selector(playVodeo), for: .touchUpInside)
        button.isHidden = true
        return button
    }()
}

// MARK: 视频压缩和上传
// MARK: 视频压缩 和 上传
extension TradeCACertificationViewController {
    
    // MARK: 视频压缩
    /// 视频压缩
    /// - Parameters:
    ///   - inputPath: 原视频路径
    ///   - outputPath: 压缩后的视频路径
    ///   - outputFileType: 压缩的后视频的类型
    func transformMoive(inputPath: String, outputPath: String, outputFileType: AVFileType = .mp4){
        
        guard FileManager.jk.judgeFileOrFolderExists(filePath: inputPath) else {
            return
        }
        
        let startTime = CFAbsoluteTimeGetCurrent()
        JKPrint("--------------------------------------开始转码--------------------------------------")
        AVAssetExportSession.jk.assetExportSession(inputPath: inputPath, outputPath: outputPath, outputFileType: outputFileType, completionHandler: { (exportSession, duration, videoSize, path) in
            switch exportSession.status {
            case .waiting:
                JKPrint("等待压缩")
                break
            case .exporting:
                JKPrint("压缩中-压缩进度：\(exportSession.progress)")
                break
            case .completed:
                JKPrint("--------------------------------------转码成功--------------------------------------")
                let endTime = CFAbsoluteTimeGetCurrent()
                JKPrint("视频时长 \(duration), 压缩后的大小：\(videoSize), 当前的线程：\(Thread.current)")
                JKPrint("代码执行时长：%f 毫秒", (endTime - startTime)*1000)
                //转码成功后获取视频视频地址
                //上传
                self.uploadVideo(videoPath: outputPath)
                break
            case .cancelled:
                JKPrint("取消")
                break
            case .failed:
                JKPrint("失败...\(String(describing: exportSession.error?.localizedDescription))")
                break
            default:
                JKPrint("..")
                break
            }
        }, shouldOptimizeForNetworkUse: true)
    }
    
    // 上传视频到服务器
    func uploadVideo(videoPath: String){
        
        let url = URL(fileURLWithPath: videoPath)
        JKPrint("url 存在----")
        let _ = try? Data(contentsOf: url)
        
    }
}

// MARK: - CAAnimationDelegate
extension TradeCACertificationViewController: CAAnimationDelegate {
    /// 动画开始
    func animationDidStart(_ anim: CAAnimation) {
        captureSession.startRunning()
    }
    
    /// 动画结束
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
    }
}

// MARK:- 录像的代理方法
extension TradeCACertificationViewController: AVCaptureFileOutputRecordingDelegate {
    // 录像开始的代理方法
    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
    }
    
    // 录像结束的代理方法
    func fileOutput(_ output: AVCaptureFileOutput,
                    didFinishRecordingTo outputFileURL: URL,
                    from connections: [AVCaptureConnection], error: Error?) {
        currentOutputFileURL = outputFileURL
    }
}
