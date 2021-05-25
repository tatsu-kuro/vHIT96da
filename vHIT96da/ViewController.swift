//
//  ViewController.swift
//  vHIT96da
//
//  Created by kuroda tatsuaki on 2018/02/10.
//  Copyright © 2018年 tatsuaki.kuroda. All rights reserved.
//

import UIKit
import AVFoundation
import AssetsLibrary
import Photos
import MessageUI
//import CoreLocation
//import CoreTelephony

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
        let ratio = widthRatio < heightRatio ? widthRatio : heightRatio
        
        let resizedSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        
        UIGraphicsBeginImageContextWithOptions(resizedSize, false, 0.0) // 変更
        draw(in: CGRect(origin: .zero, size: resizedSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return resizedImage
    }

    
    func createGrayImage(r:[CGFloat], g: [CGFloat], b:[CGFloat], a:[CGFloat]) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        let wid:Int = Int(size.width)
        let hei:Int = Int(size.height)
        
        for w in 0..<wid {
            for h in 0..<hei {
                let index = (w * wid) + h
                let color = 0.2126 * r[index] + 0.7152 * g[index] + 0.0722 * b[index]
                UIColor(red: color, green: color, blue: color, alpha: a[index]).setFill()
                let drawRect = CGRect(x: w, y: h, width: 1, height: 1)
                UIRectFill(drawRect)
                draw(in: drawRect, blendMode: .destinationIn, alpha: 1)
            }
        }
        let grayImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return grayImage
    }
    
    func tint(color: [UIColor]) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        var colorCnt:Int = 0
        let colorTotalCnt=color.count
        for w in 0..<Int(size.width) {
            for h in 0..<Int(size.height) {
                let index = (w * Int(size.width)) + h
                if colorCnt==colorTotalCnt{
                    color[index-1].setFill()
                    let drawRect = CGRect(x: w, y: h, width: 1, height: 1)
                    UIRectFill(drawRect)
                    draw(in: drawRect, blendMode: .destinationIn, alpha: 0)
                    break
                }else{
                    color[index].setFill()
                    let drawRect = CGRect(x: w, y: h, width: 1, height: 1)
                    UIRectFill(drawRect)
                    draw(in: drawRect, blendMode: .destinationIn, alpha: 1)
                }
                colorCnt += 1
            }
            if colorCnt==colorTotalCnt{
                break
            }
        }
        let tintedImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return tintedImage
    }
    func createImage(r:[CGFloat], g: [CGFloat], b:[CGFloat], a:[CGFloat]) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        let wid:Int = Int(size.width)
        let hei:Int = Int(size.height)
        
        for w in 0..<wid {
            for h in 0..<hei {
                let index = (w * wid) + h
                UIColor(red: r[index], green: g[index], blue: b[index], alpha: a[index]).setFill()
                let drawRect = CGRect(x: w, y: h, width: 1, height: 1)
                UIRectFill(drawRect)
                draw(in: drawRect, blendMode: .destinationIn, alpha: 1)
            }
            print("createImage/h:",w)
        }
        let tintedImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return tintedImage
    }
}

@available(iOS 13.0, *)
class ViewController: UIViewController, MFMailComposeViewControllerDelegate{
    let openCV = opencvWrapper()
//    var isIphone:Bool = true//falseではアラートを出して走らないようにする
    var vhitCurpoint:Int = 0//現在表示波形の視点（アレイインデックス）
    var vogCurpoint:Int = 0
    var videoPlayer: AVPlayer!
//    var vogImageView:UIImageView?

    @IBOutlet weak var videoSlider: UISlider!
    //以下はalbum関連
    let albumName:String = "vHIT_VOG"
    var albumExist:Bool=false
    var videoArrayCount:Int = 0
    var videoDate = Array<String>()
    var videoDateTime = Array<Date>()//creationDate+durationより１−２秒遅れるpngdate
    var videoURL = Array<URL>()
    var videoImg = Array<UIImage>()
    var videoDura = Array<String>()
    var videoAsset = Array<AVAsset>()
    var videoCurrent:Int=0
//    var pngDateTime = Array<Date>()//videoDateTimeより遅れる
//    var pngImg = Array<UIImage>()
//    var pngAsset = Array<PHAsset>()
    //album関連、ここまで
    
    var vogImage:UIImage?
    @IBOutlet weak var cameraButton: UIButton!
    var boxF:Bool=false
    @IBOutlet weak var vogButton: UIButton!
    @IBOutlet weak var vhitButton: UIButton!
    
    @IBOutlet weak var forwardButton: UIButton!
    @IBOutlet weak var backwardButton: UIButton!
    
    @IBOutlet weak var damyBottom: UILabel!
    
    func playTrack()//こんな方法もある
    {
        let playerItem = AVPlayerItem(url: videoURL[videoCurrent])
        videoPlayer.replaceCurrentItem(with:playerItem)
        videoPlayer.play()
    }
    func playTrack(number:Int)//こんな方法もある
    {
        videoPlayer.replaceCurrentItem(with:AVPlayerItem(url: videoURL[number]))
        videoPlayer.play()
    }
    @IBAction func onPlayButton(_ sender: Any) {
        showBoxies(f: false)
        if (videoPlayer.rate != 0) && (videoPlayer.error == nil) {//playing
            videoPlayer.pause()
            onForwardButton(0)
        }else{
            if videoSlider.value>videoSlider.maximumValue-0.5{
                videoSlider.value=0
                let newTime = CMTime(seconds: Double(videoSlider.value), preferredTimescale: 600)
                videoPlayer.seek(to: newTime, toleranceBefore: .zero, toleranceAfter: .zero)
                startFrame=Int(videoSlider.value*getFPS(url: videoURL[self.videoCurrent]))
            }else{
                videoPlayer.play()
            }
        }
    }
    @IBAction func onForwardButton(_ sender: Any) {
        if videoURL.count == 0{
            return
        }
        videoPlayer.pause()
        if videoSlider.value>videoSlider.maximumValue-0.1{
            return
        }
        videoSlider.value += 0.05
        let newTime = CMTime(seconds: Double(videoSlider.value), preferredTimescale: 600)
        videoPlayer.seek(to: newTime, toleranceBefore: .zero, toleranceAfter: .zero)
        startFrame=Int(videoSlider.value*getFPS(url: videoURL[self.videoCurrent]))
    }
    
    @IBAction func onBackwardButton(_ sender: Any) {
        if videoURL.count == 0{
            return
        }
       videoPlayer.pause()
        if videoSlider.value < 0.1{
            return
        }
        videoSlider.value -= 0.05
        let newTime = CMTime(seconds: Double(videoSlider.value), preferredTimescale: 600)
        videoPlayer.seek(to: newTime, toleranceBefore: .zero, toleranceAfter: .zero)
        startFrame=Int(videoSlider.value*getFPS(url: videoURL[self.videoCurrent]))
    }
    
    @IBOutlet weak var wakuAll: UIImageView!
    
    @IBOutlet weak var wakuEye: UIImageView!
    @IBOutlet weak var wakuEyeb: UIImageView!
    @IBOutlet weak var wakuFac: UIImageView!
    @IBOutlet weak var wakuFacb: UIImageView!
    
    var vogBoxHeight:CGFloat=0
    var vogBoxYmin:CGFloat=0
    var vogBoxYcenter:CGFloat=0
    var vhitBoxHeight:CGFloat=0
    var vhitBoxYmin:CGFloat=0
    var vhitBoxYcenter:CGFloat=0
    var gyroBoxHeight:CGFloat=0
    var gyroBoxYmin:CGFloat=0
    var gyroBoxYcenter:CGFloat=0
    var mailWidth:CGFloat=0//VOG
    var mailHeight:CGFloat=0//VOG
    var gyroBoxView: UIImageView?//vhit realtime
    var gyroLineView: UIImageView?//vhit realtime
    var vhitBoxView: UIImageView?//vhits
    var vhitLineView: UIImageView?//vhits
    var vogLineView:UIImageView?//vog
    var vogBoxView:UIImageView?//vog
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var eraseButton: UIButton!
    var startFrame:Int=0
    var calcFlag:Bool = false//calc中かどうか
    var nonsavedFlag:Bool = false //calcしてなければfalse, calcしたらtrue, saveしたらfalse
    var openCVstopFlag:Bool = false//calcdrawVHITの時は止めないとvHITeye
    //vHITeyeがちゃんと読めない瞬間が生じるようだ
    @IBOutlet weak var videoDuration: UILabel!
    @IBOutlet weak var videoFps: UILabel!
//    @IBOutlet weak var buttonsWaku: UIStackView!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var helpButton: UIButton!
    @IBOutlet weak var waveButton: UIButton!
    @IBOutlet weak var stopButton: UIButton!
    @IBOutlet weak var listButton: UIButton!
    @IBOutlet weak var calcButton: UIButton!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var paraButton: UIButton!
    @IBOutlet weak var eyeWaku_image: UIImageView!
    
    @IBOutlet weak var faceWaku_image: UIImageView!
    
    @IBOutlet weak var wakuShowFace_image: UIImageView!
    @IBOutlet weak var wakuShowEye_image: UIImageView!
    
    var wave3View:UIImageView?
    var wakuE = CGRect(x:300.0,y:100.0,width:5.0,height:5.0)
    var wakuF = CGRect(x:300.0,y:200.0,width:5.0,height:5.0)
    
    @IBOutlet weak var slowImage: UIImageView!
    @IBOutlet weak var currentVideoDate: UILabel!
    var calcDate:String = ""
    var idNumber:Int = 0
    var vHITtitle:String = ""
    
    var widthRange:Int = 0
    var waveWidth:Int = 0
    var eyeBorder:Int = 20
    var eyeRatio:Int = 100//vhit
    var gyroRatio:Int = 100//vhit
    var posRatio:Int = 100//vog
    var veloRatio:Int = 100//vog
    var isVHIT:Bool?//true-vhit false-vog
    var faceF:Int = 0
    var videoGyroZure:Int = 40
    //解析結果保存用配列
    
    var waveTuple = Array<(Int,Int,Int,Int)>()//rl,framenum,disp onoff,current disp onoff)
    
    var eyePosXOrig = Array<CGFloat>()//eyePosOrig
    var eyePosXFiltered = Array<CGFloat>()//eyePosFiltered
    var eyeVeloXOrig = Array<CGFloat>()//eyeVeloOrig
    var eyeVeloXFiltered = Array<CGFloat>()//eyeVeloFiltered
 
    var eyePosYOrig = Array<CGFloat>()//eyePosOrig
    var eyePosYFiltered = Array<CGFloat>()//eyePosFiltered
    var eyeVeloYOrig = Array<CGFloat>()//eyeVeloOrig
    var eyeVeloYFiltered = Array<CGFloat>()//eyeVeloFiltered

    
    var faceVeloOrig = Array<CGFloat>()//faceVeloOrig
    var faceVeloFiltered = Array<CGFloat>()//faceVeloFiltered
    var gyroFiltered = Array<CGFloat>()//gyroFiltered
    var gyroMoved = Array<CGFloat>()//gyroVeloFilterd
    
    var timer: Timer!
    
