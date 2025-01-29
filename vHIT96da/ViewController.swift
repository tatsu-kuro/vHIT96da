//
//  ViewController.swift
//  vHIT96da
//
//  Created by kuroda tatsuaki on 2018/02/10.
//  Copyright © 2018年 tatsuaki.kuroda. All rights reserved.
//  main202303をmainにした。2023/3/25
//  mainをまたmainに戻した。2023/4/4

import UIKit
import AVFoundation
import AssetsLibrary
import Photos
import MessageUI

extension UIAlertController {
    
    func setMessageAlignment(_ alignment : NSTextAlignment) {
        let paragraphStyle = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
        paragraphStyle.alignment = alignment
        
        let messageText = NSMutableAttributedString(
            string: self.message ?? "",
            attributes: [
                NSAttributedString.Key.paragraphStyle: paragraphStyle,
                NSAttributedString.Key.font: UIFont.systemFont(ofSize: 15),
                NSAttributedString.Key.foregroundColor: UIColor.black
            ]
        )
        self.setValue(messageText, forKey: "attributedMessage")
    }
}

extension UIImage {
    func pixelData() -> [UInt8]? {
        let size = self.size
        let dataSize = size.width * size.height * 4
        var pixelData = [UInt8](repeating: 0, count: Int(dataSize))
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: &pixelData,
                                width: Int(size.width),
                                height: Int(size.height),
                                bitsPerComponent: 8,
                                bytesPerRow: 4 * Int(size.width),
                                space: colorSpace,
                                bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)
        guard let cgImage = self.cgImage else { return nil }
        context?.draw(cgImage, in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        return pixelData
    }
 
    func resize(size _size: CGSize) -> UIImage? {
          let widthRatio = _size.width / size.width
          let heightRatio = _size.height / size.height
          let ratio = min(widthRatio, heightRatio)
          
          let resizedSize = CGSize(width: size.width * ratio, height: size.height * ratio)
          
          // UIGraphicsImageRenderer を使用
          let renderer = UIGraphicsImageRenderer(size: resizedSize)
          
          return renderer.image { _ in
              draw(in: CGRect(origin: .zero, size: resizedSize))
          }
      }
      func createGrayImage(r: [CGFloat], g: [CGFloat], b: [CGFloat], a: [CGFloat]) -> UIImage {
          let wid = Int(size.width)
          let hei = Int(size.height)
          let renderer = UIGraphicsImageRenderer(size: size)

          return renderer.image { context in
              for w in 0..<wid {
                  for h in 0..<hei {
                      let index = (w * wid) + h
                      let grayValue = 0.2126 * r[index] + 0.7152 * g[index] + 0.0722 * b[index]
                      UIColor(red: grayValue, green: grayValue, blue: grayValue, alpha: a[index]).setFill()
                      let drawRect = CGRect(x: w, y: h, width: 1, height: 1)
                      context.fill(drawRect)
                  }
              }
          }
      }

    
      func tint(color: [UIColor]) -> UIImage {
          let renderer = UIGraphicsImageRenderer(size: size)
          return renderer.image { context in
              var colorCnt: Int = 0
              let colorTotalCnt = color.count
              
              for w in 0..<Int(size.width) {
                  for h in 0..<Int(size.height) {
                      let index = (w * Int(size.width)) + h
                      if colorCnt == colorTotalCnt {
                          color[index - 1].setFill()
                          let drawRect = CGRect(x: w, y: h, width: 1, height: 1)
                          context.cgContext.fill(drawRect)
                          self.draw(in: drawRect, blendMode: .destinationIn, alpha: 0)
                          break
                      } else {
                          color[index].setFill()
                          let drawRect = CGRect(x: w, y: h, width: 1, height: 1)
                          context.cgContext.fill(drawRect)
                          self.draw(in: drawRect, blendMode: .destinationIn, alpha: 1)
                      }
                      colorCnt += 1
                  }
                  if colorCnt == colorTotalCnt {
                      break
                  }
              }
          }
      }
   

      func createImage(r: [CGFloat], g: [CGFloat], b: [CGFloat], a: [CGFloat]) -> UIImage {
          let renderer = UIGraphicsImageRenderer(size: size)
          return renderer.image { context in
              let wid = Int(size.width)
              let hei = Int(size.height)
              
              for w in 0..<wid {
                  for h in 0..<hei {
                      let index = (w * wid) + h
                      UIColor(red: r[index], green: g[index], blue: b[index], alpha: a[index]).setFill()
                      let drawRect = CGRect(x: w, y: h, width: 1, height: 1)
                      context.cgContext.fill(drawRect)
                      self.draw(in: drawRect, blendMode: .destinationIn, alpha: 1)
                  }
                  print("createImage/h:", w)
              }
          }
      }
     
  }

@available(iOS 13.0, *)
class ViewController: UIViewController, MFMailComposeViewControllerDelegate{
    var userID:String="????"//起動時にuserDefaultに保存してあればそれとPWDをセット、
    //なければ新規にメールで申請して貰ったものとPWDをセットする
    let openCV = opencvWrapper()
    let iroiro = myFunctions(albumName: "vHIT96da")
    var writingDataNow:Bool = false//videoを解析した値をアレイに書き込み中
    var readingDataNow:Bool = false//VOGimageを作るためにアレイデータを読み込み中
    var vhitCurpoint:Int = 0//現在表示波形の視点（アレイインデックス）
    
    var videoPlayer: AVPlayer!
    let vHIT96da:String="vHIT96da"
    let Wave96da:String="Wave96da"
    var matchingTestMode:Bool=false
    var fpsIs120:Bool=false
    var currentVideoFPS:Float=0
    @IBOutlet weak var waveSlider: UISlider!
    @IBOutlet weak var videoSlider: UISlider!
    //以下はalbum関連
    var albumExist:Bool=false
    var videoDate = Array<String>()
    var videoDura = Array<String>()
    var videoPHAsset = Array<PHAsset>()
    var pngPHAsset = Array<PHAsset>()
    var videoCurrent:Int=0
    
    //album関連、ここまで
    var vogImage:UIImage?
    @IBOutlet weak var cameraButton: UIButton!
    var boxiesFlag:Bool=false
    @IBOutlet weak var changeModeButton: UIButton!
    @IBOutlet weak var changeModeButton1: UIButton!
    
    @IBOutlet weak var changeModeButton2: UIButton!
    @IBOutlet weak var backwardButton: UIButton!
    
 //iCloudFileMagangeここから
    let iCloudManager = iCloudFileManager()
    func iCloudSaveTextFile(fileName:String,textContent:String){//使い方
   //     let fileName = "test.txt"
    //    let textContent = "iCloudに保存するテキスト"
      
        // 保存
        iCloudManager.saveTextFile(fileName: fileName, content: textContent) { success, error in
            DispatchQueue.main.async{
                if success {
                    print("✅ ファイル保存成功: \(fileName)")
                } else {
                    print("❌ 保存失敗: \(error?.localizedDescription ?? "不明なエラー")")
                }
            }
        }
    }
    func iCloudLoadTextFile(fileName:String){
        // 読み込み
        iCloudManager.loadTextFile(fileName: fileName) { content, error in
            if let content = content {
                print("📄 読み込んだ内容: \(content)")
            } else {
                print("❌ 読み込み失敗: \(error?.localizedDescription ?? "不明なエラー")")
            }
        }
    }
    func iCloudListFiles(){
        // ファイル一覧
        iCloudManager.listFiles { files, error in
            if let files = files {
                print("📂 iCloudのファイル一覧: \(files)")
            } else {
                print("❌ ファイル一覧取得失敗: \(error?.localizedDescription ?? "不明なエラー")")
            }
        }
    }
    func iCloudDeleteFile(fileName:String){
        // 削除
        iCloudManager.deleteFile(fileName: fileName) { success, error in
            if success {
                print("🗑️ ファイル削除成功: \(fileName)")
            } else {
                print("❌ 削除失敗: \(error?.localizedDescription ?? "不明なエラー")")
            }
        }
    }
//iCloudFileManagerここまで
    
    var videoPlayMode:Int = 0//0:playerに任せる 1:backward 2:forward
    @IBAction func onPlayButton(_ sender: Any) {
        
        setVideoButtons(mode: true)
        
        showBoxies(f: false)
        videoPlayMode=0
        
        startTimerVideo()
        if (videoPlayer.rate != 0) && (videoPlayer.error == nil) {//playing
            videoPlayer.pause()
        }else{
            videoPlayer.play()
        }
    }
    
    func forwardBackwardButton(mode:Int){
        if checkDispMode() != 0{
            return
        }
        startTimerVideo()
        if videoDate.count == 0{
            return
        }
        if videoPlayMode==mode{
            videoPlayMode=0
            return
        }
        showBoxies(f: false)
        videoPlayer.pause()
        videoPlayMode=mode
    }
    @IBAction func onBackwardButton(_ sender: Any) {
        videoPlayer.pause()
        videoPlayMode=0
        videoSlider.value=0
        let newTime = CMTime(seconds: Double(videoSlider.value), preferredTimescale: 600)
        videoPlayer.seek(to: newTime, toleranceBefore: .zero, toleranceAfter: .zero)
        startFrame=0
        dispWakus()
        showWakuImages()
    }
    //cameraforword
    
    
    var mailWidth:CGFloat=0//VOG
    var mailHeight:CGFloat=0//VOG
    
    @IBOutlet weak var waveBoxView: UIImageView!
    
    @IBOutlet weak var vHITBoxView: UIImageView!
    
    var vHITDisplayMode:Int=0
    
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var eraseButton: UIButton!
    var startFrame:Int=0
    var calcFlag:Bool = false//calc中かどうか
    var nonsavedFlag:Bool = false //calcしてなければfalse, calcしたらtrue, saveしたらfalse
    //vHITeyeがちゃんと読めない瞬間が生じるようだ
    
    @IBOutlet weak var videoFps: UILabel!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var helpButton: UIButton!
    @IBOutlet weak var waveButton: UIButton!
    @IBOutlet weak var stopButton: UIButton!
    @IBOutlet weak var listButton: UIButton!
    @IBOutlet weak var calcButton: UIButton!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var paraButton: UIButton!
    @IBOutlet weak var eyeWaku_image: UIImageView!
    
    @IBOutlet weak var wakuShowEye_image: UIImageView!
    
    
    var wakuE = CGRect(x:300.0,y:100.0,width:5.0,height:5.0)
    var wakuF = CGRect(x:300.0,y:200.0,width:5.0,height:5.0)
    
    @IBOutlet weak var currentVideoDate: UILabel!
    var calcDate:String = ""
    var idString:String = "00000000"
    var vHITtitle:String = ""
    
    var widthRange:Int = 0
    var waveWidth:Int = 0
    var wakuLength:Int = 0
    var eyeBorder:Int = 20
    var eyeRatio:Int = 100//vhit
    var gyroRatio:Int = 100//vhit
    
    var calcMode:Int?//0:HIThorizontal 1:HITvertical 2:VOG
    
    var videoGyroZure:Int = 20
    var vorGainCorrection:Int = 100
    //解析結果保存用配列
    
    var waveTuple = Array<(Int,Int,Int,Int)>()//rl,framenum,disp onoff,current disp onoff)
    var tempTuple = Array<(Int,Int,Int,Int)>()
    var eyePosXFiltered = Array<CGFloat>()//eyePosFiltered
    var eyeVeloXFiltered = Array<CGFloat>()//eyeVeloFiltered
    var eyePosYFiltered = Array<CGFloat>()//eyePosFiltered
    var eyeVeloYFiltered = Array<CGFloat>()//eyeVeloFiltered
    //update(timer)では、まずcalc threadを止めてデータをもらってcalc thread再開し、もらったデータを処理する
    //calcとtimerでデータを同時に扱うとエラーが出るようだ
    var eyePosXFiltered4update = Array<CGFloat>()
    var eyeVeloXFiltered4update = Array<CGFloat>()
    var eyePosYFiltered4update = Array<CGFloat>()
    var eyeVeloYFiltered4update = Array<CGFloat>()
    var gyroHFiltered = Array<CGFloat>()//gyroFiltered
    var gyroVFiltered = Array<CGFloat>()//gyroFiltered
    var gyroMoved = Array<CGFloat>()//gyroVeloFilterd
    var errArray = Array<Bool>()//gyroVeloFilterd
    
    var timerCalc: Timer!
    var timerVideo:Timer!
    
