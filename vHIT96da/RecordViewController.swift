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
    var fileOutput = AVCaptureMovieFileOutput()
    var gyro = Array<Double>()
    var recStart = CFAbsoluteTimeGetCurrent()

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
    @IBAction func startRecord(_ sender: Any) {
        onClickRecordButton()
    }
    
    @IBOutlet weak var damyBottom: UILabel!
    @IBAction func stopRecord(_ sender: Any) {
        onClickRecordButton()
    }
    func drawSquare(x:CGFloat,y:CGFloat){
        /* --- 正方形を描画 --- */
        let dia:CGFloat = view.bounds.width/5
        let squareLayer = CAShapeLayer.init()
        let squareFrame = CGRect.init(x:x-dia/2,y:y-dia/2,width:dia,height:dia)
        squareLayer.frame = squareFrame
        // 輪郭の色
        squareLayer.strokeColor = UIColor.red.cgColor
        // 中の色
        squareLayer.fillColor = UIColor.clear.cgColor//UIColor.red.cgColor
        // 輪郭の太さ
        squareLayer.lineWidth = 1.0
        // 正方形を描画
        squareLayer.path = UIBezierPath.init(rect: CGRect.init(x: 0, y: 0, width: squareFrame.size.width, height: squareFrame.size.height)).cgPath
        self.view.layer.addSublayer(squareLayer)
    }

    var tapFlag:Bool=false
    @IBAction func tapGes(_ sender: UITapGestureRecognizer) {
        let screenSize=cameraView.bounds.size
        let x0 = sender.location(in: self.view).x
        let y0 = sender.location(in: self.view).y
        print("tap:",x0,y0,screenSize.height)
        
        if y0>view.bounds.height*3/5{//screenSize.height*3/4{
            return
        }
        let x = y0/screenSize.height
        let y = 1.0 - x0/screenSize.width
        let focusPoint = CGPoint(x:x,y:y)
        
        if let device = videoDevice{
            do {
                try device.lockForConfiguration()
                
                device.focusPointOfInterest = focusPoint
                //                device.focusMode = .continuousAutoFocus
                device.focusMode = .autoFocus
                //                device.focusMode = .locked
                // 露出の設定
                if device.isExposureModeSupported(.continuousAutoExposure) && device.isExposurePointOfInterestSupported {
                    device.exposurePointOfInterest = focusPoint
                    device.exposureMode = .continuousAutoExposure
                }
                device.unlockForConfiguration()
                
                if tapFlag {
                    view.layer.sublayers?.removeLast()
                }
                drawSquare(x: x0, y: y0)
                tapFlag=true;
                //                }
            }
            catch {
                // just ignore
            }
        }
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
        //time0=CFAbsoluteTimeGetCurrent()
        //        var initf:Bool=false
        motionManager.startDeviceMotionUpdates(to: OperationQueue.current!, withHandler: { (motion, error) in
            guard let motion = motion, error == nil else { return }
            self.gyro.append(CFAbsoluteTimeGetCurrent())
            self.gyro.append(motion.rotationRate.y)//
           })
    }
 
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .black
        print("maxFps,fps2:",maxFps,fps_non_120_240)
        if UserDefaults.standard.object(forKey: "maxFps") != nil{
            maxFps = Double(UserDefaults.standard.integer(forKey:"maxFps"))
            fps_non_120_240 = UserDefaults.standard.integer(forKey: "fps_non_120_240")
            initSession(fps: fps_non_120_240)
          }else{
            checkinitSession()//maxFpsを設定
            UserDefaults.standard.set(Int(maxFps),forKey: "maxFps")
            UserDefaults.standard.set(fps_non_120_240,forKey: "fps_non_120_240")
            print("生まれて初めての時だけ、通るところのはず")//ここでmaxFpsを設定
        }
        hideButtons(type: true)
        setButtons(type: true)
//        stopButton.isHidden=true
        startButton.isHidden=false
        print("maxFps,fps2:",maxFps,fps_non_120_240)