    var eyeWs = [[Int]](repeating:[Int](repeating:0,count:125),count:80)
    var gyroWs = [[Int]](repeating:[Int](repeating:0,count:125),count:80)
    var initialFlag:Bool=true//:Int = 0
    func playVideoURL(video:URL){//nextVideo
        let options = [CIDetectorAccuracy: CIDetectorAccuracyHigh]
        let avAsset = AVURLAsset(url: video, options: options)
        let playerItem: AVPlayerItem = AVPlayerItem(asset: avAsset)
        let videoDuration=Float(CMTimeGetSeconds(avAsset.duration))
        // Create AVPlayer
        videoPlayer = AVPlayer(playerItem: playerItem)
        // Add AVPlayer
        let layer = AVPlayerLayer()
        layer.videoGravity = AVLayerVideoGravity.resize//resizeAspect
        layer.player = videoPlayer
        layer.frame = view.bounds
        print("layerCount:",view.layer.sublayers?.count)
        if initialFlag==true{//1回目は一番奥にビデオのlayerを加える。
            view.layer.insertSublayer(layer, at: 0)
            initialFlag = false
        }else{//2回目からは一番奥のlayerに置き換える。
            view.layer.sublayers![0]=layer
        }
        videoSlider.minimumValue = 0
        videoSlider.maximumValue = videoDuration
        videoSlider.value=0
        videoSlider.addTarget(self, action: #selector(onSliderValueChange), for: UIControl.Event.valueChanged)
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
//            self.startFrame=Int(value*self.getFPS(url: self.videoURL[self.videoCurrent]))
        })
    }
    @objc func onSliderValueChange(){
        videoPlayer.pause()
        let newTime = CMTime(seconds: Double(videoSlider.value), preferredTimescale: 600)
        videoPlayer.seek(to: newTime, toleranceBefore: .zero, toleranceAfter: .zero)
        startFrame=Int(videoSlider.value*getFPS(url: videoURL[videoCurrent]))
        let nsstring : NSString = NSString(string: videoDura[videoCurrent])
        let num : Float = nsstring.floatValue - 1
        if startFrame > Int(getFPS(url:videoURL[videoCurrent])*num){
            startFrame = Int(getFPS(url:videoURL[videoCurrent])*num)
        }else if startFrame < 0{
            startFrame=0
        }
        dispWakus()
        showWakuImages()
     }
    /*
     override func viewDidLoad() {
         super.viewDidLoad()
         getUserDefaults()
 //        cameraButton.selectedSegmentIndex = cameraMode
         //setteiしてなければ、以下
     
         let avAsset = AVURLAsset(url: videoURL!)
         let ww:CGFloat=view.bounds.width
         let wh:CGFloat=view.bounds.height
         let sp=ww/120//間隙
         let bw=(ww-sp*10)/7//ボタン幅
         let bh=bw*170/440
         let by = wh - bh - sp
         let seeky = by - bh
         
         videoDuration=Float(CMTimeGetSeconds(avAsset.duration))
         let playerItem: AVPlayerItem = AVPlayerItem(asset: avAsset)
         // Create AVPlayer
         videoPlayer = AVPlayer(playerItem: playerItem)
         // Add AVPlayer
         let videoPlayerLayer = AVPlayerLayer()
         videoPlayerLayer.videoGravity = AVLayerVideoGravity.resizeAspect
         videoPlayerLayer.player = videoPlayer
         if videoPlayerLayerRect.width==0 {
             videoPlayerLayerRect=view.bounds
         }
         videoPlayerLayer.frame = videoPlayerLayerRect
 //        layer.frame = CGRect(x:-view.bounds.width,y:0,width: view.bounds.width*2,height:view.bounds.height*2)
         view.layer.addSublayer(videoPlayerLayer)
         // Create Movie SeekBar
         seekBar.frame = CGRect(x: sp*2, y:seeky, width: ww - 4*sp, height: bh)
         seekBar.thumbTintColor=UIColor.orange
         seekBar.minimumValue = 0
         seekBar.maximumValue = videoDuration
         seekBar.addTarget(self, action: #selector(onSliderValueChange), for: UIControl.Event.valueChanged)
         view.addSubview(seekBar)
         // Set SeekBar Interval
         let interval : Double = Double(0.5 * seekBar.maximumValue) / Double(seekBar.bounds.maxX)
         // ConvertCMTime
         let time : CMTime = CMTimeMakeWithSeconds(interval, preferredTimescale: Int32(NSEC_PER_SEC))
         // Observer
         videoPlayer.addPeriodicTimeObserver(forInterval: time, queue: nil, using: {time in
             // Change SeekBar Position
             let duration = CMTimeGetSeconds(self.videoPlayer.currentItem!.duration)
             let time = CMTimeGetSeconds(self.videoPlayer.currentTime())
             let value = Float(self.seekBar.maximumValue - self.seekBar.minimumValue) * Float(time) / Float(duration) + Float(self.seekBar.minimumValue)
             self.seekBar.value = value
         })
         currTimeLabel.frame = CGRect(x: sp*2, y: 5, width: bw*2, height: bh)
         currTimeLabel!.font=UIFont.monospacedDigitSystemFont(ofSize: 15, weight: .medium)
         view.bringSubviewToFront(currTimeLabel)
         // Create Movie Start Button
         mailButton.frame = CGRect(x:sp*2+bw*0,y:by,width:bw,height:bh)
         setButtonProperty(button: mailButton, color: UIColor.darkGray)
         view.bringSubviewToFront(mailButton)
         saveButton.frame = CGRect(x:sp*3+bw*1,y:by,width:bw,height:bh)
         setButtonProperty(button: saveButton, color: UIColor.darkGray)
         view.bringSubviewToFront(saveButton)
         waveButton.frame = CGRect(x:sp*4+bw*2,y:by,width:bw,height:bh)
         setButtonProperty(button: waveButton, color: UIColor.darkGray)
         view.bringSubviewToFront(waveButton)
         calcButton.frame = CGRect(x: sp*5+bw*3, y: by, width: bw, height: bh)
         setButtonProperty(button: calcButton, color: UIColor.blue)
         view.bringSubviewToFront(calcButton)
         playButton.frame = CGRect(x: sp*6+bw*4, y: by, width: bw, height: bh)
         setButtonProperty(button: playButton, color: UIColor.orange)
         view.bringSubviewToFront(playButton)
         album.setButtonProperty(setteiButton,x:sp*7+bw*5,y:by,w:bw,h:bh,UIColor.darkGray)
         view.bringSubviewToFront(setteiButton)
         album.setButtonProperty(exitButton,x: sp*8+bw*6,y:by, w:bw,h:bh,UIColor.darkGray)
         view.bringSubviewToFront(exitButton)
         timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.update), userInfo: nil, repeats: true)
         videoSize=resolutionSizeOfVideo(url:videoURL!)
         screenSize=view.bounds.size
         videoFps=getFPS(url: videoURL!)
         dispWakus()
         showWakuImages()
         fpsLabel.frame=CGRect(x:ww - bw*2,y:5,width: bw*2-sp*2,height: bh)
         fpsLabel.text = String(format:"fps:%.0f w:%.0f h:%.0f",videoFps,videoSize.width,videoSize.height)
         fpsLabel!.font=UIFont.monospacedDigitSystemFont(ofSize: 15, weight: .medium)
         view.bringSubviewToFront(fpsLabel)
         vogBoxHeight=ww*16/25
         vogBoxYmin=wh/2-vogBoxHeight/2
         vogBoxYcenter=wh/2
         fpsXd=Int((240.0/videoFps).rounded())
 //        mailButton.isEnabled=false
 //        cameraButton.frame = CGRect(x:  sp*7+bw*5, y: by-bh*2, width: bw*2+sp, height:bh)
 //        view.bringSubviewToFront(cameraButton)
 //        cameraButton.isHidden=true//fps<230ならfrontCameraと判定することとした
     }
   
     */
    func getPHAssetcollection(albumTitle:String)->PHAssetCollection{
        let requestOptions = PHImageRequestOptions()
        requestOptions.isSynchronous = true
        requestOptions.isNetworkAccessAllowed = false
        requestOptions.deliveryMode = .highQualityFormat //これでもicloud上のvideoを取ってしまう
        //アルバムをフェッチ
        let assetFetchOptions = PHFetchOptions()
        assetFetchOptions.predicate = NSPredicate(format: "title == %@", albumTitle)
        let assetCollections = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .smartAlbumVideos, options: assetFetchOptions)
        //ここはunwindから呼ばれる。アルバムはprepareで作っているはず？
        //        if (assetCollections.count > 0) {
        //同じ名前のアルバムは一つしかないはずなので最初のオブジェクトを使用
        return assetCollections.object(at:0)
    }
    @IBAction func eraseVideo(_ sender: Any) {
 //       videoAsset[videoCurrent]
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
//            var eraseAssetDate=assets[0].creationDate
//            var eraseAssetPngNumber=0
            for i in 0..<assets.count{
                let date_sub=assets[i].creationDate
                let date = formatter.string(from:date_sub!)
//                eraseAssetPngNumber=i+1
                if videoDate[videoCurrent].contains(date){
                    if !assets[i].canPerform(.delete) {
                        return
                    }
                    var delAssets=Array<PHAsset>()
                    delAssets.append(assets[i])
                    if assets[i+1].duration==0{//pngが無くて、videoが選択されてない事を確認
                        delAssets.append(assets[i+1])//pngはその次に入っているはず
                    }
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
//                    break
                }
            }
        }
        while dialogStatus == 0{//dialogから抜けるまでは0
            sleep(UInt32(0.2))
        }
        if dialogStatus == 1{//yesで抜けた時
//            removeFile(delFile: videoDate[videoCurrent] + "-gyro.csv")
            videoDate.remove(at: videoCurrent)
            videoURL.remove(at: videoCurrent)
            videoImg.remove(at: videoCurrent)
            videoDura.remove(at: videoCurrent)
            videoArrayCount -= 1
            videoCurrent -= 1
            showVideoIroiro(num: 0)
            if videoImg.count==0{
                playButton.isEnabled=false
            }
        }
    }
    func readGyroFromPngOfVideo(videoDate:String){
        gyroFiltered.removeAll()
        for _ in 0...240*60*6{
            gyroFiltered.append(0)
        }
        let requestOptions = PHImageRequestOptions()
        requestOptions.isSynchronous = true
        requestOptions.isNetworkAccessAllowed = false
        requestOptions.deliveryMode = .highQualityFormat //これでもicloud上のvideoを取ってしまう
        //アルバムをフェッチ
        let assetFetchOptions = PHFetchOptions()
        
        assetFetchOptions.predicate = NSPredicate(format: "title == %@", albumName)
        
        let assetCollections = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .smartAlbumVideos, options: assetFetchOptions)
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
            for i in 0..<assets.count{
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
                        
                    }else{
                      
                    }
                }
            }
        }
    }
   
    @IBAction func vhitGo(_ sender: Any) {
        if calcFlag == true || isVHIT == true{
            return
        }
        isVHIT=true
        setButtons(mode: true)
        dispWakus()
        showWakuImages()
        if eyeVeloXOrig.count>0 && videoCurrent != -1{
            vhitCurpoint=0
            drawOnewave(startcount: 0)
            calcDrawVHIT()
        }
        showBoxies(f:boxF)
    }
    
    @IBAction func vogGo(_ sender: Any) {
        rectType=0
        if calcFlag == true || isVHIT == false{
            return
        }
        isVHIT = false
        setButtons(mode: true)
        dispWakus()
        showWakuImages()
        if eyeVeloXOrig.count>0  && videoCurrent != -1{
            vogCurpoint=0
            drawVOG2endPt(end: 0)
            drawVogtext()
        }
        showBoxies(f: boxF)
    }

    @IBAction func backVideo(_ sender: Any) {
        if vhitLineView?.isHidden == false{
            return
        }
        startFrame=0
        showVideoIroiro(num: -1)
    }
   
    func showVideoIroiro(num:Int){//videosCurrentを移動して、諸々表示
        if videoDura.count == 0{
            slowImage.image=UIImage(named:"vhittop")
            return
        }else{
            slowImage.alpha=0
        }
        videoCurrent += num
        if videoCurrent>videoArrayCount-1{
            videoCurrent=0
        }else if videoCurrent<0{
                videoCurrent=videoArrayCount-1
        }
        playVideoURL(video: videoURL[videoCurrent])
        currentVideoDate.font=UIFont.monospacedDigitSystemFont(ofSize: 22, weight: .medium)
        currentVideoDate.text=videoDate[videoCurrent] + "(" + (videoCurrent+1).description + ")"
        let roundFps:Int = Int(round(getFPS(url: videoURL[videoCurrent])))
        videoFps.text=videoDura[videoCurrent] + "/" + String(format: "%dfps",roundFps)
        showWakuImages()
        setBacknext(f:true)
    }

    @IBAction func nextVideo(_ sender: Any) {//
           
        if vhitLineView?.isHidden == false{
            return
        }
        startFrame=0
        showVideoIroiro(num: 1)
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
        //左右には border 、上下には border/2 を広げる
        //この関数も上と同じようにroundした方がいいかもしれないが、
        //現状ではscreen座標のみで使っているのでfloatのまま。
        return CGRect(x:rect.origin.x - border,
                      y:rect.origin.y - border,
                      width:rect.size.width + border * 2,
                      height:rect.size.height + border * 2)
    }
    func expandRectWithBorder(rect:CGRect, border:CGFloat) -> CGRect {
        //左右には border 、上下には border/2 を広げる
        //この関数も上と同じようにroundした方がいいかもしれないが、
        //現状ではscreen座標のみで使っているのでfloatのまま。
        return CGRect(x:rect.origin.x - border,
                      y:rect.origin.y - border / 4,
                      width:rect.size.width + border * 2,
                      height:rect.size.height + border / 2)
    }
    func expandRectError(rect:CGRect, border:CGFloat) -> CGRect {
        //左右には border 、上下には border/2 を広げる
        //この関数も上と同じようにroundした方がいいかもしれないが、
        //現状ではscreen座標のみで使っているのでfloatのまま。
        return CGRect(x:rect.origin.x - border,
                      y:rect.origin.y - border ,
                      width:rect.size.width + border * 2,
                      height:rect.size.height + border * 2)
    }
    
    var kalVs:[[CGFloat]]=[[0.0001,0.001,0,1,2],[0.0001,0.001,3,4,5],[0.0001,0.001,6,7,8],[0.0001,0.001,10,11,12],[0.0001,0.001,13,14,15],[0.0001,0.001,16,17,18],[0.0001,0.001,19,20,21]]
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
    
    func startTimer() {
        if timer?.isValid == true {
            timer.invalidate()
        }else{
            lastArraycount=0
            if isVHIT == true{
                timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.update_vHIT), userInfo: nil, repeats: true)
            }else{
                timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.update_vog), userInfo: nil, repeats: true)
            }
        }
    }
    func showBoxies(f:Bool){
        if f==true && isVHIT==false{//vog wave
            boxF=true
            vogBoxView?.isHidden = false
            vogLineView?.isHidden = false
            wave3View?.isHidden=false
            vhitBoxView?.isHidden = true
            vhitLineView?.isHidden = true
            gyroBoxView?.isHidden = true
            gyroLineView?.isHidden = true
            setBacknext(f: false)
            eraseButton.isHidden=true
            //       playButton.isEnabled=false
        }else if f==true && isVHIT==true{//vhit wave
            boxF=true
            vogBoxView?.isHidden = true
            vogLineView?.isHidden = true
            wave3View?.isHidden=true
            vhitBoxView?.isHidden = false
            vhitLineView?.isHidden = false
            gyroBoxView?.isHidden = false
            gyroLineView?.isHidden = false
            setBacknext(f: false)
            eraseButton.isHidden=true
            //         playButton.isEnabled=false
        }else{//no wave
            boxF=false
            vogBoxView?.isHidden = true
            vogLineView?.isHidden = true
            wave3View?.isHidden=true
            vhitBoxView?.isHidden = true
            vhitLineView?.isHidden = true
            gyroBoxView?.isHidden = true
            gyroLineView?.isHidden = true
            setBacknext(f: true)
            //         playButton.isEnabled=true
            if videoImg.count != 0{
                eraseButton.isHidden=false
            }else{
                eraseButton.isHidden=true
            }
//            eraseButton.isHidden=true//とりあえず
        }
    }
    @IBAction func showWave(_ sender: Any) {//saveresult record-unwind の２箇所
        if calcFlag == true{
            return
        }
        if vhitBoxView?.isHidden==false || vogBoxView?.isHidden==false{
            showBoxies(f: false)
            //    playButton.isEnabled = true
        }else{
            showBoxies(f: true)
            //  playButton.isEnabled = false
        }
    }
    func setBacknext(f:Bool){//back and next button
        nextButton.isHidden = !f
        backButton.isHidden = !f
        if videoURL.count < 2{
            nextButton.isHidden = true
            backButton.isHidden = true
        }
    }
    @IBAction func stopCalc(_ sender: Any) {
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
            playButton.isEnabled = true
//            faceButton.isEnabled = true
//            eyeButton.isEnabled = true
            vogButton.isEnabled = true
            vhitButton.isEnabled = true
            cameraButton.isEnabled = true
            if isVHIT==true{
                vhitButton.backgroundColor=UIColor.blue
                vogButton.backgroundColor=UIColor.darkGray
            }else{
                vhitButton.backgroundColor=UIColor.darkGray
                 vogButton.backgroundColor=UIColor.blue
            }
            cameraButton.backgroundColor=UIColor.orange
//            eyeButton.backgroundColor=UIColor.darkGray
//            faceButton.backgroundColor=UIColor.darkGray
        }else{
            calcButton.isHidden = true
            stopButton.isHidden = false
            stopButton.isEnabled = false
            listButton.isEnabled = false
            paraButton.isEnabled = false
            saveButton.isEnabled = false
            waveButton.isEnabled = false
            helpButton.isEnabled = false
            playButton.isEnabled = false
//            faceButton.isEnabled = false
//            eyeButton.isEnabled = false
            vogButton.isEnabled = false
            vhitButton.isEnabled = false
            cameraButton.isEnabled = false
            vhitButton.backgroundColor=UIColor.gray
            cameraButton.backgroundColor=UIColor.gray
            vogButton.backgroundColor=UIColor.gray
            if isVHIT==true{
                vhitButton.backgroundColor=UIColor.systemBlue
            }else{
                vogButton.backgroundColor=UIColor.systemBlue
            }
            
//            eyeButton.backgroundColor=UIColor.gray
//            faceButton.backgroundColor=UIColor.gray
        }
    }
    @IBAction func vHITcalc(_ sender: Any) {
        if videoImg.count==0{
            return
        }
        setUserDefaults()
        if nonsavedFlag == true && (waveTuple.count > 0 || eyePosXFiltered.count > 0){
            setButtons(mode: false)
            var alert = UIAlertController(
                title: "You are erasing vHIT Data.",
                message: "OK ?",
                preferredStyle: .alert)
            if isVHIT==false{
                alert = UIAlertController(
                    title: "You are erasing VOG Data.",
                    message: "OK ?",
                    preferredStyle: .alert)
            }
            // アラートにボタンをつける
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
                self.setButtons(mode: false)
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
            setButtons(mode: false)
            vHITcalc()
        }
        //２：直ぐここを通る
    }
    
    func moveGyroData(){//gyroDeltaとstartFrameをずらして

        gyroMoved.removeAll()
        var sn=startFrame
        let fps=getFPS(url: videoURL[videoCurrent])
        if fps<200{
            sn=startFrame*2
        }
        sn -= videoGyroZure//初起動時に機種を判定（適当）して設定。設定ページで変更可能。
        if gyroFiltered.count>10{
            for i in sn..<gyroFiltered.count{
                if i>=0{
                    gyroMoved.append(gyroFiltered[i])
                }else{
                    gyroMoved.append(0)
                }
            }
        }
    }
    
    func vHITcalc(){
        var cvError:Int = 0
        calcFlag = true
        faceVeloOrig.removeAll()
        faceVeloFiltered.removeAll()
        eyePosXOrig.removeAll()
        eyePosXFiltered.removeAll()
        eyeVeloXOrig.removeAll()
        eyeVeloXFiltered.removeAll()
        eyePosYOrig.removeAll()
        eyePosYFiltered.removeAll()
        eyeVeloYOrig.removeAll()
        eyeVeloYFiltered.removeAll()
        gyroMoved.removeAll()
        KalmanInit()
        showBoxies(f: true)
        vogImage = makeVOGimgWakulines(width:mailWidth*18,height:mailHeight)//枠だけ
        //vHITlinewViewだけは消しておく。その他波は１秒後には消えるので、そのまま。
        if vhitLineView != nil{
            vhitLineView?.removeFromSuperview()
        }
        //videoの次のpngからgyroデータを得る。なければ５分間の０のgyroデータを戻す。
        readGyroFromPngOfVideo(videoDate: videoDate[videoCurrent])
        //        if pngImg.count>videoCurrent{
        //            readGyroFromPng(img: pngImg[videoCurrent])
        //        }else{
        //            for _ in 0...240*60*5+10{
        //                gyroFiltered.append(0)
        //            }
        //        }
        //        readGyro(gyroPath: videoDate[videoCurrent] + "-gyro.csv")//gyroDataを読み込む
        moveGyroData()//gyroDeltastartframe分をズラして
        var vHITcnt:Int = 0
        startTime=CFAbsoluteTimeGetCurrent()
        timercnt = 0
        
        openCVstopFlag = false
        UIApplication.shared.isIdleTimerDisabled = true
        let eyeborder:CGFloat = CGFloat(eyeBorder)
        //        print("eyeborder:",eyeBorder,faceF)
        startTimer()//resizerectのチェックの時はここをコメントアウト*********************
        //       let fileURL = URL(fileURLWithPath: vidPath[vidCurrent])
        
        //         let fileURL = getfileURL(path: vidPath[vidCurrent])
        let options = [CIDetectorAccuracy: CIDetectorAccuracyHigh]
        let avAsset = AVURLAsset(url: videoURL[videoCurrent], options: options)
        calcDate = currentVideoDate.text!
        //        print("calcdate:",calcDate)
        var fpsIs120:Bool=false
        if getFPS(url: videoURL[videoCurrent])<200.0{
            fpsIs120=true
        }
        var reader: AVAssetReader! = nil
        do {
            reader = try AVAssetReader(asset: avAsset)
        } catch {
            #if DEBUG
            print("could not initialize reader.")
            #endif
            return
        }
        guard let videoTrack = avAsset.tracks(withMediaType: AVMediaType.video).last else {
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
        
        // UnsafeとMutableはまあ調べてもらうとして、eX, eY等は<Int32>が一つ格納されている場所へのポインタとして宣言される。
        let eX = UnsafeMutablePointer<Int32>.allocate(capacity: 1)
        let eY = UnsafeMutablePointer<Int32>.allocate(capacity: 1)
        let fX = UnsafeMutablePointer<Int32>.allocate(capacity: 1)
        let fY = UnsafeMutablePointer<Int32>.allocate(capacity: 1)
        var eyeCGImage:CGImage!
        let eyeUIImage:UIImage!
        var eyeWithBorderCGImage:CGImage!
        var eyeWithBorderUIImage:UIImage!
        var faceCGImage:CGImage!
        var faceUIImage:UIImage!
        var faceWithBorderCGImage:CGImage!
        var faceWithBorderUIImage:UIImage!
        
        let eyeRectOnScreen=CGRect(x:wakuE.origin.x, y:wakuE.origin.y, width: wakuE.width, height: wakuE.height)
        let eyeWithBorderRectOnScreen = expandRectWithBorderWide(rect: eyeRectOnScreen, border: eyeborder)
        
        let faceRectOnScreen=CGRect(x:wakuF.origin.x,y:wakuF.origin.y,width: wakuF.width,height: wakuF.height)
        let faceWithBorderRectOnScreen = expandRectWithBorderWide(rect: faceRectOnScreen, border: eyeborder)
        
        let context:CIContext = CIContext.init(options: nil)
        //            let up = UIImage.Orientation.right
        var sample:CMSampleBuffer!
        stopButton.isEnabled = true
        sample = readerOutput.copyNextSampleBuffer()
        
        let pixelBuffer:CVPixelBuffer = CMSampleBufferGetImageBuffer(sample!)!
        let ciImage:CIImage = CIImage(cvPixelBuffer: pixelBuffer).oriented(CGImagePropertyOrientation.right)
        let videoWidth=ciImage.extent.size.width
        let videoHeight=ciImage.extent.size.height
        let eyeRect = resizeR2(eyeRectOnScreen, viewRect:view.frame, image:ciImage)
        var eyeWithBorderRect = resizeR2(eyeWithBorderRectOnScreen, viewRect:view.frame, image:ciImage)
        
        let maxWidthWithBorder=videoWidth-eyeWithBorderRect.width-5
        let maxHeightWithBorder=videoHeight-eyeWithBorderRect.height-5
        let faceRect = resizeR2(faceRectOnScreen, viewRect: view.frame, image:ciImage)
        var faceWithBorderRect = resizeR2(faceWithBorderRectOnScreen, viewRect:view.frame, image:ciImage)
        
        let eyebR0 = eyeWithBorderRect
        let facbR0 = faceWithBorderRect
        
        eyeCGImage = context.createCGImage(ciImage, from: eyeRect)!
        
        eyeUIImage = UIImage.init(cgImage: eyeCGImage)
        faceCGImage = context.createCGImage(ciImage, from: faceRect)!
        
        faceUIImage = UIImage.init(cgImage:faceCGImage)
        
        let borderRectDiffer=faceWithBorderRect.width-faceRect.width
        
        let osEyeX:CGFloat = (eyeWithBorderRect.size.width - eyeRect.size.width) / 2.0//上下方向
        let osEyeY:CGFloat = (eyeWithBorderRect.size.height - eyeRect.size.height) / 2.0//左右方向
        let osFacX:CGFloat = (faceWithBorderRect.size.width - faceRect.size.width) / 2.0//上下方向
        let osFacY:CGFloat = (faceWithBorderRect.size.height - faceRect.size.height) / 2.0//左右方向
        
        var maxEyeV:Double = 0
        var maxFaceV:Double = 0
        while reader.status != AVAssetReader.Status.reading {
            sleep(UInt32(0.1))
        }
        DispatchQueue.global(qos: .default).async {//resizerectのチェックの時はここをコメントアウト下がいいかな？
            while let sample = readerOutput.copyNextSampleBuffer(), self.calcFlag != false {
                var ex:CGFloat = 0
                var ey:CGFloat = 0
                var eyePosX:CGFloat = 0
                var eyePosY:CGFloat = 0
                var fx:CGFloat = 0
                var fy:CGFloat = 0
                
                //for test display
                #if DEBUG
                var x:CGFloat = 0.0
                let y:CGFloat = 500.0
                #endif
                autoreleasepool{
                    let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sample)!//27sec:10sec
                    cvError -= 1
                    if cvError < 0{
                        //orientation.upとrightは所要時間同じ
                        let ciImage: CIImage =
                            CIImage(cvPixelBuffer: pixelBuffer).oriented(CGImagePropertyOrientation.right)
                        eyeWithBorderCGImage = context.createCGImage(ciImage, from: eyeWithBorderRect)!
                        eyeWithBorderUIImage = UIImage.init(cgImage: eyeWithBorderCGImage)
                        
                        #if DEBUG
                        //                        画面表示はmain threadで行う
                        
                        let eye0CGImage = context.createCGImage(ciImage, from:eyebR0)!
                        //                        let eye0CGImage = context.createCGImage(ciImage, from:eyeErrorRect)!
                        let eye0UIImage = UIImage.init(cgImage: eye0CGImage)
                        
                        DispatchQueue.main.async {
                            self.wakuEye.frame=CGRect(x:x,y:y,width:eyeRect.size.width*2,height:eyeRect.size.height*2)
                            self.wakuEye.image=eyeUIImage
                            x += eyeRect.size.width*2
                            
                            self.wakuEyeb.frame=CGRect(x:x,y:y,width:eyeWithBorderRect.size.width*2,height:eyeWithBorderRect.size.height*2)
                            self.wakuEyeb.image=eyeWithBorderUIImage
                            x += eyeWithBorderRect.size.width*2
                            if self.faceF==0 || self.isVHIT==false{
                                self.wakuFacb.frame=CGRect(x:x,y:y,width:eyebR0.size.width*2,height:eyebR0.size.height*2)
                                self.wakuFacb.image=eye0UIImage
                            }
                        }
                        #endif
                        maxEyeV=self.openCV.matching(eyeWithBorderUIImage,
                                                     narrow: eyeUIImage,
                                                     x: eX,
                                                     y: eY)
                        //                        while self.openCVstopFlag == true{//vHITeyeを使用中なら待つ
                        //                            usleep(1)
                        //                        }
                        if maxEyeV < 0.7{//errorもここに来るぞ!!　ey=0で戻ってくる
                            cvError=5//10/240secはcontinue
                            eyeWithBorderRect=eyebR0//初期位置に戻す
                            faceWithBorderRect=facbR0
                        }else{//検出できた時
                            
                            
                            //eXはポインタなので、".pointee"でそのポインタの内容が取り出せる。Cでいうところの"*"
                            //上で宣言しているとおりInt32が返ってくるのでCGFloatに変換して代入
                            ex = CGFloat(eX.pointee) - osEyeX
                            ey = borderRectDiffer - CGFloat(eY.pointee) - osEyeY
                            //                            ey = eyeWithBorderRect.height - CGFloat(eY.pointee) - eyeRect.height - osEyeY
                            eyeWithBorderRect.origin.x += ex
                            eyeWithBorderRect.origin.y += ey
                            eyePosX = eyeWithBorderRect.origin.x - eyebR0.origin.x + ex
                            eyePosY = eyeWithBorderRect.origin.y - eyebR0.origin.y + ey
                            
                            if self.faceF==1 && self.isVHIT==true{
                                faceWithBorderCGImage = context.createCGImage(ciImage, from:faceWithBorderRect)!
                                faceWithBorderUIImage = UIImage.init(cgImage: faceWithBorderCGImage)
                                #if DEBUG
                                DispatchQueue.main.async {
                                    if self.faceF==1&&self.isVHIT==true{
                                        self.wakuFac.frame=CGRect(x:x,y:y,width:faceRect.size.width*2,height:faceRect.size.height*2)
                                        self.wakuFac.image=faceUIImage
                                        x += faceRect.size.width*2
                                        self.wakuFacb.frame=CGRect(x:x,y:y,width:faceWithBorderRect.size.width*2,height:faceWithBorderRect.size.height*2)
                                        self.wakuFacb.image=faceWithBorderUIImage
                                    }
                                }
                                #endif
                                
                                maxFaceV=self.openCV.matching(faceWithBorderUIImage, narrow: faceUIImage, x: fX, y: fY)
                                //                                while self.openCVstopFlag == true{//vHITeyeを使用中なら待つ
                                //                                    usleep(1)
                                //                                }
                                if maxFaceV<0.7{
                                    cvError=5
                                    faceWithBorderRect=facbR0
                                    eyeWithBorderRect=eyebR0
                                }else{
                                    fx = CGFloat(fX.pointee) - osFacX
                                    fy = -CGFloat(fY.pointee) + osFacY
                                    faceWithBorderRect.origin.x += fx
                                    faceWithBorderRect.origin.y += fy
                                }
                            }
                        }
                        context.clearCaches()
                    }
                    
                    if self.faceF==1{
                        self.faceVeloOrig.append(fx)
                        self.faceVeloFiltered.append(-12.0*self.Kalman(value: fx,num: 0))
                    }else{
                        self.faceVeloOrig.append(0)
                        self.faceVeloFiltered.append(0)
                    }
                    // eyePos, ey, fyをそれぞれ配列に追加
                    // vogをkalmanにかけ配列に追加
                    self.eyePosXOrig.append(eyePosX)
                    self.eyePosXFiltered.append( -1.0*self.Kalman(value:eyePosX,num:1))
                    self.eyePosYOrig.append(eyePosY)
                    self.eyePosYFiltered.append( -1.0*self.Kalman(value:eyePosY,num:5))
                    
                    self.eyeVeloXOrig.append(ex)
                    let eye5x = -12.0*self.Kalman(value: ex,num:2)//そのままではずれる
                    self.eyeVeloXFiltered.append(eye5x-self.faceVeloFiltered.last!)
                    
                    self.eyeVeloYOrig.append(ey)
                    let eye5y = -12.0*self.Kalman(value: ey,num:6)//そのままではずれる
                    self.eyeVeloYFiltered.append(eye5y-self.faceVeloFiltered.last!)
                    
                    vHITcnt += 1
                    while reader.status != AVAssetReader.Status.reading {
                        sleep(UInt32(0.1))
                    }
                    self.fps120(is120: fpsIs120)
                    //eyeのみでチェックしているが。。。。
                    if eyeWithBorderRect.origin.x < 5 ||
                        eyeWithBorderRect.origin.x > maxWidthWithBorder ||
                        eyeWithBorderRect.origin.y < 5 ||
                        eyeWithBorderRect.origin.y > maxHeightWithBorder
                    {
                        self.calcFlag=false//quit
                    }
                }
                //マッチングデバッグ用スリープ、デバッグが終わったら削除
                #if DEBUG
                usleep(200)
                #endif
            }
            //            print("time:",CFAbsoluteTimeGetCurrent()-st)
            self.calcFlag = false
            if self.waveTuple.count > 0{
                self.nonsavedFlag = true
            }
        }
    }
    //    func average5(
    func fps120(is120:Bool){
        if is120==true{
            self.faceVeloOrig.append(self.faceVeloFiltered.last!)
            self.faceVeloFiltered.append(self.faceVeloFiltered.last!)
            self.eyePosXOrig.append(self.eyePosXOrig.last!)
            self.eyePosXFiltered.append(self.eyePosXFiltered.last!)
            self.eyeVeloXOrig.append(self.eyeVeloXOrig.last!)
            self.eyeVeloXFiltered.append(self.eyeVeloXFiltered.last!)
            self.eyePosYOrig.append(self.eyePosYOrig.last!)
            self.eyePosYFiltered.append(self.eyePosYFiltered.last!)
            self.eyeVeloYOrig.append(self.eyeVeloYOrig.last!)
            self.eyeVeloYFiltered.append(self.eyeVeloYFiltered.last!)
        }
    }
    func showWakuImages(){//結果が表示されていない時、画面上部1/4をタップするとWaku表示
        if videoDura.count<1 {
            return
        }
        if faceF==1 && isVHIT==true{
            wakuShowFace_image.isHidden=false
        }else{
            wakuShowFace_image.isHidden=true
        }
        let options = [CIDetectorAccuracy: CIDetectorAccuracyHigh]
        let avAsset = AVURLAsset(url: videoURL[videoCurrent], options: options)
        calcDate = currentVideoDate.text!
        var reader: AVAssetReader! = nil
        do {
            reader = try AVAssetReader(asset: avAsset)
        } catch {
            #if DEBUG
            print("could not initialize reader.")
            #endif
            return
        }
        guard let videoTrack = avAsset.tracks(withMediaType: AVMediaType.video).last else {
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
        var CGfac:CGImage!//face
        var UIfac:UIImage!
        let context:CIContext = CIContext.init(options: nil)
        let orientation = UIImage.Orientation.up//right
        var sample:CMSampleBuffer!
        sample = readerOutput.copyNextSampleBuffer()
        let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sample!)!
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer).oriented(CGImagePropertyOrientation.right)
        let eyeR = resizeR2(wakuE, viewRect:view.frame,image:ciImage)
        let facR = resizeR2(wakuF, viewRect:view.frame, image: ciImage)
        CGfac = context.createCGImage(ciImage, from: facR)!
        UIfac = UIImage.init(cgImage: CGfac, scale:1.0, orientation:orientation)
        CGeye = context.createCGImage(ciImage, from: eyeR)!
        UIeye = UIImage.init(cgImage: CGeye, scale:1.0, orientation:orientation)
        let wakuY=videoFps.frame.origin.y+videoFps.frame.size.height+5
        wakuShowEye_image.frame=CGRect(x:5,y:wakuY,width: eyeR.size.width*5,height: eyeR.size.height*5)
        wakuShowEye_image.layer.borderWidth = 1.0
        wakuShowEye_image.backgroundColor = UIColor.clear
        wakuShowEye_image.layer.cornerRadius = 3
        wakuShowFace_image.frame=CGRect(x:5,y:wakuY+eyeR.size.height*5.1,width: eyeR.size.width*5,height: eyeR.size.height*5)
        wakuShowFace_image.layer.borderWidth = 1.0
        wakuShowFace_image.backgroundColor = UIColor.clear
        wakuShowFace_image.layer.cornerRadius = 3
        wakuShowEye_image.image=UIeye
        wakuShowFace_image.image=UIfac
        if rectType == 0{
            wakuShowEye_image.layer.borderColor = UIColor.green.cgColor
            wakuShowFace_image.layer.borderColor = UIColor.gray.cgColor
        }else{
            wakuShowEye_image.layer.borderColor = UIColor.gray.cgColor
            wakuShowFace_image.layer.borderColor = UIColor.green.cgColor
        }
    }

    func getframeImage(frameNumber:Int)->UIImage{//結果が表示されていない時、画面上部1/4をタップするとWaku表示
//        let fileURL = getfileURL(path: vidPath[vidCurrent])
        let options = [CIDetectorAccuracy: CIDetectorAccuracyHigh]
        let avAsset = AVURLAsset(url: videoURL[videoCurrent], options: options)
        var reader: AVAssetReader! = nil
        do {
            reader = try AVAssetReader(asset: avAsset)
        } catch {
            #if DEBUG
            print("could not initialize reader.")
            #endif
            return UIImage(named:"led")!
        }
        guard let videoTrack = avAsset.tracks(withMediaType: AVMediaType.video).last else {
            #if DEBUG
            print("could not retrieve the video track.")
            #endif
            return UIImage(named:"led")!
        }
        
        let readerOutputSettings: [String: Any] = [kCVPixelBufferPixelFormatTypeKey as String : Int(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)]
        let readerOutput = AVAssetReaderTrackOutput(track: videoTrack, outputSettings: readerOutputSettings)
        
        reader.add(readerOutput)
        let frameRate = videoTrack.nominalFrameRate
        //let startframe=startPoints[vhitVideocurrent]
        let startTime = CMTime(value: CMTimeValue(frameNumber), timescale: CMTimeScale(frameRate))
        let timeRange = CMTimeRange(start: startTime, end:CMTime.positiveInfinity)
        //print("time",timeRange)
        reader.timeRange = timeRange //読み込む範囲を`timeRange`で指定
        reader.startReading()
        let context:CIContext = CIContext.init(options: nil)
        let orientation = UIImage.Orientation.right
        var sample:CMSampleBuffer!
        sample = readerOutput.copyNextSampleBuffer()
        let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sample!)!
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let cgImage:CGImage = context.createCGImage(ciImage, from: ciImage.extent)!
        return UIImage.init(cgImage: cgImage, scale:1.0, orientation:orientation)
    }
    
    func printR(str:String,rct:CGRect){
        print("\(str)",String(format: "%.1f %.1f %.1f %.1f",rct.origin.x,rct.origin.y,rct.width,rct.height))
    }
    func printR(str:String,rct1:CGRect,rct2:CGRect){
        print("\(str)",String(format: "%.0f,%.0f %.0f,%.0f",rct1.origin.x,rct1.origin.y,rct2.origin.x,rct2.origin.y))
    }
    func printR(str:String,cnt:Int,rct1:CGRect,rct2:CGRect){
        print("\(str)",String(format: "%d-%.0f,%.0f %.0f,%.0f",cnt,rct1.origin.x,rct1.origin.y,rct2.origin.x,rct2.origin.y))
    }
    func printR(str:String,cnt:Int,max:Double,rct1:CGRect,rct2:CGRect){
        print("\(str)",String(format: "%d %.2f-%.0f,%.0f %.0f,%.0f",cnt,max,rct1.origin.x,rct1.origin.y,rct2.origin.x,rct2.origin.y))
    }
    override func viewDidAppear(_ animated: Bool) {
        dispWakus()
        setButtons_first()
        showWakuImages()
//        eraseButton.isHidden=true//とりあえず
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
       // dispWakuImages()ここでは効かない
        //        dispWakus()ここでは効かない
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        if timer?.isValid == true {
            timer.invalidate()
        }
        //       print("willdisappear")
    }
    
    func makeBox(width w:CGFloat,height h:CGFloat) -> UIImage{//vHITとVOG同じ
        let size = CGSize(width:w, height:h)
        UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
        let context = UIGraphicsGetCurrentContext()
        let drawRect = CGRect(x:0, y:0, width:w, height:h)
        let drawPath = UIBezierPath(rect:drawRect)
        context?.setFillColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        drawPath.fill()
        context?.setStrokeColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
        drawPath.stroke()
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }
    
    func makeBoxies(){
        if gyroBoxView == nil {//vHITboxView vogboxView
            let vw=view.bounds.width
            let vh=view.bounds.height
            
            vhitBoxHeight=vw*2/5
            vhitBoxYmin=160*vh/568-vogBoxHeight/2
            vhitBoxYcenter=160*vh/568
            var boxImage = makeBox(width: vw, height: vhitBoxHeight)//128
            vhitBoxView = UIImageView(image: boxImage)
            vhitBoxView?.center = CGPoint(x:vw/2,y:vhitBoxYcenter)//vh/4)//160)// view.center
            view.addSubview(vhitBoxView!)
            
            gyroBoxHeight=180*vw/320
            gyroBoxYmin=340*vh/568-vogBoxHeight/2
            gyroBoxYcenter=340*vh/568
            boxImage = makeBox(width: vw, height: gyroBoxHeight)
            gyroBoxView = UIImageView(image: boxImage)
            gyroBoxView?.center = CGPoint(x:vw/2,y:gyroBoxYcenter)//340)
            view.addSubview(gyroBoxView!)
            
            vogBoxHeight=vw*16/24
            vogBoxYmin=vh/2-vogBoxHeight/2
            vogBoxYcenter=vh/2
            boxImage = makeBox(width: vw, height:vogBoxHeight)
            vogBoxView = UIImageView(image: boxImage)
            
            vogBoxView?.center = CGPoint(x:vw/2,y:vogBoxYcenter)
            view.addSubview(vogBoxView!)
        }
    }
    func drawVOG2endPt(end:Int){//endまでを画面に表示
        if vogLineView != nil{
            vogLineView?.removeFromSuperview()
        }
        if wave3View != nil{
            wave3View?.removeFromSuperview()
        }
        let ww=view.bounds.width
        let drawImage = vogImage!.resize(size: CGSize(width:ww*18, height:vogBoxHeight))
        // 画面に表示する
        wave3View = UIImageView(image: drawImage)
        view.addSubview(wave3View!)
        let k=CGFloat(Int(view.bounds.width)/Int(mailWidth))
        let k1:CGFloat=view.bounds.width/mailWidth
        print("ratio:",ww,mailWidth,k,k1)
        var endPos = CGFloat(end) - 2400
        if CGFloat(end) < 2400{
            endPos=0
        }
        wave3View!.frame=CGRect(x:-endPos*ww/mailWidth,y:vogBoxYmin,width:view.bounds.width*18,height:vogBoxHeight)
     }

