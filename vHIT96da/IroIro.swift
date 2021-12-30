//
//  IroIro.swift
//  vHIT96da
//
//  Created by 黒田建彰 on 2021/12/30.
//  Copyright © 2021 tatsuaki.kuroda. All rights reserved.
import UIKit
import Photos
import AVFoundation

class myFunctions: NSObject, AVCaptureFileOutputRecordingDelegate{
    let tempFilePath: String = "\(NSTemporaryDirectory())temp.mp4"
    let albumName:String = "iCapNYS"
    var videoDevice: AVCaptureDevice?
    var captureSession: AVCaptureSession!
    var fileOutput = AVCaptureMovieFileOutput()
    var soundIdx:SystemSoundID = 0
    var saved2album:Bool = false
    var videoDate = Array<String>()
//    var videoURL = Array<URL?>()
    var videoAlbumAssets = Array<PHAsset>()

    var albumExistFlag:Bool = false
    var dialogStatus:Int=0
    var fpsCurrent:Int=0
    var widthCurrent:Int=0
    var heightCurrent:Int=0
    var cameraMode:Int=0
//    init(name: String) {
//        // 全てのプロパティを初期化する前にインスタンスメソッドを実行することはできない
//        self.albumName = "Fushiki"//name
//    }
    func getCameraNumber()->Int{
        var cameras:Int = 0
        if AVCaptureDevice.default(.builtInUltraWideCamera, for: .video, position: .back) != nil {
            cameras += 4
        }
        if AVCaptureDevice.default(.builtInTelephotoCamera, for: .video, position: .back) != nil {
            cameras += 2
        }
        if AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) != nil {
            cameras += 1
        }
        return cameras
    }
    //ジワーッと文字を表示するため
    func updateRecClarification(tm: Int)->CGFloat {
        var cnt=tm%40
        if cnt>19{
            cnt = 40 - cnt
        }
        var alpha=CGFloat(cnt)*0.9/20.0//少し目立たなくなる
        alpha += 0.05
        return alpha
    }
    func getRecClarificationRct(width:CGFloat,height:CGFloat)->CGRect{
        let imgH=height/30//415*177 2.34  383*114 3.36 257*112 2.3
        let imgW=imgH*2.3
        let space=imgW*0.1
        return CGRect(x:width-imgW-space,y:height-imgH-space,width: imgW,height:imgH)
    }
    func albumExists() -> Bool {
        // ここで以下のようなエラーが出るが、なぜか問題なくアルバムが取得できている
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
    //何も返していないが、ここで見つけたor作成したalbumを返したい。そうすればグローバル変数にアクセスせずに済む
    func createNewAlbum( callback: @escaping (Bool) -> Void) {
        if self.albumExists() {
            callback(true)
        } else {
            PHPhotoLibrary.shared().performChanges({ [self] in
                _ = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: albumName)
            }) { (isSuccess, error) in
                callback(isSuccess)
            }
        }
    }
    func makeAlbum(){
        if albumExists()==false{
            createNewAlbum() { [self] (isSuccess) in
                if isSuccess{
                    print(albumName," can be made,")
                } else{
                    print(albumName," can't be made.")
                }
            }
        }else{
            print(albumName," exist already.")
        }
    }
    func getPHAssetcollection()->PHAssetCollection{
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

    func getAlbumAssets(){
        let requestOptions = PHImageRequestOptions()
        videoAlbumAssets.removeAll()
//        videoURL.removeAll()
        videoDate.removeAll()
        requestOptions.isSynchronous = true
        requestOptions.isNetworkAccessAllowed = true//これでもicloud上のvideoを取ってしまう
        requestOptions.deliveryMode = .highQualityFormat
        // アルバムをフェッチ
        let assetFetchOptions = PHFetchOptions()
        assetFetchOptions.predicate = NSPredicate(format: "title == %@", albumName)
        let assetCollections = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .smartAlbumVideos, options: assetFetchOptions)
        if (assetCollections.count > 0) {//アルバムが存在しない時
            //同じ名前のアルバムは一つしかないはずなので最初のオブジェクトを使用
            let assetCollection = assetCollections.object(at:0)
            // creationDate降順でアルバム内のアセットをフェッチ
            let fetchOptions = PHFetchOptions()
            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            let assets = PHAsset.fetchAssets(in: assetCollection, options: fetchOptions)
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            for i in 0..<assets.count{
                let asset=assets[i]
                if asset.duration>0{//静止画を省く
                    videoAlbumAssets.append(asset)
//                    print("asset:",asset)
//                    videoURL.append(nil)
                    let date_sub = asset.creationDate
                    let date = formatter.string(from: date_sub!)
                    let duration = String(format:"%.1fs",asset.duration)
                    videoDate.append(date + "(" + duration + ")")
//                    asset.video
                }
            }
        }
    }
   
