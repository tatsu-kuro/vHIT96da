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
    let iroiro = myFunctions(albumName:"vHIT96da")
    let tempFilePath: String = "\(NSTemporaryDirectory())temp.mp4"
    let TEMPFilePath: String = "\(NSTemporaryDirectory())TEMP.mp4"
    let vHIT96da:String="vHIT96da"
    var recordedFlag:Bool = false
    let motionManager = CMMotionManager()
    var captureSession: AVCaptureSession!
    var videoDevice: AVCaptureDevice?
    var filePath:String?
    var timer:Timer?
    var videoCount:Int?//保持するだけ
    var vHIT96daAlbum: PHAssetCollection? // アルバムをオブジェクト化
    var fpsMax:Int?
    var fps_non_120_240:Int=2
    var maxFps:Double=240
 //   @IBOutlet weak var speakerSwitch: UISwitch!
 //   @IBOutlet weak var speakerLabel: UILabel!
    
  //  @IBOutlet weak var speakerImage: UIImageView!
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
    
    
//    @IBAction func onSpeakerSwitch(_ sender: UISwitch) {
//        if speakerSwitch.isOn==true{
//            UserDefaults.standard.set(1, forKey: "recordSound")
//            speakerImage.tintColor=UIColor.green
//        }else{
//            UserDefaults.standard.set(0, forKey: "recordSound")
//            speakerImage.tintColor=UIColor.gray
//        }
//    }
    
    @IBAction func onCameraChange(_ sender: Any) {//camera>1
        if captureSession.isRunning{
            // セッションが始動中なら止める
            print("isrunning")
            captureSession.stopRunning()
        }
        initSession(fps: fps_non_120_240)
        setFlashlevel(level: LEDBar.value)
    }
    

    @IBAction func onClickStopButton(_ sender: Any) {
        if self.fileOutput.isRecording {
            motionManager.stopDeviceMotionUpdates()//ここで止めたが良さそう。
            if timer?.isValid == true {
                timer!.invalidate()
            }
         //   if speakerSwitch.isOn==true{
                if let soundUrl = URL(string:
                                        "/System/Library/Audio/UISounds/end_record.caf"/*photoShutter.caf*/){
                    AudioServicesCreateSystemSoundID(soundUrl as CFURL, &soundIdx)
                    AudioServicesPlaySystemSound(soundIdx)
                }
        //    }
            print("ストップボタンを押した。")
            fileOutput.stopRecording()
        }
    }
 
    // 指定の FPS のフォーマットに切り替える (その FPS で最大解像度のフォーマットを選ぶ)
    //
    // - Parameters:
    //   - desiredFps: 切り替えたい FPS (AVFrameRateRange.maxFrameRate が Double なので合わせる)
    func switchFormat(desiredFps: Double)->Bool {
        // セッションが始動しているかどうか
        var retF:Bool=false
        let isRunning = captureSession.isRunning
        
        // セッションが始動中なら止める
        if isRunning {
            print("isrunning")
            captureSession.stopRunning()
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
            captureSession.startRunning()
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
            self.gyro.append(motion.rotationRate.y)//holizontal
            self.gyro.append(-motion.rotationRate.x*1.414)//verticalは４５度ズレているので、√２
        })
    }
    var telephotoCamera:Bool=false
    var ultrawideCamera:Bool=false
    var cameraType:Int = 0 //0:wideAngle(all） 1:telePhoto 2:ultraWide(12mini)
    func getCameras(){
        if AVCaptureDevice.default(.builtInUltraWideCamera, for: .video, position: .back) != nil{
            ultrawideCamera=true//12miniに付いている
        }
        if AVCaptureDevice.default(.builtInTelephotoCamera, for: .video, position: .back) != nil{
            telephotoCamera=true
        }
    }
    func getUserDefault(str:String,ret:Int) -> Int{//getUserDefault_one
        if (UserDefaults.standard.object(forKey: str) != nil){//keyが設定してなければretをセット
            return UserDefaults.standard.integer(forKey:str)
        }else{
            UserDefaults.standard.set(ret, forKey: str)
            return ret
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        getCameras()
        if ultrawideCamera==true{//12mini
            cameraType=2
        }else{//ipodTouch
            cameraType=0
        }
        let sound=getUserDefault(str: "recordSound", ret: 1)
//        if sound==0{
//            speakerSwitch.isOn=false
//            speakerImage.tintColor=UIColor.gray
//        }else{
//            speakerSwitch.isOn=true
//            speakerImage.tintColor=UIColor.green
//        }
        print("cameraType",cameraType)
        self.view.backgroundColor = .black
        
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
        LEDBar.value=getUserDefault(str: "LEDValue", ret:0.03)//初期値はmini12に合わせる
        setFlashlevel(level:LEDBar.value)
        focusBar.minimumValue = 0
        focusBar.maximumValue = 1.0
        focusBar.addTarget(self, action: #selector(onFocusValueChange), for: UIControl.Event.valueChanged)
        focusBar.value=getUserDefault(str: "focusValue", ret:0.0)//初期値はmini12に合わせる
        setFocus(focus: focusBar.value)
        setZoom()
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
        setFlashlevel(level: LEDBar.value)
        UserDefaults.standard.set(LEDBar.value, forKey: "LEDValue")
   //     print("led:",LEDBar.value)
    }
    @objc func onFocusValueChange(){
        setFocus(focus:focusBar.value)
        UserDefaults.standard.set(focusBar.value, forKey: "focusValue")
   //     print("focus:",focusBar.value)
    }

    override func viewDidAppear(_ animated: Bool) {
        setButtons()//type: true)
        hideButtons(type:false)
        stopButton.isHidden=true
        currentTime.isHidden=true
        if maxFps==120{
            fps240Button.isHidden=true
        }
        LEDBar.isHidden=false
        LEDHigh.isHidden=false
        LEDLow.isHidden=false
        focusBar.isHidden=false
        focusNear.isHidden=false
        focusFar.isHidden=false
   //     speakerImage.isHidden=false
  //      speakerSwitch.isHidden=false
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
            setFlashlevel(level: LEDBar.value)
            setZoom()
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
            setFlashlevel(level: LEDBar.value)
            setZoom()
        }
    }
    func hideButtons(type:Bool){
     //   speakerImage.isHidden=true
    //    speakerSwitch.isHidden=true
        startButton.isHidden=type
        stopButton.isHidden=type
        currentTime.isHidden=type
        fps240Button.isHidden=type
        fps120Button.isHidden=type
        LEDBar.isHidden=true
        LEDLow.isHidden=true
        LEDHigh.isHidden=true
        focusBar.isHidden=true
        focusNear.isHidden=true
        focusFar.isHidden=true
        exitBut.isHidden=type
        if ultrawideCamera==false && telephotoCamera==false{
            cameraChangeButton.isHidden=true
        }
    }
    func setButtons(){//type:Bool){
        // recording button
        let ww=view.bounds.width
        let bottom=CGFloat( UserDefaults.standard.float(forKey: "bottom"))
        let top=CGFloat(UserDefaults.standard.float(forKey: "top"))
  
        let wh=view.bounds.height-bottom
        let bw=(ww/4)-8
        let bh:CGFloat=60
        let y0=wh-bh-10
        let y1=y0-bh-10
        let y2=y1-bh+bh/4
        let y3=y2-10-bh/2
        let x1=ww-5-bw
        
        currentTime.frame   = CGRect(x:0,   y: 0 ,width: bw*1.5, height: bh/2)
        currentTime.layer.position=CGPoint(x:ww/2,y:wh-bh*4)

        currentTime.layer.masksToBounds = true
        currentTime.layer.cornerRadius = 5
        currentTime.font = UIFont.monospacedDigitSystemFont(ofSize: 25*view.bounds.width/320, weight: .medium)
        
        iroiro.setButtonProperty(fps240Button, x:5,y: y1, w: bw, h:bh,UIColor.gray)
        iroiro.setButtonProperty(fps120Button, x:5,y:y0, w: bw, h: bh,UIColor.gray)

        
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

    //    speakerSwitch.frame=CGRect(x:8,y:y2,width: 47,height: 31)
    //    speakerImage.frame=CGRect(x:60,y:y2,width: 31,height: 31)
        iroiro.setLabelProperty(LEDLow,x:5,y:y3,w:bw,h:bh/2,UIColor.gray)
        iroiro.setLabelProperty(LEDHigh,x:x1,y:y3, w: bw, h:bh/2,UIColor.systemOrange)
        iroiro.setButtonProperty(exitBut,x:x1,y:y0, w: bw, h:bh,UIColor.darkGray)
        LEDBar.frame=CGRect(x:20+bw,y:y3,width:ww-bw*2-40,height:bh/2)
        iroiro.setLabelProperty(focusNear,x:5,y:y3-bh/2-4,w:bw,h:bh/2,UIColor.darkGray)
        iroiro.setLabelProperty(focusFar,x:x1,y:y3-bh/2-4, w: bw, h:bh/2,UIColor.darkGray)
        focusBar.frame=CGRect(x:20+bw,y:y3-bh/2-4,width:ww-bw*2-40,height:bh/2)

        startButton.frame=CGRect(x:(ww-bh*3.2)/2,y:wh-10-bh*3.2,width:bh*3.2,height:bh*3.2)
        stopButton.frame=CGRect(x:(ww-bh*3.2)/2,y:wh-10-bh*3.2,width:bh*3.2,height:bh*3.2)
        startButton.isHidden=true
        stopButton.isHidden=true
        stopButton.tintColor=UIColor.orange
        cameraChangeButton.isHidden=true
        focusBar.isHidden=true
        focusFar.isHidden=true
        focusNear.isHidden=true
        LEDLow.isHidden=true
        LEDHigh.isHidden=true
        LEDBar.isHidden=true
  //      speakerSwitch.isHidden=true
  //      speakerImage.isHidden=true
    }
    
    func initSession(fps:Int) {
        // セッション生成
        captureSession = AVCaptureSession()
        // 入力 : 背面カメラ
        if cameraType==0{
            videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
        }else if cameraType==2{
            videoDevice = AVCaptureDevice.default(.builtInUltraWideCamera, for: .video, position: .back)
        }
        let videoInput = try! AVCaptureDeviceInput.init(device: videoDevice!)
        captureSession.addInput(videoInput)
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
        captureSession.addOutput(fileOutput)
        //手振れ補正はデフォルトがoff
        let videoLayer : AVCaptureVideoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        videoLayer.frame = self.view.bounds
        videoLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill//無くても同じ
        cameraView.layer.addSublayer(videoLayer)
         // セッションを開始する (録画開始とは別)
        captureSession.startRunning()
    }
    func checkinitSession() {//maxFpsを設定
        // セッション生成
        captureSession = AVCaptureSession()
        // 入力 : 背面カメラ
        videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
        let videoInput = try! AVCaptureDeviceInput.init(device: videoDevice!)
        captureSession.addInput(videoInput)
        
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
        captureSession.addOutput(fileOutput)
        
        let videoLayer : AVCaptureVideoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        videoLayer.frame = self.view.bounds
        videoLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill//無くても同じ
        cameraView.layer.addSublayer(videoLayer)
        // セッションを開始する (録画開始とは別)
        captureSession.startRunning()
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
            currentTime.text=String(format:"%02d",timerCnt/60) + ":" + String(format: "%02d",timerCnt%60)
            if timerCnt%2==0{
                stopButton.tintColor=UIColor.orange
            }else{
                stopButton.tintColor=UIColor.red
            }
        }
        if timerCnt > 60*5{
            timer!.invalidate()
            if self.fileOutput.isRecording{
                onClickStopButton(0)
            }else{
                performSegue(withIdentifier: "fromRecordToMain", sender: self)
            }
        }
    }
    func setZoom(){//level:Float){//
    
        var zoom:Float=0
        if cameraType==2{
            if fps_non_120_240==1{
                zoom=0.007
            }else{
                zoom=0.014
            }
        }
        if let device = videoDevice {
        do {
            
            try device.lockForConfiguration()
                device.ramp(
                    toVideoZoomFactor: (device.minAvailableVideoZoomFactor) + CGFloat(zoom) * ((device.maxAvailableVideoZoomFactor) - (device.minAvailableVideoZoomFactor)),
                    withRate: 30.0)
            device.unlockForConfiguration()
            } catch {
                print("Failed to change zoom.")
            }
        }
    }
    func setFocus(focus:Float) {//focus 0:最接近　0-1.0
        if let device = videoDevice{
    //        print("focus-videodevice")
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
 //                   print("focus-changed")
                }
                catch {
                    // just ignore
 //                   print("focus-error")
                }
            }
        }else{
            print("focus-device-error")
        }
    }
  
    var soundIdx:SystemSoundID = 0
    func sound(){
      //  if speakerSwitch.isOn==true{
                 if let soundUrl = URL(string:
                                         "/System/Library/Audio/UISounds/end_record.caf"/*photoShutter.caf*/){
                     AudioServicesCreateSystemSoundID(soundUrl as CFURL, &soundIdx)
                     AudioServicesPlaySystemSound(soundIdx)
                 }
    //         }
    }
    func getFileURL(from filePath: String) -> URL {
        return URL(fileURLWithPath: filePath)
    }
    @IBAction func onClickStartButton(_ sender: Any) {

        sound()
         hideButtons(type: true)
        stopButton.isHidden=true
        currentTime.isHidden=false
        sleep(3)
        UIApplication.shared.isIdleTimerDisabled = true//スリープしない
        sound()
        
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: tempFilePath) {
            do {
                // 🗑 ファイルを削除
                try fileManager.removeItem(at: getFileURL(from: tempFilePath))
                print("✅ 削除成功: \(tempFilePath)")
            } catch {
                print("❌ 削除失敗: \(error.localizedDescription)")
            }
        } else {
            print("⚠️ 指定したファイルは存在しません: \(tempFilePath)")
        }
        if fileManager.fileExists(atPath: TEMPFilePath) {
            do {
                // 🗑 ファイルを削除
                try fileManager.removeItem(at: getFileURL(from: TEMPFilePath))
                print("✅ 削除成功: \(TEMPFilePath)")
            } catch {
                print("❌ 削除失敗: \(error.localizedDescription)")
            }
        } else {
            print("⚠️ 指定したファイルは存在しません: \(TEMPFilePath)")
        }
        
        
        
        
