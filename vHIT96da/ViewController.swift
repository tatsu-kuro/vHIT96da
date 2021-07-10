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
    var appendingDataNow:Bool = false//videoを解析した値をアレイに書き込み中
    var gettingDataNow:Bool = false//VOGimageを作るためにアレイデータを読み込み中
    var vhitCurpoint:Int = 0//現在表示波形の視点（アレイインデックス）
    var vogCurpoint:Int = 0
    var videoPlayer: AVPlayer!
    let vHIT_VOG:String="vHIT_VOG"
    let Wave96da:String="Wave96da"
    
    @IBOutlet weak var waveSlider: UISlider!
    @IBOutlet weak var videoSlider: UISlider!
    //以下はalbum関連
    var albumExist:Bool=false
    var videoArrayCount:Int = 0
    var videoDate = Array<String>()
    var videoDateTime = Array<Date>()//creationDate+durationより１−２秒遅れるpngdate
    var videoURL = Array<URL>()
    var videoImg = Array<UIImage>()
    var videoDura = Array<String>()
    var videoAsset = Array<AVAsset>()
    var videoCurrent:Int=0

    //album関連、ここまで
    
    var vogImage:UIImage?
    @IBOutlet weak var cameraButton: UIButton!
    var boxF:Bool=false
    @IBOutlet weak var modeDispButton: UIButton!
    @IBOutlet weak var changeModeButton: UIButton!
    
    @IBOutlet weak var forwardButton: UIButton!
    @IBOutlet weak var backwardButton: UIButton!
    
    @IBOutlet weak var damyBottom: UILabel!
    
