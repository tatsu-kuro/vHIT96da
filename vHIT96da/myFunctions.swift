//
//  recordAlbum.swift
//  Fushiki
//
//  Created by 黒田建彰 on 2021/01/10.
//  Copyright © 2021 tatsuaki.Fushiki. All rights reserved.
//
import UIKit
import Photos
import AVFoundation

class myFunctions: NSObject, AVCaptureFileOutputRecordingDelegate{
    let tempFilePath: String = "\(NSTemporaryDirectory())temp.mp4"
    var defaultAlbumName:String = "any"
    var videoDevice: AVCaptureDevice?
    var captureSession: AVCaptureSession!
    var fileOutput = AVCaptureMovieFileOutput()
    var soundIdx:SystemSoundID = 0
    var saved2album:Bool = false
    var videoDate = Array<String>()
//    var videoURL = Array<URL?>()
    var videoPHAsset = Array<PHAsset>()
    var videoAVAsset = Array<AVAsset>()

    var albumExistFlag:Bool = false
    var dialogStatus:Int=0
    var fpsCurrent:Int=0
    var widthCurrent:Int=0
    var heightCurrent:Int=0
    var cameraMode:Int=0
    init(albumName: String) {
        // 全てのプロパティを初期化する前にインスタンスメソッドを実行することはできない
        self.defaultAlbumName = albumName
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
        let w=width/100
        let left=CGFloat( UserDefaults.standard.float(forKey: "left"))
        if left==0{
            return CGRect(x:width-w,y:height-w,width:w,height:w)
        }else{
            return CGRect(x:left/6,y:height-height/5.5,width:w,height:w)
        }
    }
    func checkEttString(ettStr:String)->Bool{//ettTextがちゃんと並んでいるか like as 1,2:3:20,3:2:20
        let ettTxtComponents = ettStr.components(separatedBy: ",")
        let widthCnt = ettTxtComponents[0].components(separatedBy: ":").count
        var paramCnt = 3
        if ettTxtComponents.count<2{
            return false
        }
        for i in 1...ettTxtComponents.count-1{//3個以外の時はその数値をセット
            let str = ettTxtComponents[i].components(separatedBy: ":")
            if str.count != 3{
                paramCnt = str.count
            }
        }
        
        if widthCnt == 1 && paramCnt == 3 && ettStr.isAlphanumeric(){
            return true
        }else{
            return false
        }
    }
    func albumExists(_ albumTitle: String) -> Bool {
        // ここで以下のようなエラーが出るが、なぜか問題なくアルバムが取得できている
        // [core] "Error returned from daemon: Error Domain=com.apple.accounts Code=7 "(null)""
        let albums = PHAssetCollection.fetchAssetCollections(with: PHAssetCollectionType.album, subtype:
                                                                PHAssetCollectionSubtype.albumRegular, options: nil)
        for i in 0 ..< albums.count {
            let album = albums.object(at: i)
            if album.localizedTitle != nil && album.localizedTitle == albumTitle {
//                vHIT96daAlbum = album
                return true
            }
        }
        return false
    }