//        setFlashlevel(level: 0.0)
        LEDBar.minimumValue = 0
        LEDBar.maximumValue = 0.1
        LEDBar.addTarget(self, action: #selector(onLEDValueChange), for: UIControl.Event.valueChanged)
        LEDBar.value=getUserDefault(str: "LEDValue", ret:0)
        setFlashlevel(level: LEDBar.value)
        
        focusBar.minimumValue = 0
        focusBar.maximumValue = 1.0
        focusBar.addTarget(self, action: #selector(onSliderValueChange), for: UIControl.Event.valueChanged)
        focusBar.value=getUserDefault(str: "focusValue", ret: 0)
        setFocus(focus: focusBar.value)
        
//        flashFlag=false
//        let flashFlagTemp=getUserDefault(str: "flashFlag", ret: 0)
//        if flashFlagTemp==1{
//            LEDonoff(0)
//        }
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
        setFocus(focus:focusBar.value)
        UserDefaults.standard.set(focusBar.value, forKey: "focusValue")
    }
    override func viewDidAppear(_ animated: Bool) {
        hideButtons(type: false)
        setButtons(type: true)
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
    }
    func setButtons(type:Bool){
        // recording button
        let ww=view.bounds.width
        let wh=damyBottom.frame.maxY// view.bounds.height
        let bw=(ww/4)-8
        //        let bd=Int(ww/5/4)
        let bh:CGFloat=60
        let bpos=wh-bh/2-10

        currentTime.frame   = CGRect(x:0,   y: 0 ,width: bw*1.5, height: bh/2)
        currentTime.layer.position=CGPoint(x:ww/2,y:wh-bh*2.5)
        currentTime.isHidden=true
        currentTime.layer.masksToBounds = true
        currentTime.layer.cornerRadius = 5
        
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
//            fps240Button.isHidden=true
            fps120Button.backgroundColor=UIColor.gray
            fps120Button.isEnabled=false
            fps120Button.isHidden=false
        }else{
            fps240Button.isHidden=false
//            fps120Button.isEnabled=false
            fps120Button.isHidden=false
        }
        //startButton
//        LEDCircle.frame=CGRect(x:0,y:0,width:bw,height: bh)
//        LEDCircle.layer.position=CGPoint(x:ww-10-bw/2,y:bpos-40-bh*12/4)
//        setButtonProperty(button: LEDButton, bw: bw, bh: bh/2, cx: ww-10-bw/2, cy: bpos-100-bh*9/4)
        setLabelProperty(label: focusNear,bw:bw,bh:bh/2,cx:(10+bw)/2,cy:bpos-20-bh*7/4)
        setLabelProperty(label:focusFar, bw: bw, bh:bh/2, cx:ww-10-bw/2, cy:bpos-20-bh*7/4)
        setLabelProperty(label: LEDLow,bw:bw,bh:bh/2,cx:(10+bw)/2,cy:bpos-30-bh*9/4)
        setLabelProperty(label:LEDHigh, bw: bw, bh:bh/2, cx:ww-10-bw/2, cy:bpos-30-bh*9/4)
        focusBar.frame=CGRect(x:0,y:0,width:ww-bw*2-40,height:bh/2)
        focusBar.layer.position=CGPoint(x:ww/2,y:bpos-20-bh*7/4)
        LEDBar.frame=CGRect(x:0,y:0,width:ww-bw*2-40,height:bh/2)
        LEDBar.layer.position=CGPoint(x:ww/2,y:bpos-30-bh*9/4)
    
        startButton.frame=CGRect(x:0,y:0,width:bh*2,height:bh*2)
        startButton.layer.position = CGPoint(x:ww/2,y:bpos-bh/3)
        stopButton.frame=CGRect(x:0,y:0,width:bh*2,height:bh*2)
        stopButton.layer.position = CGPoint(x:ww/2,y:bpos-bh/3)
        startButton.isHidden=false
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
        videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
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
        fileOutput.maxRecordedDuration = CMTimeMake(value:5*60, timescale: 1)//最長録画時間
        session.addOutput(fileOutput)
        
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
        fileOutput.maxRecordedDuration = CMTimeMake(value: 5*60, timescale: 1)//最長録画時間
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
    
    var counter:Int=0
    @objc func update(tm: Timer) {
        if fileOutput.isRecording{
            counter += 1
            currentTime.text=String(format:"%02d",counter/60) + ":" + String(format: "%02d",counter%60)
            if counter%2==0{
                stopButton.tintColor=UIColor.orange
            }else{
                stopButton.tintColor=UIColor.red
            }
        }else{
            UserDefaults.standard.set(videoDevice?.lensPosition, forKey: "focusValue")
            focusBar.value=videoDevice!.lensPosition
        }
    }
    func setFocus(focus:Float) {//focus 0:最接近　0-1.0
         if let device = videoDevice{
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
            }
        }
    }
    func albumCheck(){//ここでもチェックしないとダメのよう
        if albumExists(albumTitle: "iCapNYS")==false{
            createNewAlbum(albumTitle: "iCapNYS") { (isSuccess) in
                if isSuccess{
                    print("iCapNYS_album can be made,")
                } else{
                    print("iCapNYS_album can't be made.")
                }
            }
        }else{
            print("iCapNYS_album exist already.")
        }
    }
    func onClickRecordButton() {
        albumCheck()
        if self.fileOutput.isRecording {
            // stop recording
            print("ストップボタンを押した。")
            fileOutput.stopRecording()
        } else {
            //start recording
            setMotion()
            hideButtons(type: true)
            stopButton.isHidden=false
            currentTime.isHidden=false
            UIApplication.shared.isIdleTimerDisabled = true//スリープしない
            if let soundUrl = CFBundleCopyResourceURL(CFBundleGetMainBundle(), nil, nil, nil){
                AudioServicesCreateSystemSoundID(soundUrl, &soundIdstart)
                AudioServicesPlaySystemSound(soundIdstart)
            }
            
            let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
            let documentsDirectory = paths[0] as String
            // 現在時刻をファイル名に付与することでファイル重複を防ぐ : "myvideo-20190101125900.mp4" な形式になる
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd_HH:mm:ss"
            filePath = "vHIT96da\(formatter.string(from: Date())).MOV"
            let filefullPath="\(documentsDirectory)/" + filePath!
            let fileURL = NSURL(fileURLWithPath: filefullPath)
            //               setMotion()//作動中ならそのまま戻る
            print("録画開始 : \(filePath!)")
            fileOutput.startRecording(to: fileURL as URL, recordingDelegate: self)
        }
    }
    // アルバムが既にあるか確認し、iCapNYSAlbumに代入
    func albumExists(albumTitle: String) -> Bool {
        // ここで以下のようなエラーが出るが、なぜか問題なくアルバムが取得できている
        // [core] "Error returned from daemon: Error Domain=com.apple.accounts Code=7 "(null)""
        let albums = PHAssetCollection.fetchAssetCollections(with: PHAssetCollectionType.album, subtype:
            PHAssetCollectionSubtype.albumRegular, options: nil)
        for i in 0 ..< albums.count {
            let album = albums.object(at: i)
            if album.localizedTitle != nil && album.localizedTitle == albumTitle {
                vHIT96daAlbum = album
                return true
            }
        }
        return false
    }
    
    //何も返していないが、ここで見つけたor作成したalbumを返したい。そうすればグローバル変数にアクセスせずに済む
    func createNewAlbum(albumTitle: String, callback: @escaping (Bool) -> Void) {
        if self.albumExists(albumTitle: albumTitle) {
            callback(true)
        } else {
            PHPhotoLibrary.shared().performChanges({
                let createAlbumRequest = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: albumTitle)
            }) { (isSuccess, error) in
                callback(isSuccess)
            }
        }
    }
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if let soundUrl = CFBundleCopyResourceURL(CFBundleGetMainBundle(), nil, nil, nil){
            AudioServicesCreateSystemSoundID(soundUrl, &soundIdstop)
            AudioServicesPlaySystemSound(soundIdstop)
        }
        print("終了ボタン、最大を超えた時もここを通る")
        motionManager.stopDeviceMotionUpdates()//ここで止めたが良さそう。
        
        recordedFlag=true
        if timer?.isValid == true {
            timer!.invalidate()
        }
        performSegue(withIdentifier: "fromRecordToMain", sender: self)
    }
    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection]) {
        recStart=CFAbsoluteTimeGetCurrent()
        print("録画開始")
        //fileOutput.stopRecording()
     }
}
