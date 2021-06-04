//
//  RecordViewController.swift
//  vHIT96da
//
//  Created by 黒田建彰 on 2020/02/29.
//  Copyright © 2020 tatsuaki.kuroda. All rights reserved.
//

import UIKit
import AVFoundation
import GLKit
import Photos
import CoreMotion
class RecordViewController: UIViewController, AVCaptureFileOutputRecordingDelegate{
    let TempFilePath: String = "\(NSTemporaryDirectory())temp.mp4"
    let vHIT_VOG:String="vHIT_VOG"
    var recordedFlag:Bool = false
    let motionManager = CMMotionManager()
    var session: AVCaptureSession!
    var videoDevice: AVCaptureDevice?
    var filePath:String?
    var timer:Timer?
   
    var vHIT96daAlbum: PHAssetCollection? // アルバムをオブジェクト化
    var fpsMax:Int?
    var fps_non_120_240:Int=2
    var maxFps:Double=240
    var saved2album:Bool=false//albumに保存終了（エラーの時も）
    var fileOutput = AVCaptureMovieFileOutput()
    var gyro = Array<Double>()
    var recStart:Double=0// = CFAbsoluteTimeGetCurrent()
    
    @IBOutlet weak var focusNear: UILabel!
    
    @IBOutlet weak var focusBar: UISlider!
    @IBOutlet weak var focusFar: UILabel!
    
    @IBOutlet weak var LEDHigh: UILabel!
    @IBOutlet weak var LEDLow: UILabel!
    @IBOutlet weak var LEDBar: UISlider!
    @IBOutlet weak var currentTime: UILabel!
    
    @IBOutlet weak var fps240Button: UIButton!
    
    @IBOutlet weak var fps120Button: UIButton!
    @IBOutlet weak var stopButton: UIButton!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var exitBut: UIButton!
    @IBOutlet weak var cameraView: UIImageView!
    
    @IBOutlet weak var cameraChangeButton: UIButton!
    
    func setBars(){
        if cameraType==2{
            focusBar.value=getUserDefault(str: "zoomValue", ret: 0)
            setZoom(level: focusBar.value/10)
            focusFar.text = "ZOOM"
            focusNear.text = "zoom"
        }else{
            focusBar.value=getUserDefault(str: "focusValue", ret: 0)
            setFocus(focus: focusBar.value)
            focusFar.text = "far"//false
            focusNear.text = "near"//isHidden=false
        }
    }
    @IBAction func onCameraChange(_ sender: Any) {//camera>1
        cameraType=UserDefaults.standard.integer(forKey:"cameraType")
        if cameraType==0{
            if telephotoCamera == true{
                cameraType=1//telephoto
            }else if ultrawideCamera == true{
                cameraType=2
            }
        }else if cameraType==1{
            if ultrawideCamera==true{
                cameraType=2//ultraWide
            }else{
                cameraType=0
            }
        }else{
            cameraType=0//wideAngle
        }
        print("cameraType",cameraType)
        UserDefaults.standard.set(cameraType, forKey: "cameraType")
         if session.isRunning{
        // セッションが始動中なら止める
            print("isrunning")
            session.stopRunning()
        }
        initSession(fps: fps_non_120_240)
        setBars()
    }
    
    @IBOutlet weak var damyBottom: UILabel!
    @IBAction func onClickStopButton(_ sender: Any) {
        
        if self.fileOutput.isRecording {
            print("ストップボタンを押した。")
            fileOutput.stopRecording()
        }

    }
 