//        try? FileManager.default.removeItem(atPath: TempFilePath)
        
        let fileURL = NSURL(fileURLWithPath: tempFilePath)
        //下３行の様にしたら、ビデオとジャイロのズレが安定した。zure:10
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
    func requestAVAsset(asset: PHAsset)-> AVAsset? {
        guard asset.mediaType == .video else { return nil }
        let phVideoOptions = PHVideoRequestOptions()
        phVideoOptions.version = .original
        let group = DispatchGroup()
        let imageManager = PHImageManager.default()
        var avAsset: AVAsset?
        group.enter()
        imageManager.requestAVAsset(forVideo: asset, options: phVideoOptions) { (asset, _, _) in
            avAsset = asset
            group.leave()
        }
        group.wait()
        return avAsset
    }
     func getFPS(from fileURL: URL) -> Float? {
        let asset = AVURLAsset(url: fileURL)
        
        // 🎥 動画トラックを取得
        if let track = asset.tracks(withMediaType: .video).first {
            return track.nominalFrameRate // FPS（フレームレート）を取得
        }
        
        return nil
    }
    var kalVs:[[CGFloat]]=[[0.0001 ,0.001 ,0,0,0],[0.0001 ,0.001 ,0,0,0],
                           [0.0001 ,0.001 ,0,0,0],[0.0001 ,0.001 ,0,0,0],
                           [0.0001 ,0.001 ,0,0,0],[0.0001 ,0.001 ,0,0,0],
                           [0.0001 ,0.001 ,0,0,0],[0.0001 ,0.001 ,0,0,0]]
    func KalmanS(Q:CGFloat,R:CGFloat,num:Int){
        kalVs[num][4] = (kalVs[num][3] + Q) / (kalVs[num][3] + Q + R);
        kalVs[num][3] = R * (kalVs[num][3] + Q) / (R + kalVs[num][3] + Q);
    }
    func Kalman(value:CGFloat,num:Int)->CGFloat{
        KalmanS(Q:kalVs[num][0],R:kalVs[num][1],num:num);
        let result = kalVs[num][2] + (value - kalVs[num][2]) * kalVs[num][4];
        kalVs[num][2] = result;
        return result;
    }
    func KalmanInit(){
        for i in 0...6{
            kalVs[i][2]=0
            kalVs[i][3]=0
            kalVs[i][4]=0
        }
    }
    var gyroHFiltered = Array<CGFloat>()//.removeAll()
    var gyroVFiltered = Array<CGFloat>()//.removeAll()

    func getGyroCSV()->String{//gyroDataをCSVに変換
        var text:String=""
        for i in 0..<gyroHFiltered.count{
            text += String(Int(gyroHFiltered[i]*100)) + ","
            text += String(Int(gyroVFiltered[i]*100)) + ","
            //            print(text,str,gyroFiltered[i])
        }
        //        print("elapsed time:",CFAbsoluteTimeGetCurrent()-Start,gyroFiltered.count)
//        let txt:NSString = text as NSString
        //        print("elapsed time:",CFAbsoluteTimeGetCurrent()-Start,gyroFiltered.count)
        return text
    }
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if let error = error {
            print("録画エラー: \(error.localizedDescription)")
            startButton.isHidden=true
            stopButton.isHidden=true
            performSegue(withIdentifier: "fromRecordToMain", sender: self)
        }
        print("outputFileURL: \(outputFileURL)")
        let fileURL=getFileURL(from: TEMPFilePath)
        
        
        var dH:Double=0//lateral
        var dV:Double=0//vertical
        var gyroH = Array<Double>()//Holizontal
        var gyroV = Array<Double>()//vertical
        var gyroTime = Array<Double>()
        KalmanInit()
        gyroHFiltered.removeAll()
        gyroVFiltered.removeAll()
          
          for i in 0...gyro.count/3-3{//-2でエラーなので、-3としてみた
            gyroTime.append(gyro[i*3])
            dH=Double(Kalman(value:CGFloat(gyro[i*3+1]*10),num:0))
            dV=Double(Kalman(value:CGFloat(gyro[i*3+2]*10),num:1))
            gyroH.append(-dH)
            gyroV.append(-dV)
        }
        //gyroは10msごとに拾ってある.合わせる
        //これをvideoのフレーム数に合わせる
     