    func createNewAlbum(_ albumTitle: String, callback: @escaping (Bool) -> Void) {
        if self.albumExists(albumTitle) {
            callback(true)
        } else {
            PHPhotoLibrary.shared().performChanges({
                _ = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: albumTitle)
            }) { (isSuccess, error) in
                callback(isSuccess)
            }
        }
    }

    func makeAlbum(_ name:String){
        if albumExists(name )==false{
            createNewAlbum(name) {  isSuccess in
                if isSuccess{
                    print(name," can be made,")
                } else{
                    print(name," can't be made.")
                }
            }
        }else{
            print(name," exist already.")
        }
    }

    func getPHAssetcollection()->PHAssetCollection{
        let requestOptions = PHImageRequestOptions()
        requestOptions.isSynchronous = true
        requestOptions.isNetworkAccessAllowed = false
        requestOptions.deliveryMode = .highQualityFormat //これでもicloud上のvideoを取ってしまう
        //アルバムをフェッチ
        let assetFetchOptions = PHFetchOptions()
        assetFetchOptions.predicate = NSPredicate(format: "title == %@", defaultAlbumName)
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

    var gettingThumbFlag:Bool?
    func getThumb(avasset:AVAsset) -> UIImage{//getするまで待って帰る
        gettingThumbFlag=true
        let img=getThumb_sub(avasset:avasset)
        while gettingThumbFlag==true{
            sleep(UInt32(0.1))
        }
        print("getthumb:",img?.size)
        return img!
    }
    func createWhiteImage(with size: CGSize) -> UIImage? {
        // 白い背景のビットマップコンテキストを作成
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        
        // 背景を白に塗りつぶす
        UIColor.white.setFill()
        let rect = CGRect(origin: .zero, size: size)
        UIRectFill(rect)
        
        // 画像を取得
        let image = UIGraphicsGetImageFromCurrentImageContext()
        
        // コンテキストを終了
        UIGraphicsEndImageContext()
        
        return image
    }
  
    func getThumb_sub(avasset:AVAsset) -> UIImage? {
        do {
//            let asset = AVURLAsset(url: url as URL , options: nil)
            let imgGenerator = AVAssetImageGenerator(asset: avasset)
            imgGenerator.appliesPreferredTrackTransform = true
            let cgImage = try imgGenerator.copyCGImage(at: CMTimeMake(value: 0, timescale: 1), actualTime: nil)
            let thumbnail = UIImage(cgImage: cgImage)
            gettingThumbFlag=false
            return thumbnail
        } catch let error {
            print("*** Error generating thumbnail: \(error.localizedDescription)")
            return nil
        }
    }
//    
//    func getThumnailImage(avasset: AVAsset) -> UIImage? {
//        let imageGenerator = AVAssetImageGenerator(asset: avasset)
//        do {
//            let thumnailCGImage = try imageGenerator.copyCGImage(at: CMTimeMake(value: 1,timescale: 60), actualTime: nil)
//            print("well done")
//            return UIImage(cgImage: thumnailCGImage, scale: 0, orientation: .up)
//        }catch let err{
//            print("error\(err)")
//        }
//        return nil
//    }
    func setZoom(level:Float){//
        if !UserDefaults.standard.bool(forKey: "cameraON"){
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
        if !UserDefaults.standard.bool(forKey: "cameraON"){
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
        
        assetFetchOptions.predicate = NSPredicate(format: "title == %@", defaultAlbumName)
        
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
        if !UserDefaults.standard.bool(forKey: "cameraON"){
            return
        }
        if let soundUrl = URL(string:
                                "/System/Library/Audio/UISounds/end_record.caf"/*photoShutter.caf*/){
            let speakerOnOff=UserDefaults.standard.integer(forKey: "speakerOnOff")
            if speakerOnOff==1{
            
            AudioServicesCreateSystemSoundID(soundUrl as CFURL, &soundIdx)
            AudioServicesPlaySystemSound(soundIdx)
            }
        }
        
        
        try? FileManager.default.removeItem(atPath: tempFilePath)
        let fileURL = NSURL(fileURLWithPath: tempFilePath)
        fileOutput.startRecording(to: fileURL as URL, recordingDelegate: self)
    }
    func recordStop(){
        if !UserDefaults.standard.bool(forKey: "cameraON"){
            return
        }
        captureSession.stopRunning()//下行と入れ替えても動く
        fileOutput.stopRecording()
     }
    func stopRunning(){
        if !UserDefaults.standard.bool(forKey: "cameraON"){
            return
        }
        captureSession.stopRunning()
    }

    func initSession(camera:Int,bounds:CGRect,cameraView:UIImageView) {
        // セッション生成
        cameraMode=camera
        if !UserDefaults.standard.bool(forKey: "cameraON"){
            return
        }
        captureSession = AVCaptureSession()
        // 入力 : 背面カメラ
        //Fushiki-->builtInWideAngleCamera
        //builtInUltraWideCamera//12-upper, 8-error, 7plus-error
        //builtInTelephontoCamera//7plus-right,8-error
        //builtInWideAngleCamera//12-lower, 7plus-left, 8
        if camera==0{
            videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
        }else if camera==1{
            videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
        }else if camera==2{
            videoDevice = AVCaptureDevice.default(.builtInUltraWideCamera, for: .video, position: .back)
        }else{
            videoDevice = AVCaptureDevice.default(.builtInTelephotoCamera, for: .video, position: .back)

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
            let speakerOnOff=UserDefaults.standard.integer(forKey: "speakerOnOff")
            if speakerOnOff==1{
            
            AudioServicesCreateSystemSoundID(soundUrl as CFURL, &soundIdx)
            AudioServicesPlaySystemSound(soundIdx)
            }
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
        
        if albumExists(defaultAlbumName)==true{
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
        label.textColor = UIColor.white
        label.backgroundColor = color
    }
   
    func setButtonProperty(_ button:UIButton,x:CGFloat,y:CGFloat,w:CGFloat,h:CGFloat,_ color:UIColor){
        button.frame   = CGRect(x:x, y:y, width: w, height: h)
        button.layer.borderColor = UIColor.black.cgColor
        button.layer.borderWidth = 1.0
        button.layer.cornerRadius = 5
        button.backgroundColor = color
    }
    func setButtonTopRectangle(_ ui:UIButton, rect:CGRect,_ color:UIColor ){
        ui.frame   = CGRect(x:rect.minX+2, y:rect.minY+1, width: rect.width-4, height: 4)
        ui.layer.masksToBounds = true
        ui.layer.cornerRadius = 1
        ui.backgroundColor = color
    }
    func setLabelTopRectangle(_ ui:UILabel, rect:CGRect,_ color:UIColor ){
        ui.frame   = CGRect(x:rect.minX, y:rect.minY, width: rect.width, height: 4)
        ui.layer.masksToBounds = true
        ui.layer.cornerRadius = 3
        ui.backgroundColor = color
    }

    func getUserDefaultCGFloat(str:String,ret:CGFloat) -> CGFloat{
        if (UserDefaults.standard.object(forKey: str) != nil){
            return CGFloat(UserDefaults.standard.float(forKey: str))
        }else{//keyが設定してなければretをセット
            UserDefaults.standard.set(ret, forKey: str)
            return ret
        }
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
    func getUserDefaultString(str:String,ret:String) -> String{
        if (UserDefaults.standard.object(forKey: str) != nil){
            return UserDefaults.standard.string(forKey:str)!
        }else{//keyが設定してなければretをセット
            UserDefaults.standard.set(ret, forKey: str)
            return ret
        }
    }
    func setLedLevel(level:Float){
        
        if !UserDefaults.standard.bool(forKey: "cameraON"){
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