    @IBAction func tapGes(_ sender: UITapGestureRecognizer) {
//        if cameraType==2{
//            return
//        }
//        let screenSize=cameraView.bounds.size
//        let x0 = sender.location(in: self.view).x
//        let y0 = sender.location(in: self.view).y
//        print("tap:",x0,y0,screenSize.height)
//
//        if y0>view.bounds.height*3/5{//screenSize.height*3/4{
//            return
//        }
//        let x = y0/screenSize.height
//        let y = 1.0 - x0/screenSize.width
//        let focusPoint = CGPoint(x:x,y:y)
//        if let device = videoDevice{
//            do {
//                try device.lockForConfiguration()
//
//                device.focusPointOfInterest = focusPoint
////                                device.focusMode = .continuousAutoFocus
//                device.focusMode = .autoFocus
//
//                device.unlockForConfiguration()
//            }
//            catch {
//                // just ignore
//            }
//        }
    }
    // 指定の FPS のフォーマットに切り替える (その FPS で最大解像度のフォーマットを選ぶ)
    //
    // - Parameters:
    //   - desiredFps: 切り替えたい FPS (AVFrameRateRange.maxFrameRate が Double なので合わせる)
    func switchFormat(desiredFps: Double)->Bool {
        // セッションが始動しているかどうか
        var retF:Bool=false
        let isRunning = session.isRunning
        
        // セッションが始動中なら止める
        if isRunning {
            print("isrunning")
            session.stopRunning()
        }
        
        // 取得したフォーマットを格納する変数
        var selectedFormat: AVCaptureDevice.Format! = nil
        // そのフレームレートの中で一番大きい解像度を取得する
        var maxWidth: Int32 = 0
        
        // フォーマットを探る
        for format in videoDevice!.formats {
            // フォーマット内の情報を抜き出す (for in と書いているが1つの format につき1つの range しかない)
            for range: AVFrameRateRange in format.videoSupportedFrameRateRanges {
                let description = format.formatDescription as CMFormatDescription    // フォーマットの説明
                let dimensions = CMVideoFormatDescriptionGetDimensions(description)  // 幅・高さ情報を抜き出す
                let width = dimensions.width
                if desiredFps == range.maxFrameRate && width >= maxWidth {
                    selectedFormat = format
                    maxWidth = width
                }
            }
        }
        
        // フォーマットが取得できていれば設定する
        if selectedFormat != nil {
            do {
                try videoDevice!.lockForConfiguration()
                videoDevice!.activeFormat = selectedFormat
                videoDevice!.activeVideoMinFrameDuration = CMTimeMake(value: 1, timescale: Int32(desiredFps))
                videoDevice!.activeVideoMaxFrameDuration = CMTimeMake(value: 1, timescale: Int32(desiredFps))
                videoDevice!.unlockForConfiguration()
                print("フォーマット・フレームレートを設定 : \(desiredFps) fps・\(maxWidth) px")
                retF=true
            }
            catch {
                print("フォーマット・フレームレートが指定できなかった")
                retF=false
            }
        }
        else {
            print("指定のフォーマットが取得できなかった")
            retF=false
        }
        
        // セッションが始動中だったら再開する
        if isRunning {
            session.startRunning()
        }
        return retF
    }
    