//         let videoCount=Controller.videoCount
//         ビデオが出来るまで待つ
//         while videoDura.count==videoCount{
//             sleep(UInt32(0.5))
//         }
        
//         videoCurrent=videoDura.count-1
//         showVideoIroiro(num:0)
        var fps=getFPS(from: outputFileURL)
        if fps! < 200.0{
            fps! *= 2.0
        }
        let framecount=Int(Float(gyroH.count)*(fps!)/100.0)
        var lastJ:Int=0
        //                let t1=CFAbsoluteTimeGetCurrent()
        for i in 0...framecount+500{//100を尻に付けないとgyrodataが変な値になる
            let gn=Double(i)/Double(fps!)//iフレーム目の秒数
            var getj:Int=0
            for j in lastJ...gyroH.count-1{
                if gyroTime[j] >= gn{//secondの値が入っている。
                    getj=j//越えるところを見つける
                    lastJ=j
                    break
                }
            }
            gyroHFiltered.append(Kalman(value:CGFloat(gyroH[getj]),num:2))
            gyroVFiltered.append(Kalman(value:CGFloat(gyroV[getj]),num: 3))
        }
        let appendCSVData=getGyroCSV()//csv文字列
        //                int rgb[240*60*5*2 + 240*5*2];//5minの水平、垂直と５秒の余裕
        //pixel2imageで240*60*5*2 + 240*5*2の配列を作るので,増やすときは注意