//    var setURLfromPHAssetFlag:Bool=false
//    var getURL:URL?
/*    func getURLfromPHAsset(asset:PHAsset)->URL?{
        setURLfromPHAssetFlag=false
        setURLfromPHAsset(phasset: asset)
        while setURLfromPHAssetFlag == false{
            sleep(UInt32(0.1))
        }
        print("geturl:",getURL)
        return getURL!
    }*/
    /*
   func getURLfromPHAsset(asset:PHAsset)->URL?{
        setURLfromPHAssetFlag=false
        setURLfromPHAsset(asset: asset)
        while setURLfromPHAssetFlag == false{
            sleep(UInt32(0.1))
        }
        return getURL!
    }
    func setURLfromPHAsset(asset:PHAsset){
        //        let asset = PHAsset.fetchAssets(withLocalIdentifiers: localID, options: nil).object(at: num)
        let options = PHVideoRequestOptions()
        options.version = .original
        PHImageManager.default().requestAVAsset(forVideo: asset, options: options) { [self] (asset: AVAsset?, audioMix: AVAudioMix?, info: [AnyHashable : Any]?) -> Void in
            if let urlAsset = asset as? AVURLAsset {//on iphone?
                let localVideoUrl = urlAsset.url as URL
                getURL = localVideoUrl
                setURLfromPHAssetFlag=true
            }else{//on cloud?
//                getURL = nil//tempFileURL!// URL(string: tempFilePath)
                getURL = URL(string: tempFilePath)
                setURLfromPHAssetFlag=true
            }
        }
    }
    */
 /*   func setURLfromPHAsset(phasset:PHAsset){
        setURLfromPHAssetFlag=false
        PHCachingImageManager().requestAVAsset(forVideo: phasset, options: nil) { (asset, audioMix, args) in
            let asset = asset as! AVURLAsset
            DispatchQueue.main.async {
                self.getURL=asset.url
                self.setURLfromPHAssetFlag=true
                print("url:",self.getURL as Any)
            }
        }
    }*/
    /*
     func playVideo (view: UIViewController, videoAsset: PHAsset) {

         guard (videoAsset.mediaType == .video) else {
             print("Not a valid video media type")
             return
         }

         PHCachingImageManager().requestAVAsset(forVideo: videoAsset, options: nil) { (asset, audioMix, args) in
             let asset = asset as! AVURLAsset

             DispatchQueue.main.async {
                 let player = AVPlayer(url: asset.url)
                 let playerViewController = AVPlayerViewController()
                 playerViewController.player = player
                 view.present(playerViewController, animated: true) {
                     playerViewController.player!.play()
                 }
             }
         }
     }
     */
    
    func setZoom(level:Float){//
        if cameraMode==2{
            return
        }
        if let device = videoDevice {
        do {
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
    
    func setFocus(focus:Float){//focus 0:最接近　0-1.0
        if cameraMode==2{
            return
        }
        if let device = videoDevice {
            do {
                try! device.lockForConfiguration()
                if device.isFocusPointOfInterestSupported{
                    //Add Focus on Point
                    device.focusMode = .locked
                    device.setFocusModeLocked(lensPosition: focus, completionHandler: { _ in
                        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1), execute: {
                            device.unlockForConfiguration()
                        })
                    })
                }
                device.unlockForConfiguration()
            }
        }
    }
    
    func eraseVideo(number:Int) {
        dialogStatus=0
        let requestOptions = PHImageRequestOptions()
        requestOptions.isSynchronous = true
        requestOptions.isNetworkAccessAllowed = false
        requestOptions.deliveryMode = .highQualityFormat //これでもicloud上のvideoを取ってしまう
        //アルバムをフェッチ
        let assetFetchOptions = PHFetchOptions()
        
        assetFetchOptions.predicate = NSPredicate(format: "title == %@", albumName)
        
        let assetCollections = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .smartAlbumVideos, options: assetFetchOptions)
//        print("asset:",assetCollections.count)
        //アルバムが存在しない事もある？
        
        if (assetCollections.count > 0) {
            //同じ名前のアルバムは一つしかないはずなので最初のオブジェクトを使用
            let assetCollection = assetCollections.object(at:0)
            // creationDate降順でアルバム内のアセットをフェッチ
            let fetchOptions = PHFetchOptions()
            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
            let assets = PHAsset.fetchAssets(in: assetCollection, options: fetchOptions)
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
//            var eraseAssetDate=assets[0].creationDate
//            var eraseAssetPngNumber=0
            for i in 0..<assets.count{
                let date_sub=assets[i].creationDate
                let date = formatter.string(from:date_sub!)
                if videoDate[number].contains(date){
                    if !assets[i].canPerform(.delete) {
                        return
                    }
                    var delAssets=Array<PHAsset>()
                    delAssets.append(assets[i])
                    
                    PHPhotoLibrary.shared().performChanges({
                        PHAssetChangeRequest.deleteAssets(NSArray(array: delAssets))
                    }, completionHandler: { [self] success,error in//[self] _, _ in
                        if success==true{
                            dialogStatus = 1//YES
                        }else{
                            dialogStatus = -1//NO
                        }
                        // 削除後の処理
                    })
//                    break
                }
            }
        }
    }

    func recordStart(){
        if cameraMode==2{
            return
        }
        try? FileManager.default.removeItem(atPath: tempFilePath)
        let fileURL = NSURL(fileURLWithPath: tempFilePath)
        fileOutput.startRecording(to: fileURL as URL, recordingDelegate: self)
    }
    func recordStop(){
        if cameraMode==2{
            return
        }
        captureSession.stopRunning()//下行と入れ替えても動く
        fileOutput.stopRecording()
     }
    func stopRunning(){
        if cameraMode==2{
            return
        }
        captureSession.stopRunning()
    }
    var topPadding:CGFloat=0
    var bottomPadding:CGFloat=0
    var leftPadding:CGFloat=0
    var rightPadding:CGFloat=0
    func getAllPadding(view:UIView) {
        if #available(iOS 11.0, *) {
            // viewDidLayoutSubviewsではSafeAreaの取得ができている
            topPadding = view.safeAreaInsets.top
            bottomPadding = view.safeAreaInsets.bottom
            leftPadding = view.safeAreaInsets.left
            rightPadding = view.safeAreaInsets.right
            print("in viewDidLayoutSubviews")
            print(topPadding,bottomPadding,leftPadding,rightPadding)
        }
    }
    func initSession(camera:Int,bounds:CGRect,cameraView:UIImageView) {
        // セッション生成
        cameraMode=camera
        if cameraMode==2{
            return
        }
        captureSession = AVCaptureSession()
        // 入力 : 背面カメラ
        if camera==0{
        videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
        }else{
            videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
        }
        let videoInput = try! AVCaptureDeviceInput.init(device: videoDevice!)
        captureSession.addInput(videoInput)

        if switchFormat(desiredFps: 240.0)==false{
            if switchFormat(desiredFps: 120.0)==false{
                if switchFormat(desiredFps: 60.0)==false{
                    if switchFormat(desiredFps: 30.0)==false{
                        print("set fps error")
                    }
                }
            }
        }
//        print("fps:",fpsCurrent)
        // ファイル出力設定
        //orientation.rawValue
        fileOutput = AVCaptureMovieFileOutput()
        captureSession.addOutput(fileOutput)
        let videoDataOuputConnection = fileOutput.connection(with: .video)
        videoDataOuputConnection!.videoOrientation = AVCaptureVideoOrientation(rawValue: AVCaptureVideoOrientation.landscapeRight.rawValue)!
        if bounds.width != 0{//previewしない時は、bounds.width==0とする
            let videoLayer : AVCaptureVideoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            videoLayer.frame = bounds
            videoLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill//無くても同じ
            videoLayer.connection!.videoOrientation = .landscapeRight//　orientation
            cameraView.layer.addSublayer(videoLayer)
        }
        // セッションを開始する (録画開始とは別)
        captureSession.startRunning()
        //手振れ補正はデフォルトがoff
        //        fileOutput.connections[0].preferredVideoStabilizationMode=AVCaptureVideoStabilizationMode.off
    }
 
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
                    widthCurrent = Int(dimensions.width)
                    heightCurrent = Int(dimensions.height)
                }
            }
        }
        fpsCurrent=0
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
                fpsCurrent=Int(desiredFps)
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
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if let soundUrl = URL(string:
                                "/System/Library/Audio/UISounds/end_record.caf"/*photoShutter.caf*/){
            AudioServicesCreateSystemSoundID(soundUrl as CFURL, &soundIdx)
            AudioServicesPlaySystemSound(soundIdx)
        }
         print("終了ボタン、最大を超えた時もここを通る")
        //         motionManager.stopDeviceMotionUpdates()//ここで止めたが良さそう。
        //         //        recordedFPS=getFPS(url: outputFileURL)
        //         //        topImage=getThumb(url: outputFileURL)
        //
        //         if timer?.isValid == true {
        //             timer!.invalidate()
        //    }
        //    let album = AlbumController(name:"fushiki")
        
        if albumExists()==true{
//            recordedFlag=true
            PHPhotoLibrary.shared().performChanges({ [self] in
                //let assetRequest = PHAssetChangeRequest.creationRequestForAsset(from: avAsset)
                let assetRequest = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: outputFileURL)!
                let albumChangeRequest = PHAssetCollectionChangeRequest(for: getPHAssetcollection())
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
            //上二つをunwindでチェック
            //アプリ起動中にアルバムを消したら、保存せずに戻る。
            //削除してもどこかにあるようで、参照URLは生きていて、再生できる。
        }
        while saved2album==false{
            sleep(UInt32(0.1))
        }
//        captureSession.stopRunning()
        //         performSegue(withIdentifier: "fromRecordToMain", sender: self)
    }
    func setLabelProperty(_ label:UILabel,x:CGFloat,y:CGFloat,w:CGFloat,h:CGFloat,_ color:UIColor){
        label.frame = CGRect(x:x, y:y, width: w, height: h)
        label.layer.borderColor = UIColor.black.cgColor
        label.layer.borderWidth = 1.0
        label.layer.masksToBounds = true
        label.layer.cornerRadius = 5
        label.backgroundColor = color
    }
    //button.backgroundColor = color
    func setButtonProperty(_ button:UIButton,x:CGFloat,y:CGFloat,w:CGFloat,h:CGFloat,_ color:UIColor){
        button.frame   = CGRect(x:x, y:y, width: w, height: h)
        button.layer.borderColor = UIColor.black.cgColor
        button.layer.borderWidth = 1.0
        button.layer.cornerRadius = 5
        button.backgroundColor = color
    }
    func getUserDefaultInt(str:String,ret:Int) -> Int{
        if (UserDefaults.standard.object(forKey: str) != nil){//keyが設定してなければretをセット
            return UserDefaults.standard.integer(forKey:str)
        }else{
            UserDefaults.standard.set(ret, forKey: str)
            return ret
        }
    }
    func getUserDefaultBool(str:String,ret:Bool) -> Bool{
        if (UserDefaults.standard.object(forKey: str) != nil){
            return UserDefaults.standard.bool(forKey: str)
        }else{//keyが設定してなければretをセット
            UserDefaults.standard.set(ret, forKey: str)
            return ret
        }
    }
    func getUserDefaultFloat(str:String,ret:Float) -> Float{
        if (UserDefaults.standard.object(forKey: str) != nil){
            return UserDefaults.standard.float(forKey: str)
        }else{//keyが設定してなければretをセット
            UserDefaults.standard.set(ret, forKey: str)
            return ret
        }
    }
    func setLedLevel(level:Float){
        if cameraMode==2{
            return
        }
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
}