//    Int(view.bounds.width)/Int(mailWidth){
    func trimmingImage(_ image: UIImage, trimmingArea: CGRect) -> UIImage {
        let imgRef = image.cgImage?.cropping(to: trimmingArea)
        let trimImage = UIImage(cgImage: imgRef!, scale: image.scale, orientation: image.imageOrientation)
        return trimImage
    }
    func drawVogall(){//すべてのvogを画面に表示
        if vogLineView != nil{
            vogLineView?.removeFromSuperview()
        }
        if wave3View != nil{
            wave3View?.removeFromSuperview()
        }
        let ww=view.bounds.width
        vogImage=makeVOGimgWakulines(width: mailWidth*18,height: mailHeight)
//        vogImage = makeVOGImage(startImg:vogImage!,width:0, height:0, start:0, end: 2400)
        vogImage = makeVOGImage(startImg:vogImage!,width:0, height:0, start:0, end:eyePosXOrig.count)
        let drawImage = vogImage!.resize(size: CGSize(width:ww*18, height:vogBoxHeight))
        // 画面に表示する
        wave3View = UIImageView(image: drawImage)
        view.addSubview(wave3View!)
        wave3View!.frame=CGRect(x:0,y:vogBoxYmin,width:view.bounds.width*18,height:vogBoxHeight)
        vogImage = makeVOGImage(startImg:vogImage!,width:0, height:0, start:2400, end:eyePosXOrig.count)
    }

    func drawText(width w:CGFloat,height h:CGFloat) -> UIImage {
        let size = CGSize(width:w, height:h)
        // イメージ処理の開始
        UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
        // パスの初期化
        let drawPath = UIBezierPath()
        let timetxt:String = String(format: "%05df (%.1fs/%@) : %ds",eyeVeloXOrig.count,CGFloat(eyeVeloXOrig.count)/240.0,videoDura[videoCurrent],timercnt+1)
        //print(timetxt)
        timetxt.draw(at: CGPoint(x: 20, y: 5), withAttributes: [
            NSAttributedString.Key.foregroundColor : UIColor.black,
            NSAttributedString.Key.font : UIFont.monospacedDigitSystemFont(ofSize: 70, weight: UIFont.Weight.regular)])
        
        
        let str1 = calcDate.components(separatedBy: ":")
        let str2 = "ID:" + String(format: "%08d", idNumber) + "  " + str1[0] + ":" + str1[1]
        let str3 = "VOG96da"
        str2.draw(at: CGPoint(x: 20, y: h-100), withAttributes: [
            NSAttributedString.Key.foregroundColor : UIColor.black,
            NSAttributedString.Key.font : UIFont.monospacedDigitSystemFont(ofSize: 70, weight: UIFont.Weight.regular)])
        str3.draw(at: CGPoint(x: w-330, y: h-100), withAttributes: [
            NSAttributedString.Key.foregroundColor : UIColor.black,
            NSAttributedString.Key.font : UIFont.monospacedDigitSystemFont(ofSize: 70, weight: UIFont.Weight.regular)])
        drawPath.stroke()
        // イメージコンテキストからUIImageを作る
        let image = UIGraphicsGetImageFromCurrentImageContext()
        // イメージ処理の終了
        UIGraphicsEndImageContext()
        return image!
    }
   
      func makeVOGImage(startImg:UIImage,width:CGFloat,height:CGFloat,start:Int,end:Int) ->UIImage{
        // Create a context of the starting image size and set it as the current one
        var startN=start
        if start<0{
            startN=0
        }
        var endN=end
        if end>eyePosXOrig.count-1{
            endN=eyePosXOrig.count-1
        }
        if width==0{
            UIGraphicsBeginImageContext(startImg.size)
            startImg.draw(at: CGPoint.zero)
        }else{
            let size=CGSize(width:width,height:height)
            UIGraphicsBeginImageContextWithOptions(size,false, 1.0)
        }
        let drawPath = UIGraphicsGetCurrentContext()!
        // Draw a red line
        let w=mailWidth
        let h=mailHeight
        
//        let wid:CGFloat=w/90.0
//        for i in 0..<90 {
//            let xp = CGFloat(i)*wid
//            drawPath.move(to: CGPoint(x:xp,y:0))
//            drawPath.addLine(to: CGPoint(x:xp,y:h-120))
//        }
//        drawPath.move(to:CGPoint(x:0,y:0))
//        drawPath.addLine(to: CGPoint(x:w,y:0))
//        drawPath.move(to:CGPoint(x:0,y:h-120))
//        drawPath.addLine(to: CGPoint(x:w,y:h-120))
//        //UIColor.blue.setStroke()
////        drawPath.lineWidth = 2.0//1.0
//        drawPath.strokePath()
////        drawPath.removeAllPoints()
//
        
        
        
        drawPath.setLineWidth(2.0)
        var pointListXpos = Array<CGPoint>()
        var pointListXvelo = Array<CGPoint>()
        var pointListYpos = Array<CGPoint>()
        var pointListYvelo = Array<CGPoint>()
//        let h=drawPath.height
//        let h=mailHeight
//        print("height:",h)
        let posR=CGFloat(posRatio)/20.0
        let veloR=CGFloat(veloRatio)/10.0
        let dx = 1// xの間隔
        for i in startN..<endN {
            let px = CGFloat(dx * i)
            let pyXpos = eyePosXFiltered[i] * posR + (h-240)/5 + 120
            let pyXvelo = eyeVeloXFiltered[i] * veloR + (h-240)*2/5 + 120
            let pyYpos = eyePosYFiltered[i] * posR + (h-240)*3/5 + 120
            let pyYvelo = eyeVeloYFiltered[i] * veloR + (h-240)*4/5 + 120
            let pntXpos = CGPoint(x: px, y: pyXpos)
            let pntXvelo = CGPoint(x: px, y: pyXvelo)
            let pntYpos = CGPoint(x: px, y: pyYpos)
            let pntYvelo = CGPoint(x: px, y: pyYvelo)
            pointListXpos.append(pntXpos)
            pointListXvelo.append(pntXvelo)
            pointListYpos.append(pntYpos)
            pointListYvelo.append(pntYvelo)
        }
        drawPath.move(to: pointListXpos[0])//move to start
        pointListXpos.removeFirst()//remove start point
        for pt in pointListXpos {//add points
            drawPath.addLine(to: pt)
        }
        drawPath.move(to: pointListXvelo[0])
        pointListXvelo.removeFirst()
        for pt in pointListXvelo {
            drawPath.addLine(to: pt)
        }
        drawPath.setStrokeColor(UIColor.black.cgColor)
        drawPath.strokePath()
        drawPath.move(to: pointListYpos[0])
        pointListYpos.removeFirst()
        for pt in pointListYpos {
            drawPath.addLine(to: pt)
        }
        drawPath.move(to: pointListYvelo[0])
        pointListYvelo.removeFirst()
        for pt in pointListYvelo {
            drawPath.addLine(to: pt)
        }
        drawPath.setStrokeColor(UIColor.red.cgColor)
        drawPath.strokePath()
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        // イメージ処理の終了
        UIGraphicsEndImageContext()
        return image!
    }
    