    func setMotion(){
        guard motionManager.isDeviceMotionAvailable else { return }
        motionManager.deviceMotionUpdateInterval = 1 / 100//が最速の模様
  
        motionManager.startDeviceMotionUpdates(to: OperationQueue.current!, withHandler: { (motion, error) in
            guard let motion = motion, error == nil else { return }
            if self.recStart == 0{
                self.gyro.append(0)//CFAbsoluteTimeGetCurrent())
            }else{
                self.gyro.append(CFAbsoluteTimeGetCurrent()-self.recStart)
            }
            self.gyro.append(motion.rotationRate.y)//
        })
    }
    var telephotoCamera:Bool=false
    var ultrawideCamera:Bool=false
    var cameraType:Int = 0
    func getCameras(){
        if AVCaptureDevice.default(.builtInUltraWideCamera, for: .video, position: .back) != nil{
            ultrawideCamera=true
        }
        if AVCaptureDevice.default(.builtInTelephotoCamera, for: .video, position: .back) != nil{
            telephotoCamera=true
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        getCameras()
        if (UserDefaults.standard.object(forKey: "cameraType") != nil){//keyが設定してなければretをセット
            cameraType=UserDefaults.standard.integer(forKey:"cameraType")
        }else{
            cameraType=0
            UserDefaults.standard.set(cameraType, forKey: "cameraType")
        }
        print("cameraType",cameraType)
        self.view.backgroundColor = .black
//        print("maxFps,fps2:",maxFps,fps_non_120_240)
        
        if UserDefaults.standard.object(forKey: "maxFps") != nil{
             maxFps = Double(UserDefaults.standard.integer(forKey:"maxFps"))
            print("maxFps 値あり",maxFps)
            fps_non_120_240 = UserDefaults.standard.integer(forKey: "fps_non_120_240")
            initSession(fps: fps_non_120_240)
        }else{
            checkinitSession()//maxFpsを設定
            UserDefaults.standard.set(Int(maxFps),forKey: "maxFps")
            print("maxFps 値無し",maxFps)
            UserDefaults.standard.set(fps_non_120_240,forKey: "fps_non_120_240")
            print("生まれて初めての時だけ、通るところのはず")//ここでmaxFpsを設定
        }

        hideButtons(type: true)

        LEDBar.minimumValue = 0
        LEDBar.maximumValue = 0.1
        LEDBar.addTarget(self, action: #selector(onLEDValueChange), for: UIControl.Event.valueChanged)
        LEDBar.value=getUserDefault(str: "LEDValue", ret:0)
        setFlashlevel(level: LEDBar.value)
        
        focusBar.minimumValue = 0
        focusBar.maximumValue = 1.0
        focusBar.addTarget(self, action: #selector(onSliderValueChange), for: UIControl.Event.valueChanged)
        setBars()
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.update), userInfo: nil, repeats: true)
    }
    
    func setFlashlevel(level:Float){
        if let device = videoDevice{
            do {
                if device.hasTorch {
                    do {
                        // torch device lock on
                        try device.lockForConfiguration()
                        
                        if (level > 0.0){
                            do {
                                try device.setTorchModeOn(level: level)
                            } catch {
                                print("error")
                            }
                            
                        } else {
                            // flash LED OFF
                            // 注意しないといけないのは、0.0はエラーになるのでLEDをoffさせます。
                            device.torchMode = AVCaptureDevice.TorchMode.off
                        }
                        // torch device unlock
                        device.unlockForConfiguration()
                        
                    } catch {
                        print("Torch could not be used")
                    }
                }
            }
        }
    }
    
    func getUserDefault(str:String,ret:Float) -> Float{
        if (UserDefaults.standard.object(forKey: str) != nil){
            return UserDefaults.standard.float(forKey: str)
        }else{//keyが設定してなければretをセット
            UserDefaults.standard.set(ret, forKey: str)
            return ret
        }
    }
    
    @objc func onLEDValueChange(){
        //        setFocus(focus:focusBar.value)
        setFlashlevel(level: LEDBar.value)
        UserDefaults.standard.set(LEDBar.value, forKey: "LEDValue")
    }
    @objc func onSliderValueChange(){
        if cameraType==2{//ultrawide
            setZoom(level:focusBar.value/10)
            UserDefaults.standard.set(focusBar.value,forKey: "zoomValue")
        }else{
            setFocus(focus:focusBar.value)
            UserDefaults.standard.set(focusBar.value, forKey: "focusValue")
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        setButtons()//type: true)
        hideButtons(type:false)
        stopButton.isHidden=true
        currentTime.isHidden=true
        if maxFps==120{
            fps240Button.isHidden=true
        }
    }
    @IBAction func onClick120fps(_ sender: Any) {
        if fps_non_120_240==1{
            return
        }else{
            fps_non_120_240=1
            self.fps120Button.backgroundColor = UIColor.blue
            self.fps240Button.backgroundColor = UIColor.darkGray
            initSession(fps: fps_non_120_240)
            UserDefaults.standard.set(fps_non_120_240,forKey: "fps_non_120_240")
        }
    }
    @IBAction func onClick240fps(_ sender: Any) {
        if fps_non_120_240==2{
            return
        }else{
            fps_non_120_240=2
            self.fps120Button.backgroundColor = UIColor.darkGray
            self.fps240Button.backgroundColor = UIColor.blue
            
            initSession(fps: fps_non_120_240)
            UserDefaults.standard.set(fps_non_120_240,forKey: "fps_non_120_240")
        }
    }
    func hideButtons(type:Bool){
        startButton.isHidden=type
        stopButton.isHidden=type
        currentTime.isHidden=type
        fps240Button.isHidden=type
        fps120Button.isHidden=type
        LEDBar.isHidden=type
        LEDLow.isHidden=type
        LEDHigh.isHidden=type
        focusBar.isHidden=type
        focusFar.isHidden=type
        focusNear.isHidden=type
        exitBut.isHidden=type
        cameraChangeButton.isHidden=type
        if ultrawideCamera==false && telephotoCamera==false{
            cameraChangeButton.isHidden=true
        }
    }
    func setButtons(){//type:Bool){
        // recording button
        let ww=view.bounds.width
        let wh=damyBottom.frame.maxY// view.bounds.height
        let bw=(ww/4)-8
        //        let bd=Int(ww/5/4)
        let bh:CGFloat=60
        let bpos=wh-bh/2-10
        
        currentTime.frame   = CGRect(x:0,   y: 0 ,width: bw*1.5, height: bh/2)
        currentTime.layer.position=CGPoint(x:ww/2,y:wh-bh*2.5)

        currentTime.layer.masksToBounds = true
        currentTime.layer.cornerRadius = 5
        currentTime.font = UIFont.monospacedDigitSystemFont(ofSize: 25*view.bounds.width/320, weight: .medium)

        setButtonProperty(button: fps240Button, bw: bw, bh:bh, cx:(10+bw)/2 , cy: bpos-10-bh)
        setButtonProperty(button: fps120Button, bw: bw, bh: bh, cx:(10+bw)/2 , cy:bpos)
        
        if fps_non_120_240==2{
            self.fps120Button.backgroundColor = UIColor.darkGray
            self.fps240Button.backgroundColor = UIColor.blue
        }else{
            self.fps120Button.backgroundColor = UIColor.blue
            self.fps240Button.backgroundColor = UIColor.darkGray
        }
        if maxFps==120{
            fps120Button.backgroundColor=UIColor.gray
            fps120Button.isEnabled=false
        }
        //startButton

        setLabelProperty(label: focusNear,bw:bw,bh:bh/2,cx:(10+bw)/2,cy:bpos-20-bh*7/4)
        setLabelProperty(label:focusFar, bw: bw, bh:bh/2, cx:ww-10-bw/2, cy:bpos-20-bh*7/4)
        setLabelProperty(label: LEDLow,bw:bw,bh:bh/2,cx:(10+bw)/2,cy:bpos-30-bh*9/4)
        setLabelProperty(label:LEDHigh, bw: bw, bh:bh/2, cx:ww-10-bw/2, cy:bpos-30-bh*9/4)
        setButtonProperty(button:cameraChangeButton, bw: bw, bh:bh/2, cx:ww-10-bw/2, cy:bpos-40-bh*11/4)
//        if ultrawideCamera == true || telephotoCamera == true{
//            cameraChangeButton.isHidden=false
//        }else{
//            cameraChangeButton.isHidden=true
//        }
        focusBar.frame=CGRect(x:0,y:0,width:ww-bw*2-40,height:bh/2)
        focusBar.layer.position=CGPoint(x:ww/2,y:bpos-20-bh*7/4)
        LEDBar.frame=CGRect(x:0,y:0,width:ww-bw*2-40,height:bh/2)
        LEDBar.layer.position=CGPoint(x:ww/2,y:bpos-30-bh*9/4)
        
        startButton.frame=CGRect(x:0,y:0,width:bh*2,height:bh*2)
        startButton.layer.position = CGPoint(x:ww/2,y:bpos-bh/3)
        stopButton.frame=CGRect(x:0,y:0,width:bh*2,height:bh*2)
        stopButton.layer.position = CGPoint(x:ww/2,y:bpos-bh/3)
        startButton.isHidden=true
        stopButton.isHidden=true
        stopButton.tintColor=UIColor.orange
        setButtonProperty(button: exitBut, bw: bw, bh:bh, cx:ww-10-bw/2, cy:bpos)
    }
    func setLabelProperty(label:UILabel,bw:CGFloat,bh:CGFloat,cx:CGFloat,cy:CGFloat){
        label.frame   = CGRect(x:0,   y: 0 ,width: bw, height: bh)
        label.layer.borderColor = UIColor.black.cgColor
        label.layer.borderWidth = 1.0
        label.layer.position=CGPoint(x:cx,y:cy)
        label.layer.masksToBounds = true
        label.layer.cornerRadius = 5
    }
    func setButtonProperty(button:UIButton,bw:CGFloat,bh:CGFloat,cx:CGFloat,cy:CGFloat){
        button.frame   = CGRect(x:0,   y: 0 ,width: bw, height: bh)
        button.layer.borderColor = UIColor.black.cgColor
        button.layer.borderWidth = 1.0
        button.layer.position=CGPoint(x:cx,y:cy)
        button.layer.cornerRadius = 5
    }
    func initSession(fps:Int) {
        // セッション生成
        session = AVCaptureSession()
        // 入力 : 背面カメラ
        if cameraType==0{
            videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
        }else if cameraType==1{
            videoDevice = AVCaptureDevice.default(.builtInTelephotoCamera, for: .video, position: .back)

        }else if cameraType==2{
            videoDevice = AVCaptureDevice.default(.builtInUltraWideCamera, for: .video, position: .back)

        }
        let videoInput = try! AVCaptureDeviceInput.init(device: videoDevice!)
        session.addInput(videoInput)
        // ↓ココ重要！！！！！
        // viewDidLoadから240fpsで飛んでくる
        //２回目は、120fps録画のみの機種では120で飛んでくる。
        //２回目は、240fps録画可能の機種ではどっちか分からない。
        if fps==2{
            if switchFormat(desiredFps: 240)==false{
            }
        }else{
            if switchFormat(desiredFps: 120)==false{
            }
        }
        // ファイル出力設定
        fileOutput = AVCaptureMovieFileOutput()
//        fileOutput.maxRecordedDuration = CMTimeMake(value:5*60, timescale: 1)//最長録画時間
        session.addOutput(fileOutput)
        //手振れ補正はデフォルトがoff
//        fileOutput.connections[0].preferredVideoStabilizationMode=AVCaptureVideoStabilizationMode.off
        let videoLayer : AVCaptureVideoPreviewLayer = AVCaptureVideoPreviewLayer(session: session)
        videoLayer.frame = self.view.bounds
        videoLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill//無くても同じ
        //self.view.layer.addSublayer(videoLayer)
        cameraView.layer.addSublayer(videoLayer)
        // zooming slider
        // セッションを開始する (録画開始とは別)
        session.startRunning()
    }
    func checkinitSession() {//maxFpsを設定
        // セッション生成
        session = AVCaptureSession()
        // 入力 : 背面カメラ
        videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
        let videoInput = try! AVCaptureDeviceInput.init(device: videoDevice!)
        session.addInput(videoInput)
        
        maxFps=240.0
        fps_non_120_240=2
        if switchFormat(desiredFps: 240.0)==false{
            maxFps=120.0
            fps_non_120_240=1
            if switchFormat(desiredFps: 120.0)==false{
                maxFps=0.0
                fps_non_120_240=0
            }
        }
        // ファイル出力設定
        fileOutput = AVCaptureMovieFileOutput()
//        fileOutput.maxRecordedDuration = CMTimeMake(value: 5*60, timescale: 1)//最長録画時間
        session.addOutput(fileOutput)
        
        let videoLayer : AVCaptureVideoPreviewLayer = AVCaptureVideoPreviewLayer(session: session)
        videoLayer.frame = self.view.bounds
        videoLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill//無くても同じ
        cameraView.layer.addSublayer(videoLayer)
        // セッションを開始する (録画開始とは別)
        session.startRunning()
    }
    
    func defaultCamera() -> AVCaptureDevice? {
        if let device = AVCaptureDevice.default(.builtInDualCamera, for: AVMediaType.video, position: .back) {
            return device
        } else if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: AVMediaType.video, position: .back) {
            return device
        } else {
            return nil
        }
    }
    
    var soundIdstart:SystemSoundID = 1117
    var soundIdstop:SystemSoundID = 1118
    var soundIdpint:SystemSoundID = 1109//1009//7
    
    var timerCnt:Int=0
    @objc func update(tm: Timer) {
        timerCnt += 1
        if timerCnt>1{
            stopButton.isHidden=false
        }
        
        if fileOutput.isRecording{
//            timerCnt += 1
            currentTime.text=String(format:"%02d",timerCnt/60) + ":" + String(format: "%02d",timerCnt%60)
            if timerCnt%2==0{
                stopButton.tintColor=UIColor.orange
            }else{
                stopButton.tintColor=UIColor.red
            }
        }else{
            if cameraType != 2{
                UserDefaults.standard.set(videoDevice?.lensPosition, forKey: "focusValue")
                focusBar.value=videoDevice!.lensPosition
            }
        }
        if timerCnt > 60*5{
            timer!.invalidate()
            if self.fileOutput.isRecording{
                onClickStopButton(0)
//                Record_or_Stop()
            }else{
                performSegue(withIdentifier: "fromRecordToMain", sender: self)
            }
        }
    }
    func setZoom(level:Float){//
       print("zoom:::::",level)
        if let device = videoDevice {
        do {
            print("zoom:::::",level)
            try device.lockForConfiguration()
                device.ramp(
                    toVideoZoomFactor: (device.minAvailableVideoZoomFactor) + CGFloat(level) * ((device.maxAvailableVideoZoomFactor) - (device.minAvailableVideoZoomFactor)),
                    withRate: 30.0)
            device.unlockForConfiguration()
            } catch {
                print("Failed to change zoom.")
            }
        }
    }
    func setFocus(focus:Float) {//focus 0:最接近　0-1.0
        if let device = videoDevice{
            if device.isFocusModeSupported(.autoFocus) && device.isFocusPointOfInterestSupported {
                do {
                    try device.lockForConfiguration()
                    device.focusMode = .locked
                    device.setFocusModeLocked(lensPosition: focus, completionHandler: { _ in
                        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1), execute: {
                            device.unlockForConfiguration()
                        })
                    })
                    device.unlockForConfiguration()
                }
                catch {
                    // just ignore
                    print("focuserror")
                }
            }
        }
    }
  
    var soundIdx:SystemSoundID = 0
    
    @IBAction func onClickStartButton(_ sender: Any) {
        //start recording
//        timerCnt=0
//        setMotion()
        hideButtons(type: true)
        stopButton.isHidden=true
        currentTime.isHidden=false
        UIApplication.shared.isIdleTimerDisabled = true//スリープしない
        if let soundUrl = URL(string:
                                "/System/Library/Audio/UISounds/end_record.caf"/*photoShutter.caf*/){
            AudioServicesCreateSystemSoundID(soundUrl as CFURL, &soundIdx)
            AudioServicesPlaySystemSound(soundIdx)
        }
        try? FileManager.default.removeItem(atPath: TempFilePath)
        
        let fileURL = NSURL(fileURLWithPath: TempFilePath)
        //下３行の様にしたら、ビデオとジャイロのズレが安定した。zure:10
        setMotion()
        sleep(UInt32(1.0))
        fileOutput.startRecording(to: fileURL as URL, recordingDelegate: self)
        timerCnt=0
    }
    
    func albumExists(albumName:String) -> Bool {
        // ここで以下のようなエラーが出るが、なぜか問題なくアルバムが取得できている
        // [core] "Error returned from daemon: Error Domain=com.apple.accounts Code=7 "(null)""
        let albums = PHAssetCollection.fetchAssetCollections(with: PHAssetCollectionType.album, subtype:
                                                                PHAssetCollectionSubtype.albumRegular, options: nil)
        for i in 0 ..< albums.count {
            let album = albums.object(at: i)
            if album.localizedTitle != nil && album.localizedTitle == albumName {
//                vHIT96daAlbum = album
                return true
            }
        }
        return false
    }
    func getPHAssetcollection(albumName:String)->PHAssetCollection{
        let requestOptions = PHImageRequestOptions()
        requestOptions.isSynchronous = true
        requestOptions.isNetworkAccessAllowed = false
        requestOptions.deliveryMode = .highQualityFormat //これでもicloud上のvideoを取ってしまう
        //アルバムをフェッチ
        let assetFetchOptions = PHFetchOptions()
        assetFetchOptions.predicate = NSPredicate(format: "title == %@", albumName)
        let assetCollections = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .smartAlbumVideos, options: assetFetchOptions)
        //アルバムはviewdidloadで作っているのであるはず？