    var eyeWs = [[CGFloat]](repeating:[CGFloat](repeating:0,count:125),count:80)
    var gyroWs = [[CGFloat]](repeating:[CGFloat](repeating:0,count:125),count:80)
    var initialFlag:Bool=true//:Int = 0
    func playCurrentVideo(){//nextVideo
        //        print("videoCurrent:",videoCurrent, videoPHAsset.count,videoDate.count)
        let avasset = iroiro.requestAVAsset(asset: videoPHAsset[videoCurrent])
        //        print("avasset:",avasset)
        let videoDuration=Float(CMTimeGetSeconds(avasset!.duration))
        let playerItem: AVPlayerItem = AVPlayerItem(asset: avasset!)
        currentVideoFPS=avasset!.tracks.first!.nominalFrameRate
        // Create AVPlayer
        videoPlayer = AVPlayer(playerItem: playerItem)
        // Add AVPlayer
        let layer = AVPlayerLayer()
        layer.videoGravity = AVLayerVideoGravity.resize//resizeAspect
        layer.player = videoPlayer
        layer.frame = view.bounds
        //        print("layerCount:",view.layer.sublayers?.count)
        if initialFlag==true{//1回目は一番奥にビデオのlayerを加える。
            view.layer.insertSublayer(layer, at: 0)
            initialFlag = false
        }else{//2回目からは一番奥のlayerに置き換える。
            view.layer.sublayers![0]=layer
        }
        videoSlider.minimumValue = 0
        videoSlider.maximumValue = videoDuration
        videoSlider.value=0
        videoSlider.addTarget(self, action: #selector(onVideoSliderValueChange), for: UIControl.Event.valueChanged)
        // Set SeekBar Interval
        let interval : Double = Double(0.5 * videoSlider.maximumValue) / Double(videoSlider.bounds.maxX)
        // ConvertCMTime
        let time : CMTime = CMTimeMakeWithSeconds(interval, preferredTimescale: Int32(NSEC_PER_SEC))
        // Observer
        videoPlayer.addPeriodicTimeObserver(forInterval: time, queue: nil, using: {time in
            // Change SeekBar Position
            let duration = CMTimeGetSeconds(self.videoPlayer.currentItem!.duration)
            let time = CMTimeGetSeconds(self.videoPlayer.currentTime())
            let value = Float(self.videoSlider.maximumValue - self.videoSlider.minimumValue) * Float(time) / Float(duration) + Float(self.videoSlider.minimumValue)
            self.videoSlider.value = value
        })
    }
    @objc func onVideoSliderValueChange(){
        videoPlayer.pause()
        videoPlayMode=0
        let FPS = getFPS(videoCurrent)
        let newTime = CMTime(seconds: Double(videoSlider.value), preferredTimescale: 600)
        videoPlayer.seek(to: newTime, toleranceBefore: .zero, toleranceAfter: .zero)
        startFrame=Int(videoSlider.value*FPS)
        let nsstring : NSString = NSString(string: videoDura[videoCurrent])
        let num : Float = nsstring.floatValue - 1
        if startFrame > Int(FPS*num){
            startFrame = Int(FPS*num)
        }else if startFrame < 0{
            startFrame=0
        }
        dispWakus()
        showWakuImages()
    }
    
    func getPHAssetcollection(albumTitle:String)->PHAssetCollection{
        let requestOptions = PHImageRequestOptions()
        requestOptions.isSynchronous = true
        requestOptions.isNetworkAccessAllowed = false
        requestOptions.deliveryMode = .highQualityFormat //これでもicloud上のvideoを取ってしまう
        //アルバムをフェッチ
        let assetFetchOptions = PHFetchOptions()
        assetFetchOptions.predicate = NSPredicate(format: "title == %@", albumTitle)
        let assetCollections = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: assetFetchOptions)
        //ここはunwindから呼ばれる。アルバムはprepareで作っているはず？
        //        if (assetCollections.count > 0) {
        //同じ名前のアルバムは一つしかないはずなので最初のオブジェクトを使用
        return assetCollections.object(at:0)
    }
    @IBAction func onEraseButton(_ sender: Any) {
        
        let requestOptions = PHImageRequestOptions()
        requestOptions.isSynchronous = true
        requestOptions.isNetworkAccessAllowed = false
        requestOptions.deliveryMode = .highQualityFormat //これでもicloud上のvideoを取ってしまう
        //アルバムをフェッチ
        let assetFetchOptions = PHFetchOptions()
        
        assetFetchOptions.predicate = NSPredicate(format: "title == %@", vHIT96da)
        
        let assetCollections = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: assetFetchOptions)
        //        print("asset:",assetCollections.count)
        //アルバムが存在しない事もある？
        var dialogStatus:Int=0
        if (assetCollections.count > 0) {
            //同じ名前のアルバムは一つしかないはずなので最初のオブジェクトを使用
            let assetCollection = assetCollections.object(at:0)
            // creationDate降順でアルバム内のアセットをフェッチ
            let fetchOptions = PHFetchOptions()
            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
            let assets = PHAsset.fetchAssets(in: assetCollection, options: fetchOptions)
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            var id:Int=0
            for i in 0..<assets.count{
                let date_sub=assets[i].creationDate
                let date = formatter.string(from:date_sub!)
                //                eraseAssetPngNumber=i+1
                if videoDate[videoCurrent].contains(date){//
                    id=i
                    break
                }
            }
            if !assets[id].canPerform(.delete) {
                return
            }
            var delAssets=Array<PHAsset>()
            delAssets.append(assets[id])
            print("erase0:",id,assets.count)
            if id != assets.count-1{//最後でなければ
                //                print("erase1:",id,assets.count)
                if assets[id+1].duration==0{//pngが無くて、videoが選択されてない事を確認
                    delAssets.append(assets[id+1])//pngはその次に入っているはず
                    print("erase2:",id,assets.count)
                }
            }
            //            delAssets.append(assets[id])
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.deleteAssets(NSArray(array: delAssets))
            }, completionHandler: { success,error in//[self] _, _ in
                if success==true{
                    dialogStatus = 1//YES
                }else{
                    dialogStatus = -1//NO
                }
                // 削除後の処理
            })
            
        }
        
        while dialogStatus == 0{//dialogから抜けるまでは0
            sleep(UInt32(0.2))
        }
        if dialogStatus == 1{//yesで抜けた時
            videoDate.remove(at: videoCurrent)
            videoDura.remove(at: videoCurrent)
            videoPHAsset.remove(at: videoCurrent)
            
            videoCurrent -= 1
            showVideoIroiro(num: 0)
            if videoDate.count==0{
                setVideoButtons(mode: false)
                if Locale.preferredLanguages.first!.contains("ja"){
                    //                    print("japanese")
                    currentVideoDate.text="右下ボタンをタップして"
                    videoFps.text="ビデオを撮影して下さい"
                }else{
                    //                    print("english")
                    currentVideoDate.text="tap button in lower right corner"
                    videoFps.text="to record the video of the eye"
                }
            }
        }
    }
    func readGyroFromPngOfVideo(videoDate:String){
        let requestOptions = PHImageRequestOptions()
        requestOptions.isSynchronous = true
        requestOptions.isNetworkAccessAllowed = false
        requestOptions.deliveryMode = .highQualityFormat //これでもicloud上のvideoを取ってしまう
        //アルバムをフェッチ
        let assetFetchOptions = PHFetchOptions()
        
        assetFetchOptions.predicate = NSPredicate(format: "title == %@", vHIT96da)
        
        let assetCollections = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: assetFetchOptions)
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
            for i in 0..<assets.count-1{//最後はvideoでは無いはずなので
                let date = formatter.string(from:assets[i].creationDate!)
                if videoDate.contains(date){//find currentVideo
                    if assets[i+1].duration==0{//pngが無くて、videoが選択されてない事を確認
                        //currentVideoの次がpngならそれを選択
                        let width=assets[i+1].pixelWidth
                        let height=assets[i+1].pixelHeight
                        let imgManager = PHImageManager.default()
                        imgManager.requestImage(for: assets[i+1], targetSize: CGSize(width: width, height: height), contentMode:
                                .aspectFill, options: requestOptions, resultHandler: { [self] img, _ in
                                    if let img = img {
                                        readGyroFromPng(img: img)
                                    }
                                })
                        
                    }else{//次がpngでないとき。録画失敗して、gyroデータを保存できなかったとき
                        readGyroFromNul()//5min 0
                    }
                }
            }
        }
    }
    //calcMode 0:hori.  1:vert. 2:vog
    
    @IBAction func onChangeModeButton1(_ sender: Any) {
        if calcFlag == true || calcMode == 2 || videoDate.count == 0{
            return
        }
        
        if calcMode==0{
            return
        }else{
            calcMode=0
        }
        
        //        showModeText()
        setButtons_first()
        setButtons(mode: true)
        dispWakus()
        showWakuImages()
        calcStartTime=CFAbsoluteTimeGetCurrent()//所要時間の起点 update_vog
        if calcMode != 2{
            if eyePosXFiltered.count>0 && videoCurrent != -1{
                vhitCurpoint=0
                drawOneWave(startcount: 0,clearFlag: false)
                calcDrawVHIT(tuple: false)
            }
        }
        showBoxies(f:boxiesFlag)
    }
    @IBAction func onChangeModeButton2(_ sender: Any) {
        if calcFlag == true || calcMode == 2 || videoDate.count == 0{
            return
        }
        
        if calcMode==1{
            return
        }else{
            calcMode=1
        }
        
        //        showModeText()
        setButtons_first()
        setButtons(mode: true)
        dispWakus()
        showWakuImages()
        calcStartTime=CFAbsoluteTimeGetCurrent()//所要時間の起点 update_vog
        if calcMode != 2{
            if eyePosXFiltered.count>0 && videoCurrent != -1{
                vhitCurpoint=0
                drawOneWave(startcount: 0,clearFlag: false)
                calcDrawVHIT(tuple: false)
            }
        }
        showBoxies(f:boxiesFlag)
    }
    
    @IBAction func onBackVideoButton(_ sender: Any) {
        if vHITBoxView?.isHidden == false{
            return
        }
        startFrame=0
        videoPlayMode=0
        //        print("onBackVideo****")
        showVideoIroiro(num: -1)
    }
    @IBAction func onNextVideoButton(_ sender: Any) {
        if vHITBoxView?.isHidden == false{
            return
        }
        startFrame=0
        videoPlayMode=0
        //        print("onNextVideo*****")
        showVideoIroiro(num: 1)
    }
    
    func setVideoButtons(mode:Bool){
        videoSlider.isHidden = !mode
        videoSlider.isEnabled = mode
        waveSlider.isHidden = mode
        backwardButton.isEnabled=mode
        playButton.isEnabled=mode
        eraseButton.isHidden = !mode
    }
    func showVideoIroiro(num:Int){//videosCurrentを移動して、諸々表示
        if videoDura.count == 0{
            //            print("none!!!!!!!!!")
            setVideoButtons(mode: false)
            return
        }
        //        print("showvideoiroiro***********")
        setVideoButtons(mode: true)
        videoCurrent += num
        if videoCurrent>videoDura.count-1{
            videoCurrent=0
        }else if videoCurrent<0{
            videoCurrent=videoDura.count-1
        }
        playCurrentVideo()
        currentVideoDate.font=UIFont.monospacedDigitSystemFont(ofSize: 22, weight: .medium)
        currentVideoDate.text=videoDate[videoCurrent] + "(" + (videoCurrent+1).description + ")"
        let roundFps:Int = Int(round(getFPS(videoCurrent)))
        videoFps.text=videoDura[videoCurrent] + "/" + String(format: "%dfps",roundFps)
        showWakuImages()
        setBacknext(f:true)
        //videoCurrentを保存
        UserDefaults.standard.set(videoCurrent, forKey: "videoCurrent")
    }
    
    func resizeR2(_ targetRect:CGRect, viewRect:CGRect, image:CIImage) -> CGRect {
        //view.frameとtargetRectとimageをもらうことでその場で縦横の比率を計算してtargetRectのimage上の位置を返す関数
        //view.frameとtargetRectは画面上の位置だが、返すのはimage上の位置なので、そこをうまく考慮する必要がある。
        //getRealrectの代わり
        
        let vw = viewRect.width
        let vh = viewRect.height
        
        let iw = CGFloat(image.extent.width)
        let ih = CGFloat(image.extent.height)
        
        //　viewRect.originを引く事でtargetRectがview.bounds起点となる (xは0なのでやる必要はないが・・・）
        let tx = CGFloat(targetRect.origin.x) - CGFloat(viewRect.origin.x)
        let ty = CGFloat(targetRect.origin.y) - CGFloat(viewRect.origin.y)
        
        let tw = CGFloat(targetRect.width)
        let th = CGFloat(targetRect.height)
        
        // ここで返されるCGRectはCIImage/CGImage上の座標なので全て整数である必要がある
        // 端数があるまま渡すとmatchingが誤動作した
        return CGRect(x: (tx * iw / vw).rounded(),
                      y: ((vh - ty - th) * ih / vh).rounded(),
                      width: (tw * iw / vw).rounded(),
                      height: (th * ih / vh).rounded())
    }
    func expandRectWithBorderWide(rect:CGRect, border:CGFloat) -> CGRect {
        //上下左右に border 広げる
        //この関数も上と同じようにroundした方がいいかもしれないが、
        //現状ではscreen座標のみで使っているのでfloatのまま。
        
        return CGRect(x:rect.origin.x - border,
                      y:rect.origin.y - border,
                      width:rect.size.width + border * 2,
                      height:rect.size.height + border * 2)
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
    func KalmanInit(num:Int){
        kalVs[num][2]=0
        kalVs[num][3]=0
        kalVs[num][4]=0
    }
    func stopTimerVideo(){
        if timerVideo?.isValid == true {
            timerVideo!.invalidate()
        }
    }
    func startTimerVideo() {
        stopTimerVideo()
        timerVideo = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.update_video), userInfo: nil, repeats: true)
    }
    @objc func update_video(tm: Timer) {
        if videoPlayMode==0 {
            if !((videoPlayer.rate != 0) && (videoPlayer.error == nil)) {//notplaying
                if videoSlider.value>videoSlider.maximumValue-0.01{
                    videoSlider.value=0
                }else{
                    return
                }
            }else{
                return
            }
        }else if videoPlayMode == 1{
            videoSlider.value -= 0.02
        }else if videoPlayMode==2{
            videoSlider.value += 0.02
        }
        if videoSlider.value < 0 || videoSlider.value > videoSlider.maximumValue - 0.1{
            videoSlider.value = 0
            videoPlayMode=0
        }
        let newTime = CMTime(seconds: Double(videoSlider.value), preferredTimescale: 600)
        videoPlayer.seek(to: newTime, toleranceBefore: .zero, toleranceAfter: .zero)
        startFrame=Int(videoSlider.value*getFPS(videoCurrent))
        //            dispWakus()
        if videoSlider.value == 0{
            showWakuImages()
        }
    }
    func stopTimerCalc(){
        if timerCalc?.isValid == true {
            timerCalc!.invalidate()
        }
    }
    func startTimerCalc() {
        stopTimerCalc()
        lastArraycount=0
        if calcMode != 2{
            timerCalc = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.update_vHIT), userInfo: nil, repeats: true)
        }else{
            //            timerCalc = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.update_vog), userInfo: nil, repeats: true)
        }
    }
    func showBoxies(f:Bool){
        if f==true && calcMode == 2{//vog wave
            boxiesFlag=true
            //         vogBoxView?.isHidden = false
            vHITBoxView?.isHidden = true
            
            waveBoxView?.isHidden = true
            setBacknext(f: false)
            eraseButton.isHidden=true
            playButton.isEnabled=false
        }else if f==true && calcMode != 2{//vhit wave
            boxiesFlag=true
            //          vogBoxView?.isHidden = true
            vHITBoxView?.isHidden = false
            waveBoxView?.isHidden = false
            setBacknext(f: false)
            eraseButton.isHidden=true
            playButton.isEnabled=false
        }else{//no wave
            boxiesFlag=false
            //          vogBoxView?.isHidden = true
            vHITBoxView?.isHidden = true
            waveBoxView?.isHidden = true
            setBacknext(f: true)
            if videoDate.count>0{
                playButton.isEnabled=true
            }
            if videoDate.count != 0{
                eraseButton.isHidden=false
            }else{
                eraseButton.isHidden=true
            }
        }
    }
    //checkDispMode() 1-vHIT 2-VOG 3-non
    func checkDispMode()->Int{
        if vHITBoxView?.isHidden==false {//vHIT on
            return 1
            //        }else if vogBoxView?.isHidden==false{//VOG on
            //            return 2
        }else{//off
            return 0
        }
    }
    @IBAction func onWaveButton(_ sender: Any) {//saveresult record-unwind の２箇所
        if videoDate.count == 0{
            return
        }
        if checkDispMode()==0{
            showBoxies(f: true)
            setVideoButtons(mode: false)
        }else{
            showBoxies(f: false)
            setVideoButtons(mode: true)
        }
    }
    
    func setBacknext(f:Bool){//back and next button
        nextButton.isHidden = !f
        backButton.isHidden = !f
        if videoDate.count < 2{
            nextButton.isHidden = true
            backButton.isHidden = true
        }
    }
    
    @IBAction func onStopButton(_ sender: Any) {
        calcFlag = false
    }
    
    func setButtons(mode:Bool){
        if mode == true{
            calcButton.isHidden = false
            calcButton.isEnabled = true
            stopButton.isHidden = true
            listButton.isEnabled = true
            paraButton.isEnabled = true
            saveButton.isEnabled = true
            waveButton.isEnabled = true
            helpButton.isEnabled = true
            if checkDispMode()==0{
                setVideoButtons(mode: true)
            }else{
                setVideoButtons(mode: false)
            }
            changeModeButton1.isEnabled = true
            changeModeButton2.isEnabled = true
            cameraButton.isEnabled = true
        }else{
            calcButton.isHidden = true
            stopButton.isHidden = false
            stopButton.isEnabled = false
            listButton.isEnabled = false
            paraButton.isEnabled = false
            saveButton.isEnabled = false
            waveButton.isEnabled = false
            helpButton.isEnabled = false
            setVideoButtons(mode: false)
            changeModeButton1.isEnabled = false
            cameraButton.isEnabled = false
            cameraButton.isEnabled = false
        }
    }
    @IBAction func onCalcButton(_ sender: Any) {
        if videoDate.count==0{
            return
        }
        if (videoPlayer.rate != 0) && (videoPlayer.error == nil) {//playing
            return
        }
        setUserDefaults()
        if nonsavedFlag == true && (waveTuple.count > 0 || eyePosXFiltered.count > 1){
            setButtons(mode: false)
            var alert = UIAlertController(
                title: "You are erasing vHIT Data.",
                message: "OK ?",
                preferredStyle: .alert)
            if calcMode==2{
                alert = UIAlertController(
                    title: "You are erasing VOG Data.",
                    message: "OK ?",
                    preferredStyle: .alert)
            }
            // アラートにボタンをつける
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
                
                self.vHITcalc()
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel,handler:{ action in
                self.setButtons(mode: true)
                //         print("****cancel")
            }))
            // アラート表示
            self.present(alert, animated: true, completion: nil)
            //１：直ぐここと２を通る
        }else{
            
            vHITcalc()
            
        }
        //２：直ぐここを通る
    }
    
    func moveGyroData(){//gyroDeltaとstartFrameをずらして
        
        gyroMoved.removeAll()
        var sn=startFrame
        let fps=getFPS(videoCurrent)
        if fps<200{
            sn=startFrame*2
        }
        sn -= videoGyroZure//初起動時に機種を判定（適当）して設定。設定ページで変更可能。
        if calcMode == 0{
            if gyroHFiltered.count>10{
                for i in sn..<gyroHFiltered.count{
                    if i>=0{
                        gyroMoved.append(gyroHFiltered[i])
                    }else{
                        gyroMoved.append(0)
                    }
                }
            }
        }else{
            if gyroVFiltered.count>10{
                for i in sn..<gyroVFiltered.count{
                    if i>=0{
                        gyroMoved.append(gyroVFiltered[i])
                    }else{
                        gyroMoved.append(0)
                    }
                }
            }
        }
    }
    func setArraysData(type:Int){
        if type==0{//removeAll
            eyePosXFiltered.removeAll()
            eyeVeloXFiltered.removeAll()
            eyePosYFiltered.removeAll()
            eyeVeloYFiltered.removeAll()
            gyroMoved.removeAll()
            errArray.removeAll()
            //表示用データ
            eyePosXFiltered4update.removeAll()
            eyeVeloXFiltered4update.removeAll()
            eyePosYFiltered4update.removeAll()
            eyeVeloYFiltered4update.removeAll()
            
        }else if type==1{//append(0)
            eyePosXFiltered.append(0)
            eyeVeloXFiltered.append(0)
            eyePosYFiltered.append(0)
            eyeVeloYFiltered.append(0)
            eyePosXFiltered4update.append(0)
            eyePosYFiltered4update.append(0)
            eyeVeloXFiltered4update.append(0)
            eyeVeloYFiltered4update.append(0)
            gyroMoved.append(0)
            errArray.append(false)
        }
    }
    
    
    
    func vHITcalc(){
        var cvError:Int = 0
        calcFlag = true
        KalmanInit()
        calcStartTime=CFAbsoluteTimeGetCurrent()
        setButtons(mode: false)
        
        setArraysData(type: 0)//removeAll
        setArraysData(type: 1)//append(0)
        
        showBoxies(f: true)
        drawVHITwaves(clearFlag: true)
        drawOneWave(startcount: 0,clearFlag: true)
        
        //      waveBoxView.image = UIImage(named:"VOGen")//eye")
        waveSlider.isHidden=false
        videoSlider.isHidden=true
        
        //videoの次のpngからgyroデータを得る。なければ５分間の０のgyroデータを戻す。
        readGyroFromPngOfVideo(videoDate: videoDate[videoCurrent])
        moveGyroData()//gyroDeltastartframe分をズラして
        
        timercnt = 0
        UIApplication.shared.isIdleTimerDisabled = true//not sleep
        let eyeborder:CGFloat = CGFloat(eyeBorder)
        startTimerCalc()//resizerectのチェックの時はここをコメントアウト*********************
        let avasset = iroiro.requestAVAsset(asset: videoPHAsset[videoCurrent])
        calcDate = currentVideoDate.text!
        let fps=getFPS(videoCurrent)
        var realframeRatio:Float=fps/240
        //これを設定すると頭出ししてもあまりずれない。
        //どのようにデータを作ったのか読み直すのも面倒なので、取り敢えずやってみたら、いい具合。
        if fps<200.0{
            fpsIs120=true
            realframeRatio=fps/120.0
        }else{
            fpsIs120=false
        }
        
        var reader: AVAssetReader! = nil
        do {
            reader = try AVAssetReader(asset: avasset!)
        } catch {
#if DEBUG
            print("could not initialize reader.")
#endif
            return
        }
        guard let videoTrack = avasset!.tracks(withMediaType: AVMediaType.video).last else {
#if DEBUG
            print("could not retrieve the video track.")
#endif
            return
        }
        
        let readerOutputSettings: [String: Any] = [kCVPixelBufferPixelFormatTypeKey as String : Int(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)]
        let readerOutput = AVAssetReaderTrackOutput(track: videoTrack, outputSettings: readerOutputSettings)
        
        reader.add(readerOutput)
        
        let frameRate = videoTrack.nominalFrameRate
        //let startframe=startPoints[vhitVideocurrent]
        let startTime = CMTime(value: CMTimeValue(Float(startFrame)*realframeRatio), timescale: CMTimeScale(frameRate))
        let timeRange = CMTimeRange(start: startTime, end:CMTime.positiveInfinity)
        
        reader.timeRange = timeRange //読み込む範囲を`timeRange`で指定
        reader.startReading()
        
        // UnsafeとMutableはまあ調べてもらうとして、eX, eY等は<Int32>が一つ格納されている場所へのポインタとして宣言される。
        let eX = UnsafeMutablePointer<Int32>.allocate(capacity: 1)
        let eY = UnsafeMutablePointer<Int32>.allocate(capacity: 1)
        var eyeWithBorderCGImage:CGImage!
        var eyeWithBorderUIImage:UIImage!
        
        let eyeRectOnScreen=CGRect(x:wakuE.origin.x, y:wakuE.origin.y, width: wakuE.width, height: wakuE.height)
        let eyeWithBorderRectOnScreen = expandRectWithBorderWide(rect: eyeRectOnScreen, border: eyeborder)
        let eyeBigRectOnScreen = expandRectWithBorderWide(rect: eyeRectOnScreen, border: view.bounds.width/5)//10)
        
        let context:CIContext = CIContext.init(options: nil)
        
        var sample:CMSampleBuffer!
        stopButton.isEnabled = true
        sample = readerOutput.copyNextSampleBuffer()
        
        let pixelBuffer:CVPixelBuffer = CMSampleBufferGetImageBuffer(sample!)!
        var lastCIImage:CIImage = CIImage(cvPixelBuffer: pixelBuffer).oriented(.right)
        let eyeRect = resizeR2(eyeRectOnScreen, viewRect:view.frame, image:lastCIImage)
        var eyeWithBorderRect = resizeR2(eyeWithBorderRectOnScreen, viewRect:view.frame, image:lastCIImage)
        let eyeBigRect = resizeR2(eyeBigRectOnScreen, viewRect:view.frame, image:lastCIImage)
        let eyeWithBorderRect0 = eyeWithBorderRect
        
        let eyeCGImage = context.createCGImage(lastCIImage, from: eyeRect)!
        let eyeUIImage = UIImage.init(cgImage: eyeCGImage)
        
        let offsetEyeX:CGFloat = (eyeWithBorderRect.size.width - eyeRect.size.width) / 2.0
        let offsetEyeY:CGFloat = (eyeWithBorderRect.size.height - eyeRect.size.height) / 2.0
        
        var maxEyeV:Double = 0
        initSum5XY()//平均加算の初期化
        while reader.status != AVAssetReader.Status.reading {
            //            sleep(UInt32(0.1))
            usleep(1000)//0.001sec
        }
        
        DispatchQueue.global(qos: .default).async { [self] in
            while let sample = readerOutput.copyNextSampleBuffer(), self.calcFlag != false {
                var eyeVeloX:CGFloat = 0
                var eyeVeloY:CGFloat = 0
                var eyePosX:CGFloat = 0
                var eyePosY:CGFloat = 0
                autoreleasepool{
                    let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sample)!//27sec:10sec
                    cvError -= 1
                    
                    if cvError <= 0{
                        //orientation.upとrightは所要時間同じ
                        lastCIImage = CIImage(cvPixelBuffer: pixelBuffer).oriented(.right)
                        eyeWithBorderCGImage = context.createCGImage(lastCIImage, from: eyeWithBorderRect)!
                        eyeWithBorderUIImage = UIImage.init(cgImage: eyeWithBorderCGImage)
                        
                        maxEyeV=openCV.matching(eyeWithBorderUIImage,narrow: eyeUIImage,x: eX, y: eY)
                        if maxEyeV < 0.90{
                            if cvError==0{//4回空回りした後は1回だけ空回り
                                cvError=1
                            }else{
                                cvError=5//10/240secはcontinue
                            }
                            eyeWithBorderRect=eyeWithBorderRect0//初期位置に戻す
                        }else{//検出できた時
                            //eXはポインタなので、".pointee"でそのポインタの内容が取り出せる。Cでいうところの"*"
                            //上で宣言しているとおりInt32が返ってくるのでCGFloatに変換して代入
                            eyeVeloX = CGFloat(eX.pointee) - offsetEyeX
                            eyeVeloY =  -CGFloat(eY.pointee) + offsetEyeY
                            eyeWithBorderRect.origin.x += eyeVeloX
                            eyeWithBorderRect.origin.y += eyeVeloY
                            eyePosX = eyeWithBorderRect.origin.x - eyeWithBorderRect0.origin.x// + ex
                            eyePosY = eyeWithBorderRect.origin.y - eyeWithBorderRect0.origin.y// + ey
                            
                            let x=(eyeWithBorderRect.minX+eyeWithBorderRect.maxX)/2
                            let y=(eyeWithBorderRect.minY+eyeWithBorderRect.maxY)/2
                            if x<eyeBigRect.minX ||
                                x>eyeBigRect.maxX ||
                                y<eyeBigRect.minY ||
                                y>eyeBigRect.maxY{
                                cvError=5
                                eyeWithBorderRect=eyeWithBorderRect0
                            }
                        }
                        context.clearCaches()
                    }
                    
                    if calcFlag==true{//faceMatchingErrorの時は抜ける
                        while readingDataNow==true{//--------の間はアレイデータを書き込まない？
                            usleep(1000)//0.001sec
                            print("loop-reeding")
                        }
                        writingDataNow=true
                        
                        if cvError<0{
                            errArray.append(true)
                            eyePosXFiltered.append( -1.0*Kalman(value:eyePosX,num:2))
                            eyePosYFiltered.append( -1.0*Kalman(value:eyePosY,num:3))
                            let cnt=eyePosXFiltered.count
                            if calcMode != 2{//vHIT
                                eyeVeloXFiltered.append(12*(eyePosXFiltered[cnt-1]-eyePosXFiltered[cnt-2]))
                                eyeVeloYFiltered.append(12*(eyePosYFiltered[cnt-1]-eyePosYFiltered[cnt-2]))
                            }else{//vogでは、２重にフィフターをかけると体裁が良いが、それで良いのだろうか？
                                eyeVeloXFiltered.append(12*Kalman(value:eyePosXFiltered[cnt-1]-eyePosXFiltered[cnt-2],num:4))
                                eyeVeloYFiltered.append(12*Kalman(value:eyePosYFiltered[cnt-1]-eyePosYFiltered[cnt-2],num:5))
                            }
                            
                        }else{
                            errArray.append(false)
                            KalmanInit()
                            eyePosXFiltered.append(eyePosXFiltered.last!)
                            eyePosYFiltered.append(eyePosYFiltered.last!)
                            eyeVeloXFiltered.append(eyeVeloXFiltered.last!)
                            eyeVeloYFiltered.append(eyeVeloYFiltered.last!)
                        }
                        if fpsIs120==true{
                            eyePosXFiltered.append(eyePosXFiltered.last!)
                            eyePosYFiltered.append(eyePosYFiltered.last!)
                            eyeVeloXFiltered.append(eyeVeloXFiltered.last!)
                            eyeVeloYFiltered.append(eyeVeloYFiltered.last!)
                            errArray.append(errArray.last!)
                        }
                        writingDataNow=false
                    }
                    if calcFlag==true{//faceMatchingErrorでない時
                        while reader.status != AVAssetReader.Status.reading {
                            usleep(1000)//0.001sec
                        }
                    }
                }
            }
            calcFlag = false//video 終了
            nonsavedFlag=true
        }
    }
    
    var sum5X:CGFloat=0
    var sum5Y:CGFloat=0
    func initSum5XY(){
        sum5X=0
        sum5Y=0
    }
    
    var debugDisplayX:CGFloat=0
    var debugDisplayY:CGFloat=0
    func showWakuImages(){//結果が表示されていない時、画面上部1/4をタップするとWaku表示
        if videoDura.count<1 {
            return
        }
//        print("videoCurrent:",videoCurrent)
        
        let avasset = iroiro.requestAVAsset(asset: videoPHAsset[videoCurrent])
        
        calcDate = currentVideoDate.text!
        var reader: AVAssetReader! = nil
        do {
            reader = try AVAssetReader(asset: avasset!)
        } catch {
#if DEBUG
            print("could not initialize reader.")
#endif
            return
        }
        guard let videoTrack = avasset!.tracks(withMediaType: AVMediaType.video).last else {
#if DEBUG
            print("could not retrieve the video track.")
#endif
            return
        }
        
        let readerOutputSettings: [String: Any] = [kCVPixelBufferPixelFormatTypeKey as String : Int(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)]
        let readerOutput = AVAssetReaderTrackOutput(track: videoTrack, outputSettings: readerOutputSettings)
        
        reader.add(readerOutput)
        let frameRate = videoTrack.nominalFrameRate
        //let startframe=startPoints[vhitVideocurrent]
        let startTime = CMTime(value: CMTimeValue(startFrame), timescale: CMTimeScale(frameRate))
        let timeRange = CMTimeRange(start: startTime, end:CMTime.positiveInfinity)
        //print("time",timeRange)
        reader.timeRange = timeRange //読み込む範囲を`timeRange`で指定
        reader.startReading()
        
        let CGeye:CGImage!//eye
        let UIeye:UIImage!
        let context:CIContext = CIContext.init(options: nil)
        let orientation = UIImage.Orientation.up//right
        var sample:CMSampleBuffer!
        sample = readerOutput.copyNextSampleBuffer()
        let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sample!)!
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer).oriented(.right)
        //        print("waku",wakuE.size.width,wakuE.size.height)
        let eyeR = resizeR2(wakuE, viewRect:view.frame,image:ciImage)
        CGeye = context.createCGImage(ciImage, from: eyeR)!
        UIeye = UIImage.init(cgImage: CGeye, scale:1.0, orientation:orientation)
        let wakuY=videoFps.frame.origin.y+videoFps.frame.size.height+5
        let wakuSizeW:CGFloat=view.bounds.width/8
        let wakuSizeH=wakuSizeW*eyeR.height/eyeR.width
        wakuShowEye_image.frame=CGRect(x:5,y:wakuY,width:wakuSizeW,height:wakuSizeH)// eyeR.size.width*5,height: eyeR.size.height*5)
        //        #if DEBUG
        debugDisplayX=wakuShowEye_image.frame.maxX
        debugDisplayY=wakuShowEye_image.frame.minY
        //        #endif
        wakuShowEye_image.layer.borderWidth = 1.0
        wakuShowEye_image.backgroundColor = UIColor.clear
        wakuShowEye_image.layer.cornerRadius = 3
        
        wakuShowEye_image.image=UIeye
        wakuShowEye_image.layer.borderColor = UIColor.green.cgColor
        
    }
    
    func printR(str:String,rct:CGRect){
        print("\(str)",String(format: "%.2f %.2f %.2f %.2f",rct.origin.x,rct.origin.y,rct.width,rct.height))
    }
    func printR(str:String,rct1:CGRect,rct2:CGRect){
        print("\(str)",String(format: "%.1f,%.1f,%.1f  %.1f,%.1f,%.1f",rct1.origin.x,rct1.origin.y,rct1.width,rct2.origin.x,rct2.origin.y,rct2.width))
    }
    func printR(str:String,cnt:Int,rct1:CGRect,rct2:CGRect){
        print("\(str)",String(format: "%d-%.0f,%.0f,%.0f  %.0f,%.0f,%.0f",cnt,rct1.origin.x,rct1.origin.y,rct1.width, rct2.origin.x,rct2.origin.y,rct2.width))
    }
    func printR(str:String,cnt:Int,max:Double,rct1:CGRect,rct2:CGRect){
        print("\(str)",String(format: "%d %.2f-%.0f,%.0f %.0f,%.0f",cnt,max,rct1.origin.x,rct1.origin.y,rct2.origin.x,rct2.origin.y))
    }
    
    func getAlbumFirst(){
        if PHPhotoLibrary.authorizationStatus() != .authorized {
            PHPhotoLibrary.requestAuthorization { status in
                if status == .authorized {
                    //                    self.checkLibraryAuthrizedFlag=1
                    print("authorized")
                } else if status == .denied {
                    //                    self.checkLibraryAuthrizedFlag = -1
                    print("denied")
                }else{
                    //                    self.checkLibraryAuthrizedFlag = -1
                }
            }
        }else{
            getAlbumAssets()//完了したら戻ってくるようにしたつもり
            //videcurrentは前回終了時のものを利用する
            videoCurrent = getUserDefault(str: "videoCurrent", ret: 0)
            //            startFrame = getUserDefault(str: "startFrame", ret: 0)
            if videoCurrent>videoDate.count-1{
                videoCurrent=videoDate.count-1
            }
            self.setNeedsStatusBarAppearanceUpdate()
            dispWakus()
#if DEBUG
            print("didloadcount:",videoDate.count)
#endif
            showVideoIroiro(num:0)
            if videoDate.count==0{
                setVideoButtons(mode: false)
            }else{
                startTimerVideo()
            }
            waveSlider.isHidden=true
        }
    }
    


    func getLocalHighFrameRateVideoURLsInAlbum(albumName: String, completion: @escaping ([URL]) -> Void) {
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized else {
                completion([])
                return
            }

            let fetchOptions = PHFetchOptions()
            fetchOptions.predicate = NSPredicate(format: "title = %@", albumName)
            let albumResult = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)

            guard let album = albumResult.firstObject else {
                completion([])
                return
            }

            let assetsFetchOptions = PHFetchOptions()
            let assets = PHAsset.fetchAssets(in: album, options: assetsFetchOptions)

            var highFrameRateVideoURLs: [URL] = []
            let dispatchGroup = DispatchGroup()

            assets.enumerateObjects { asset, _, _ in
                if asset.mediaSubtypes.contains(.videoHighFrameRate) && asset.sourceType == .typeUserLibrary {
                    dispatchGroup.enter()
                    let options = PHVideoRequestOptions()
                    options.version = .original
                    options.isNetworkAccessAllowed = false  // cloud上のファイルは排除する

                    PHImageManager.default().requestAVAsset(forVideo: asset, options: options) { avAsset, _, _ in
                        if let urlAsset = avAsset as? AVURLAsset {
                            let frameRate = self.getVideoFrameRate(url: urlAsset.url)
                            if frameRate == 120 || frameRate == 240 {
    highFrameRateVideoURLs.append(urlAsset.url)
                            }
                        }
                        dispatchGroup.leave()
                    }
                }
            }

            dispatchGroup.notify(queue: .main) {
                completion(highFrameRateVideoURLs)
            }
        }
    }

    private func getVideoFrameRate(url: URL) -> Float {
        let asset = AVAsset(url: url)
        guard let track = asset.tracks(withMediaType: .video).first else {
            return 0
        }
        return track.nominalFrameRate
    }