//           let dImage = drawText(width:mailWidth,height:mailHeight)
//    func drawResultVOG()
    func drawAllvogwaves(width w:CGFloat,height h:CGFloat) ->UIImage{
        //        let nx:Int=18//3min 180sec 目盛は10秒毎 18本
        let size = CGSize(width:w, height:h)
        // イメージ処理の開始
        UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
        // パスの初期化
        let drawPath = UIBezierPath()
        
        //let wI:Int = Int(w)//2400*18
        let wid:CGFloat=w/90.0
        for i in 0..<90 {
            let xp = CGFloat(i)*wid
            drawPath.move(to: CGPoint(x:xp,y:0))
            drawPath.addLine(to: CGPoint(x:xp,y:h-120))
        }
        drawPath.move(to:CGPoint(x:0,y:0))
        drawPath.addLine(to: CGPoint(x:w,y:0))
        drawPath.move(to:CGPoint(x:0,y:h-120))
        drawPath.addLine(to: CGPoint(x:w,y:h-120))
        //UIColor.blue.setStroke()
        drawPath.lineWidth = 2.0//1.0
        drawPath.stroke()
        drawPath.removeAllPoints()
        var pntListXpos = Array<CGPoint>()
        var pntListXvelo = Array<CGPoint>()
        var pntListYpos = Array<CGPoint>()
        var pntListYvelo = Array<CGPoint>()
        let dx = 1// xの間隔
        
        for i in 0..<Int(w) {
            if i < eyeVeloXOrig.count - 4{
                let px = CGFloat(dx * i)
                let pyXpos = eyePosXFiltered[i] * CGFloat(posRatio)/20.0 + (h-240)/5 + 120
                let pyXvelo = eyeVeloXFiltered[i] * CGFloat(veloRatio)/10.0 + (h-240)*2/5 + 120
                let pyYpos = eyePosYFiltered[i] * CGFloat(posRatio)/20.0 + (h-240)*3/5 + 120
                let pyYvelo = eyeVeloYFiltered[i] * CGFloat(veloRatio)/10.0 + (h-240)*4/5 + 120
                let pntXpos = CGPoint(x: px, y: pyXpos)
                let pntXvelo = CGPoint(x: px, y: pyXvelo)
                let pntYpos = CGPoint(x: px, y: pyYpos)
                let pntYvelo = CGPoint(x: px, y: pyYvelo)
                pntListYpos.append(pntYpos)
                pntListYvelo.append(pntYvelo)
                pntListXpos.append(pntXpos)
                pntListXvelo.append(pntXvelo)
            }
        }
        
        drawPath.move(to: pntListXpos[0])//move to start
        pntListXpos.removeFirst()//remove start point
        for pt in pntListXpos {//add points
            drawPath.addLine(to: pt)
        }
        
        drawPath.move(to: pntListXvelo[0])
        pntListXvelo.removeFirst()
        for pt in pntListXvelo {
            drawPath.addLine(to: pt)
        }
        drawPath.move(to: pntListYpos[0])
        pntListYpos.removeFirst()
        for pt in pntListYpos {
            drawPath.addLine(to: pt)
        }
        drawPath.move(to: pntListYvelo[0])
        pntListYvelo.removeFirst()
        for pt in pntListYvelo {
            drawPath.addLine(to: pt)
        }
        // 線の色
        UIColor.black.setStroke()
        // 線を描く
        drawPath.stroke()
        // イメージコンテキストからUIImageを作る
        let image = UIGraphicsGetImageFromCurrentImageContext()
        // イメージ処理の終了
        UIGraphicsEndImageContext()
        return image!
    }
    func drawVogwaves(num:Int, width w:CGFloat,height h:CGFloat) -> UIImage {
        let size = CGSize(width:w, height:h)
        // イメージ処理の開始
        UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
        // パスの初期化
        let drawPath = UIGraphicsGetCurrentContext()!
        

        let str1 = calcDate.components(separatedBy: ":")
        let str2 = "ID:" + String(format: "%08d", idNumber) + "  " + str1[0] + ":" + str1[1]
        let str3 = "VOG96da"
        
        str2.draw(at: CGPoint(x: 20, y: h-100), withAttributes: [
            NSAttributedString.Key.foregroundColor : UIColor.black,
            NSAttributedString.Key.font : UIFont.monospacedDigitSystemFont(ofSize: 70, weight: UIFont.Weight.regular)])
        str3.draw(at: CGPoint(x: w-330, y: h-100), withAttributes: [
            NSAttributedString.Key.foregroundColor : UIColor.black,
            NSAttributedString.Key.font : UIFont.monospacedDigitSystemFont(ofSize: 70, weight: UIFont.Weight.regular)])
        
//        UIColor.black.setStroke()
        drawPath.setLineWidth(2.0)
//        drawPath.lineWidth = 2.0//1.0
        let wI:Int = Int(w)
        var startp=num-240*10
        if num<240*10{
            startp=0
        }
        for i in 0...5 {
            let xp:CGFloat = CGFloat(i*wI/5-startp%(wI/5))
            drawPath.move(to: CGPoint(x:xp,y:0))
            drawPath.addLine(to: CGPoint(x:xp,y:h-120))
        }
        drawPath.move(to:CGPoint(x:0,y:0))
        drawPath.addLine(to: CGPoint(x:w,y:0))
        drawPath.move(to:CGPoint(x:0,y:h-120))
        drawPath.addLine(to: CGPoint(x:w,y:h-120))
        
//        drawPath.move(to: pointListXpos[0])//move to start
//        pointListXpos.removeFirst()//remove start point

        drawPath.setStrokeColor(UIColor.red.cgColor)
        drawPath.strokePath()
//        drawPath.stroke()
//        drawPath.removeAllPoints()
        var pointListXpos = Array<CGPoint>()
        var pointListXvelo = Array<CGPoint>()
        var pointListYpos = Array<CGPoint>()
        var pointListYvelo = Array<CGPoint>()
 
        let eyeVeloFilteredCnt=eyeVeloXFiltered.count
        let dx = 1// xの間隔
        //        print("vogPos5,vHITEye5,vHITeye",vogPos5.count,vHITEye5.count,vHITEye.count)
        
        for n in 1..<wI {
            let start = startp + n
            if start < eyeVeloFilteredCnt {//-20としてみたがエラー。関係なさそう。
                let px = CGFloat(dx * n)
                let pyXpos = eyePosXFiltered[start] * CGFloat(posRatio)/20.0 + (h-240)/5 + 120
                let pyXvelo = eyeVeloXFiltered[start] * CGFloat(veloRatio)/10.0 + (h-240)*2/5 + 120
                let pyYpos = eyePosYFiltered[start] * CGFloat(posRatio)/20.0 + (h-240)*3/5 + 120
                let pyYvelo = eyeVeloYFiltered[start] * CGFloat(veloRatio)/10.0 + (h-240)*4/5 + 120
                let pntXpos = CGPoint(x: px, y: pyXpos)
                let pntXvelo = CGPoint(x: px, y: pyXvelo)
                let pntYpos = CGPoint(x: px, y: pyYpos)
                let pntYvelo = CGPoint(x: px, y: pyYvelo)
                pointListYpos.append(pntYpos)
                pointListYvelo.append(pntYvelo)
                pointListXpos.append(pntXpos)
                pointListXvelo.append(pntXvelo)
            }
        }
    
        drawPath.move(to: pointListXpos[0])//move to start
        pointListXpos.removeFirst()//remove start point
        for pt in pointListXpos {//add points
            drawPath.addLine(to: pt)
        }
        
        drawPath.move(to: pointListXvelo[0])
        pointListXvelo.removeFirst()
        for pt in pointListXvelo {
            drawPath.addLine(to: pt)
        }
//        UIColor.black.setStroke()
        drawPath.setStrokeColor(UIColor.black.cgColor)
        drawPath.strokePath()

        // 線を描く
//        drawPath.stroke()
        drawPath.move(to: pointListYpos[0])
        pointListYpos.removeFirst()
        for pt in pointListYpos {
            drawPath.addLine(to: pt)
        }
        drawPath.move(to: pointListYvelo[0])
        pointListYvelo.removeFirst()
        for pt in pointListYvelo {
            drawPath.addLine(to: pt)
        }
        drawPath.setStrokeColor(UIColor.red.cgColor)
        drawPath.strokePath()
        // 線の色
//        UIColor.red.setStroke()
        // 線を描く
//        drawPath.stroke()
        // イメージコンテキストからUIImageを作る
        let image = UIGraphicsGetImageFromCurrentImageContext()
        // イメージ処理の終了
        UIGraphicsEndImageContext()
        return image!
    }
    
 
    func drawVogtext(){
        if vogLineView != nil{
            vogLineView?.removeFromSuperview()
        }
        let dImage = drawText(width:mailWidth,height:mailHeight)
        let drawImage = dImage.resize(size: CGSize(width:view.bounds.width, height:vogBoxHeight))
        vogLineView = UIImageView(image: drawImage)
        vogLineView?.center =  CGPoint(x:view.bounds.width/2,y:view.bounds.height/2)
        // 画面に表示する
        view.addSubview(vogLineView!)
    }

    func drawVHITwaves(){//解析結果のvHITwavesを表示する
        if vhitLineView != nil{
            vhitLineView?.removeFromSuperview()
        }
        //        let drawImage = drawWaves(width:view.bounds.width,height: view.bounds.width*2/5)
        let drawImage = drawvhitWaves(width:500,height:200)
        let dImage = drawImage.resize(size: CGSize(width:view.bounds.width, height:vhitBoxHeight))//view.bounds.width*2/5))
        vhitLineView = UIImageView(image: dImage)
        vhitLineView?.center =  CGPoint(x:view.bounds.width/2,y:vhitBoxYcenter)
        // 画面に表示する
        view.addSubview(vhitLineView!)
        //   showVog(f: true)
    }
    func drawRealwave(){//vHIT_eye_head
        if gyroLineView != nil{//これが無いとエラーがでる。
            gyroLineView?.removeFromSuperview()
            //            lineView?.isHidden = false
        }
        var startcnt = 0
        if eyeVeloXFiltered.count < Int(self.view.bounds.width){//横幅以内なら０からそこまで表示
            startcnt = 0
        }else{//横幅超えたら、新しい横幅分を表示
            startcnt = eyeVeloXFiltered.count - Int(self.view.bounds.width)
        }
        //波形を時間軸で表示
        let drawImage = drawLine(num:startcnt,width:self.view.bounds.width,height:gyroBoxHeight)//180)
        // イメージビューに設定する
        gyroLineView = UIImageView(image: drawImage)
        //       lineView?.center = self.view.center
        gyroLineView?.center = CGPoint(x:view.bounds.width/2,y:gyroBoxYcenter)//340)//ここらあたりを変更se~7plusの大きさにも対応できた。
        view.addSubview(gyroLineView!)
        //      showBoxies(f: true)
        //        print("count----" + "\(view.subviews.count)")
    }
    
    func drawOnewave(startcount:Int){//vHIT_eye_head
        var startcnt = startcount
        if startcnt < 0 {
            startcnt = 0
        }
        if gyroLineView != nil{//これが無いとエラーがでる。
            gyroLineView?.removeFromSuperview()
            //            lineView?.isHidden = false
        }
        if eyeVeloXFiltered.count < Int(self.view.bounds.width){//横幅以内なら０からそこまで表示
            startcnt = 0
        }else if startcnt > eyeVeloXFiltered.count - Int(self.view.bounds.width){
            startcnt = eyeVeloXFiltered.count - Int(self.view.bounds.width)
        }
        //波形を時間軸で表示
        let drawImage = drawLine(num:startcnt,width:self.view.bounds.width,height:gyroBoxHeight)// 180)
        // イメージビューに設定する
        gyroLineView = UIImageView(image: drawImage)
        //       lineView?.center = self.view.center
        gyroLineView?.center = CGPoint(x:view.bounds.width/2,y:gyroBoxYcenter)// 340)
        //ここらあたりを変更se~7plusの大きさにも対応できた。
        view.addSubview(gyroLineView!)
        //        print("count----" + "\(view.subviews.count)")
    }
    var timercnt:Int = 0
    var lastArraycount:Int = 0
    @objc func update_vog(tm: Timer) {
        timercnt += 1
        if eyePosXOrig.count < 5 {
            return
        }
        if calcFlag == false {//終わったらここ
            timer.invalidate()
            setButtons(mode: true)
            UIApplication.shared.isIdleTimerDisabled = false
            vogImage=makeVOGImage(startImg: vogImage!, width: 0, height: 0,start:lastArraycount-200, end: eyePosXOrig.count)
            drawVOG2endPt(end: 0)
            if vogLineView != nil{
                vogLineView?.removeFromSuperview()//waveを消して
            }
            drawVogtext()//文字を表示
            //終わり直前で認識されたvhitdataが認識されないこともあるかもしれない
        }else{
            #if DEBUG
            print("debug-update",timercnt)
            #endif
 
            let cntTemp=eyePosXOrig.count
            vogImage=makeVOGImage(startImg: vogImage!, width: 0, height: 0,start:lastArraycount-200, end: eyePosXOrig.count)
            lastArraycount=eyePosXOrig.count
            drawVOG2endPt(end: cntTemp)
            print("update_vog",timercnt,cntTemp)
            drawVogtext()
        }
    }
 
    var startTime=CFAbsoluteTimeGetCurrent()


    func getNamedImage(startingImage:UIImage) ->UIImage{
        // Create a context of the starting image size and set it as the current one
        UIGraphicsBeginImageContext(startingImage.size)
        // Draw the starting image in the current context as background
        startingImage.draw(at: CGPoint.zero)
        // Get the current context
        let context = UIGraphicsGetCurrentContext()!
        // Draw a red line
        context.setLineWidth(2.0)
        context.setStrokeColor(UIColor.black.cgColor)
        // パスの初期化
        let drawPath = UIBezierPath()
        let w=startingImage.size.width
        let h=startingImage.size.height
        let str1 = calcDate.components(separatedBy: ":")
        let str2 = "ID:" + String(format: "%08d", idNumber) + "  " + str1[0] + ":" + str1[1]
        let str3 = "vHIT96da"
        
        str2.draw(at: CGPoint(x: 20, y: h-100), withAttributes: [
                    NSAttributedString.Key.foregroundColor : UIColor.black,
                    NSAttributedString.Key.font : UIFont.monospacedDigitSystemFont(ofSize: 70, weight: UIFont.Weight.regular)])
        str3.draw(at: CGPoint(x: w-360, y: h-100), withAttributes: [
                    NSAttributedString.Key.foregroundColor : UIColor.black,
                    NSAttributedString.Key.font : UIFont.monospacedDigitSystemFont(ofSize: 70, weight: UIFont.Weight.regular)])
        
        UIColor.black.setStroke()
        // イメージコンテキストからUIImageを作る
        let image = UIGraphicsGetImageFromCurrentImageContext()
        // イメージ処理の終了
        UIGraphicsEndImageContext()
        return image!
    }
    
   
    @objc func update_vHIT(tm: Timer) {
        if eyeVeloXFiltered.count < 5 {
            return
        }
        if calcFlag == false {
            vhitCurpoint=0
            //if timer?.isValid == true {
            timer.invalidate()
            setButtons(mode: true)
            //  }
            UIApplication.shared.isIdleTimerDisabled = false
            //            makeBoxies()
            //            calcDrawVHIT()
            //終わり直前で認識されたvhitdataが認識されないこともあるかもしれないので、駄目押し。だめ押し用のcalcdrawvhitは別に作る必要があるかもしれない。
            if self.waveTuple.count > 0{
                self.nonsavedFlag = true
            }
        }
        vogImage=makeVOGImage(startImg: vogImage!, width: 0, height: 0,start:lastArraycount-100, end: eyeVeloXOrig.count)
        lastArraycount=eyeVeloXOrig.count
        drawRealwave()
        timercnt += 1
        #if DEBUG
        print("debug-update",timercnt)
        #endif
        calcDrawVHIT()
        if calcFlag==false{
            drawOnewave(startcount: 0)
        }
    }
    
    func update_gyrodelta() {
        if eyeVeloXFiltered.count < 5 {
            return
        }
        if calcFlag == false {
            //           makeBoxies()
            calcDrawVHIT()
            //終わり直前で認識されたvhitdataが認識されないこともあるかもしれないので、駄目押し。だめ押し用のcalcdrawvhitは別に作る必要があるかもしれない。
            if waveTuple.count > 0{
                nonsavedFlag = true
            }
        }
        drawRealwave()
        calcDrawVHIT()
    }
    
    func Field2value(field:UITextField) -> Int {
        if field.text?.count != 0 {
            return Int(field.text!)!
        }else{
            return 0
        }
    }
 /*
    func getVideofns()->String{
        let str=getFsindoc().components(separatedBy: ",")
        
        if !str[0].contains("vHIT96da"){
            return ""
        }
        var retStr:String=""
        for i in 0..<str.count{
            if str[i].contains(".MOV"){
                retStr += str[i] + ","
            }
        }
        //ifretStr += str[str.count-1]
        let retStr2=retStr.dropLast()
        return String(retStr2)
    }
 
    func getfileURL(path:String)->URL{
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = paths[0] as String
        let vidpath = documentsDirectory + "/" + path
        return URL(fileURLWithPath: vidpath)
    }
  
    func getdocumentPath(path:String)->String{
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = paths[0] as String
        let vidpath = documentsDirectory + "/" + path
        return vidpath
    }
    
*/
    func getFPS(url:URL) -> Float{
        let options = [CIDetectorAccuracy: CIDetectorAccuracyHigh]
        let avAsset = AVURLAsset(url: url, options: options)
        return avAsset.tracks.first!.nominalFrameRate
    }

    func getUserDefault(str:String,ret:Int) -> Int{//getUserDefault_one
        if (UserDefaults.standard.object(forKey: str) != nil){//keyが設定してなければretをセット
            return UserDefaults.standard.integer(forKey:str)
        }else{
            UserDefaults.standard.set(ret, forKey: str)
            return ret
        }
    }
    func getVideoGyryoZureDefault(){
       
        if UserDefaults.standard.object(forKey:"videoGyroZure") != nil{
            videoGyroZure=UserDefaults.standard.integer(forKey: "videoGyroZure")
        }else{
            let vw=view.bounds.width
            let vh=view.bounds.height
            if UIDevice.self.current.model.contains("touch"){//Touch7:320x568->30:120fps
                videoGyroZure=30
            }else if vw==414 && vh==736{//7plus:414x736->15(15:120)
                videoGyroZure=15
            }else if vw==320 && vh==568{//se:320x568->25(25:120)
                videoGyroZure=25
            }else if vw==375 && vh==667{//8:375x667->22(15:120)
                videoGyroZure=15
            }else if vw==414 && vh==896{//11:414x896->10(10:120fps)
                videoGyroZure=10
            }else{
                videoGyroZure=10
            }
            UserDefaults.standard.set(videoGyroZure, forKey: "videoGyroZure")
            print("videoGyroZure",videoGyroZure)
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
    //アルバムの一覧取得
    var gettingAlbumF:Bool=true
    func getVideosAlbumList(){//最後のvideoを取得するまで待つ
        gettingAlbumF = true
        getAlbumList_sub()//videosURL,videosDate,videosDuraをゲット
        while gettingAlbumF == true{
            sleep(UInt32(0.1))
        }
        //videosImgだけはここでゲット
        videoImg.removeAll()
        for i in 0..<videoURL.count{
            videoImg.append(getThumb(url: videoURL[i]))
        }
    }
 
    func getAlbumList_sub(){
        //     let imgManager = PHImageManager.default()
        let requestOptions = PHImageRequestOptions()
        videoURL.removeAll()
        videoDate.removeAll()
        videoDateTime.removeAll()
        videoDura.removeAll()
        videoAsset.removeAll()
        //videoImgだけは上記３arrayを取得後に、getAlbumListで取得する。
        requestOptions.isSynchronous = true
        requestOptions.isNetworkAccessAllowed = false
        requestOptions.deliveryMode = .highQualityFormat
        //これでもicloud上のvideoを取ってしまう
        // アルバムをフェッチ
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
//            fetchOptions.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.image.rawValue)
            fetchOptions.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.video.rawValue)
            let assets = PHAsset.fetchAssets(in: assetCollection, options: fetchOptions)
//            videoAssets = assets
//            print("assets:",assets.count)
            albumExist=true
            if assets.count == 0{
                gettingAlbumF=false
                albumExist=false
                return
            }
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            for i in 0..<assets.count{
                let asset=assets[i]
                let date_sub = asset.creationDate
                let date = formatter.string(from: date_sub!)
                let duration = String(format:"%.1fs",asset.duration)
                let options=PHVideoRequestOptions()
                options.version = .original
                PHImageManager.default().requestAVAsset(forVideo:asset,
                                                        options: options){ [self](asset:AVAsset?,audioMix, info:[AnyHashable:Any]?)->Void in
                    
                    if let urlAsset = asset as? AVURLAsset{//not on iCloud
                        videoURL.append(urlAsset.url)
                        videoDate.append(date)// + "(" + duration + ")")
                        videoDura.append(duration)
                        videoDateTime.append(date_sub!)//pngDateTimeと比較する？念のため
                        videoAsset.append(asset!)
                        //ここではgetThumbができないことがある。
//                        videosImg.append(getThumb(url: urlAsset.url))
//                        print(videoDate.last as Any)
                        if i == assets.count - 1{
                            gettingAlbumF=false
                        }
                    }else{//on icloud
//                        print("on icloud:",asset)
                        if i == assets.count - 1{
                            gettingAlbumF=false
                        }
                    }
                }
            }
        }else{
            albumExist=false
            gettingAlbumF=false
        }
    }

    func getUserDefaults(){
        widthRange = getUserDefault(str: "widthRange", ret: 30)
        waveWidth = getUserDefault(str: "waveWidth", ret: 80)
        eyeBorder = getUserDefault(str: "eyeBorder", ret: 10)
        eyeRatio = getUserDefault(str: "eyeRatio", ret: 100)
        gyroRatio = getUserDefault(str: "gyroRatio", ret: 100)
        posRatio = getUserDefault(str: "posRatio", ret: 100)
        veloRatio = getUserDefault(str: "veloRatio", ret: 100)
        faceF = getUserDefault(str: "faceF", ret:0)
        getVideoGyryoZureDefault()
        isVHIT = getUserDefault(str: "isVHIT", ret: true)
        let width=Int(view.bounds.width/2)
        let height=Int(view.bounds.height/3)
        wakuE.origin.x = CGFloat(getUserDefault(str: "wakuE_x", ret:width))
        wakuE.origin.y = CGFloat(getUserDefault(str: "wakuE_y", ret:height))
        
        wakuE.size.width = 5
        wakuE.size.height = 5
        wakuF.origin.x = CGFloat(getUserDefault(str: "wakuF_x", ret:width))
        wakuF.origin.y = CGFloat(getUserDefault(str: "wakuF_y", ret:height+30))
        
        wakuF.size.width = 5
        wakuF.size.height = 5
    }
    //default値をセットするんじゃなく、defaultというものに値を設定するという意味
    func setUserDefaults(){
        //        UserDefaults.standard.set(freeCounter, forKey: "freeCounter")
        UserDefaults.standard.set(widthRange, forKey: "widthRange")
        UserDefaults.standard.set(waveWidth, forKey: "waveWidth")
        UserDefaults.standard.set(eyeBorder, forKey: "eyeBorder")
        UserDefaults.standard.set(eyeRatio, forKey: "eyeRatio")
        UserDefaults.standard.set(gyroRatio, forKey: "gyroRatio")
        UserDefaults.standard.set(posRatio, forKey: "posRatio")
        UserDefaults.standard.set(veloRatio, forKey: "veloRatio")
        UserDefaults.standard.set(faceF,forKey: "faceF")
        UserDefaults.standard.set(videoGyroZure,forKey:"videoGyroZure")
        
        UserDefaults.standard.set(Int(wakuE.origin.x), forKey: "wakuE_x")
        UserDefaults.standard.set(Int(wakuE.origin.y), forKey: "wakuE_y")
        UserDefaults.standard.set(Int(wakuF.origin.x), forKey: "wakuF_x")
        UserDefaults.standard.set(Int(wakuF.origin.y), forKey: "wakuF_y")
        UserDefaults.standard.set(isVHIT,forKey: "isVHIT")
    }
    
    func dispWakus(){
        let nullRect:CGRect = CGRect(x:0,y:0,width:0,height:0)
        if faceF==0{
            rectType=0
        }
        //        printR(str:"wakuE:",rct: wakuE)
        eyeWaku_image.frame=CGRect(x:(wakuE.origin.x)-15,y:wakuE.origin.y-15,width:(wakuE.size.width)+30,height: wakuE.size.height+30)
        if  isVHIT==false || faceF==0{//vHIT 表示無し、補整無し
            faceWaku_image.frame=nullRect
        }else{
            faceWaku_image.frame=CGRect(x:(wakuF.origin.x)-15,y:wakuF.origin.y-15,width:wakuF.size.width+30,height: wakuF.size.height+30)
        }
        
        if rectType==0{
            eyeWaku_image.layer.borderColor = UIColor.green.cgColor
            eyeWaku_image.backgroundColor = UIColor.clear
            eyeWaku_image.layer.borderWidth = 1.0
            eyeWaku_image.layer.cornerRadius = 3
            faceWaku_image.layer.borderWidth = 0
        }else{
            faceWaku_image.layer.borderColor = UIColor.green.cgColor
            faceWaku_image.backgroundColor = UIColor.clear
            faceWaku_image.layer.borderWidth = 1.0
            faceWaku_image.layer.cornerRadius = 3
            eyeWaku_image.layer.borderWidth = 0
        }
    }
    //vHIT_eye_head
    func drawLine(num:Int, width w:CGFloat,height h:CGFloat) -> UIImage {
        let size = CGSize(width:w, height:h)
        UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
        // 折れ線にする点の配列
        var pointList0 = Array<CGPoint>()
        var pointList1 = Array<CGPoint>()
        var pointList2 = Array<CGPoint>()
        var py1:CGFloat?
        var point1:CGPoint?
        let pointCount = Int(w) // 点の個数
        // xの間隔
        let dx:CGFloat = 1//Int(w)/pointCount
        let eyeVeloFilteredCnt=eyeVeloXFiltered.count
        let gyroMovedCnt=gyroMoved.count
        
        for n in 1...(pointCount) {
            if num + n < eyeVeloFilteredCnt && num + n < gyroMovedCnt {
                let px = dx * CGFloat(n)
                let py0 = eyeVeloXFiltered[num + n] * CGFloat(eyeRatio)/230.0 + gyroBoxHeight*2/6
                if faceF==1{
                    py1 = faceVeloFiltered[num + n] * CGFloat(eyeRatio)/230.0 + gyroBoxHeight*3/6
                }
                let py2 = gyroMoved[num + n] * CGFloat(gyroRatio)/300.0 + gyroBoxHeight*4/6
                let point0 = CGPoint(x: px, y: py0)
                if faceF==1{
                    point1 = CGPoint(x: px, y: py1!)
                }
                let point2 = CGPoint(x: px, y: py2)
                pointList0.append(point0)
                if faceF==1{
                    pointList1.append(point1!)
                }
                pointList2.append(point2)
            }
        }
        
        // イメージ処理の開始
        UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
        // パスの初期化
        let drawPath0 = UIBezierPath()
        let drawPath1 = UIBezierPath()
        let drawPath2 = UIBezierPath()
        // 始点に移動する
        drawPath0.move(to: pointList0[0])
        // 配列から始点の値を取り除く
        pointList0.removeFirst()
        // 配列から点を取り出して連結していく
        for pt in pointList0 {
            drawPath0.addLine(to: pt)
        }
        if faceF==1{
            drawPath1.move(to: pointList1[0])
            // 配列から始点の値を取り除く
            pointList1.removeFirst()
            // 配列から点を取り出して連結していく
            for pt in pointList1 {
                drawPath1.addLine(to: pt)
            }
        }
        drawPath2.move(to: pointList2[0])
        // 配列から始点の値を取り除く
        pointList2.removeFirst()
        // 配列から点を取り出して連結していく
        for pt in pointList2 {
            drawPath2.addLine(to: pt)
        }
        // 線の色
        UIColor.black.setStroke()
        // 線幅
        drawPath0.lineWidth = 0.3
        drawPath1.lineWidth = 0.3
        drawPath2.lineWidth = 0.3
        // 線を描く
        drawPath0.stroke()
        if faceF==1{
            drawPath1.stroke()
        }
        drawPath2.stroke()
        let timetxt:String = String(format: "%05df (%.1fs/%@) : %ds",eyeVeloXFiltered.count,CGFloat(eyeVeloXFiltered.count)/240.0,videoDura[videoCurrent],timercnt+1)
        //print(timetxt)
        timetxt.draw(at: CGPoint(x: 3, y: 3), withAttributes: [
            NSAttributedString.Key.foregroundColor : UIColor.black,
            NSAttributedString.Key.font : UIFont.monospacedDigitSystemFont(ofSize: 13, weight: UIFont.Weight.regular)])
        
        //イメージコンテキストからUIImageを作る
        let image = UIGraphicsGetImageFromCurrentImageContext()
        // イメージ処理の終了
        UIGraphicsEndImageContext()
        return image!
    }
    
    func draw1wave(){//just vHIT
        var pointList = Array<CGPoint>()
        let drawPath = UIBezierPath()
        var rlPt:Int = 0
        for i in 0..<waveTuple.count{//右のvHIT
            if waveTuple[i].2 == 0 || waveTuple[i].0 == 0{
                continue
            }
            for n in 0..<120 {
                let px = CGFloat(260 + n*2)//260 or 0
                var py:CGFloat = 0
                py = CGFloat(eyeWs[i][n] + 90)
                let point = CGPoint(x:px,y:py)
                pointList.append(point)
            }
            // 始点に移動する
            drawPath.move(to: pointList[0])
            // 配列から始点の値を取り除く
            pointList.removeFirst()
            // 配列から点を取り出して連結していく
            for pt in pointList {
                drawPath.addLine(to: pt)
            }
            // 線の色
            UIColor.red.setStroke()
            // 線幅
            drawPath.lineWidth = 0.3
            pointList.removeAll()
        }
        drawPath.stroke()
        drawPath.removeAllPoints()
        for i in 0..<waveTuple.count{//左のvHIT
            if waveTuple[i].2 == 0 || waveTuple[i].0 == 1{
                continue
            }
            for n in 0..<120 {
                let px = CGFloat(n*2)//260 or 0
                var py:CGFloat = 0
                py = CGFloat(eyeWs[i][n] + 90)
                let point = CGPoint(x:px,y:py)
                pointList.append(point)
            }
            // 始点に移動する
            drawPath.move(to: pointList[0])
            // 配列から始点の値を取り除く
            pointList.removeFirst()
            // 配列から点を取り出して連結していく
            for pt in pointList {
                drawPath.addLine(to: pt)
            }
            // 線の色
            UIColor.blue.setStroke()
            // 線幅
            drawPath.lineWidth = 0.3
            pointList.removeAll()
        }
        drawPath.stroke()
        drawPath.removeAllPoints()
        for i in 0..<waveTuple.count{//左右のoutWsを表示
            if waveTuple[i].2 == 0{
                continue
            }
            if waveTuple[i].0 == 0{
                rlPt=0
            }else{
                rlPt=260
            }
            for n in 0..<120 {
                let px = CGFloat(rlPt + n*2)
                let py = CGFloat(gyroWs[i][n] + 90)
                let point = CGPoint(x:px,y:py)
                pointList.append(point)
            }
            drawPath.move(to: pointList[0])
            pointList.removeFirst()
            for pt in pointList {
                drawPath.addLine(to: pt)
            }
            UIColor.black.setStroke()
            drawPath.lineWidth = 0.3
            pointList.removeAll()
        }
        drawPath.stroke()
        drawPath.removeAllPoints()
        for i in 0..<waveTuple.count{//太く表示する
            if waveTuple[i].3 == 1 || (waveTuple[i].3 == 2 && waveTuple[i].2 == 1){
                if waveTuple[i].0 == 0{
                    rlPt=0
                }else{
                    rlPt=260
                }
                for n in 0..<120 {
                    let px = CGFloat(rlPt + n*2)
                    let py = CGFloat(gyroWs[i][n] + 90)
                    let point = CGPoint(x:px,y:py)
                    pointList.append(point)
                }
                drawPath.move(to: pointList[0])
                pointList.removeFirst()
                for pt in pointList {
                    drawPath.addLine(to: pt)
                }
                UIColor.black.setStroke()
                drawPath.lineWidth = 1.0
                pointList.removeAll()
                for n in 0..<120 {
                    let px = CGFloat(rlPt + n*2)
                    var py:CGFloat = 0
                    py = CGFloat(eyeWs[i][n] + 90)
                    let point = CGPoint(x:px,y:py)
                    pointList.append(point)
                }
                drawPath.move(to: pointList[0])
                pointList.removeFirst()
                for pt in pointList {
                    drawPath.addLine(to: pt)
                }
                UIColor.black.setStroke()
                drawPath.lineWidth = 1.0
                pointList.removeAll()
            }
        }
        drawPath.stroke()
        drawPath.removeAllPoints()
    }
    
    //アラート画面にテキスト入力欄を表示する。上記のswift入門よりコピー
    var tempnum:Int = 0
    @IBAction func saveResult(_ sender: Any) {//vhit
        if calcFlag == true{
            return
        }
        if isVHIT==false{
            saveResult_vog(0)
            return
        }
        if waveTuple.count < 1 {
            return
        }
        if vhitBoxView?.isHidden == true{
            showBoxies(f: true)
        }
        //var idNumber:Int = 0
        let alert = UIAlertController(title: "vHIT96da", message: "Input ID number", preferredStyle: .alert)
        let saveAction = UIAlertAction(title: "OK", style: .default) { (action:UIAlertAction!) -> Void in
            
            // 入力したテキストをコンソールに表示
            let textField = alert.textFields![0] as UITextField
            #if DEBUG
            print("\(String(describing: textField.text))")
            #endif
            self.idNumber = self.Field2value(field: textField)
            let drawImage = self.drawvhitWaves(width:500,height:200)
            // イメージビューに設定する
            UIImageWriteToSavedPhotosAlbum(drawImage, nil, nil, nil)
            self.nonsavedFlag = false //解析結果がsaveされたのでfalse
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .default) { (action:UIAlertAction!) -> Void in
            self.idNumber = 1//キャンセルしてもここは通らない？
        }
        // UIAlertControllerにtextFieldを追加
        alert.addTextField { (textField:UITextField!) -> Void in
            textField.keyboardType = UIKeyboardType.numberPad
        }
        alert.addAction(cancelAction)//この行と下の行の並びを変えるとCancelとOKの左右が入れ替わる。
        alert.addAction(saveAction)
        present(alert, animated: true, completion: nil)
        
    }
    func saveResult_vog(_ sender: Any) {//vog
        if calcFlag == true{
            return
        }
        let alert = UIAlertController(title: "VOG96da", message: "Input ID number", preferredStyle: .alert)
        let saveAction = UIAlertAction(title: "OK", style: .default) { (action:UIAlertAction!) -> Void in
            // 入力したテキストをコンソールに表示
            let textField = alert.textFields![0] as UITextField
            #if DEBUG
            print("\(String(describing: textField.text))")
            #endif
            self.idNumber = self.Field2value(field: textField)
            self.drawVogtext()//ここが無くてもIDはsaveされるが、ないとIDが表示されない。
            var cnt = -self.vogCurpoint
            cnt=cnt*Int(self.mailWidth)/Int(self.view.bounds.width)
            let drawImage = self.drawVogwaves( num:240*10+cnt,width:self.mailWidth,height:self.mailHeight)
  // イメージビューに設定する
            UIImageWriteToSavedPhotosAlbum(drawImage, nil, nil, nil)
            self.nonsavedFlag = false //解析結果がsaveされたのでfalse
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .default) { (action:UIAlertAction!) -> Void in
            self.idNumber = 1//キャンセルしてもここは通らない？
        }
        
        // UIAlertControllerにtextFieldを追加
        alert.addTextField { (textField:UITextField!) -> Void in
            textField.keyboardType = UIKeyboardType.numberPad
        }
        alert.addAction(cancelAction)//この行と下の行の並びを変えるとCancelとOKの左右が入れ替わる。
        alert.addAction(saveAction)
        present(alert, animated: true, completion: nil)
    }
    
    func drawvhitWaves(width w:CGFloat,height h:CGFloat) -> UIImage {
        let size = CGSize(width:w, height:h)
        // イメージ処理の開始
        UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
        // パスの初期化
        let drawPath = UIBezierPath()
        
        let str1 = calcDate.components(separatedBy: ":")
        let str2 = "ID:" + String(format: "%08d", idNumber) + "  " + str1[0] + ":" + str1[1]
        let str3 = "vHIT96da"
        str2.draw(at: CGPoint(x: 5, y: 180), withAttributes: [
            NSAttributedString.Key.foregroundColor : UIColor.black,
            NSAttributedString.Key.font : UIFont.monospacedDigitSystemFont(ofSize: 15, weight: UIFont.Weight.regular)])
        str3.draw(at: CGPoint(x: 428, y: 180), withAttributes: [
            NSAttributedString.Key.foregroundColor : UIColor.black,
            NSAttributedString.Key.font : UIFont.monospacedDigitSystemFont(ofSize: 15, weight: UIFont.Weight.regular)])
        
        UIColor.black.setStroke()
        var pList = Array<CGPoint>()
        pList.append(CGPoint(x:0,y:0))
        pList.append(CGPoint(x:0,y:180))
        pList.append(CGPoint(x:240,y:180))
        pList.append(CGPoint(x:240,y:0))
        pList.append(CGPoint(x:260,y:0))
        pList.append(CGPoint(x:260,y:180))
        pList.append(CGPoint(x:500,y:180))
        pList.append(CGPoint(x:500,y:0))
        drawPath.lineWidth = 0.1
        drawPath.move(to:pList[0])
        drawPath.addLine(to:pList[1])
        drawPath.addLine(to:pList[2])
        drawPath.addLine(to:pList[3])
        drawPath.addLine(to:pList[0])
        drawPath.move(to:pList[4])
        drawPath.addLine(to:pList[5])
        drawPath.addLine(to:pList[6])
        drawPath.addLine(to:pList[7])
        drawPath.addLine(to:pList[4])
        for i in 0...4 {
            drawPath.move(to: CGPoint(x:30 + i*48,y:0))
            drawPath.addLine(to: CGPoint(x:30 + i*48,y:180))
            drawPath.move(to: CGPoint(x:290 + i*48,y:0))
            drawPath.addLine(to: CGPoint(x:290 + i*48,y:180))
        }
        drawPath.stroke()
        drawPath.removeAllPoints()
        draw1wave()//just vHIT
        var riln:Int = 0
        var leln:Int = 0
        for i in 0..<waveTuple.count{
            if waveTuple[i].2 == 1{
                if waveTuple[i].0 == 0 {
                    riln += 1
                }else{
                    leln += 1
                }
            }
        }
        "\(riln)".draw(at: CGPoint(x: 3, y: 0), withAttributes: [
            NSAttributedString.Key.foregroundColor : UIColor.black,
            NSAttributedString.Key.font : UIFont.monospacedDigitSystemFont(ofSize: 15, weight: UIFont.Weight.regular)])
        "\(leln)".draw(at: CGPoint(x: 263, y: 0), withAttributes: [
            NSAttributedString.Key.foregroundColor : UIColor.black,
            NSAttributedString.Key.font : UIFont.monospacedDigitSystemFont(ofSize: 15, weight: UIFont.Weight.regular)])
        // イメージコンテキストからUIImageを作る
        let image = UIGraphicsGetImageFromCurrentImageContext()
        // イメージ処理の終了
        UIGraphicsEndImageContext()
        return image!
    }
    
    @objc func viewWillEnterForeground(_ notification: Notification?) {
        //       print("willenter")
        if (self.isViewLoaded && (self.view.window != nil)) {
            //            freeCounter += 1
            //            UserDefaults.standard.set(freeCounter, forKey: "freeCounter")
            //            videoFps.text = "\(freeCounter)"
        }
    }
    var gettingThumbFlag:Bool?
    func getThumb(url:URL) -> UIImage{//getするまで待って帰る
        gettingThumbFlag=true
        let img=getThumb_sub(url:url)
        while gettingThumbFlag==true{
            sleep(UInt32(0.1))
        }
        return img!
    }
    func getThumb_sub(url: URL) -> UIImage? {
        do {
            let asset = AVURLAsset(url: url as URL , options: nil)
            let imgGenerator = AVAssetImageGenerator(asset: asset)
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
    func getThumbnailFrom(path:String) -> UIImage{//getするまで待って帰る
        gettingThumbFlag=true
        let img=getThumbnailFrom_sub(path: path)
        while gettingThumbFlag==true{
            sleep(UInt32(0.1))
        }
        return img!
    }
    func getThumbnailFrom_sub(path: String) -> UIImage? {
        let url = NSURL(fileURLWithPath: path)
        if path==""{
            return nil
        }
        do {
            let asset = AVURLAsset(url: url as URL , options: nil)
            let imgGenerator = AVAssetImageGenerator(asset: asset)
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
    // アルバムが既にあるか確認し
    func albumExists(albumTitle: String) -> Bool {
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
    
    //何も返していないが、ここで見つけたor作成したalbumを返したい。そうすればグローバル変数にアクセスせずに済む
    func createNewAlbum(albumTitle: String, callback: @escaping (Bool) -> Void) {
        if self.albumExists(albumTitle: albumTitle) {
            callback(true)
        } else {
            PHPhotoLibrary.shared().performChanges({
                _ = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: albumTitle)
            }) { (isSuccess, error) in
                callback(isSuccess)
            }
        }
    }
  
 
    
    override func viewDidLoad() {
        super.viewDidLoad()
        dispFsindoc()//for debug
        //機種にょって異なるVOG結果サイズだったのを2400*1600に統一した
        mailWidth=2400//240*10
        mailHeight=1600//240*10*2/3//0.36*view.bounds.height/view.bounds.width
         //vHIT結果サイズは500*200
        getUserDefaults()
        setButtons(mode: true)
        stopButton.isHidden = true
//        camera_alert()
        getVideosAlbumList()
        videoArrayCount = videoURL.count
        videoCurrent=videoArrayCount-1
        makeBoxies()//three boxies of gyro vHIT vog
        showBoxies(f: false)//isVHITに応じてviewを表示
        self.setNeedsStatusBarAppearanceUpdate()
        dispWakus()
        showVideoIroiro(num:0)
        if videoImg.count==0{
            playButton.isEnabled=false
        }
    }
    func setButtons_first(){
        let ww=view.bounds.width
//        let wh=view.bounds.height
        var bw=(ww-30)/4//vhit,camera,vogのボタンの幅
        let distance:CGFloat=4//最下段のボタンとボタンの距離
        let bottomY=damyBottom.frame.minY

        let bh:CGFloat=(ww-20-6*distance)/7//最下段のボタンの高さ、幅と同じ
        let bh1=bottomY-5-bh/2-bh//2段目
        let bh2=bottomY-10-2.8*bh//videoSlider
        backButton.layer.cornerRadius = 5
        nextButton.layer.cornerRadius = 5
        videoSlider.frame = CGRect(x: 10, y:bh2, width: ww - 20, height: bh)
        videoSlider.thumbTintColor=UIColor.systemYellow

        bw=bh//bhは冒頭で決めている。上２段のボタンの高さと同じ。
        let bwd=bw+distance
        let bh0=bottomY-bh/2//wh-10-bw/2
        setButtonProperty(button:listButton,bw:bw,bh:bh,cx:10+bw/2+bwd*0,cy:bh0)
        setButtonProperty(button:saveButton,bw:bw,bh:bh,cx:10+bw/2+bwd*1,cy:bh0)
        setButtonProperty(button:waveButton,bw:bw,bh:bh,cx:10+bw/2+bwd*2,cy:bh0)
        setButtonProperty(button:calcButton,bw:bw,bh:bh,cx:10+bw/2+bwd*3,cy:bh0)
        calcButton.backgroundColor=UIColor.blue
        setButtonProperty(button:stopButton,bw:bw,bh:bh,cx:10+bw/2+bwd*3,cy:bh0)
        stopButton.backgroundColor=UIColor.blue
        setButtonProperty(button:paraButton,bw:bw,bh:bh,cx:10+bw/2+bwd*4,cy:bh0)
        setButtonProperty(button:cameraButton,bw:bw,bh:bh,cx:10+bw/2+bwd*6,cy:bh0)
        setButtonProperty(button:helpButton,bw:bw,bh:bh,cx:10+bw/2+bwd*5,cy:bh0)
        setButtonProperty(button:backwardButton,bw:bh,bh:bh,cx:10+bw/2+bwd*4,cy:bh1)
        setButtonProperty(button:playButton,bw:bh,bh:bh,cx:10+bw/2+bwd*5,cy:bh1)
        setButtonProperty(button:forwardButton,bw:bh,bh:bh,cx:10+bw/2+bwd*6,cy:bh1)
        bw=(bh*3+distance)/2
        setButtonProperty(button:vhitButton,bw:bw,bh:bh,cx:10+bw/2,cy:bh1)
        setButtonProperty(button:vogButton,bw:bw,bh:bh,cx:10+bw/2+bw+distance,cy:bh1)
    }
    func setButtonProperty(button:UIButton,bw:CGFloat,bh:CGFloat,cx:CGFloat,cy:CGFloat){
        button.frame = CGRect(x:0,y:0,width:bw,height:bh)
        button.layer.borderColor = UIColor.black.cgColor
        button.layer.borderWidth = 1.0
        button.layer.position=CGPoint(x:cx,y:cy)
        button.layer.cornerRadius = 5
    }

    @objc func onEyeFaceButton(sender: UIButton) {
        showWave(0)
    }
    
    override var prefersHomeIndicatorAutoHidden: Bool {
        get {
            return true
        }
    }
    //    override func prefersHomeIndicatorAutoHidden() -> Bool {
    //        return true
    //    }
    override var prefersStatusBarHidden: Bool {
        return true
    }
    /*
    func initVogImage(width w:CGFloat,height h:CGFloat) -> UIImage {
        let size = CGSize(width:w, height:h)
        // イメージ処理の開始
        UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
        let context = UIGraphicsGetCurrentContext()
        // パスの初期化
        let drawRect = CGRect(x:0, y:0, width:w, height:h)
        let drawPath = UIBezierPath(rect:drawRect)
        
        context?.setFillColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        drawPath.fill()
        context?.setStrokeColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
        drawPath.stroke()
        
        UIColor.black.setStroke()
        
        let wid:CGFloat=w/90.0
        for i in 0..<90 {
            let xp = CGFloat(i)*wid
            drawPath.move(to: CGPoint(x:xp,y:0))
            drawPath.addLine(to: CGPoint(x:xp,y:h-120))
        }
        drawPath.move(to:CGPoint(x:0,y:0))
        drawPath.addLine(to: CGPoint(x:w,y:0))
        drawPath.move(to:CGPoint(x:0,y:h-120))
        drawPath.addLine(to: CGPoint(x:w,y:h-120))
        //UIColor.blue.setStroke()
        drawPath.lineWidth = 2.0//1.0
        drawPath.stroke()
        // イメージコンテキストからUIImageを作る
        let image = UIGraphicsGetImageFromCurrentImageContext()
        // イメージ処理の終了
        UIGraphicsEndImageContext()
        return image!
    }
    */
    func makeVOGimgWakulines(width w:CGFloat,height h:CGFloat) ->UIImage{
        let size = CGSize(width:w, height:h)
        // イメージ処理の開始
        UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
        // パスの初期化
        let drawPath = UIBezierPath()
        
        //let wI:Int = Int(w)//2400*18
        let wid:CGFloat=w/90.0
        for i in 0..<90 {
            let xp = CGFloat(i)*wid
            drawPath.move(to: CGPoint(x:xp,y:0))
            drawPath.addLine(to: CGPoint(x:xp,y:h-120))
        }
        drawPath.move(to:CGPoint(x:0,y:0))
        drawPath.addLine(to: CGPoint(x:w,y:0))
        drawPath.move(to:CGPoint(x:0,y:h-120))
        drawPath.addLine(to: CGPoint(x:w,y:h-120))
        //UIColor.blue.setStroke()
        drawPath.lineWidth = 2.0//1.0
        drawPath.stroke()
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        // イメージ処理の終了
        UIGraphicsEndImageContext()
        return image!
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
//        let Start=CFAbsoluteTimeGetCurrent()
        var text:String=""
        for i in 0..<gyroFiltered.count{
//            let str=String(Int(gyroFiltered[i]*100))
            text += String(Int(gyroFiltered[i]*100)) + ","
//            print(text,str,gyroFiltered[i])
        }
//        print("elapsed time:",CFAbsoluteTimeGetCurrent()-Start,gyroFiltered.count)
        let txt:NSString = text as NSString
//        print("elapsed time:",CFAbsoluteTimeGetCurrent()-Start,gyroFiltered.count)
        return txt
    }
 
    func dispFsindoc(){
        let documentDirectoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        do {
            let contentUrls = try FileManager.default.contentsOfDirectory(at: documentDirectoryURL, includingPropertiesForKeys: nil)
            let files = contentUrls.map{$0.lastPathComponent}
            
            for i in 0..<files.count{
                print(files[i])
            }
        } catch {
            print("ないよ？")
        }
    }
  
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
   
    func makeAlbum(albumTitle:String){
        if albumExists(albumTitle: albumName)==false{
            createNewAlbum(albumTitle: albumName) { [self] (isSuccess) in
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
    //    var tempCalcflag:Bool = false
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // segueから遷移先のResultViewControllerを取得する
        //      tempCalcflag = calcFlag//別ページに移る時が計算中かどうか
        if let vc = segue.destination as? ParametersViewController {
            let ParametersViewController:ParametersViewController = vc
            //      遷移先のParametersViewControllerで宣言している値に代入して渡す
            ParametersViewController.widthRange = widthRange
            ParametersViewController.waveWidth = waveWidth
            ParametersViewController.isVHIT = isVHIT
            ParametersViewController.eyeBorder = eyeBorder
            //            ParametersViewController.gyroDelta = gyroDelta
            ParametersViewController.faceF = faceF
            if isVHIT == true{
                ParametersViewController.ratio1 = eyeRatio
                ParametersViewController.ratio2 = gyroRatio
                ParametersViewController.videoGyroZure=videoGyroZure
            }else{
                ParametersViewController.ratio1 = posRatio
                ParametersViewController.ratio2 = veloRatio
                //                ParametersViewController.okpMode = okpMode
            }
            #if DEBUG
            print("prepare para")
            #endif
        }else if let vc = segue.destination as? ImagePickerViewController{
            let Controller:ImagePickerViewController = vc
            //            Controller.tateyokoRatio=mailHeight/mailWidth
            Controller.isVHIT=isVHIT
        }else if let vc = segue.destination as? HelpjViewController{
            let Controller:HelpjViewController = vc
            Controller.isVHIT = isVHIT
        }else if segue.destination is RecordViewController{
            makeAlbum(albumTitle: "vHIT_VOG")//なければ作る
        }else{
            #if DEBUG
            print("prepare list")
            #endif
        }
    }
    func removeBoxies(){
        gyroBoxView?.isHidden = true
        vhitBoxView?.isHidden = true
        vhitLineView?.isHidden = true //removeFromSuperview()
        gyroLineView?.isHidden = true //removeFromSuperview()
    }
    var path2albumDoneFlag:Bool=false//不必要かもしれないが念の為
    func savePath2album(path:String){
        path2albumDoneFlag=false
        savePath2album_sub(path: path)
        while path2albumDoneFlag==false{
            sleep(UInt32(0.2))
        }
    }

    func savePath2album_sub(path:String){
        
//        if albumExists(albumTitle: "vHIT_VOG")==false{
//            return
//        }
        if let dir = FileManager.default.urls( for: .documentDirectory, in: .userDomainMask ).first {
            
            let fileURL = dir.appendingPathComponent( path )
            
            PHPhotoLibrary.shared().performChanges({ [self] in
                let assetRequest = PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: fileURL)!
                let albumChangeRequest = PHAssetCollectionChangeRequest(for: getPHAssetcollection(albumTitle: albumName))
                let placeHolder = assetRequest.placeholderForCreatedAsset
                albumChangeRequest?.addAssets([placeHolder!] as NSArray)
            }) { (isSuccess, error) in
                if isSuccess {
                    self.path2albumDoneFlag=true
                    // 保存成功
                } else {
                    self.path2albumDoneFlag=true
                    // 保存失敗
                }
            }
        }
    }

    func saveImage2path(image:UIImage,path:String) {//imageを保存
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
            //            gyroDelta = ParametersViewController.gyroDelta
            var chanF=false
            if isVHIT == true{
                eyeRatio=ParametersViewController.ratio1
                gyroRatio=ParametersViewController.ratio2
                faceF=ParametersViewController.faceF!
                videoGyroZure=ParametersViewController.videoGyroZure
            }else{
                if posRatio != ParametersViewController.ratio1 ||
                    veloRatio != ParametersViewController.ratio2{
                    chanF=true
                }
                posRatio=ParametersViewController.ratio1
                veloRatio=ParametersViewController.ratio2
            }
            setUserDefaults()
            if eyeVeloXFiltered.count > 400{
                if isVHIT == true{//データがありそうな時は表示
                    calcDrawVHIT()
                }else{
                    if chanF==true{
                        vogCurpoint=0
                        drawVogall()
                        drawVogtext()
                    }
                }
            }
            dispWakus()
            if boxF==false{
                showBoxies(f: false)
            }else{
                showBoxies(f: true)
            }
            #if DEBUG
            print("TATSUAKI-unwind from para")
            #endif
        }else if let vc = segue.source as? RecordViewController{
            let Controller:RecordViewController = vc
            if Controller.session.isRunning{//何もせず帰ってきた時
                Controller.session.stopRunning()
                print("sessionが動いている")
            }else{
                print("sessionが動いていない")
            }
            if Controller.recordedFlag==true{
                //                getVideosAlbumList()
                //            }else{//
                print("ちゃんと録画した")
                var d:Double=0
                var gyro = Array<Double>()
                var gyroTime = Array<Double>()
                KalmanInit()
                gyroFiltered.removeAll()
                showBoxies(f: false)
                playButton.isEnabled=true
                for i in 0...Controller.gyro.count/2-4{//-2でエラーなので、-5としてみた
                    gyroTime.append(Controller.gyro[i*2])
                    d=Double(Kalman(value:CGFloat(Controller.gyro[i*2+1]*10),num:3))
                    gyro.append(-d)
                }
                //gyroは10msごとに拾ってある.合わせる
                //これをvideoのフレーム数に合わせる
                while Controller.saved2album == false{//fileができるまで待つ
                    sleep(UInt32(0.1))
                }
                removeFile(delFile: "temp.png")
                getVideosAlbumList()
                while videoDura.count==videoArrayCount{
                    sleep(UInt32(0.5))
                }
                videoArrayCount=videoDura.count
                videoCurrent=videoArrayCount-1
                showVideoIroiro(num:0)
                var fps=getFPS(url: videoURL[videoCurrent])
                if fps < 200.0{
                    fps *= 2.0
                }
                let framecount=Int(Float(gyro.count)*(fps)/100.0)
                for i in 0...framecount+10{
                    let gn=Double(i)/Double(fps)//iフレーム目の秒数
                    var getj:Int=0
                    for j in 0...gyro.count-1{
                        if gyroTime[j] >= gn{//secondの値が入っている。
                            getj=j//越えるところを見つける
                            break
                        }
                    }
                    gyroFiltered.append(Kalman(value:CGFloat(gyro[getj]),num:4))
                }
                let gyroCSV=getGyroCSV()//csv文字列
                //pixel2imageで240*60*6の配列を作るので,増やすときは注意
                let gyroImage=openCV.pixel2image(videoImg[videoCurrent], csv: gyroCSV as String)
                //まずtemp.pngに保存して、それをvHIT_VOGアルバムにコピーする
                saveImage2path(image: gyroImage!, path: "temp.png")
                while existFile(aFile: "temp.png")==false{
                    sleep(UInt32(0.1))
                }
                savePath2album(path: "temp.png")
                startFrame=0
                //                getPngsAlbumList()
                //VOGの時もgyrodataを保存する。（不必要だが、考えるべきことが減りそうなので）
            }else{
                if Controller.startButton.isHidden==true && Controller.stopButton.isHidden==true{
                    getVideosAlbumList()
                    slowImage.image=UIImage(named:"vhittop")
                    playButton.isEnabled=false
                    print("アルバムを消されていたので、録画を保存しなかった。")
                }else{
                    print("Exitで抜けた。")
                }
            }
        }else{
            #if DEBUG
            print("tatsuaki-unwind from list")
            #endif
        }
    }
//    func printRGB(img:UIImage){
//           let rgb8=img.pixelData()
//           print("rgb8",rgb8!.count,img.size.width,img.size.height)
//           for i in 0...6{
//               print(rgb8![i*4],rgb8![i*4+1],rgb8![i*4+2],rgb8![i*4+3])
//           }
//       }
    func readGyroFromPng(img:UIImage){
        gyroFiltered.removeAll()
        let rgb8=img.pixelData()
        for i in 0..<rgb8!.count/4{
            var rgb:Int=0
            if rgb8![i*4]==1{
                rgb = Int(rgb8![i*4+1])*256 + Int(rgb8![i*4+2])
            }else{
                rgb = -Int(rgb8![i*4+1])*256 - Int(rgb8![i*4+2])
            }
            gyroFiltered.append(CGFloat(rgb)/100.0)
        }
    }
    func printRGB(img:UIImage){
        gyroFiltered.removeAll()
        let rgb8=img.pixelData()
        for i in 0...6{
            print(rgb8![i*4],rgb8![i*4+1],rgb8![i*4+2],rgb8![i*4+3])
        }
        var str:String=""
        print("rgb8",rgb8!.count,img.size.width,img.size.height)
        for i in 0...50{
            var rgb:Int=0
            if rgb8![i*4]==1{
                rgb = Int(rgb8![i*4+1])*256 + Int(rgb8![i*4+2])
            }else{
                rgb = -Int(rgb8![i*4+1])*256 - Int(rgb8![i*4+2])
            }
            str += rgb.description + ","
            gyroFiltered.append(CGFloat(rgb)/100.0)
        }
        print(str)
    }
    func moveWakus
        (rect:CGRect,stRect:CGRect,stPo:CGPoint,movePo:CGPoint,hani:CGRect) -> CGRect{
        var r:CGRect
        r = rect//2種類の枠を代入、変更してreturnで返す
        let dx:CGFloat = movePo.x
        let dy:CGFloat = movePo.y
        r.origin.x = stRect.origin.x + dx;
        r.origin.y = stRect.origin.y + dy;
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
    
    var leftrightFlag:Bool = false
    var rectType:Int = 0//0:eye 1:face 2:outer -1:何も選択されていない
    var stPo:CGPoint = CGPoint(x:0,y:0)//stRect.origin tapした位置
    var stRect:CGRect = CGRect(x:0,y:0,width:0,height:0)//tapしたrectのtapした時のrect
    var changePo:CGPoint = CGPoint(x:0,y:0)
    var endPo:CGPoint = CGPoint(x:0,y:0)
    var lastslowVideo:Int = -2
    var lastVogpoint:Int = -2
    var lastVhitpoint:Int = -2
    var lastmoveX:Int = -2
    var lastmoveXgyro:Int = -2//vHIT用
    @IBAction func panGesture(_ sender: UIPanGestureRecognizer) {
        if calcFlag == true{
            return
        }
        let move:CGPoint = sender.translation(in: self.view)
        let pos = sender.location(in: self.view)
        if sender.state == .began {
            stPo = sender.location(in: self.view)
            if vhitBoxView?.isHidden == true && vogBoxView?.isHidden  == true{
                //タップして動かすと、ここに来る
                //                rectType = checkWaks(po: pos)//0:枠設定 -1:違う
                if isVHIT==false{
                    rectType=0
                }
                if rectType==0{
                    stRect=wakuE
                }else{
                    stRect=wakuF
                }
            }
        } else if sender.state == .changed {
            if isVHIT == true && vhitBoxView?.isHidden == false{//vhit
                let h=self.view.bounds.height
                //let hI=Int(h)
                //let posyI=Int(pos.y)
                //                if isVHIT == true{//vhit
                if pos.y > h/2{//下半分の時
                    var dd=Int(10)
                    if pos.y < h/2 + h/6{//dd < 10{
                        dd = 2
                    }else if pos.y > h/2 + h*2/6{
                        dd = 20
                    }
                    if Int(move.x) > lastmoveX + dd{
                        vhitCurpoint -= dd*4
                        lastmoveX = Int(move.x)
                    }else if Int(move.x) < lastmoveX - dd{
                        vhitCurpoint += dd*4
                        lastmoveX = Int(move.x)
                    }
                    //print("all",dd,Int(move.x),lastmoveX,vhitCurpoint)// Int(move.x/10.0),movex)
                    if vhitCurpoint<0{
                        vhitCurpoint = 0
                    }else if vhitCurpoint > eyeVeloXFiltered.count - Int(self.view.bounds.width){
                        vhitCurpoint = eyeVeloXFiltered.count - Int(self.view.bounds.width)
                    }
                    if vhitCurpoint != lastVhitpoint{
                        drawOnewave(startcount: vhitCurpoint)
                        lastVhitpoint = vhitCurpoint
                        if waveTuple.count>0{
                            checksetPos(pos: lastVhitpoint + Int(self.view.bounds.width/2), mode:1)
                            drawVHITwaves()
                        }
                    }
                }else{
                    
                }
            }else if isVHIT == false && vogBoxView?.isHidden == false{//vog
                if eyePosXFiltered.count<240*10{//||okpMode==1{//240*10以下なら動けない。
                    return
                }
                let dd:Int=1
                if Int(move.x) > lastmoveX + dd{
                    vogCurpoint += dd*10
                    lastmoveX = Int(move.x)
                }else if Int(move.x) < lastmoveX - dd{
                    vogCurpoint -= dd*10
                    lastmoveX = Int(move.x)
                }
                let temp=Int(240*10-eyePosXFiltered.count)
                
                if vogCurpoint < temp*Int(view.bounds.width)/Int(mailWidth){
                    vogCurpoint = temp*Int(view.bounds.width)/Int(mailWidth)
                }else if vogCurpoint>0{//240*10以下には動けない
                    vogCurpoint = 0
                }
                print("vogcur",vogCurpoint)
                
                wave3View!.frame=CGRect(x:CGFloat(vogCurpoint),y:vogBoxYmin,width:view.bounds.width*18,height:vogBoxHeight)
             }else{//枠 changed
                if pos.y>view.bounds.height*3/4{
                   return
                }
                if rectType > -1 {//枠の設定の場合
                    //                    let w3=view.bounds.width/3
                    let ww=view.bounds.width
                    let wh=view.bounds.height
                    if rectType == 0 {
                        if faceF==0 || isVHIT==false{//EyeRect
                            let et=CGRect(x:ww/10,y:wh/20,width: ww*4/5,height:wh*3/4)
                            wakuE = moveWakus(rect:wakuE,stRect: stRect,stPo: stPo,movePo: move,hani: et)
                        }else{//vHIT && faceF==true FaceRect
                            let et=CGRect(x:ww/10,y:wh/20,width: ww*4/5,height:wh*3/4)
                            wakuE = moveWakus(rect:wakuE,stRect: stRect,stPo: stPo,movePo: move,hani:et)
                        }
                    }else{
                        //let xt=wakuE.origin.x
                        //let w12=view.bounds.width/12
                        let et=CGRect(x:ww/10,y:wh/20,width: ww*4/5,height:wh*3/4)
                        wakuF = moveWakus(rect:wakuF,stRect:stRect, stPo: stPo,movePo: move,hani:et)
                    }
                    dispWakus()
                    showWakuImages()
                    setUserDefaults()
                }
            }
        }else if sender.state == .ended{
            
            setUserDefaults()
            if vhitBoxView?.isHidden == false{//結果が表示されている時
                if waveTuple.count>0 {
                    for i in 0..<waveTuple.count{
                        if waveTuple[i].3 == 1{
                            waveTuple[i].3 = 2
                        }
                    }
                    drawVHITwaves()
                }
            }
        }
    }
    
    @IBAction func tapFrame(_ sender: UITapGestureRecognizer) {
        print("tapFrame****before")
        if calcFlag == true {
            return
        }
//        if sender.location(in: self.view).y>view.bounds.height*2/3{
//            showWave(0)
//            return
//        }
        if vhitBoxView?.isHidden==false && waveTuple.count>0{
            if sender.location(in: self.view).y > self.view.bounds.width/5 + 160{
            //上に中央vHITwaveをタップで表示させるタップ範囲を設定
                let temp = checksetPos(pos:lastVhitpoint + Int(sender.location(in: self.view).x),mode: 2)
                if temp >= 0{
                    if waveTuple[temp].2 == 1{
                        waveTuple[temp].2 = 0
                    }else{
                        waveTuple[temp].2 = 1
                    }
                }
                
                drawVHITwaves()
//                return
            }
        }else{
            if sender.location(in:self.view).y>view.bounds.height*3/4{
                return
            }
            if faceF==1 && isVHIT==true{
                print("faceF:",faceF)
                if rectType==0{
                    rectType=1
                }else{
                    rectType=0
                }
                dispWakus()
                showWakuImages()
            }
        }
    }
    
    func checksetPos(pos:Int,mode:Int) -> Int{
        let cnt=waveTuple.count
        var return_n = -2
        if cnt>0{
            for i in 0..<cnt{
                if waveTuple[i].1<pos && waveTuple[i].1+120>pos{
                    waveTuple[i].3 = mode //sellected
                    return_n = i
                    break
                }
                waveTuple[i].3 = 0//not sellected
            }
            if return_n > -1 && return_n < cnt{
                for n in (return_n + 1)..<cnt{
                    waveTuple[n].3 = 0
                }
            }
        }else{
            return -1
        }
        return return_n
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
        let sl:CGFloat=10//slope:傾き
        let g1=g5(st:i+1)-g5(st:i)
        let g2=g5(st:i+2)-g5(st:i+1)
        let g3=g5(st:i+3)-g5(st:i+2)
        let ga=g5(st:i+naf-raf+1)-g5(st:i+naf-raf)
        let gb=g5(st:i+naf-raf+2)-g5(st:i+naf-raf+1)
        let gc=g5(st:i+naf+raf+1)-g5(st:i+naf+raf)
        let gd=g5(st:i+naf+raf+2)-g5(st:i+naf+raf+1)
        if g1>4 && g2>g1+1 && g3>g2+1 && ga>sl && gb>sl && gc < -sl && gd < -sl  {
            return 1
        }else if g1 < -4 && g2<g1+1 && g3<g2+1 && ga < -sl && gb < -sl && gc>sl && gd>sl{
            return 0
        }
        return -1
    }
    
    func SetWave2wP(number:Int) -> Int {//-1:波なし 0:上向き波？ 1:その反対向きの波
        let flatwidth:Int = 12//12frame-50ms
        let t = upDownp(i: number + flatwidth)
        //        let t = Getupdownp(num: number,flatwidth:flatwidth)
        //      print("getupdownp:",t)
        if t != -1 {
            let ws = number// - flatwidth + 12;//波表示開始位置 wavestartpoint
            waveTuple.append((t,ws,1,0))//L/R,frameNumber,disp,current)
            let num=waveTuple.count-1
            for k1 in ws..<ws + 120{
                eyeWs[num][k1 - ws] = Int(eyeVeloXFiltered[k1]*CGFloat(eyeRatio)/100.0)
            }
            for k2 in ws..<ws + 120{
                gyroWs[num][k2 - ws] = Int(gyroMoved[k2]*CGFloat(gyroRatio)/100.0)
            }//ここでエラーが出るようだ？
        }
        return t
    }
    
    func calcDrawVHIT(){
        waveTuple.removeAll()
        //       print("calcdrawvhit*****")
        openCVstopFlag = true//計算中はvHITeyeへの書き込みを止める。
        let vHITcnt = eyeVeloXFiltered.count
        if vHITcnt < 400 {
            openCVstopFlag = false
            return
        }
        var skipCnt:Int = 0
        for vcnt in 50..<(vHITcnt - 130) {// flatwidth + 120 までを表示する。実在しないvHITeyeをアクセスしないように！
            if skipCnt > 0{
                skipCnt -= 1
            }else if SetWave2wP(number:vcnt) > -1{
                skipCnt = 30
            }
        }
        openCVstopFlag = false
        drawVHITwaves()
    }
}