//        if (assetCollections.count > 0) {
        //同じ名前のアルバムは一つしかないはずなので最初のオブジェクトを使用
        return assetCollections.object(at:0)
    }
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if let soundUrl = URL(string:
                          "/System/Library/Audio/UISounds/end_record.caf"/*photoShutter.caf*/){
            AudioServicesCreateSystemSoundID(soundUrl as CFURL, &soundIdx)
            AudioServicesPlaySystemSound(soundIdx)
        }

        print("終了ボタン、最大を超えた時もここを通る")
        UIApplication.shared.isIdleTimerDisabled = false//スリープする
        
//        for _ in 0...20{
//            self.gyro.append(CFAbsoluteTimeGetCurrent()-self.recStart)
//            self.gyro.append(0)//
//        }

        motionManager.stopDeviceMotionUpdates()//ここで止めたが良さそう。
        //        recordedFPS=getFPS(url: outputFileURL)
        //        topImage=getThumb(url: outputFileURL)
        
        if timer?.isValid == true {
            timer!.invalidate()
        }
        if albumExists(albumName: vHIT_VOG)==true{
            recordedFlag=true
            PHPhotoLibrary.shared().performChanges({ [self] in
                //let assetRequest = PHAssetChangeRequest.creationRequestForAsset(from: avAsset)
                let assetRequest = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: outputFileURL)!
                let albumChangeRequest = PHAssetCollectionChangeRequest(for: getPHAssetcollection(albumName: vHIT_VOG))
                let placeHolder = assetRequest.placeholderForCreatedAsset
                albumChangeRequest?.addAssets([placeHolder!] as NSArray)
                //imageID = assetRequest.placeholderForCreatedAsset?.localIdentifier
                print("file add to album")
            }) { [self] (isSuccess, error) in
                if isSuccess {
                    // 保存した画像にアクセスする為のimageIDを返却
                    //completionBlock(imageID)
                    print("success")
                    self.saved2album=true
                } else {
                    //failureBlock(error)
                    print("fail")
                    //                print(error)
                    self.saved2album=true
                }
                //            _ = try? FileManager.default.removeItem(atPath: self.TempFilePath)
            }
        }else{
            startButton.isHidden=true
            stopButton.isHidden=true
            //上二つをunwindでチェック
            //アプリ起動中にアルバムを消したら、保存せずに戻る。
            //削除してもどこかにあるようで、参照URLは生きていて、再生できる。
        }
        performSegue(withIdentifier: "fromRecordToMain", sender: self)
    }
    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection]) {
        recStart=CFAbsoluteTimeGetCurrent()
//        print("録画開始")
        //fileOutput.stopRecording()
    }
}