//    func playTrack()//こんな方法もある
//    {
//        let playerItem = AVPlayerItem(url: videoURL[videoCurrent])
//        videoPlayer.replaceCurrentItem(with:playerItem)
//        videoPlayer.play()
//    }
//    func playTrack(number:Int)//こんな方法もある
//    {
//        videoPlayer.replaceCurrentItem(with:AVPlayerItem(url: videoURL[number]))
//        videoPlayer.play()
//    }
    var videoPlayMode:Int = 0//0:playerに任せる 1:backward 2:forward
    @IBAction func onPlayButton(_ sender: Any) {
        if checkDispMode() != 0{
            return
        }
        showBoxies(f: false)
        videoPlayMode=0
//        stopTimerVideo()
        startTimerVideo()
        if (videoPlayer.rate != 0) && (videoPlayer.error == nil) {//playing
            videoPlayer.pause()
        }else{
            videoPlayer.play()
        }
    }
    @IBAction func onForwardButton(_ sender: Any) {
        forwardBackwardButton(mode: 2)
    }
    func forwardBackwardButton(mode:Int){
        if checkDispMode() != 0{
            return
        }
//        stopTimerVideo()
        startTimerVideo()
        if videoURL.count == 0{
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
        forwardBackwardButton(mode: 1)
    }
    
    @IBOutlet weak var wakuEye: UIImageView!
    @IBOutlet weak var wakuEyeb: UIImageView!
    @IBOutlet weak var wakuFace: UIImageView!
    @IBOutlet weak var wakuFaceb: UIImageView!
    
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
    
    @IBOutlet weak var faceWaku_image: UIImageView!
    
    @IBOutlet weak var wakuShowFace_image: UIImageView!
    @IBOutlet weak var wakuShowEye_image: UIImageView!
    
    var wave3View:UIImageView?
    var wakuE = CGRect(x:300.0,y:100.0,width:5.0,height:5.0)
    var wakuF = CGRect(x:300.0,y:200.0,width:5.0,height:5.0)
    
//    @IBOutlet weak var slowImage: UIImageView!
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
    var posRatio:Int = 100//vog
    var veloRatio:Int = 100//vog
    var calcMode:Int?//0:HIThorizontal 1:HITvertical 2:VOG
    var faceF:Int = 0
    var videoGyroZure:Int = 10
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

    
    var faceVeloXOrig = Array<CGFloat>()//faceVeloOrig
    var faceVeloXFiltered = Array<CGFloat>()//faceVeloFiltered
    var faceVeloYOrig = Array<CGFloat>()//faceVeloOrig
    var faceVeloYFiltered = Array<CGFloat>()//faceVeloFiltered
    var gyroHFiltered = Array<CGFloat>()//gyroFiltered
    var gyroVFiltered = Array<CGFloat>()//gyroFiltered
    var gyroMoved = Array<CGFloat>()//gyroVeloFilterd
    
    var timerCalc: Timer!
    var timerVideo:Timer!
    
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
        
        assetFetchOptions.predicate = NSPredicate(format: "title == %@", vHIT_VOG)
        
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
                if videoDate[videoCurrent].contains(date){//
                    if !assets[i].canPerform(.delete) {
                        return
                    }
                    var delAssets=Array<PHAsset>()
                    delAssets.append(assets[i])
                    if i != assets.count-1{//最後でなければ
                        if assets[i+1].duration==0{//pngが無くて、videoが選択されてない事を確認
                            delAssets.append(assets[i+1])//pngはその次に入っているはず
                        }
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
            videoDate.remove(at: videoCurrent)
            videoURL.remove(at: videoCurrent)
            videoImg.remove(at: videoCurrent)
            videoDura.remove(at: videoCurrent)
            videoArrayCount -= 1
            videoCurrent -= 1
            showVideoIroiro(num: 0)
            if videoImg.count==0{
                setVideoButtons(mode: false)
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
        
        assetFetchOptions.predicate = NSPredicate(format: "title == %@", vHIT_VOG)
        
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
                        
                    }else{
                      
                    }
                }
            }
        }
    }
    func showModeText(){
        if calcMode==0{
            modeDispButton.setTitle("vHIT hori", for: .normal)
        }
        else if calcMode==1{
            modeDispButton.setTitle("vHIT vert", for: .normal)
        }
        else{
            modeDispButton.setTitle("VOG", for: .normal)
        }
    }
    @IBAction func onChangeModeButton(_ sender: Any) {
        if calcFlag == true {//|| calcMode != 2{
            return
        }
        calcMode! += 1
        if calcMode!>2{
            calcMode=0
        }
        showModeText()
        setButtons(mode: true)
//        dispWakus()
//        showWakuImages()
        if calcMode != 2{
            if eyeVeloXOrig.count>0 && videoCurrent != -1{
                vhitCurpoint=0
                drawOnewave(startcount: 0)
                calcDrawVHIT()
            }
        }else{
            rectType=0
            if eyeVeloXOrig.count>0  && videoCurrent != -1{
                vogCurpoint=0
                drawVOG2endPt(end: 0)
                drawVogtext()
            }
        }
        showBoxies(f:boxF)
    }
 

    @IBAction func backVideo(_ sender: Any) {
        if vhitLineView?.isHidden == false{
            return
        }
        startFrame=0
        videoPlayMode=0
        showVideoIroiro(num: -1)
    }
    @IBAction func nextVideo(_ sender: Any) {
        if vhitLineView?.isHidden == false{
            return
        }
        startFrame=0
        videoPlayMode=0
        showVideoIroiro(num: 1)
    }
    
    func setVideoButtons(mode:Bool){
        videoSlider.isHidden = !mode
        waveSlider.isHidden = mode
        backwardButton.isEnabled=mode
        forwardButton.isEnabled=mode
        playButton.isEnabled=mode
        eraseButton.isHidden = !mode
    }
    func showVideoIroiro(num:Int){//videosCurrentを移動して、諸々表示
        if videoDura.count == 0{
            print("ないですよ！！！！！！")
            setVideoButtons(mode: false)
            currentVideoDate.text="tap button in lower right corner"
            videoFps.text="to record the video of the eye"
            return
        }
        setVideoButtons(mode: true)
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
//    func expandRectWithBorder(rect:CGRect, border:CGFloat) -> CGRect {
//        //左右には border 、上下には border/2 を広げる
//        //この関数も上と同じようにroundした方がいいかもしれないが、
//        //現状ではscreen座標のみで使っているのでfloatのまま。
//        return CGRect(x:rect.origin.x - border,
//                      y:rect.origin.y - border / 4,
//                      width:rect.size.width + border * 2,
//                      height:rect.size.height + border / 2)
//    }
//    func expandRectError(rect:CGRect, border:CGFloat) -> CGRect {
//        //左右には border 、上下には border/2 を広げる
//        //この関数も上と同じようにroundした方がいいかもしれないが、
//        //現状ではscreen座標のみで使っているのでfloatのまま。
//        return CGRect(x:rect.origin.x - border,
//                      y:rect.origin.y - border ,
//                      width:rect.size.width + border * 2,
//                      height:rect.size.height + border * 2)
//    }
    
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
        startFrame=Int(videoSlider.value*getFPS(url: videoURL[self.videoCurrent]))
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
            timerCalc = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.update_vog), userInfo: nil, repeats: true)
        }
    }
    func showBoxies(f:Bool){
        if f==true && calcMode == 2{//vog wave
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
        }else if f==true && calcMode != 2{//vhit wave
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
    func checkDispMode()->Int{
        if vhitBoxView?.isHidden==false {//vHIT on
            return 1
        }else if vogBoxView?.isHidden==false{//VOG on
            return 2
        }else{//off
            return 0
        }
    }
    @IBAction func showWave(_ sender: Any) {//saveresult record-unwind の２箇所
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
            if checkDispMode()==0{
                setVideoButtons(mode: true)
            }else{
                setVideoButtons(mode: false)
            }
            modeDispButton.isEnabled = true
            changeModeButton.isEnabled = true
            cameraButton.isEnabled = true
//            cameraButton.backgroundColor=UIColor.orange
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
            modeDispButton.isEnabled = false
            changeModeButton.isEnabled = false
            cameraButton.isEnabled = false
            cameraButton.isEnabled = false// backgroundColor=UIColor.gray
         }
    }
    @IBAction func vHITcalc(_ sender: Any) {
        videoPlayer.pause()
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
            if calcMode==2{
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
    
    func vHITcalc(){
        var cvError:Int = 0
        calcFlag = true
        faceVeloXOrig.removeAll()
        faceVeloXFiltered.removeAll()
        faceVeloYOrig.removeAll()
        faceVeloYFiltered.removeAll()
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
        waveSlider.isHidden=false
        videoSlider.isHidden=true
        vogImage = makeVOGimgWakulines(width:mailWidth*18,height:mailHeight)//枠だけ
        //vHITlinewViewだけは消しておく。その他波は１秒後には消えるので、そのまま。
        if vhitLineView != nil{
            vhitLineView?.removeFromSuperview()
        }
        //videoの次のpngからgyroデータを得る。なければ５分間の０のgyroデータを戻す。
        readGyroFromPngOfVideo(videoDate: videoDate[videoCurrent])
        moveGyroData()//gyroDeltastartframe分をズラして
        var vHITcnt:Int = 0
        startTime=CFAbsoluteTimeGetCurrent()
        timercnt = 0
        UIApplication.shared.isIdleTimerDisabled = true//not sleep
//        let eyeborder:CGFloat = CGFloat(eyeBorder)
        //        print("eyeborder:",eyeBorder,faceF)
        startTimerCalc()//resizerectのチェックの時はここをコメントアウト*********************
        let options = [CIDetectorAccuracy: CIDetectorAccuracyHigh]
        let avAsset = AVURLAsset(url: videoURL[videoCurrent], options: options)
        calcDate = currentVideoDate.text!
        //        print("calcdate:",calcDate)
        var fpsIs120:Bool=false
        let fps=getFPS(url: videoURL[videoCurrent])
        var realframeRatio:Float=fps/240
        //これを設定すると頭出ししてもあまりずれない。どのようにデータを作ったのか読み直すのも面倒なので、取り敢えずやってみたら、いい具合。
         if fps<200.0{
            fpsIs120=true
            realframeRatio=fps/120.0
        }
//        print("fps:",getFPS(url: videoURL[videoCurrent]))
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
        let startTime = CMTime(value: CMTimeValue(Float(startFrame)*realframeRatio), timescale: CMTimeScale(frameRate))
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
        let eyeWithBorderRectOnScreen = expandRectWithBorderWide(rect: eyeRectOnScreen, border: CGFloat(eyeBorder))
        
        let faceRectOnScreen=CGRect(x:wakuF.origin.x,y:wakuF.origin.y,width: wakuF.width,height: wakuF.height)
        let faceWithBorderRectOnScreen = expandRectWithBorderWide(rect: faceRectOnScreen, border:CGFloat(eyeBorder))
        
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
//            sleep(UInt32(0.1))
            usleep(1000)//0.001sec
        }
        
        DispatchQueue.global(qos: .default).async { [self] in
            while let sample = readerOutput.copyNextSampleBuffer(), self.calcFlag != false {
                var ex:CGFloat = 0
                var ey:CGFloat = 0
                var eyePosX:CGFloat = 0
                var eyePosY:CGFloat = 0
                var fx:CGFloat = 0
                var fy:CGFloat = 0
                
                #if DEBUG //for test display
                var x:CGFloat = debugDisplayX//wakuShowEye_image.frame.maxX
                let y:CGFloat = debugDisplayY//wakuShowEye_image.frame.minY
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
                        // let eye0CGImage = context.createCGImage(ciImage, from:eyeErrorRect)!
                        let eye0UIImage = UIImage.init(cgImage: eye0CGImage)
                        
                        DispatchQueue.main.async {
                            wakuEye.frame=CGRect(x:x,y:y,width:eyeRect.size.width*2,height:eyeRect.size.height*2)
                            wakuEye.image=eyeUIImage
                            x += eyeRect.size.width*2
                            
                            wakuEyeb.frame=CGRect(x:x,y:y,width:eyeWithBorderRect.size.width*2,height:eyeWithBorderRect.size.height*2)
                            wakuEyeb.image=eyeWithBorderUIImage
                            x += eyeWithBorderRect.size.width*2
                            if faceF==0 || calcMode==2{
                                wakuFaceb.frame=CGRect(x:x,y:y,width:eyebR0.size.width*2,height:eyebR0.size.height*2)
                                wakuFaceb.image=eye0UIImage
                            }
                        }
                        #endif
                        maxEyeV=openCV.matching(eyeWithBorderUIImage,
                                                     narrow: eyeUIImage,
                                                     x: eX,
                                                     y: eY)
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
                            
                            if faceF==1 && calcMode != 2{
                                faceWithBorderCGImage = context.createCGImage(ciImage, from:faceWithBorderRect)!
                                faceWithBorderUIImage = UIImage.init(cgImage: faceWithBorderCGImage)
                                #if DEBUG
                                DispatchQueue.main.async {
                                    if faceF==1&&calcMode != 2{
                                        wakuFace.frame=CGRect(x:x,y:y,width:faceRect.size.width*2,height:faceRect.size.height*2)
                                        wakuFace.image=faceUIImage
                                        x += faceRect.size.width*2
                                        wakuFaceb.frame=CGRect(x:x,y:y,width:faceWithBorderRect.size.width*2,height:faceWithBorderRect.size.height*2)
                                        wakuFaceb.image=faceWithBorderUIImage
                                    }
                                }
                                #endif
                                
                                maxFaceV=openCV.matching(faceWithBorderUIImage, narrow: faceUIImage, x: fX, y: fY)
                                //     while self.openCVstopFlag == true{//vHITeyeを使用中なら待つ
                                //             usleep(1)
                                //     }
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
                    while gettingDataNow==true{//--------の間はアレイデータを書き込まない？
//                        sleep(UInt32(0.1))
                        usleep(1000)//0.001sec
                    }
                    appendingDataNow=true
                    if faceF==1{
                        faceVeloXOrig.append(fx)
                        faceVeloXFiltered.append(-12.0*Kalman(value: fx,num: 0))
                        faceVeloYOrig.append(fy)
                        faceVeloYFiltered.append(-12.0*Kalman(value: fy,num: 1))
                    }else{
                        faceVeloXOrig.append(0)
                        faceVeloXFiltered.append(0)
                        faceVeloYOrig.append(0)
                        faceVeloYFiltered.append(0)
                    }
                    // eyePos, ey, fyをそれぞれ配列に追加
                    // vogをkalmanにかけ配列に追加
                    eyePosXOrig.append(eyePosX)
                    eyePosXFiltered.append( -1.0*Kalman(value:eyePosX,num:2))
                    eyePosYOrig.append(eyePosY)
                    eyePosYFiltered.append( -1.0*Kalman(value:eyePosY,num:3))
                    eyeVeloXOrig.append(ex)
                    let eye5x = -2.0*Kalman(value: ex,num:4)//そのままではずれる
                    eyeVeloXFiltered.append(eye5x-faceVeloXFiltered.last!)

                    eyeVeloYOrig.append(ey)
                    let eye5y = -2.0*Kalman(value: ey,num:5)//そのままではずれる
                    eyeVeloYFiltered.append(eye5y-faceVeloYFiltered.last!)//?
                    appendingDataNow=false//--------------------------------
                    vHITcnt += 1
                    while reader.status != AVAssetReader.Status.reading {
                        usleep(1000)//0.001sec
//                        sleep(UInt32(0.1))
                    }
                    while gettingDataNow==true{//--------の間はアレイデータを書き込まない？
//                        sleep(UInt32(0.1))
                        usleep(1000)//0.001sec
                    }
                    if fpsIs120==true{
                        appendingDataNow=true
                        fps120()//
                        appendingDataNow=false
                    }
                    //eyeのみでチェックしているが。。。。
                    if eyeWithBorderRect.origin.x < 5 ||
                        eyeWithBorderRect.origin.x > maxWidthWithBorder ||
                        eyeWithBorderRect.origin.y < 5 ||
                        eyeWithBorderRect.origin.y > maxHeightWithBorder
                    {
                        calcFlag=false//quit
                    }
                }
                //マッチングデバッグ用スリープ、デバッグが終わったら削除
                #if DEBUG
                usleep(1000)
                #endif
            }
            //            print("time:",CFAbsoluteTimeGetCurrent()-st)
            calcFlag = false
            if waveTuple.count > 0{
                nonsavedFlag = true
            }
        }
    }
    //    func average5(
    func fps120(){
        self.faceVeloXOrig.append(0)
        self.faceVeloXFiltered.append(0)
        self.faceVeloYOrig.append(0)
        self.faceVeloYFiltered.append(0)
        self.eyePosXOrig.append(0)
        self.eyePosXFiltered.append(0)
        self.eyeVeloXOrig.append(0)
        self.eyeVeloXFiltered.append(0)
        self.eyePosYOrig.append(0)
        self.eyePosYFiltered.append(0)
        self.eyeVeloYOrig.append(0)
        self.eyeVeloYFiltered.append(0)
        let i=faceVeloXOrig.count
        if i>3{
            let n1=i-2
            let n2=i-3
            let n3=i-4
            self.faceVeloXOrig[n2]=self.faceVeloXOrig[n1]/2+self.faceVeloXOrig[n3]/2
            self.faceVeloXFiltered[n2]=self.faceVeloXFiltered[n1]/2+self.faceVeloXFiltered[n3]/2
            self.faceVeloYOrig[n2]=self.faceVeloYOrig[n1]/2+self.faceVeloYOrig[n3]/2
            self.faceVeloYFiltered[n2]=self.faceVeloYFiltered[n1]/2+self.faceVeloYFiltered[n3]/2

            self.eyePosXOrig[n2]=self.eyePosXOrig[n1]/2+self.eyePosXOrig[n3]/2
            self.eyePosXFiltered[n2]=self.eyePosXFiltered[n1]/2+self.eyePosXFiltered[n3]/2
            
            self.eyeVeloXOrig[n2]=self.eyeVeloXOrig[n1]/2+self.eyeVeloXOrig[n3]/2
            self.eyeVeloXFiltered[n2]=self.eyeVeloXFiltered[n1]/2+self.eyeVeloXFiltered[n3]/2
 
            self.eyePosYOrig[n2]=self.eyePosYOrig[n1]/2+self.eyePosYOrig[n3]/2
            self.eyePosYFiltered[n2]=self.eyePosYFiltered[n1]/2+self.eyePosYFiltered[n3]/2
            
            self.eyeVeloYOrig[n2]=self.eyeVeloYOrig[n1]/2+self.eyeVeloYOrig[n3]/2
            self.eyeVeloYFiltered[n2]=self.eyeVeloYFiltered[n1]/2+self.eyeVeloYFiltered[n3]/2
        }
    }
    #if DEBUG
    var debugDisplayX:CGFloat=0
    var debugDisplayY:CGFloat=0
    #endif
    func showWakuImages(){//結果が表示されていない時、画面上部1/4をタップするとWaku表示
        if videoDura.count<1 {
            return
        }
        if faceF==1 && calcMode != 2{
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
        print("waku",wakuE.size.width,wakuE.size.height)
        let eyeR = resizeR2(wakuE, viewRect:view.frame,image:ciImage)
        let facR = resizeR2(wakuF, viewRect:view.frame, image: ciImage)
        CGfac = context.createCGImage(ciImage, from: facR)!
        UIfac = UIImage.init(cgImage: CGfac, scale:1.0, orientation:orientation)
        CGeye = context.createCGImage(ciImage, from: eyeR)!
        UIeye = UIImage.init(cgImage: CGeye, scale:1.0, orientation:orientation)
        let wakuY=videoFps.frame.origin.y+videoFps.frame.size.height+5
        wakuShowEye_image.frame=CGRect(x:5,y:wakuY,width: eyeR.size.width*5,height: eyeR.size.height*5)
        #if DEBUG
        debugDisplayX=wakuShowEye_image.frame.maxX
        debugDisplayY=wakuShowEye_image.frame.minY
        #endif
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
        var endPos = CGFloat(end) - 2400
        if CGFloat(end) < 2400{
            endPos=0
        }
        wave3View!.frame=CGRect(x:-endPos*ww/mailWidth,y:vogBoxYmin,width:view.bounds.width*18,height:vogBoxHeight)
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
        vogImage = makeVOGImage(startImg:vogImage!,width:0, height:0, start:0, end:eyePosXOrig.count)
        let drawImage = vogImage!.resize(size: CGSize(width:ww*18, height:vogBoxHeight))
        // 画面に表示する
        wave3View = UIImageView(image: drawImage)
        view.addSubview(wave3View!)
        wave3View!.frame=CGRect(x:0,y:vogBoxYmin,width:view.bounds.width*18,height:vogBoxHeight)
    }

    func getVOGText(orgImg:UIImage,width w:CGFloat,height h:CGFloat,mail:Bool) -> UIImage {
        // イメージ処理の開始]
        if mail{//mailの時は直に貼り付ける
            UIGraphicsBeginImageContext(orgImg.size)
            orgImg.draw(at:CGPoint.zero)
        }else{
            let size = CGSize(width:w, height:h)
            UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
        }// パスの初期化
        let drawPath = UIBezierPath()
        if !mail{//mailの時は時間経過は表示しない
            let timetxt:String = String(format: "%05df (%.1fs/%@) : %ds",eyeVeloXOrig.count,CGFloat(eyeVeloXOrig.count)/240.0,videoDura[videoCurrent],timercnt+1)
            //print(timetxt)
            
            timetxt.draw(at: CGPoint(x: 20, y: 5), withAttributes: [
                            NSAttributedString.Key.foregroundColor : UIColor.black,
                            NSAttributedString.Key.font : UIFont.monospacedDigitSystemFont(ofSize: 70, weight: UIFont.Weight.regular)])
        }
        
        let str1 = calcDate.components(separatedBy: ":")
        let str2 = "ID:" + idString + "  " + str1[0] + ":" + str1[1]
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
        let h=mailHeight
        drawPath.setLineWidth(2.0)
        var pointListXpos = Array<CGPoint>()
        var pointListXvelo = Array<CGPoint>()
        var pointListYpos = Array<CGPoint>()
        var pointListYvelo = Array<CGPoint>()

        let posR=CGFloat(posRatio)/30.0
        let veloR=CGFloat(veloRatio)/10.0
        let py1=(h-240)/5+120
        let py2=(h-240)*2/5+120
        let py3=(h-240)*3/5+120
        let py4=(h-240)*4/5+120
        let dx = 1// xの間隔

        gettingDataNow=true
        while appendingDataNow==true{//--------の間はアレイデータを書き込まない？
            usleep(1000)//0.001sec
        }
        for i in startN..<endN {
            let px = CGFloat(dx * i)
            let pyXpos = eyePosXFiltered[i] * posR + py1
            let pyXvelo = eyeVeloXFiltered[i] * veloR + py2
            let pyYpos = eyePosYFiltered[i] * posR + py3
            let pyYvelo = eyeVeloYFiltered[i] * veloR + py4
            let pntXpos = CGPoint(x: px, y: pyXpos)
            let pntXvelo = CGPoint(x: px, y: pyXvelo)
            let pntYpos = CGPoint(x: px, y: pyYpos)
            let pntYvelo = CGPoint(x: px, y: pyYvelo)
            pointListXpos.append(pntXpos)
            pointListXvelo.append(pntXvelo)
            pointListYpos.append(pntYpos)
            pointListYvelo.append(pntYvelo)
        }
        gettingDataNow=false
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
        drawPath.setStrokeColor(UIColor.blue.cgColor)
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
    
 
    func drawVogtext(){
        if vogLineView != nil{
            vogLineView?.removeFromSuperview()
        }
        let dImage = getVOGText(orgImg:vogImage!,width:mailWidth,height:mailHeight,mail: false)
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
            timerCalc.invalidate()
            setButtons(mode: true)
            UIApplication.shared.isIdleTimerDisabled = false//do sleep
            vogImage=makeVOGImage(startImg: vogImage!, width: 0, height: 0,start:lastArraycount-200, end: eyePosXOrig.count)
            drawVOG2endPt(end: 0)
            if vogLineView != nil{
                vogLineView?.removeFromSuperview()//waveを消して
            }
            drawVogtext()//文字を表示
            setWaveSlider()
            //終わり直前で認識されたvhitdataが認識されないこともあるかもしれない
        }else{
            #if DEBUG
            print("debug-update",timercnt)
            #endif
 
            let cntTemp=eyePosXOrig.count
            vogImage=makeVOGImage(startImg: vogImage!, width: 0, height: 0,start:lastArraycount-200, end: eyePosXOrig.count)
            lastArraycount=eyePosXOrig.count
            drawVOG2endPt(end: cntTemp)
//            print("update_vog",timercnt,cntTemp)
            drawVogtext()
        }
    }
    @objc func onWaveSliderValueChange(){
        let mode=checkDispMode()
//        print("modes:",mode,calcMode)
        if mode==1{//vhit
            vhitCurpoint=Int(waveSlider.value*(waveSlider.maximumValue-Float(view.bounds.width))/waveSlider.maximumValue)
//            print(vhitCurpoint)p
            drawOnewave(startcount: vhitCurpoint)
            lastVhitpoint = vhitCurpoint
            if waveTuple.count>0{
                checksetPos(pos: lastVhitpoint + Int(self.view.bounds.width/2), mode:1)
                drawVHITwaves()
            }
        }else if mode==2{//vog
            if eyePosXFiltered.count<240*10{//||okpMode==1{//240*10以下なら動けない。
                return
            }
            let r = view.bounds.width/CGFloat(mailWidth)
            vogCurpoint = -Int(Float(r)*waveSlider.value*Float(eyePosXFiltered.count-2400))/eyePosXFiltered.count
            wave3View!.frame=CGRect(x:CGFloat(vogCurpoint),y:vogBoxYmin,width:view.bounds.width*18,height:vogBoxHeight)
        }
    }
    func setWaveSlider(){
//        waveSlider.isEnabled=true
        setVideoButtons(mode: false)
        waveSlider.minimumValue = 0
        //count==0の時もエラーにならないのでそのまま
        waveSlider.maximumValue = Float(eyePosXFiltered.count)
        waveSlider.value=0
        waveSlider.addTarget(self, action: #selector(onWaveSliderValueChange), for: UIControl.Event.valueChanged)
        
    }
    var startTime=CFAbsoluteTimeGetCurrent()

    @objc func update_vHIT(tm: Timer) {
        if eyeVeloXFiltered.count < 5 {
            return
        }
        if calcFlag == false {
            vhitCurpoint=0
            //if timer?.isValid == true {
            timerCalc.invalidate()
            setButtons(mode: true)
            //  }
            UIApplication.shared.isIdleTimerDisabled = false
            //            makeBoxies()
            //            calcDrawVHIT()
            //終わり直前で認識されたvhitdataが認識されないこともあるかもしれないので、駄目押し。だめ押し用のcalcdrawvhitは別に作る必要があるかもしれない。
            if self.waveTuple.count > 0{
                self.nonsavedFlag = true
            }
            setWaveSlider()
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
//            let vw=view.bounds.width
//            let vh=view.bounds.height
//            if UIDevice.self.current.model.contains("touch"){//Touch7:320x568->30:120fps
//                videoGyroZure=25
//            }else if vw==414 && vh==736{//7plus:414x736->15(15:120)
//                videoGyroZure=15
//            }else if vw==320 && vh==568{//se:320x568->25(25:120)
//                videoGyroZure=10
//            }else if vw==375 && vh==667{//8:375x667->22(15:120)
//                videoGyroZure=20
//            }else if vw==414 && vh==896{//11:414x896->10(10:120fps)
//                videoGyroZure=10
//            }else{
//                videoGyroZure=10
//            }
            videoGyroZure=10
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
    func getVideosAlbumList(name:String){//最後のvideoを取得するまで待つ
        gettingAlbumF = true
        getAlbumList_sub(name:name)//videosURL,videosDate,videosDuraをゲット
        while gettingAlbumF == true{
            sleep(UInt32(0.1))
        }
        //videosImgだけはここでゲット
        videoImg.removeAll()
        for i in 0..<videoURL.count{
            videoImg.append(getThumb(url: videoURL[i]))
        }
    }
 
    func getAlbumList_sub(name:String){
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
        
        assetFetchOptions.predicate = NSPredicate(format: "title == %@", name)
        
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
        calcMode = getUserDefault(str: "calcMode", ret: 0)
        
        let width=Int(view.bounds.width/2)
        let height=Int(view.bounds.height/3)
        wakuE.origin.x = CGFloat(getUserDefault(str: "wakuE_x", ret:width))
        wakuE.origin.y = CGFloat(getUserDefault(str: "wakuE_y", ret:height))
        wakuLength = getUserDefault(str: "wakuLength", ret: 5)
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
        UserDefaults.standard.set(posRatio, forKey: "posRatio")
        UserDefaults.standard.set(veloRatio, forKey: "veloRatio")
        UserDefaults.standard.set(faceF,forKey: "faceF")
        UserDefaults.standard.set(videoGyroZure,forKey:"videoGyroZure")
        
        UserDefaults.standard.set(Int(wakuE.origin.x), forKey: "wakuE_x")
        UserDefaults.standard.set(Int(wakuE.origin.y), forKey: "wakuE_y")
        UserDefaults.standard.set(Int(wakuF.origin.x), forKey: "wakuF_x")
        UserDefaults.standard.set(Int(wakuF.origin.y), forKey: "wakuF_y")
        UserDefaults.standard.set(calcMode,forKey: "calcMode")
    }
    
    func dispWakus(){
        let nullRect:CGRect = CGRect(x:0,y:0,width:0,height:0)
        if faceF==0{
            rectType=0
        }
        //        printR(str:"wakuE:",rct: wakuE)
        eyeWaku_image.frame=CGRect(x:(wakuE.origin.x)-15,y:wakuE.origin.y-15,width:(wakuE.size.width)+30,height: wakuE.size.height+30)
        if  calcMode==2 || faceF==0{//vHIT 表示無し、補整無し
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
        let y0=gyroBoxHeight*2/6
        let y1=gyroBoxHeight*3/6
        let y2=gyroBoxHeight*4/6
        var py0:CGFloat=0
        for n in 1...(pointCount) {
            if num + n < eyeVeloFilteredCnt && num + n < gyroMovedCnt {
                let px = dx * CGFloat(n)
                if calcMode==0{
                    py0 = eyeVeloXFiltered[num + n] * CGFloat(eyeRatio)/450.0 + y0
                }else{
                    py0 = eyeVeloYFiltered[num + n] * CGFloat(eyeRatio)/450.0 + y0
                }
                if faceF==1{
                    if calcMode==0{
                        py1 = faceVeloXFiltered[num + n] * CGFloat(eyeRatio)/450.0 + y1
                    }else{
                        py1 = faceVeloYFiltered[num + n] * CGFloat(eyeRatio)/450.0 + y1
                    }
                }
                let py2 = gyroMoved[num + n] * CGFloat(gyroRatio)/150.0 + y2
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
    
    func draw1wave(r:CGFloat){//just vHIT
        var pointList = Array<CGPoint>()
        let drawPath = UIBezierPath()
        var rlPt:CGFloat = 0
        for i in 0..<waveTuple.count{//右のvHIT
            if waveTuple[i].2 == 0 || waveTuple[i].0 == 0{
                continue
            }
            for n in 0..<120 {
                let px = 260*r + CGFloat(n)*2*r//260 or 0
                var py:CGFloat = 0
                py = CGFloat(eyeWs[i][n])*r + 90*r
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
            drawPath.lineWidth = 0.3*r
            pointList.removeAll()
        }
        drawPath.stroke()
        drawPath.removeAllPoints()
        for i in 0..<waveTuple.count{//左のvHIT
            if waveTuple[i].2 == 0 || waveTuple[i].0 == 1{
                continue
            }
            for n in 0..<120 {
                let px = CGFloat(n*2)*r//260 or 0
                var py:CGFloat = 0
                py = CGFloat(eyeWs[i][n])*r + 90*r
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
            drawPath.lineWidth = 0.3*r
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
                let px = rlPt*r + CGFloat(n*2)*r
                let py = CGFloat(gyroWs[i][n])*r + 90*r
                let point = CGPoint(x:px,y:py)
                pointList.append(point)
            }
            drawPath.move(to: pointList[0])
            pointList.removeFirst()
            for pt in pointList {
                drawPath.addLine(to: pt)
            }
            UIColor.black.setStroke()
            drawPath.lineWidth = 0.3*r
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
                    let px = rlPt*r + CGFloat( n*2)*r
                    let py = CGFloat(gyroWs[i][n])*r + 90*r
                    let point = CGPoint(x:px,y:py)
                    pointList.append(point)
                }
                drawPath.move(to: pointList[0])
                pointList.removeFirst()
                for pt in pointList {
                    drawPath.addLine(to: pt)
                }
                UIColor.black.setStroke()
                drawPath.lineWidth = 1.0*r
                pointList.removeAll()
                for n in 0..<120 {
                    let px = rlPt*r + CGFloat(n*2)*r
                    var py:CGFloat = 0
                    py = CGFloat(eyeWs[i][n])*r + 90*r
                    let point = CGPoint(x:px,y:py)
                    pointList.append(point)
                }
                drawPath.move(to: pointList[0])
                pointList.removeFirst()
                for pt in pointList {
                    drawPath.addLine(to: pt)
                }
                UIColor.black.setStroke()
                drawPath.lineWidth = 1.0*r
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
        if calcMode==2{
            saveResult_vog(0)
            return
        }
        if waveTuple.count < 1 {
            return
        }
        if vhitBoxView?.isHidden == true{
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
            
            //まずtemp.pngに保存して、それをvHIT_VOGアルバムにコピーする
            saveImage2path(image: drawImage, path: "temp.png")
            while existFile(aFile: "temp.png") == false{
                sleep(UInt32(0.1))
            }
            savePath2album(name:Wave96da,path: "temp.png")
            calcDrawVHIT()//idnumber表示のため
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
    func trimmingImage(_ image: UIImage, trimmingArea: CGRect) -> UIImage {
        let imgRef = image.cgImage?.cropping(to: trimmingArea)
        let trimImage = UIImage(cgImage: imgRef!, scale: image.scale, orientation: image.imageOrientation)
        return trimImage
    }
    func saveResult_vog(_ sender: Any) {//vog
        if calcFlag == true{
            return
        }
        if eyePosXOrig.count == 0{
            return
        }
        let alert = UIAlertController(title: "VOG96da", message: "Input ID", preferredStyle: .alert)
        let saveAction = UIAlertAction(title: "OK", style: .default) { [self] (action:UIAlertAction!) -> Void in

            // 入力したテキストをコンソールに表示
            let textField = alert.textFields![0] as UITextField
            #if DEBUG
            print("\(String(describing: textField.text))")
            #endif
            idString = textField.text!
            drawVogtext()//画面にID表示。
  // イメージビューに設定する
            let pos = -CGFloat(vogCurpoint)*mailWidth/view.bounds.width
            let drawImage=trimmingImage(vogImage!, trimmingArea: CGRect(x:pos,y:0,width: mailWidth,height: mailHeight))
            let imgWithText=getVOGText(orgImg: drawImage, width: mailWidth , height: mailHeight,mail:true)
            
            //まずtemp.pngに保存して、それをvHIT_VOGアルバムにコピーする
            saveImage2path(image: imgWithText, path: "temp.png")
            while existFile(aFile: "temp.png") == false{
                sleep(UInt32(0.1))
            }
            savePath2album(name:Wave96da,path: "temp.png")
            nonsavedFlag = false //解析結果がsaveされたのでfalse
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .default) { (action:UIAlertAction!) -> Void in
        }
        // UIAlertControllerにtextFieldを追加
        alert.addTextField { (textField:UITextField!) -> Void in
            textField.keyboardType = UIKeyboardType.default
//            textField.keyboardType = UIKeyboardType.numberPad
        }
        alert.addAction(cancelAction)//この行と下の行の並びを変えるとCancelとOKの左右が入れ替わる。
        alert.addAction(saveAction)
        present(alert, animated: true, completion: nil)
    }
    
    func drawvhitWaves(width w:CGFloat,height h:CGFloat) -> UIImage {
        let size = CGSize(width:w, height:h)
        var r:CGFloat=1
        if w==500*4{
           r=4
        }
        // イメージ処理の開始
        UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
        // パスの初期化
        let drawPath = UIBezierPath()
        
        let str1 = calcDate.components(separatedBy: ":")
        let str2 = "ID:" + idString + "  " + str1[0] + ":" + str1[1]
        let str3 = "vHIT96da"
        str2.draw(at: CGPoint(x: 5*r, y: 180*r), withAttributes: [
            NSAttributedString.Key.foregroundColor : UIColor.black,
            NSAttributedString.Key.font : UIFont.monospacedDigitSystemFont(ofSize: 15*r, weight: UIFont.Weight.regular)])
        str3.draw(at: CGPoint(x: 428*r, y: 180*4), withAttributes: [
            NSAttributedString.Key.foregroundColor : UIColor.black,
            NSAttributedString.Key.font : UIFont.monospacedDigitSystemFont(ofSize: 15*r, weight: UIFont.Weight.regular)])
        
        UIColor.black.setStroke()
        var pList = Array<CGPoint>()
        pList.append(CGPoint(x:0,y:0))
        pList.append(CGPoint(x:0,y:180*r))
        pList.append(CGPoint(x:240*r,y:180*r))
        pList.append(CGPoint(x:240*r,y:0))
        pList.append(CGPoint(x:260*r,y:0))
        pList.append(CGPoint(x:260*r,y:180*r))
        pList.append(CGPoint(x:500*r,y:180*r))
        pList.append(CGPoint(x:500*r,y:0))
        drawPath.lineWidth = 0.1*r
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
            drawPath.move(to: CGPoint(x:30*r + CGFloat(i)*48*r,y:0))
            drawPath.addLine(to: CGPoint(x:30*r + CGFloat(i)*48*r,y:180*r))
            drawPath.move(to: CGPoint(x:290*r + CGFloat(i)*48*r,y:0))
            drawPath.addLine(to: CGPoint(x:290*r + CGFloat(i)*48*r,y:180*r))
        }
        drawPath.stroke()
        drawPath.removeAllPoints()
        draw1wave(r: r)//just vHIT
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
        "\(riln)".draw(at: CGPoint(x: 3*r, y: 0), withAttributes: [
            NSAttributedString.Key.foregroundColor : UIColor.black,
            NSAttributedString.Key.font : UIFont.monospacedDigitSystemFont(ofSize: 15*r, weight: UIFont.Weight.regular)])
        "\(leln)".draw(at: CGPoint(x: 263*r, y: 0), withAttributes: [
            NSAttributedString.Key.foregroundColor : UIColor.black,
            NSAttributedString.Key.font : UIFont.monospacedDigitSystemFont(ofSize: 15*r, weight: UIFont.Weight.regular)])
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
        showModeText()

        getVideosAlbumList(name:vHIT_VOG)
        videoArrayCount = videoURL.count
        videoCurrent=videoArrayCount-1
        makeBoxies()//three boxies of gyro vHIT vog
        showBoxies(f: false)//isVHITに応じてviewを表示
        self.setNeedsStatusBarAppearanceUpdate()
        dispWakus()
        showVideoIroiro(num:0)
        if videoImg.count==0{
            setVideoButtons(mode: false)
        }else{
            startTimerVideo()
        }
        waveSlider.isHidden=true
    }
    func setButtons_first(){
        let ww=view.bounds.width
        var bw=(ww-30)/4//vhit,camera,vogのボタンの幅
        let distance:CGFloat=4//最下段のボタンとボタンの距離
        let bottomY=damyBottom.frame.minY

        let bh:CGFloat=(ww-20-6*distance)/7//最下段のボタンの高さ、幅と同じ
        let bh1=bottomY-5-bh-bh//2段目
        let bh2=bottomY-10-2.9*bh//videoSlider
        backButton.layer.cornerRadius = 5
        nextButton.layer.cornerRadius = 5
        videoSlider.frame = CGRect(x: 10, y:bh2, width: ww - 20, height: bh)
        videoSlider.thumbTintColor=UIColor.systemYellow
        waveSlider.frame = CGRect(x: 10, y:bh2, width: ww - 20, height: bh)
        waveSlider.thumbTintColor=UIColor.systemBlue
        bw=bh//bhは冒頭で決めている。上２段のボタンの高さと同じ。
        let bwd=bw+distance
        let bh0=bottomY-bh//wh-10-bw/2
        setButtonProperty(button:listButton,bw:bw,bh:bh,x:10+bwd*0,y:bh0)
        setButtonProperty(button:saveButton,bw:bw,bh:bh,x:10+bwd*1,y:bh0)
        setButtonProperty(button:waveButton,bw:bw,bh:bh,x:10+bwd*2,y:bh0)
        setButtonProperty(button:calcButton,bw:bw,bh:bh,x:10+bwd*3,y:bh0)
//        calcButton.backgroundColor=UIColor.blue
        setButtonProperty(button:stopButton,bw:bw,bh:bh,x:10+bwd*3,y:bh0)
//        stopButton.backgroundColor=UIColor.blue
        setButtonProperty(button:paraButton,bw:bw,bh:bh,x:10+bwd*4,y:bh0)
        setButtonProperty(button:cameraButton,bw:bw,bh:bh,x:10+bwd*6,y:bh0)
        setButtonProperty(button:helpButton,bw:bw,bh:bh,x:10+bwd*5,y:bh0)
        setButtonProperty(button:backwardButton,bw:bh,bh:bh,x:10+bwd*4,y:bh1)
        setButtonProperty(button:playButton,bw:bh,bh:bh,x:10+bwd*5,y:bh1)
        setButtonProperty(button:forwardButton,bw:bh,bh:bh,x:10+bwd*6,y:bh1)
        setButtonProperty(button:changeModeButton,bw:bh*2+distance,bh:bh,x:10,y:bh1)
        setButtonProperty(button:modeDispButton,bw:bh*2+distance,bh:bh,x:10+bwd*2,y:bh1)
    }
    func setButtonProperty(button:UIButton,bw:CGFloat,bh:CGFloat,x:CGFloat,y:CGFloat){
        button.frame = CGRect(x:x,y:y,width:bw,height:bh)
        button.layer.borderColor = UIColor.black.cgColor
        button.layer.borderWidth = 1.0
        button.layer.cornerRadius = 5
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
        get {
            return true
        }
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
 
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
   
    func makeAlbum(name:String){
        if albumExists(albumTitle:name )==false{
            createNewAlbum(albumTitle: name) {  isSuccess in
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
    //    var tempCalcflag:Bool = false
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // segueから遷移先のResultViewControllerを取得する
        //      tempCalcflag = calcFlag//別ページに移る時が計算中かどうか
        if let vc = segue.destination as? ParametersViewController {
            let ParametersViewController:ParametersViewController = vc
            //      遷移先のParametersViewControllerで宣言している値に代入して渡す
            ParametersViewController.widthRange = widthRange
            ParametersViewController.waveWidth = waveWidth
            ParametersViewController.calcMode = calcMode
            ParametersViewController.eyeBorder = eyeBorder
            //            ParametersViewController.gyroDelta = gyroDelta
            ParametersViewController.faceF = faceF
            ParametersViewController.wakuLength = wakuLength
            if calcMode != 2{
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

        }else if let vc = segue.destination as? HelpjViewController{
            let Controller:HelpjViewController = vc
            Controller.calcMode = calcMode
        }else if segue.destination is RecordViewController{
            makeAlbum(name: vHIT_VOG)//なければ作る
            makeAlbum(name: Wave96da)//これもなければ作る

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
    func savePath2album(name:String,path:String){
        path2albumDoneFlag=false
        savePath2album_sub(name:name,path: path)
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
            
            wakuLength = ParametersViewController.wakuLength
            wakuE.size.width = CGFloat(wakuLength)
            wakuE.size.height = CGFloat(wakuLength)
            //            gyroDelta = ParametersViewController.gyroDelta
            var chanF=false
            if calcMode != 2{
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
                if calcMode != 2{//データがありそうな時は表示
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
                getVideosAlbumList(name: vHIT_VOG)
                print("rewind***3")
                //ビデオが出来るまで待つ
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
                let gyroImage=openCV.pixel2image(videoImg[videoCurrent], csv: gyroCSV as String)
                //まずtemp.pngに保存して、それをvHIT_VOGアルバムにコピーする
                saveImage2path(image: gyroImage!, path: "temp.png")
                while existFile(aFile: "temp.png")==false{
                    sleep(UInt32(0.1))
                }
                print("rewind***5")

                savePath2album(name:vHIT_VOG,path: "temp.png")
                startFrame=0
                //                getPngsAlbumList()
                //VOGの時もgyrodataを保存する。（不必要だが、考えるべきことが減りそうなので）
            }else{
                if Controller.startButton.isHidden==true && Controller.stopButton.isHidden==true{
                    getVideosAlbumList(name: vHIT_VOG)
                    print("アルバムを消されていたので、録画を保存しなかった。")
                }else{
                    print("Exitで抜けた。")
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

    func moveWakus
    (rect:CGRect,stRect:CGRect,stPo:CGPoint,movePo:CGPoint,hani:CGRect) -> CGRect{
        var r:CGRect
        r = rect//2種類の枠を代入、変更してreturnで返す
        let dx:CGFloat = movePo.x
        let dy:CGFloat = movePo.y
     
        r.origin.x = stRect.origin.x + dx/5//3->5
        r.origin.y = stRect.origin.y + dy/5
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
                if calcMode==2{
                    rectType=0
                }
                if rectType==0{
                    stRect=wakuE
                }else{
                    stRect=wakuF
                }
            }
        } else if sender.state == .changed {
            if calcMode != 2 && vhitBoxView?.isHidden == false{//vhit
                
                
            }else if calcMode == 2 && vogBoxView?.isHidden == false{//vog
                
            }else{//枠 changed
                if pos.y>view.bounds.height*3/4{
                    return
                }
                if rectType > -1 {//枠の設定の場合
                    //                    let w3=view.bounds.width/3
                    let ww=view.bounds.width
                    let wh=view.bounds.height
                    if rectType == 0 {
                        if faceF==0 || calcMode==2{//EyeRect
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
    
    @IBAction func tapGesture(_ sender: UITapGestureRecognizer) {
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
        }else if vhitBoxView?.isHidden==true{
//            let locationX=sender.location(in: self.view).x
            let locationY=sender.location(in: self.view).y
            if locationY>view.bounds.height*3/4{
                //video slide bar と被らないように
                return
            }
            if faceF==1 && calcMode != 2{
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
            if calcMode==0{
                for k1 in ws..<ws + 120{
                    eyeWs[num][k1 - ws] = Int(eyeVeloXFiltered[k1]*CGFloat(eyeRatio)/300.0)
                }
            }else{
                for k1 in ws..<ws + 120{
                    eyeWs[num][k1 - ws] = Int(eyeVeloYFiltered[k1]*CGFloat(eyeRatio)/300.0)
                }
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
        while appendingDataNow==true{//--------の間はアレイデータを書き込まない？
            usleep(1000)//0.001sec
        }
        let vHITcnt = eyeVeloXFiltered.count
        if vHITcnt < 400 {
            return
        }
        var skipCnt:Int = 0
        gettingDataNow=true
        for vcnt in 50..<(vHITcnt - 130) {// flatwidth + 120 までを表示する。実在しないvHITeyeをアクセスしないように！
            
            if skipCnt > 0{
                skipCnt -= 1
            }else if SetWave2wP(number:vcnt) > -1{
                skipCnt = 30
            }
        }
        gettingDataNow = false
        drawVHITwaves()
    }
}