//        let appendData = "Some additional data append 可変長"

        appendVariableSizeGyroDataToMP4(originalURL:outputFileURL, newFileURL:fileURL, gyroData:appendCSVData)
//        print("fileFPS:",getFPS(from: outputFileURL) as Any)
//        print("fileFPSnew:",getFPS(from: fileURL) as Any)
        // 録画が正常に終了した場合、ビデオをアルバムに保存
        recordedFlag=true
        saveToCustomAlbum(url: fileURL)
        
        
  
        
        // 動画のFPSとDurationを取得
//        let asset = AVAsset(url: outputFileURL)
//        setVideoProperties(from: asset)
//        let duration = asset.duration
        //          let durationSeconds = CMTimeGetSeconds(duration)
   
        //          var fps: Float = 0
        //          if let videoTrack = asset.tracks(withMediaType: .video).first {
        //              fps = videoTrack.nominalFrameRate
        //              print("動画のFPS: \(fps)")
        //          }
        //
        //          // FPSとDurationを出力
        //           print("動画の再生時間: \(duration)秒")
    }
  
    // MP4 ファイルにデータを追記
    func appendVariableSizeGyroDataToMP4(originalURL: URL, newFileURL: URL, gyroData: String) {
        do {
            // 🔍 元の MP4 ファイルのデータを読み込む
            let videoData = try Data(contentsOf: originalURL)
            
            // 📝 `<gyro-data>` ヘッダー付きのデータを作成
            let formattedGyroData = "<gyro-data>\n\(gyroData)\n</gyro-data>"
            
            // 🔄 `UTF-8` でエンコード
            let textData = formattedGyroData.data(using: .utf8) ?? Data()
            
            // 🔗 MP4 データ + 可変長の Gyro データを結合
            var combinedData = videoData
            combinedData.append(textData)
            
            // 💾 新しい MP4 ファイルとして保存
            try combinedData.write(to: newFileURL)
            
            print("✅ \(newFileURL) を作成しました")
            
        } catch {
            print("❌ エラー: \(error.localizedDescription)")
        }
    }
    // 🎬 4KB 固定サイズの `<gyro-data>` を MP4 の末尾に書き込む
    func appendFixedSizeGyroDataToMP4(originalURL:URL , newFileURL: URL, gyroData: String) {
        do {
            // 🔍 元の MP4 ファイルのデータを読み込む
            let videoData = try Data(contentsOf: originalURL)
            
            // 📝 `<gyro-data>` ヘッダー付きのデータを作成
            let formattedGyroData = "<gyro-data>\n\(gyroData)\n</gyro-data>"
            
            // 🔄 `UTF-8` でエンコードし、4KB に調整
            var textData = formattedGyroData.data(using: .utf8) ?? Data()
            
            if textData.count > 4096 {
                print("⚠️ Gyro データが 4KB を超えています。切り詰めます。")
                textData = textData.prefix(4096)
            } else if textData.count < 4096 {
                let padding = Data(repeating: 0, count: 4096 - textData.count)
                textData.append(padding)
            }
            
            // 🔗 MP4 データ + 4KB の Gyro データを結合
            var combinedData = videoData
            combinedData.append(textData)
            
            // 💾 新しい MP4 ファイルとして保存
            try combinedData.write(to: newFileURL)
            
            print("✅ \(newFileURL) を作成しました")

        } catch {
            print("❌ エラー: \(error.localizedDescription)")
        }
    }

     // カスタムアルバムに保存
     func saveToCustomAlbum(url: URL) {
         // アルバム名
         let albumName = vHIT96da
         
         // 写真ライブラリに保存
         PHPhotoLibrary.shared().performChanges({
             // アルバムがすでにあるか確認
             let fetchOptions = PHFetchOptions()
             fetchOptions.predicate = NSPredicate(format: "title = %@", albumName)
             let fetchResult = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
             
             var assetCollection: PHAssetCollection?
             if fetchResult.count == 0 {
                 // 新しいアルバムを作成
                 PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: albumName)
                 assetCollection = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions).firstObject
             } else {
                 assetCollection = fetchResult.firstObject
             }
             
             // 写真ライブラリに動画を保存
             let creationRequest = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
             
             guard let album = assetCollection else { return }
             let assetCollectionChangeRequest = PHAssetCollectionChangeRequest(for: album)
             assetCollectionChangeRequest?.addAssets([creationRequest!.placeholderForCreatedAsset!] as NSArray)
             
         }) { success, error in
             if success {
                 self.saved2album=true
                 print("動画をアルバムに保存しました。")
             } else {
                 self.saved2album=false
                 print("アルバム保存に失敗しました: \(String(describing: error))")
             }
             DispatchQueue.main.async {
                 self.performSegue(withIdentifier: "fromRecordToMain", sender: self)
             }
         }
     }
    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection]) {
        recStart=CFAbsoluteTimeGetCurrent()
        setMotion()//ここにしても安定したような
    }
}