/*
    // 使用例
    getLocalHighFrameRateVideoURLsInAlbum(albumName: "vHIT96da") { urls in
        urls.forEach { url in
            print("スローモーション動画のURL: \(url)")
        }
    }
 */
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //      #if DEBUG
        //        print("viewDidLoad******")
        //    #endif
        //        dispFilesindoc()//for debug
        //機種にょって異なるVOG結果サイズだったのを2400*1600に統一した
        mailWidth=2400//240*10
        mailHeight=1600//240*10*2/3
        //vHIT結果サイズは500*200
        getUserDefaults()
        //        setButtons(mode: true)
        stopButton.isHidden = true
        showBoxies(f: false)//isVHITに応じてviewを表示
        if UserDefaults.standard.object(forKey: "installed") != nil{//StatementViewControllerが表示されている時まだnil
            stopButton.isHidden = true
            showBoxies(f: false)//isVHITに応じてviewを表示
            setButtons_first()
            getAlbumFirst()
            dispWakus()
            showWakuImages()
            print("installed nil!!!")
        }else{
            //nilの時はviewDidAppearでStamentViewControllerでStatementを表示
            //StatementViewControllerからのunwindで以下３行を行う
            //getAlbumFirst()
            //dispWakus()
            //showWakuImages()
        }
        print("didload****************************")
    }
    func getUserDefaultBool(str:String,ret:Bool) -> Bool{
        if (UserDefaults.standard.object(forKey: str) != nil){
            return UserDefaults.standard.bool(forKey: str)
        }else{//keyが設定してなければretをセット
            UserDefaults.standard.set(ret, forKey: str)
            return ret
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        getLocalHighFrameRateVideoURLsInAlbum(albumName: "vHIT96da") { urls in
            urls.forEach { url in
                print("スローモーション動画のURL: \(url)")
            }
        }
        //StatementViewController(KeySet)の中でinstalledを作りyesを設定
        if UserDefaults.standard.object(forKey: "installed") == nil{
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let nextVC = storyboard.instantiateViewController(withIdentifier: "KeySet")
            nextVC.modalPresentationStyle = .fullScreen
            present(nextVC, animated: true, completion: nil)//ここでinstalledにyesを設定
            
        }
        print("viewDidAppear*****")
        showWakuImages()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        // dispWakuImages()ここでは効かない
        //        dispWakus()ここでは効かない
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        if timerCalc?.isValid == true {
            timerCalc.invalidate()
        }
    }
    
    
    
    var initDrawVhitF:Bool=true
    func drawVHITwaves(clearFlag:Bool){//解析結果のvHITwavesを表示する
        let ww=view.bounds.width
        var drawImage = drawvhitWaves(width:500,height:200)
        if clearFlag{
            drawImage=drawvhitWavesClear(width:500,height: 200)
        }
        let dImage = drawImage.resize(size: CGSize(width:ww, height:ww*2/5))//view.bounds.width*2/5))
        // 画面に表示する
        if initDrawVhitF==true{
            initDrawVhitF=false
        }else{
            vHITBoxView.layer.sublayers?.removeLast()
        }
        vHITBoxView.addSubview(UIImageView(image: dImage))
        vHITBoxView.isHidden=false
    }
    
    var initDrawOneFlag:Bool=true
    func drawOneWave(startcount:Int,clearFlag:Bool){//vHIT_eye_head
        var startcnt = startcount
        let ww=view.bounds.width
        
        if startcnt < 0 {
            startcnt = 0
        }
        if arrayDataCount < Int(ww){//横幅以内なら０からそこまで表示
            startcnt = 0
        }else if startcnt > arrayDataCount - Int(ww){
            startcnt = arrayDataCount - Int(ww)
        }
        //波形を時間軸で表示
        var drawImage:UIImage//  = drawLine(num:startcnt,width:ww,height:ww*9/16)// 180)
        if clearFlag{
            drawImage = drawLineClear(num:startcnt,width:ww,height:ww*9/16)// 180)
        }else{// イメージビューに設定する
            drawImage = drawLine(num:startcnt,width:ww,height:ww*9/16)// 180)
        }
        if initDrawOneFlag==true{
            initDrawOneFlag=false
        }else{
            waveBoxView.layer.sublayers?.removeLast()
        }      //ここらあたりを変更se~7plusの大きさにも対応できた。
        waveBoxView.addSubview(UIImageView(image: drawImage))
        //        print("count----" + "\(view.subviews.count)")
    }
    var arrayDataCount:Int=0
    var lastPosXFiltered:Int=0
    
    
    func average5(filtered:[CGFloat],i:Int)->CGFloat{
        return (filtered[i]+filtered[i+1]+filtered[i+2]+filtered[i+3]+filtered[i+4])/5
    }
    func average4(filtered:[CGFloat],i:Int)->CGFloat{
        return (filtered[i]+filtered[i+1]+filtered[i+2]+filtered[i+3])/4
    }
    func averagingData(){
        let filterCnt=UserDefaults.standard.integer(forKey:"lowPassFilterCnt")
        if filterCnt==0{
            return
        }else if filterCnt==1{
            for i in 0..<eyeVeloXFiltered4update.count-6{
                eyeVeloXFiltered4update[i]=(eyeVeloXFiltered4update[i]+eyeVeloXFiltered4update[i+1])/2
                eyeVeloYFiltered4update[i]=(eyeVeloYFiltered4update[i]+eyeVeloYFiltered4update[i+1])/2
            }
        }else if filterCnt==2{
            for i in 0..<eyeVeloXFiltered4update.count-6{
                eyeVeloXFiltered4update[i]=(eyeVeloXFiltered4update[i]+eyeVeloXFiltered4update[i+1]+eyeVeloXFiltered4update[i+1])/3
                eyeVeloYFiltered4update[i]=(eyeVeloYFiltered4update[i]+eyeVeloYFiltered4update[i+1]+eyeVeloYFiltered4update[i+1])/3
            }
        }else if filterCnt==3{
            for i in 0..<eyeVeloXFiltered4update.count-6{
                eyeVeloXFiltered4update[i]=average4(filtered: eyeVeloXFiltered4update, i: i)
                eyeVeloYFiltered4update[i]=average4(filtered: eyeVeloYFiltered4update, i: i)
            }
        }else{
            for i in 0..<eyeVeloXFiltered4update.count-6{
                eyeVeloXFiltered4update[i]=average5(filtered: eyeVeloXFiltered4update, i: i)
                eyeVeloYFiltered4update[i]=average5(filtered: eyeVeloYFiltered4update, i: i)
            }
        }
    }
    func getArrayData()->Int{//一気にデータ取得して、そのデータをゆっくり？表示用に利用する。
        while writingDataNow==true{
            usleep(1000)
#if DEBUG
            print("writing_loop")
#endif
        }
        readingDataNow=true
        let n1=eyePosXFiltered4update.count
        let n2=eyePosXFiltered.count
        
        for i in n1..<n2{
            if errArray[i]==true{
                eyePosXFiltered4update.append(eyePosXFiltered[i])
                eyePosYFiltered4update.append(eyePosYFiltered[i])
                eyeVeloXFiltered4update.append(eyeVeloXFiltered[i])
                eyeVeloYFiltered4update.append(eyeVeloYFiltered[i])
            }else{
                eyePosXFiltered4update.append(eyePosXFiltered4update.last!)
                eyePosYFiltered4update.append(eyePosYFiltered4update.last! )
                eyeVeloXFiltered4update.append(eyeVeloXFiltered4update.last!)
                eyeVeloYFiltered4update.append(eyeVeloYFiltered4update.last!)
            }
        }
        readingDataNow=false
        return eyePosXFiltered4update.count
    }
    var timercnt:Int = 0
    var lastArraycount:Int = 0
    
    var lastVhitpoint:Int = -2//これはなんだろう→あとでチェック！！！
    @objc func onWaveSliderValueChange(){
        let mode=checkDispMode()
        let ww=view.bounds.width
        //        print("modes:",mode,calcMode)
        if mode==1{//vhit
            vhitCurpoint=Int(waveSlider.value*(waveSlider.maximumValue-Float(view.bounds.width))/waveSlider.maximumValue)
            //            print(vhitCurpoint)p
            drawOneWave(startcount: vhitCurpoint,clearFlag: false)
            lastVhitpoint = vhitCurpoint
            if waveTuple.count>0{
                //setするだけか？
                setCurrVHIT(pos: lastVhitpoint + Int(ww/2))//, mode:1)
                drawVHITwaves(clearFlag: false)
            }
        }else if mode==2{//vogalc
        }
    }
    func setWaveSlider(){
        setVideoButtons(mode: false)
        waveSlider.minimumValue = 0
        //count==0の時もエラーにならないのでそのまま
        waveSlider.maximumValue = Float(arrayDataCount)
        waveSlider.value=0
        waveSlider.addTarget(self, action: #selector(onWaveSliderValueChange), for: UIControl.Event.valueChanged)
    }
    var calcStartTime=CFAbsoluteTimeGetCurrent()
    //  var tapDownUpTime=CFAbsoluteTimeGetCurrent()//down-up所要時間
    @objc func update_vHIT(tm: Timer) {
        
        /*   if matchingTestMode==true{
         if calcFlag == false{
         timerCalc.invalidate()
         setButtons(mode: true)
         setVideoButtons(mode: true)
         videoSlider.isEnabled=true
         nextButton.isHidden=false
         backButton.isHidden=false
         matchingTestMode=false
         }
         return
         }*/
        arrayDataCount = getArrayData()
        if arrayDataCount < 5 {
            return
        }
        
        if calcFlag == false {
            vhitCurpoint=0
            //if timer?.isValid == true {
            timerCalc.invalidate()
            setButtons(mode: true)
            //  }
            UIApplication.shared.isIdleTimerDisabled = false
            //終わり直前で認識されたvhitdataが認識されないこともあるかもしれないので、駄目押し。だめ押し用のcalcdrawvhitは別に作る必要があるかもしれない。
            averagingData()//結局ここでスムーズになる？
            if self.waveTuple.count > 0{
                self.nonsavedFlag = true
            }
            setWaveSlider()
        }
        //        let tmpCount=getPosXFilteredCount()
        //   vogImage=makeVOGImage(startImg: vogImage!, width: 0, height: 0,start:lastArraycount, end: arrayDataCount)
        lastArraycount=arrayDataCount
        //        drawRealwave()
        drawOneWave(startcount: arrayDataCount,clearFlag: false)
        timercnt += 1
#if DEBUG
        print("debug-update",timercnt)
#endif
        calcDrawVHIT(tuple: true)//waveTupleは更新する。
        if calcFlag==false{
            drawOneWave(startcount: 0,clearFlag: false)
        }
    }
    
    func getFPS(_ current:Int) -> Float{
        let avasset = iroiro.requestAVAsset(asset: videoPHAsset[current])
        return avasset!.tracks.first!.nominalFrameRate
    }
    
    func getUserDefault(str:String,ret:Int) -> Int{//getUserDefault_one
        if (UserDefaults.standard.object(forKey: str) != nil){//keyが設定してなければretをセット
            return UserDefaults.standard.integer(forKey:str)
        }else{
            UserDefaults.standard.set(ret, forKey: str)
            return ret
        }
    }
    
    func getUserDefault(str:String,ret:Bool)->Bool{
        if (UserDefaults.standard.object(forKey: str) != nil){//keyがなければretをセット
            return UserDefaults.standard.bool(forKey:str)
        }else{
            UserDefaults.standard.set(ret, forKey: str)
            return ret
        }
    }
    var iCloudStatus:Bool=true
    func checkIsiCloud(assetVideo:PHAsset,cachingImageManager:PHCachingImageManager) -> PHImageRequestID{
        
        let opt=PHVideoRequestOptions()
        opt.deliveryMode = .mediumQualityFormat
        opt.isNetworkAccessAllowed=true //iCloud video can play
        return cachingImageManager.requestAVAsset(forVideo:assetVideo, options: opt) { (asset, audioMix, info) in
            
            DispatchQueue.main.async {
                if (info!["PHImageFileSandboxExtensionTokenKey"] != nil) {
                    self.iCloudStatus=false
                    //                        self.playVideo(videoAsset:asset!)
                }else if((info![PHImageResultIsInCloudKey]) != nil) {
                    self.iCloudStatus=true
                    
                }else{
                    self.iCloudStatus=false
                    //                       self.playVideo(videoAsset:asset!)
                }
            }
        }
        
    }
    func getAlbumAssets_last(){
        gettingAlbumF = true
        getAlbumAssets_last_sub()
        while gettingAlbumF == true{
            sleep(UInt32(0.1))
        }
    }
    
    var gettingAlbumF:Bool = false
    func getAlbumAssets_last_sub(){
        let requestOptions = PHImageRequestOptions()
        requestOptions.isSynchronous = false
        requestOptions.isNetworkAccessAllowed = false//これでもicloud上のvideoを取ってしまう
        requestOptions.deliveryMode = .highQualityFormat
        // アルバムをフェッチ
        let assetFetchOptions = PHFetchOptions()
        assetFetchOptions.predicate = NSPredicate(format: "title == %@", "vHIT96da")
        let assetCollections = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: assetFetchOptions)
        if (assetCollections.count > 0) {//アルバムが存在しない時
            //同じ名前のアルバムは一つしかないはずなので最初のオブジェクトを使用
            let assetCollection = assetCollections.object(at:0)
            // creationDate降順でアルバム内のアセットをフェッチ
            let fetchOptions = PHFetchOptions()
            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
            let assets = PHAsset.fetchAssets(in: assetCollection, options: fetchOptions)
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            for i in (assets.count-2)..<assets.count{
                let asset=assets[i]
                if asset.duration>0{//静止画を省く
                    videoPHAsset.append(asset)
#if DEBUG
                    print("asset:",asset)
#endif
                    //                    videoURL.append(nil)
                    let date_sub = asset.creationDate
                    let date = formatter.string(from: date_sub!)
                    let duration = String(format:"%.1fs",asset.duration)
                    videoDate.append(date)// + "(" + duration + ")")
                    //                    asset.video
                    videoDura.append(duration)
                }
            }
            gettingAlbumF = false
        }else{
            gettingAlbumF = false
        }
    }
/*
 func getAlbumAssets(_ recordedFlag:Bool){//
//        getAlbumAssetsEndFlag=false
  let fetchOptions = PHFetchOptions()
  fetchOptions.predicate = NSPredicate(format: "title == %@", albumName)
  let collectionResult = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
  if let album = collectionResult.firstObject {
      let assetFetchOptions = PHFetchOptions()
      assetFetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]

      //   assetFetchOptions.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.video.rawValue)
      let assets = PHAsset.fetchAssets(in: album, options: assetFetchOptions)
      var gazoPHAsset: [PHAsset] = [] // 画像(video&png)のリストを作成
      assets.enumerateObjects { (asset, _, _) in
          // スローモーション動画かどうかの確認
          //    if asset.mediaSubtypes.contains(PHAssetMediaSubtype.videoHighFrameRate) {
          // iCloudからダウンロードされていないかどうかを確認
          //    self.checkIfVideoIsLocallyAvailable(asset: asset) { isAvailable in
          //      if isAvailable {
          gazoPHAsset.append(asset)
          /*
           self.mediaAssets.append(asset)
           */
          //  }
          //}
          //    }
      }
  
       // 非同期でスローモーションビデオを表示
      DispatchQueue.main.async {
          self.getAlbumVideos(gazoPHAsset,recordedFlag)
      }
  } else {
      print("指定したアルバムが見つかりませんでした。")
  }
}*/
func getAlbumVideos(_ gazo: [PHAsset]) {
  pngPHAsset.removeAll()
  videoPHAsset.removeAll()
  videoDura.removeAll()
  videoDate.removeAll()
  let formatter = DateFormatter()
  formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    print("videoPHAsset:",videoPHAsset.count)

  if gazo.isEmpty {
      print("ビデオも静止画もありません。")
  } else {

      for videoPng in gazo {
          if videoPng.duration>0{//動画
              videoPHAsset.append(videoPng)
              let date_sub = videoPng.creationDate
              let date = formatter.string(from: date_sub!)
              let duration = String(format:"%.1fs",videoPng.duration)
              videoDate.append(date)// + "(" + duration + ")")
              videoDura.append(duration)
          }else{//静止画
              pngPHAsset.append(videoPng)
          }
      }
      for i in (0..<videoDate.count).reversed(){//cloudのは見ない・削除する
          let avasset = iroiro.requestAVAsset(asset: videoPHAsset[i])
          if avasset == nil{
              videoPHAsset.remove(at: i)
              videoDate.remove(at: i)
              videoDura.remove(at: i)
          }
      }
      print("videoPHAsset:",videoPHAsset.count)
//      gettingAlbumF = false

//      print("png,video:",pngPHAsset.count,videoPHAsset.count)
//      if recordedFlag {//recordからunwindで戻ってきた時は、録画した最後のvideoとする
//          videoCurrent=videoDate.count-1
//      }else{
//          videoCurrent = getUserDefault(str: "videoCurrent", ret: 0)
//      }
//      if videoCurrent>videoDate.count-1{//念のため
//          videoCurrent=videoDate.count-1
//      }
      
//      self.setNeedsStatusBarAppearanceUpdate()
//      //#if DEBUG
//      //            print("didloadcount:",videoDate.count)
//      //#endif
//      showVideoIroiro(num:0)
//      if videoDate.count==0{
//          setVideoButtons(mode: false)
//      }else{
//          startTimerVideo()
//      }
//      waveSlider.isHidden=true
//        for i in 0...pngPHAsset.count-1{
//            print("png,mp4:",i,pngPHAsset[i].creationDate!,videoPHAsset[i].creationDate!)
//        }
//        print("videoCurrent:",videoCurrent)
//            for mp4 in videoPHAsset{
//                print("mp4:",mp4.creationDate!)
//            }
//            print("video,png:",videoPHAsset.count,pngPHAsset.count)
//      if(recordedFlag){//録画の時はpng画像はまだ作られていないので
//          saveGyroValue()//png画像を作り、それをpngPHAssetに追加
//      }
  }
  //        getAlbumAssetsEndFlag=true
}
 
    func getAlbumAssets(){
        gettingAlbumF = true
//        getAlbumAssets_sub_newIOS()
        getAlbumAssets_sub()
        while gettingAlbumF == true{
            sleep(UInt32(0.1))
        }
        
        for i in (0..<videoDate.count).reversed(){//cloudのは見ない・削除する
            let avasset = iroiro.requestAVAsset(asset: videoPHAsset[i])
            if avasset == nil{
                videoPHAsset.remove(at: i)
                videoDate.remove(at: i)
                videoDura.remove(at: i)
            }
        }
    }
    func getAlbumAssets_sub_newIOS(){//
   //        getAlbumAssetsEndFlag=false
     let fetchOptions = PHFetchOptions()
     fetchOptions.predicate = NSPredicate(format: "title == %@", "vHIT96da")
     let collectionResult = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
     if let album = collectionResult.firstObject {
         let assetFetchOptions = PHFetchOptions()
         assetFetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]

         //   assetFetchOptions.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.video.rawValue)
         let assets = PHAsset.fetchAssets(in: album, options: assetFetchOptions)
         var gazoPHAsset: [PHAsset] = [] // 画像(video&png)のリストを作成
         assets.enumerateObjects { (asset, _, _) in
             // スローモーション動画かどうかの確認
             //    if asset.mediaSubtypes.contains(PHAssetMediaSubtype.videoHighFrameRate) {
             // iCloudからダウンロードされていないかどうかを確認
             //    self.checkIfVideoIsLocallyAvailable(asset: asset) { isAvailable in
             //      if isAvailable {
             gazoPHAsset.append(asset)
             print(asset.creationDate)
             /*
              self.mediaAssets.append(asset)
              */
             //  }
             //}
             //    }
         }
     
          // 非同期でスローモーションビデオを表示
//         DispatchQueue.main.async {
             print("gazoPHAsset")
             self.getAlbumVideos(gazoPHAsset)
             self.gettingAlbumF = false

//         }
     } else {
         print("指定したアルバムが見つかりませんでした。")
     }
   }
    func getAlbumAssets_sub(){
        let requestOptions = PHImageRequestOptions()
        videoPHAsset.removeAll()
        videoDura.removeAll()
        videoDate.removeAll()
        requestOptions.isSynchronous = false
        requestOptions.isNetworkAccessAllowed = false//これでもicloud上のvideoを取ってしまう
        requestOptions.deliveryMode = .highQualityFormat
        // アルバムをフェッチ
        let assetFetchOptions = PHFetchOptions()
        assetFetchOptions.predicate = NSPredicate(format: "title == %@", "vHIT96da")
        let assetCollections = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: assetFetchOptions)
        if (assetCollections.count > 0) {//アルバムが存在する時
            print("assetCollections.count>0")
            //同じ名前のアルバムは一つしかないはずなので最初のオブジェクトを使用
            let assetCollection = assetCollections.object(at:0)
            // creationDate降順でアルバム内のアセットをフェッチ
            let fetchOptions = PHFetchOptions()
            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
            let assets = PHAsset.fetchAssets(in: assetCollection, options: fetchOptions)
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            for i in 0..<assets.count{
                let asset=assets[i]
                if asset.duration>0{//静止画を省く
                    videoPHAsset.append(asset)
#if DEBUG
                    print("asset:",asset)
#endif
                    //                    videoURL.append(nil)
                    let date_sub = asset.creationDate
                    let date = formatter.string(from: date_sub!)
                    let duration = String(format:"%.1fs",asset.duration)
                    videoDate.append(date)// + "(" + duration + ")")
                    //                    asset.video
                    videoDura.append(duration)
                }
            }
            gettingAlbumF = false
        }else{
            print("!! assetCollections.count>0")

            gettingAlbumF = false
        }
    }
    
    //    func getUserDefaultBool(str:String,ret:Bool) -> Bool{
    //        if (UserDefaults.standard.object(forKey: str) != nil){
    //            return UserDefaults.standard.bool(forKey: str)
    //        }else{//keyが設定してなければretをセット
    //            UserDefaults.standard.set(ret, forKey: str)
    //            return ret
    //        }
    //    }
    func getUserDefaults(){
        let lowPassFilterCnt=getUserDefault(str: "lowPassFilterCnt", ret: 4)//とりあえず作っておく
        //        print("lowPassFilterCnt",lowPassFilterCnt)
        widthRange = getUserDefault(str: "widthRange", ret: 30)
        waveWidth = getUserDefault(str: "waveWidth", ret: 80)
        eyeBorder = getUserDefault(str: "eyeBorder", ret: 10)
        eyeRatio = getUserDefault(str: "eyeRatio", ret: 100)
        gyroRatio = getUserDefault(str: "gyroRatio", ret: 100)
        
        vorGainCorrection = getUserDefault(str: "vorGainCorrection", ret:101)
        videoGyroZure = getUserDefault(str: "videoGyroZure", ret: 20)
        calcMode = getUserDefault(str: "calcMode", ret: 0)
        vHITDisplayMode = getUserDefault(str: "vHITDisplayMode", ret:1)
        
        let width=Int(view.bounds.width/2)
        let height=Int(view.bounds.height/3)
        wakuE.origin.x = CGFloat(getUserDefault(str: "wakuE_x", ret:width))
        wakuE.origin.y = CGFloat(getUserDefault(str: "wakuE_y", ret:height))
        wakuLength = getUserDefault(str: "wakuLength", ret: 3)
        if wakuLength<3{
            wakuLength=3
        }
        wakuE.size.width = CGFloat(wakuLength)
        wakuE.size.height = CGFloat(wakuLength)
        wakuF.origin.x = CGFloat(getUserDefault(str: "wakuF_x", ret:width))
        wakuF.origin.y = CGFloat(getUserDefault(str: "wakuF_y", ret:height+30))
        
        wakuF.size.width = 5//wakuLength
        wakuF.size.height = 5//wakuLength
    }
    //default値をセットするんじゃなく、defaultというものに値を設定するという意味
    func setUserDefaults(){
        //        UserDefaults.standard.set(freeCounter, forKey: "freeCounter")
        UserDefaults.standard.set(widthRange, forKey: "widthRange")
        UserDefaults.standard.set(wakuLength, forKey: "wakuLength")
        UserDefaults.standard.set(waveWidth, forKey: "waveWidth")
        UserDefaults.standard.set(eyeBorder, forKey: "eyeBorder")
        UserDefaults.standard.set(eyeRatio, forKey: "eyeRatio")
        UserDefaults.standard.set(gyroRatio, forKey: "gyroRatio")
        
        UserDefaults.standard.set(videoGyroZure,forKey:"videoGyroZure")
        UserDefaults.standard.set(vorGainCorrection,forKey:"vorGainCorrection")
        
        UserDefaults.standard.set(Int(wakuE.origin.x), forKey: "wakuE_x")
        UserDefaults.standard.set(Int(wakuE.origin.y), forKey: "wakuE_y")
        UserDefaults.standard.set(Int(wakuF.origin.x), forKey: "wakuF_x")
        UserDefaults.standard.set(Int(wakuF.origin.y), forKey: "wakuF_y")
        UserDefaults.standard.set(calcMode,forKey: "calcMode")
        UserDefaults.standard.set(vHITDisplayMode,forKey: "vHITDisplayMode")
    }
    
    func dispWakus(){
        let nullRect:CGRect = CGRect(x:0,y:0,width:0,height:0)
        
        //        printR(str:"wakuE:",rct: wakuE)
        eyeWaku_image.frame=CGRect(x:(wakuE.origin.x)-15,y:wakuE.origin.y-15,width:(wakuE.size.width)+30,height: wakuE.size.height+30)
        
        
        eyeWaku_image.layer.borderColor = UIColor.green.cgColor
        eyeWaku_image.backgroundColor = UIColor.clear
        eyeWaku_image.layer.borderWidth = 1.0
        eyeWaku_image.layer.cornerRadius = 3
        
    }
    
   
    func drawLineClear(num: Int, width w: CGFloat, height h: CGFloat) -> UIImage {
         let size = CGSize(width: w, height: h)
         let renderer = UIGraphicsImageRenderer(size: size)
         let image = renderer.image { context in
             // 必要であればここで描画処理を行う
         }
         return image
     }

     func drawLine(num: Int, width w: CGFloat, height h: CGFloat) -> UIImage {
         let size = CGSize(width: w, height: h)
         let renderer = UIGraphicsImageRenderer(size: size)

         let image = renderer.image { context in
 //            let ctx = context.cgContext

             #if DEBUG
             print("drawLine:", num, w, h)
             #endif

             // 折れ線にする点の配列
             var pointList0 = [CGPoint]()
             var pointList2 = [CGPoint]()
             let pointCount = Int(w)
             let dx: CGFloat = 1
             let gyroMovedCnt = gyroMoved.count
             let y1 = view.bounds.width * 9 / 32
             var py0: CGFloat = 0
             var step = 1

             if fpsIs120 {
                 step = 2
             }

             for n in stride(from: 1, to: pointCount, by: step) {
                 if num + n < arrayDataCount, num + n < gyroMovedCnt {
                     let px = dx * CGFloat(n)
                     if calcMode == 0 {
                         py0 = eyeVeloXFiltered4update[num + n] * CGFloat(eyeRatio) / 450.0 + y1
                     } else {
                         py0 = eyeVeloYFiltered4update[num + n] * CGFloat(eyeRatio) / 450.0 + y1
                     }

                     let py2 = -gyroMoved[num + n] * CGFloat(gyroRatio) / 150.0 + y1
                     let point0 = CGPoint(x: px, y: py0)
                     let point2 = CGPoint(x: px, y: py2)

                     pointList0.append(point0)
                     pointList2.append(point2)
                 }
             }

             // パスの初期化
             let drawPath0 = UIBezierPath()
             let drawPath2 = UIBezierPath()

             // 始点に移動
             drawPath0.move(to: pointList0[0])
             pointList0.removeFirst()
             for pt in pointList0 {
                 drawPath0.addLine(to: pt)
             }

             drawPath2.move(to: pointList2[0])
             pointList2.removeFirst()
             for pt in pointList2 {
                 drawPath2.addLine(to: pt)
             }

             // 線の色と幅を設定
             UIColor.red.setStroke()
             drawPath0.lineWidth = 0.5//0.3
             drawPath0.stroke()

             UIColor.black.setStroke()
             drawPath2.lineWidth = 0.5//0.3
             drawPath2.stroke()

             // 時間テキストを描画
             let timetxt = String(format: "%05df (%.1fs/%@) : %ds", arrayDataCount, CGFloat(arrayDataCount) / 240.0, videoDura[videoCurrent], timercnt + 1)
             timetxt.draw(at: CGPoint(x: 3, y: 3), withAttributes: [
                 .foregroundColor: UIColor.black,
                 .font: UIFont.monospacedDigitSystemFont(ofSize: 13, weight: .regular)
             ])
         }

         return image
     }
    var redGainStr:String=""
    var blueGainStr:String=""
    func getAve(array:Array<Double>)->Double{
        var ave:Double=0
        for i in 0..<array.count{
            ave += array[i]
        }
        return ave/Double(array.count)
    }
    func getSD(array:Array<Double>,svvAv:Double)->Double{
        var svvSd:Double=0
        for i in 0..<array.count {
            svvSd += (array[i]-svvAv)*(array[i]-svvAv)
        }
        svvSd=svvSd/Double(array.count)
        svvSd = sqrt(svvSd)
        return svvSd
    }
    func sumArray(array:Array<CGFloat>)->CGFloat{
        var sum:CGFloat=0
        for i in 12...37{//flat12...25(x4ms)
            sum += array[i]
        }
        return sum
    }
    func draw1wave(r:CGFloat){//just vHIT
        var redVORGainArray = Array<Double>()
        var blueVORGainArray = Array<Double>()
        
        var pointList1 = Array<CGPoint>()
        var pointList2 = Array<CGPoint>()
        let drawPathEye = UIBezierPath()
        let drawPathFace = UIBezierPath()
        //        var rlPt:CGFloat = 0
        //r:4(mail)  r:1(screen)
        var posY0=135*r
        if vHITDisplayMode==0{//up down
            posY0=90*r
        }
        for i in 0..<waveTuple.count{
            if waveTuple[i].2==0{//hidden vhit
                continue
            }
            
            //        let tempGain = -eyeWs[i][27]/gyroWs[i][27]//12(+15) 60msでの値.EyeSeeCamに準じて
            let tempGain =  -sumArray(array: eyeWs[i])/sumArray(array: gyroWs[i])//sum(12~37)0ms~100ms
            if waveTuple[i].0==0{//
                redVORGainArray.append(tempGain)
            }else{
                blueVORGainArray.append(tempGain)
            }
        }
        //controll dataでGainは右:左=0.7:1.0
        let redGainAv=getAve(array: redVORGainArray)*Double(vorGainCorrection)/100
        let redGainSd=getSD(array:redVORGainArray,svvAv: redGainAv)
        let blueGainAv=getAve(array: blueVORGainArray)
        let blueGainSd=getSD(array:blueVORGainArray,svvAv: blueGainAv)
        redGainStr = String(format: "(%d) VOR-Gain     %.2f sd:%.2f",redVORGainArray.count,redGainAv,redGainSd)
        blueGainStr = String(format:"(%d) VOR-Gain     %.2f sd:%.2f",blueVORGainArray.count,blueGainAv,blueGainSd)
        
        for i in 0..<waveTuple.count{//blue vHIT
            pointList1.removeAll()
            pointList2.removeAll()
            
            for n in 0..<120 {
                var px = CGFloat(n)*2*r
                //以下はなかなか上手くいかない
                //                var py1 = vHITs[i].eye[n]*r + posY0
                //                var py2 = vHITs[i].face[n]*r + posY0
                //                if vHITDisplayMode==1 && waveTuple[i].0==0{
                //                    py2 = -vHITs[i].face[n]*r + posY0
                //                }else if vHITDisplayMode==1 && waveTuple[i].0==1{
                //                    py1 = -vHITs[i].eye[n]*r + posY0
                //                }
                
                var py1 = eyeWs[i][n]*r + posY0
                var py2 = gyroWs[i][n]*r + posY0
                if vHITDisplayMode==1 && waveTuple[i].0==0{
                    py2 = -gyroWs[i][n]*r + posY0
                }else if vHITDisplayMode==1 && waveTuple[i].0==1{
                    py1 = -eyeWs[i][n]*r + posY0
                }
                
                
                if waveTuple[i].0==1{
                    px += 260*r
                }
                let point1 = CGPoint(x:px,y:py1)
                pointList1.append(point1)
                let point2 = CGPoint(x:px,y:py2)
                pointList2.append(point2)
            }
            // 始点に移動する
            drawPathEye.move(to: pointList1[0])
            // 配列から始点の値を取り除く
            pointList1.removeFirst()
            // 配列から点を取り出して連結していく
            for pt in pointList1 {
                drawPathEye.addLine(to: pt)
            }
            drawPathFace.move(to: pointList2[0])
            // 配列から始点の値を取り除く
            pointList2.removeFirst()
            // 配列から点を取り出して連結していく
            for pt in pointList2 {
                drawPathFace.addLine(to: pt)
            }
            if waveTuple[i].3==1 && waveTuple[i].2==1 {//rl,framenum,disp onoff,current disp onoff
                drawPathEye.lineWidth = 2
                drawPathFace.lineWidth = 2
            }else if waveTuple[i].3==1 && waveTuple[i].2==0 {//非表示
                drawPathEye.lineWidth = 3.5//1.2
                drawPathFace.lineWidth = 3.5//1.2
            }else if waveTuple[i].3==0 && waveTuple[i].2==1 {//表示
                drawPathEye.lineWidth = 0.3
                drawPathFace.lineWidth = 0.3
            }else if waveTuple[i].3==0 && waveTuple[i].2==0 {
                drawPathEye.lineWidth = 0
                drawPathFace.lineWidth = 0
            }
            if r==4 && waveTuple[i].2==1{//mail
                drawPathEye.lineWidth = 1.2
                drawPathFace.lineWidth = 1.2
            }else if r==4 {//mail
                drawPathEye.lineWidth = 0
                drawPathFace.lineWidth = 0
            }
            // 線の色
            if waveTuple[i].0==0{
                UIColor.red.setStroke()
            }else{
                UIColor.blue.setStroke()
            }
//            if drawPathEye.lineWidth == 5{
//                drawPathEye.lineWidth = 1.2
//                UIColor.purple.setStroke()
//            }
//            if drawPathFace.lineWidth == 5{
//                drawPathFace.lineWidth = 1.2
//                UIColor.purple.setStroke()
//            }
            drawPathEye.stroke()
            UIColor.black.setStroke()
            drawPathFace.stroke()
            drawPathEye.removeAllPoints()
            drawPathFace.removeAllPoints()
        }
    }
    struct vHIT {
        var isRight : Bool
        var frameN : Int
        var dispOn : Bool
        var currDispOn : Bool
        var eye = [CGFloat](repeating:0,count:121)
        var face = [CGFloat](repeating:0,count:121)
    }
    
    var vHITs = [vHIT]()
    var vHITsTemp = [vHIT]()
    var vHITEye = [CGFloat](repeating: 0, count: 121)
    var vHITFace = [CGFloat](repeating: 0, count: 121)
    func append_vHITs(isRight:Bool,frameN:Int,dispOn:Bool,currDispOn:Bool){
        let temp=vHIT(isRight: isRight,frameN: frameN, dispOn: dispOn, currDispOn: currDispOn,eye:vHITEye,face:vHITFace)
        vHITs.append(temp)
    }
    func append_vHITs(isRight:Bool,frameN:Int,dispOn:Bool,currDispOn:Bool,eye:[CGFloat],face:[CGFloat]){
        let temp=vHIT(isRight: isRight,frameN: frameN, dispOn: dispOn, currDispOn: currDispOn,eye:eye,face:face)
        vHITs.append(temp)
    }
    
    //アラート画面にテキスト入力欄を表示する。上記のswift入門よりコピー
    var tempnum:Int = 0
    @IBAction func onSaveButton(_ sender: Any) {//vhit
        
        if calcFlag == true{
            return
        }
        //  if calcMode==2{
        //      saveResult_vog(0)
        //      return
        // }
        if waveTuple.count < 1 {
            return
        }
        if vHITBoxView?.isHidden == true{
            showBoxies(f: true)
        }
        
        let alert = UIAlertController(title: "vHIT96da", message: "Input ID", preferredStyle: .alert)
        let saveAction = UIAlertAction(title: "OK", style: .default) { [self] (action:UIAlertAction!) -> Void in
            // 入力したテキストをコンソールに表示
            let textField = alert.textFields![0] as UITextField
            idString = textField.text!
#if DEBUG
            print("\(String(describing: textField.text))")
#endif
            idString = textField.text!
            let drawImage = drawvhitWaves(width:500*4,height:200*4)
            
            //まずtemp.pngに保存して、それをvHIT_アルバムにコピーする
            saveJpegImage2path(image: drawImage, path: "temp.jpeg")
            while existFile(aFile: "temp.jpeg") == false{
                sleep(UInt32(0.1))
            }
            savePath2album(albumName:Wave96da,path: "temp.jpeg")
            calcDrawVHIT(tuple: false)//idnumber表示のため,waveTupleは変更しない
            // イメージビューに設定する
            //            UIImageWriteToSavedPhotosAlbum(drawImage, nil, nil, nil)
            nonsavedFlag = false //解析結果がsaveされたのでfalse
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .default) { (action:UIAlertAction!) -> Void in
        }
        // UIAlertControllerにtextFieldを追加
        alert.addTextField { (textField:UITextField!) -> Void in
            textField.keyboardType = UIKeyboardType.default//.numberPad
        }
        alert.addAction(cancelAction)//この行と下の行の並びを変えるとCancelとOKの左右が入れ替わる。
        alert.addAction(saveAction)
        present(alert, animated: true, completion: nil)
        
    }
    
    func alertKetSet() {
        var mess="key is not set yet!!"
        if Locale.preferredLanguages.first!.contains("ja"){
            mess="keyが設定されていません！!"
        }
        let alert = UIAlertController(title: "vHIT96da", message: mess, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default) { [self] (action:UIAlertAction!) -> Void in
        }
        // UIAlertControllerにtextFieldを追加
        alert.addAction(okAction)
        present(alert, animated: true, completion: nil)
    }
    
    func trimmingImage(_ image: UIImage, trimmingArea: CGRect) -> UIImage {
        let imgRef = image.cgImage?.cropping(to: trimmingArea)
        let trimImage = UIImage(cgImage: imgRef!, scale: image.scale, orientation: image.imageOrientation)
        return trimImage
    }
 
    func drawvhitWavesClear(width w: CGFloat, height h: CGFloat) -> UIImage {
           let size = CGSize(width: w, height: h)
           let renderer = UIGraphicsImageRenderer(size: size)
           
           let image = renderer.image { context in
               // パス
   //            let drawPath = UIBezierPath()
               // 必要な描画をここで行う (今回は何も描画しない場合)
           }
           
           return image
       }
       func drawvhitWaves(width w: CGFloat, height h: CGFloat) -> UIImage {
           let size = CGSize(width: w, height: h)
           var r: CGFloat = 1 // 倍率 magnification
           if w == 500 * 4 { // mail
               r = 4
           }
           
           // UIGraphicsImageRenderer を使用
           let renderer = UIGraphicsImageRenderer(size: size)
           
           let image = renderer.image { context in
               // コンテキスト
   //            let cgContext = context.cgContext
               
               // パスの初期化
               let drawPath = UIBezierPath()
               
               // テキスト描画
               let str1 = calcDate.components(separatedBy: ":")
               let str2 = "ID:" + idString + "  "
               let str3 = str1[0] + ":" + str1[1]
               let str4 = "vHIT96da"
               
               str2.draw(at: CGPoint(x: 5 * r, y: 180 * r), withAttributes: [
                   .foregroundColor: UIColor.black,
                   .font: UIFont.monospacedDigitSystemFont(ofSize: 15 * r, weight: .regular)
               ])
               
               str3.draw(at: CGPoint(x: 258 * r, y: 180 * r), withAttributes: [
                   .foregroundColor: UIColor.black,
                   .font: UIFont.monospacedDigitSystemFont(ofSize: 15 * r, weight: .regular)
               ])
               
               str4.draw(at: CGPoint(x: 425 * r, y: 180 * r), withAttributes: [
                   .foregroundColor: UIColor.black,
                   .font: UIFont.monospacedDigitSystemFont(ofSize: 15 * r, weight: .regular)
               ])
               
               // 線の描画
               UIColor.black.setStroke()
               let pList = [
                   CGPoint(x: 0, y: 0),
                   CGPoint(x: 0, y: 180 * r),
                   CGPoint(x: 240 * r, y: 180 * r),
                   CGPoint(x: 240 * r, y: 0),
                   CGPoint(x: 260 * r, y: 0),
                   CGPoint(x: 260 * r, y: 180 * r),
                   CGPoint(x: 500 * r, y: 180 * r),
                   CGPoint(x: 500 * r, y: 0)
               ]
               
               drawPath.lineWidth = 0.1 * r
               drawPath.move(to: pList[0])
               drawPath.addLine(to: pList[1])
               drawPath.addLine(to: pList[2])
               drawPath.addLine(to: pList[3])
               drawPath.addLine(to: pList[0])
               drawPath.move(to: pList[4])
               drawPath.addLine(to: pList[5])
               drawPath.addLine(to: pList[6])
               drawPath.addLine(to: pList[7])
               drawPath.addLine(to: pList[4])
               
               for i in 0...4 {
                   drawPath.move(to: CGPoint(x: 30 * r + CGFloat(i) * 48 * r, y: 0))
                   drawPath.addLine(to: CGPoint(x: 30 * r + CGFloat(i) * 48 * r, y: 180 * r))
                   drawPath.move(to: CGPoint(x: 290 * r + CGFloat(i) * 48 * r, y: 0))
                   drawPath.addLine(to: CGPoint(x: 290 * r + CGFloat(i) * 48 * r, y: 180 * r))
               }
               
               drawPath.stroke()
               drawPath.removeAllPoints()
               
               // カスタム描画（関数呼び出し）
               draw1wave(r: r) // just vHIT
               
               // ゲインの値を描画
               blueGainStr.draw(at: CGPoint(x: 263 * r, y: 167 * r - 167 * r), withAttributes: [
                   .foregroundColor: UIColor.black,
                   .font: UIFont.monospacedDigitSystemFont(ofSize: 12 * r, weight: .regular)
               ])
               
               redGainStr.draw(at: CGPoint(x: 3 * r, y: 167 * r - 167 * r), withAttributes: [
                   .foregroundColor: UIColor.black,
                   .font: UIFont.monospacedDigitSystemFont(ofSize: 12 * r, weight: .regular)
               ])
           }
           
           return image
       }
       
    @objc func viewWillEnterForeground(_ notification: Notification?) {
        //       print("willenter")
        if (self.isViewLoaded && (self.view.window != nil)) {
            //            freeCounter += 1
            //            UserDefaults.standard.set(freeCounter, forKey: "freeCounter")
            //            videoFps.text = "\(freeCounter)"
        }
    }
    
    //UIDevice
    var alertController: UIAlertController!
    func alert(title:String, message:String) {
        alertController = UIAlertController(title: title,
                                            message: message,
                                            preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK",
                                                style: .default,
                                                handler: nil))
        present(alertController, animated: true)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let topPadding = self.view.safeAreaInsets.top
        let bottomPadding = self.view.safeAreaInsets.bottom
        UserDefaults.standard.set(topPadding, forKey: "top")
        UserDefaults.standard.set(bottomPadding, forKey: "bottom")
        print("subView******")
        //        setButtons_first()
    }
    
    func setButtons_first(){
        let ww=view.bounds.width
        let wh=view.bounds.height
        let bottom=CGFloat( UserDefaults.standard.float(forKey: "bottom"))
        let sp:CGFloat=5
        let bw:CGFloat=(ww-10*sp)/7//最下段のボタンの高さ、幅と同じ
        let bh=bw
        let by0=wh-bottom-2*sp-bh
        let by1=by0-bh-sp//2段目
        //      launchButton.frame=CGRect(x:-200,y:0,width: 0,height: 0)
        vHITBoxView?.frame=CGRect(x:0,y:wh*160/568-ww/5,width :ww,height:ww*2/5)
        
        waveBoxView?.frame=CGRect(x:0,y:wh*340/568-ww*90/320,width:ww,height: ww*180/320)
        //        vogBoxView?.frame=CGRect(x:0,y:wh/2-ww/3,width:ww,height: ww*2/3)
        
        backButton.layer.cornerRadius = 5
        nextButton.layer.cornerRadius = 5
        videoSlider.frame = CGRect(x: sp*2, y:0, width: ww - 20, height: bh)//temp
        let sliderHeight=videoSlider.frame.height
        videoSlider.frame=CGRect(x:sp*2,y:(waveBoxView!.frame.maxY+by1)/2-sliderHeight/2,width:ww-sp*4,height:sliderHeight)
        waveSlider.frame=videoSlider.frame
        
        videoSlider.thumbTintColor=UIColor.systemYellow
        waveSlider.thumbTintColor=UIColor.systemBlue
        iroiro.setButtonProperty(listButton,x:sp*2,y:by0,w:bw,h:bh,UIColor.systemBlue)
        iroiro.setButtonProperty(saveButton,x:sp*3+bw*1,y:by0,w:bw,h:bh,UIColor.systemBlue)
        iroiro.setButtonProperty(waveButton,x:sp*4+bw*2,y:by0,w:bw,h:bh,UIColor.systemBlue)
        
        iroiro.setButtonProperty(calcButton,x:sp*5+bw*3,y:by0-sp/2-bh/2,w:bw,h: bh,UIColor.systemBlue)
        iroiro.setButtonProperty(stopButton,x:sp*5+bw*3,y:by0-sp/2-bh/2,w:bw,h: bh,UIColor.systemBlue)
        
        iroiro.setButtonProperty(paraButton,x:sp*6+bw*4,y:by0,w:bw,h:bh,UIColor.systemBlue)
        iroiro.setButtonProperty(helpButton,x:sp*7+bw*5,y:by0,w:bw,h:bh,UIColor.systemBlue)
        iroiro.setButtonProperty(cameraButton,x:sp*8+bw*6,y:by0-sp/2-bh/2,w:bw,h:bh,UIColor.systemRed)
        
        iroiro.setButtonProperty(backwardButton,x:sp*6+bw*4,y:by1,w:bw,h:bh,UIColor.systemOrange)
        iroiro.setButtonProperty(playButton,x:sp*7+bw*5,y:by1,w:bw,h:bh,UIColor.systemOrange)
        //calcMode 0:hori.  1:vert. 2:vog 3:arkit
        if calcMode == 0{
            iroiro.setButtonProperty(changeModeButton1,x:sp*2,y:by1,w:bh*3/2+sp/2,h:bh,UIColor.systemBlue)
            iroiro.setButtonProperty(changeModeButton2,x:sp*2+bh*3/2+sp/2+sp,y:by1,w:bh*3/2+sp/2,h:bh,UIColor.systemBlue)
            iroiro.setButtonTopRectangle(changeModeButton,rect: changeModeButton1.frame,UIColor.systemRed)
            setButtos4mode(calcMode!)
        }else if calcMode == 1{
            iroiro.setButtonProperty(changeModeButton1,x:sp*2,y:by1,w:bh*3/2+sp/2,h:bh,UIColor.systemBlue)
            iroiro.setButtonProperty(changeModeButton2,x:sp*2+bh*3/2+sp/2+sp,y:by1,w:bh*3/2+sp/2,h:bh,UIColor.systemBlue)
            iroiro.setButtonTopRectangle(changeModeButton,rect: changeModeButton2.frame,UIColor.systemRed)
            setButtos4mode(calcMode!)
        }else if calcMode==2{
            //            iroiro.setButtonProperty(changeModeButton1, x: sp*2, y:by1, w: bh*3+sp*2, h: bh, UIColor.darkGray)
            //            setButtos4mode(calcMode!)
        }else{
            iroiro.setButtonProperty(changeModeButton1, x: sp*2, y:by1, w: bh*3+sp*2, h: bh, UIColor.darkGray)
            setButtos4mode(calcMode!)
        }
        if videoDate.count == 0{
            playButton.isEnabled=false
            backwardButton.isEnabled=false
        }
    }
    
    func setButtos4mode(_ mode:Int){
        if mode==0 || mode==1{
            changeModeButton1.setTitle("vHIT hori.", for: .normal)
            changeModeButton2.setTitle("vHIT vert.", for: .normal)
            changeModeButton2.isHidden=false
            changeModeButton.isHidden=false
            backwardButton.isHidden=false
            playButton.isHidden=false
            waveButton.setImage(  UIImage(systemName:"waveform.path.ecg.rectangle"), for: .normal)
            waveButton.backgroundColor=UIColor.systemBlue
            cameraButton.isEnabled=true
            cameraButton.alpha=1
        }else if mode==2{
            changeModeButton1.setTitle("VOG hor. & vert.", for: .normal)
            changeModeButton2.isHidden=true
            changeModeButton.isHidden=true
            
            backwardButton.isHidden=false
            playButton.isHidden=false
            waveButton.setImage(  UIImage(systemName:"waveform.path.ecg.rectangle"), for: .normal)
            waveButton.backgroundColor=UIColor.systemBlue
            cameraButton.isEnabled=true
            cameraButton.alpha=1
        }else{
            
        }
        
    }
    override var prefersHomeIndicatorAutoHidden: Bool {
        get {
            return true
        }
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    
    func removeFile(delFile:String){
        if let dir = FileManager.default.urls( for: .documentDirectory, in: .userDomainMask ).first {
            let path_file_name = dir.appendingPathComponent( delFile )
            let fileManager = FileManager.default
            
            do {
                try fileManager.removeItem(at: path_file_name)
            } catch {
                print("remove -> error")//エラー処理
                return
            }
            print("remove -> well done")
        }
    }
    
    //calcVHITで実行、その後moveGyroData()
    func getGyroCSV()->NSString{//gyroDataにデータを戻す
        var text:String=""
        for i in 0..<gyroHFiltered.count{
            text += String(Int(gyroHFiltered[i]*100)) + ","
            text += String(Int(gyroVFiltered[i]*100)) + ","
            //            print(text,str,gyroFiltered[i])
        }
        //        print("elapsed time:",CFAbsoluteTimeGetCurrent()-Start,gyroFiltered.count)
        let txt:NSString = text as NSString
        //        print("elapsed time:",CFAbsoluteTimeGetCurrent()-Start,gyroFiltered.count)
        return txt
    }
    
    func dispFilesindoc(){
        let documentDirectoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        do {
            let contentUrls = try FileManager.default.contentsOfDirectory(at: documentDirectoryURL, includingPropertiesForKeys: nil)
            let files = contentUrls.map{$0.lastPathComponent}
            
            for i in 0..<files.count{
                print(files[i])
            }
        } catch {
            print("none?")
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        // segueから遷移先のResultViewControllerを取得する
        //      tempCalcflag = calcFlag//別ページに移る時が計算中かどうか
        if let vc = segue.destination as? ParametersViewController {
            let ParametersViewController:ParametersViewController = vc
            //      遷移先のParametersViewControllerで宣言している値に代入して渡す
            //           ParametersViewController.faceMarkHidden = faceMarkHidden
            ParametersViewController.widthRange = widthRange
            ParametersViewController.waveWidth = waveWidth
            //    ParametersViewController.calcMode = calcMode
            ParametersViewController.eyeBorder = eyeBorder
            
            //          ParametersViewController.faceMark = faceMark
            ParametersViewController.wakuLength = wakuLength
            //           print("eyeRatio:",eyeRatio)
            ParametersViewController.eyeRatio = eyeRatio
            ParametersViewController.gyroRatio = gyroRatio
            ParametersViewController.videoGyroZure=videoGyroZure
            //            ParametersViewController.vorGainCorrection=vorGainCorrection
            ParametersViewController.vHITDisplayMode=vHITDisplayMode
            
            
#if DEBUG
            print("prepare para")
#endif
            
        }else if let vc = segue.destination as? HelpjViewController{
            let Controller:HelpjViewController = vc
            // Controller.calcMode = calcMode
        }else if let vc = segue.destination as? RecordViewController{
            let Controller:RecordViewController = vc
            if PHPhotoLibrary.authorizationStatus(for: .readWrite) == .authorized{
                iroiro.makeAlbum(vHIT96da)//なければ作る
                iroiro.makeAlbum(Wave96da)//これもなければ作る
            }
            Controller.videoCount=videoDate.count
        }else{
#if DEBUG
            print("prepare list")
#endif
        }
    }
    func removeBoxies(){
        waveBoxView?.isHidden = true
        vHITBoxView?.isHidden = true
    }
    var path2albumDoneFlag:Bool=false//不必要かもしれないが念の為
    func savePath2album(albumName:String,path:String){
        path2albumDoneFlag=false
        savePath2album_sub(name:albumName,path: path)
        while path2albumDoneFlag==false{
            sleep(UInt32(0.2))
        }
    }
    
    func savePath2album_sub(name:String,path:String){
        if let dir = FileManager.default.urls( for: .documentDirectory, in: .userDomainMask ).first {
            let fileURL = dir.appendingPathComponent( path )
            PHPhotoLibrary.shared().performChanges({ [self] in
                let assetRequest = PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: fileURL)!
                let albumChangeRequest = PHAssetCollectionChangeRequest(for: getPHAssetcollection(albumTitle: name))
                let placeHolder = assetRequest.placeholderForCreatedAsset
                albumChangeRequest?.addAssets([placeHolder!] as NSArray)
            }) { (isSuccess, error) in
                if isSuccess {
                    self.path2albumDoneFlag=true
                    // 保存成功
                } else {
                    self.path2albumDoneFlag=true//
                    // 保存失敗しても抜けたらtrue
                }
            }
        }
    }
    //gyroDataは劣化のないPngで保存
    func savePngImage2path(image:UIImage,path:String) {//imageを保存
        if let dir = FileManager.default.urls( for: .documentDirectory, in: .userDomainMask ).first {
            let path_url = dir.appendingPathComponent( path )
            let pngImageData = image.pngData()
            do {
                try pngImageData!.write(to: path_url, options: .atomic)
                //                saving2pathFlag=false
            } catch {
                print("gyroData.txt write err")//エラー処理
            }
        }
    }
    //結果画像はJpegで保存。Pngだと背景色黒で保存されてしまう。
    func saveJpegImage2path(image:UIImage,path:String) {//imageを保存
        if let dir = FileManager.default.urls( for: .documentDirectory, in: .userDomainMask ).first {
            let path_url = dir.appendingPathComponent( path )
            let jpegImageData = image.jpegData(compressionQuality: 1.0)
            do {
                try jpegImageData!.write(to: path_url, options: .atomic)
                //                saving2pathFlag=false
            } catch {
                print("gyroData.txt write err")//エラー処理
            }
        }
    }
    func existFile(aFile:String)->Bool{
        if let dir = FileManager.default.urls( for: .documentDirectory, in: .userDomainMask ).first {
            
            let path_url = dir.appendingPathComponent( aFile )
            let fileManager = FileManager.default
            if fileManager.fileExists(atPath: path_url.path){
                return true
            }else{
                return false
            }
            
        }
        return false
    }
    
    @IBAction func unwind(_ segue: UIStoryboardSegue) {
        //     if tempCalcflag == false{
        if let vc = segue.source as? ParametersViewController {
            let ParametersViewController:ParametersViewController = vc
            // segueから遷移先のResultViewControllerを取得する
            widthRange = ParametersViewController.widthRange
            waveWidth = ParametersViewController.waveWidth
            eyeBorder = ParametersViewController.eyeBorder
            
            wakuLength = ParametersViewController.wakuLength
            wakuE.size.width = CGFloat(wakuLength)
            wakuE.size.height = CGFloat(wakuLength)
            //       calcMode=ParametersViewController.calcMode
            
            //      var chanF=false
            eyeRatio=ParametersViewController.eyeRatio
            gyroRatio=ParametersViewController.gyroRatio
            //           faceMark=ParametersViewController.faceMark
            //            vorGainCorrection=ParametersViewController.vorGainCorrection
            videoGyroZure=ParametersViewController.videoGyroZure
            vHITDisplayMode=ParametersViewController.vHITDisplayMode
            
            setUserDefaults()
            if eyeVeloXFiltered.count > 400 && videoDate.count>0{
                if calcMode != 2{//データがありそうな時は表示
                    moveGyroData()
                    calcDrawVHIT(tuple: false)
                    drawOneWave(startcount: vhitCurpoint,clearFlag: false)//gyroFileがないとエラー
                }else{
                    
                }
            }
            dispWakus()
            if boxiesFlag==false{
                showBoxies(f: false)
            }else{
                showBoxies(f: true)
            }
            setButtons_first()
#if DEBUG
            print("TATSUAKI-unwind from para")
#endif
        }else if segue.source is StatementViewController{
            stopButton.isHidden = true
            showBoxies(f: false)//isVHITに応じてviewを表示
            setButtons_first()
            getAlbumFirst()
            dispWakus()
            showWakuImages()
            
            print("StatementViewController unwind")
        }else if let vc = segue.source as? RecordViewController{
            let Controller:RecordViewController = vc
            if Controller.captureSession.isRunning{//何もせず帰ってきた時
                Controller.captureSession.stopRunning()
                print("session is moving")
            }else{
                print("session is not moving")
            }
            if Controller.recordedFlag==true{
                //                getVideosAlbumList()
                //            }else{//
                print("recorded well")
                var dH:Double=0//lateral
                var dV:Double=0//vertical
                var gyroH = Array<Double>()//Holizontal
                var gyroV = Array<Double>()//vertical
                var gyroTime = Array<Double>()
                KalmanInit()
                gyroHFiltered.removeAll()
                gyroVFiltered.removeAll()
                showBoxies(f: false)
                setVideoButtons(mode: false)
                
                print("rewind***1")
                for i in 0...Controller.gyro.count/3-3{//-2でエラーなので、-3としてみた
                    gyroTime.append(Controller.gyro[i*3])
                    dH=Double(Kalman(value:CGFloat(Controller.gyro[i*3+1]*10),num:0))
                    dV=Double(Kalman(value:CGFloat(Controller.gyro[i*3+2]*10),num:1))
                    gyroH.append(-dH)
                    gyroV.append(-dV)
                }
                //gyroは10msごとに拾ってある.合わせる
                //これをvideoのフレーム数に合わせる
                while Controller.saved2album == false{//fileができるまで待つ
                    sleep(UInt32(0.1))
                }
                print("rewind***2")
                
                removeFile(delFile: "temp.png")
                //                getVideosAlbumList(name: vHIT_)
                if videoDate.count<3{
                    getAlbumAssets()
                }else{
                    getAlbumAssets_last()
                }
                print("rewind***3")
                let videoCount=Controller.videoCount
                //ビデオが出来るまで待つ
                while videoDura.count==videoCount{
                    sleep(UInt32(0.5))
                }
                
                videoCurrent=videoDura.count-1
                showVideoIroiro(num:0)
                var fps=getFPS(videoCurrent)
                if fps < 200.0{
                    fps *= 2.0
                }
                let framecount=Int(Float(gyroH.count)*(fps)/100.0)
                var lastJ:Int=0
                //                let t1=CFAbsoluteTimeGetCurrent()
                for i in 0...framecount+500{//100を尻に付けないとgyrodataが変な値になる
                    let gn=Double(i)/Double(fps)//iフレーム目の秒数
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
                
                print("rewind***4")
                
                let gyroCSV=getGyroCSV()//csv文字列
                //                int rgb[240*60*5*2 + 240*5*2];//5minの水平、垂直と５秒の余裕
                //pixel2imageで240*60*5*2 + 240*5*2の配列を作るので,増やすときは注意
                let avasset = iroiro.requestAVAsset(asset: videoPHAsset[videoCurrent])
                let eyeImage = iroiro.getThumb(avasset: avasset!)
                let gyroImage=openCV.pixel2image(eyeImage, csv: gyroCSV as String)
                //まずtemp.pngに保存して、それをvHIT_アルバムにコピーする
                savePngImage2path(image: gyroImage!, path: "temp.png")
                while existFile(aFile: "temp.png")==false{
                    sleep(UInt32(0.1))
                }
                print("rewind***5")
                
                savePath2album(albumName:vHIT96da,path: "temp.png")
                startFrame=0
                //                getPngsAlbumList()
                //VOGの時もgyrodataを保存する。（不必要だが、考えるべきことが減りそうなので）
            }else{
                if Controller.startButton.isHidden==true && Controller.stopButton.isHidden==true{
                    
                    getAlbumAssets()
#if DEBUG
                    print("アルバムを消されていたので、録画を保存しなかった。")
#endif
                }else{
#if DEBUG
                    print("Exitで抜けた。")
#endif
                }
            }
            UIApplication.shared.isIdleTimerDisabled = false//スリープする
        }else{
#if DEBUG
            print("tatsuaki-unwind from list")
#endif
        }
    }
    
    func isVerticalData(num:Int)->Bool{
        let str1=videoDate[num].components(separatedBy: " ")
        let str=str1[0].components(separatedBy: "-")
        let date=Int(str[0])!*10000+Int(str[1])!*100+Int(str[2])!
        //        print("date",date)
        if date>20210609{//
            return true
        }
        return false
    }
    
    func readGyroFromPng(img:UIImage){
        let newVersion=isVerticalData(num: videoCurrent)//20210609より新しい場合は垂直データもある
        gyroHFiltered.removeAll()
        gyroVFiltered.removeAll()
        let rgb8=img.pixelData()
        for i in 0..<rgb8!.count/4{
            var rgb:Int=0
            if rgb8![i*4]==1{
                rgb = Int(rgb8![i*4+1])*256 + Int(rgb8![i*4+2])
            }else{
                rgb = -Int(rgb8![i*4+1])*256 - Int(rgb8![i*4+2])
            }
            if newVersion==true{
                //                print("newVersion")
                if i%2==0{
                    gyroHFiltered.append(CGFloat(rgb)/100.0)
                }else{
                    gyroVFiltered.append(CGFloat(rgb)/100.0)
                }
            }else{
                //                print("oldversion")
                gyroHFiltered.append(CGFloat(rgb)/100.0)
                gyroVFiltered.append(CGFloat(rgb)/100.0)
            }
        }
        //        print(gyroVFiltered.count)
    }
    func readGyroFromNul(){
        for _ in 0..<100*60*5{
            gyroHFiltered.append(0)
            gyroVFiltered.append(0)
        }
    }
    
    func moveWakus
    (rect:CGRect,stRect:CGRect,movePo:CGPoint,hani:CGRect) -> CGRect{
        var r:CGRect
        r = rect//2種類の枠を代入、変更してreturnで返す
        let dx:CGFloat = movePo.x
        let dy:CGFloat = movePo.y
        
        r.origin.x = stRect.origin.x + dx/20//3->5->20
        r.origin.y = stRect.origin.y + dy/20
        //r.size.width = stRect.size
        if r.origin.x < hani.origin.x{
            r.origin.x = hani.origin.x
        }else if r.origin.x > hani.origin.x+hani.width{
            r.origin.x = hani.origin.x+hani.width
        }
        if r.origin.y < hani.origin.y{
            r.origin.y = hani.origin.y
        }
        if r.origin.y > hani.origin.y+hani.height{
            r.origin.y = hani.origin.y+hani.height
        }
        return r
    }
    
    var tapPosleftRight:Int=0//left-eye,right=head最初にタップした位置で
    var startEyeGyroPoint = CGPoint(x:0,y:0)//eye,gyro
    var startZure:CGFloat=0
    var moveThumX:CGFloat=0
    var moveThumY:CGFloat=0
    var startRect:CGRect = CGRect(x:0,y:0,width:0,height:0)//tapしたrectのtapした時のrect
    @IBAction func panGesture(_ sender: UIPanGestureRecognizer) {
        if calcFlag == true{
            return
        }
        let move:CGPoint = sender.translation(in: self.view)
        let pos = sender.location(in: self.view)
        if sender.location(in: view).y>videoSlider.frame.minY-20{//
            return
        }
        if sender.state == .began {
            
            //    tapDownUpTime=CFAbsoluteTimeGetCurrent()
            
            moveThumX=0
            moveThumY=0
            if checkDispMode()==0{//checkDispMode() 1-vHIT 2-VOG 0-non
                startRect=wakuE
                
            }else if checkDispMode()==1 {//vhit
                if sender.location(in: view).y<view.bounds.height*2/5{
                    
                }else{
                    if sender.location(in: view).x<view.bounds.width/3{
                        tapPosleftRight=0
                        print("left")
                    }else if sender.location(in: view).x<view.bounds.width*2/3{
                        tapPosleftRight=1
                        print("middle")
                    }else{
                        tapPosleftRight=2
                        print("right")
                    }
                    startEyeGyroPoint=CGPoint(x:CGFloat(eyeRatio),y:CGFloat(gyroRatio))
                    startZure=CGFloat(videoGyroZure)
                }
            }else{//遅いのでやめました
            }
        } else if sender.state == .changed {
            if calcMode != 2 && vHITBoxView?.isHidden == false{//vhit
                if sender.location(in: view).y<view.bounds.height*2/5{
                    
                }else{
                    //                if sender.numberOfTouches==1{//横でzureGyroHead,縦でratio_headを変更
                    moveThumX += move.x*move.x
                    moveThumY += move.y*move.y
                    if moveThumX>moveThumY{//横移動の和＞縦移動の和
                        videoGyroZure=Int(startZure + move.x/10)
                    }else{
                        if tapPosleftRight==0{
                            eyeRatio=Int(startEyeGyroPoint.x - move.y)
                        }else if tapPosleftRight==1{
                            let gyroRatio_old=startEyeGyroPoint.y
                            gyroRatio=Int(startEyeGyroPoint.y - move.y)
                            eyeRatio=Int(startEyeGyroPoint.x*CGFloat(gyroRatio)/CGFloat(gyroRatio_old))
                        }else{
                            gyroRatio=Int(startEyeGyroPoint.y - move.y)
                        }
                    }
                    if gyroRatio>4000{
                        gyroRatio=4000
                    }else if gyroRatio<10{
                        gyroRatio=10
                    }
                    if videoGyroZure>25{
                        videoGyroZure = 25
                    }else if videoGyroZure < -10{
                        videoGyroZure = -10
                    }
                    if eyeRatio>4000{
                        eyeRatio=4000
                    }else if eyeRatio<10{
                        eyeRatio=10
                    }
                    moveGyroData()
                    calcDrawVHIT(tuple: false)
                    drawOneWave(startcount: vhitCurpoint,clearFlag: false)
                }
                //            }else if calcMode == 2 && vogBoxView?.isHidden == false{//vog
                //
            }else{//枠 changed
                if pos.y>view.bounds.height*3/4{
                    return
                }
                let ww=view.bounds.width
                let wh=view.bounds.height
                let et=CGRect(x:ww/10,y:wh/20,width: ww*4/5,height:wh*3/4)
                wakuE = moveWakus(rect:wakuE,stRect: startRect,movePo: move,hani:et)
                
                dispWakus()
                showWakuImages()
                setUserDefaults()
                
            }
        }else if sender.state == .ended{
            setUserDefaults()
        }
    }
    
    
    @IBAction func tapGesture(_ sender: UITapGestureRecognizer) {
        
        if videoDate.count==0{
            return
        }
        let loc=sender.location(in: view)
        let eyeFrame=eyeWaku_image.frame
        //checkDispMode() 1-vHIT 2-VOG 0-non
        let vHIT_dispmode=checkDispMode()
        if vHIT_dispmode==1 {//vhit
            if loc.y<vHITBoxView!.frame.minY || (loc.y>vHITBoxView!.frame.maxY && loc.y<waveBoxView!.frame.minY) ||
                (loc.y>waveBoxView!.frame.maxY && loc.y<waveSlider.frame.minY-20){//not in box
                if timerCalc?.isValid == false {//計算中でなく、表示枠以外を押した時
                    onWaveButton(0)
                    return
                }
            }else if loc.y>vHITBoxView!.frame.minY && loc.y<vHITBoxView!.frame.maxY{//vhit表示モード変更
                vHITDisplayMode = getUserDefault(str: "vHITDisplayMode", ret:1)
                if vHITDisplayMode==0{
                    vHITDisplayMode=1
                }else{
                    vHITDisplayMode=0
                }
                UserDefaults.standard.set(vHITDisplayMode,forKey: "vHITDisplayMode")
                moveGyroData()
                calcDrawVHIT(tuple: false)
                drawOneWave(startcount: vhitCurpoint,clearFlag: false)
                return
            }else if loc.y<waveBoxView!.frame.maxY && waveTuple.count>0{
                let cnt=waveTuple.count
                for i in 0..<cnt {
                    if waveTuple[i].3 == 1{
                        if waveTuple[i].2 == 0{
                            waveTuple[i].2 = 1
                        }else{
                            waveTuple[i].2 = 0
                        }
                    }
                }
                drawVHITwaves(clearFlag: false)
            }
        }else if vHIT_dispmode==2{//vog
            //            if loc.y<vogBoxView!.frame.minY || (loc.y>vogBoxView!.frame.maxY && loc.y<waveSlider.frame.minY-20){
            //                if timerCalc?.isValid == false {//計算中でなく、表示枠以外を押した時
            //                    onWaveButton(0)
            //                    return
            //                }
            //            }
        }else{//波形が表示されていないとき
            if loc.y < videoSlider.frame.minY-20{//video slide bar と被らないように
                wakuE.origin.x=loc.x
                wakuE.origin.y=loc.y
                //                wakuE = moveWakus(rect:wakuE,stRect: startRect,movePo: move,hani:et)
                dispWakus()
                showWakuImages()
                setUserDefaults()
            }
            //                print("tap")
        }
    }
    func setCurrVHIT(pos:Int){
        let cnt=waveTuple.count
        if cnt>0{
            for i in 0..<cnt{
                if waveTuple[i].1<pos && waveTuple[i].1+120>pos{
                    waveTuple[i].3 = 1 //sellected
                }else{
                    waveTuple[i].3 = 0//not sellected
                }
            }
        }
    }
    
    func g5(st:Int)->CGFloat{
        if st>3 && st<gyroMoved.count-2{
            return(gyroMoved[st-2]+gyroMoved[st-1]+gyroMoved[st]+gyroMoved[st+1]+gyroMoved[st+2])*2.0
        }
        return 0
    }
    
    func upDownp(i:Int)->Int{
        let naf:Int=waveWidth*240/1000
        let raf:Int=Int(Float(widthRange)*240.0/1000.0)
        let sl:CGFloat=5//slope:傾き　遠藤様の検査で捕まらないので10->5に変更してみる 20220715
        let g1=g5(st:i+1)-g5(st:i)
        let g2=g5(st:i+2)-g5(st:i+1)
        let g3=g5(st:i+3)-g5(st:i+2)
        let ga=g5(st:i+naf-raf+1)-g5(st:i+naf-raf)
        let gb=g5(st:i+naf-raf+2)-g5(st:i+naf-raf+1)
        let gc=g5(st:i+naf+raf+1)-g5(st:i+naf+raf)
        let gd=g5(st:i+naf+raf+2)-g5(st:i+naf+raf+1)
        
        for j in 0...140{//点取得がエラーの時
            if i+j-20<errArray.count {
                if !errArray[i+j-20] {
                    return -1
                }
            }
        }
        //下のように変更すると小さな波も拾える
        if /*g1>1 &&*/ g2>g1 && g3>g2 && ga>sl && gb>sl && gc < -sl && gd < -sl  {
            return 0
        }else if /*g1 < -1 &&*/ g2<g1 && g3<g2 && ga < -sl && gb < -sl && gc>sl && gd>sl{
            return 1
        }
        return -1
    }
    
    func SetWave2wP(number:Int) -> Int {//-1:波なし 0:上向き波？ 1:その反対向きの波
        let flatwidth:Int = 12//12frame-50ms
        
        let dep1=gyroMoved[number] - gyroMoved[number+flatwidth/2]
        let dep2=gyroMoved[number+flatwidth] - gyroMoved[number+flatwidth/2]
        if dep1*dep1+dep2*dep2>10.0 {//hitの立ち上がりの部分がエラーだった時にhit終わりの波を間違えて取らないように
            return -1
        }
        let t = upDownp(i: number + flatwidth)
        if t != -1 {
            let ws = number// - flatwidth + 12;//波表示開始位置 wavestartpoint
            
            waveTuple.append((t,ws,1,0))//L/R,frameNumber,disp,current)
            
            let n=waveTuple.count-1
            for i in 0..<120{//number..<number + 120{//calcMode:Int?//0:HIThorizontal 1:HITvertical 2:VOG
                if calcMode==0{
                    eyeWs[n][i]=eyeVeloXFiltered4update[ws+i]*CGFloat(eyeRatio)/300.0
                    gyroWs[n][i]=gyroMoved[ws+i]*CGFloat(gyroRatio)/100.0
                }else{
                    eyeWs[n][i]=eyeVeloYFiltered4update[ws+i]*CGFloat(eyeRatio)/300.0
                    gyroWs[n][i]=gyroMoved[ws+i]*CGFloat(gyroRatio)/100.0
                }
            }
        }
        return t
    }
    
    //wavetuple変更の有無、高さ(%)表示変更の時はwavetupleは変更しない。
    func calcDrawVHIT(tuple:Bool){//true:
        tempTuple.removeAll()
        for i in 0..<waveTuple.count{
            tempTuple.append(waveTuple[i])
        }
        waveTuple.removeAll()
        if arrayDataCount < 400 {
            return
        }
        var skipCnt:Int = 0
        for vcnt in 50..<(arrayDataCount - 130) {// flatwidth + 120 までを表示する。実在しないvHITeyeをアクセスしないように！
            
            if skipCnt > 0{
                skipCnt -= 1
            }else if SetWave2wP(number:vcnt) > -1{
                skipCnt = 100
            }
        }
        if tuple==false{
            waveTuple.removeAll()
            for i in 0..<tempTuple.count{
                waveTuple.append(tempTuple[i])
            }
        }
        drawVHITwaves(clearFlag: false)
    }
    
    
    @IBAction func onNextButtonLongPress(_ sender: UILongPressGestureRecognizer) {
        if (sender.state == UIGestureRecognizer.State.ended) {
            startFrame=0
            videoPlayMode=0
            showVideoIroiro(num: 5)
            print("next長押し終了")
        }
    }
    
    @IBAction func onBackButtonLongPress(_ sender: UILongPressGestureRecognizer) {
        if (sender.state == UIGestureRecognizer.State.ended) {
            if vHITBoxView?.isHidden == false{
                return
            }
            startFrame=0
            videoPlayMode=0
            showVideoIroiro(num: -5)
            print("back長押し終了")
        }
    }

}
