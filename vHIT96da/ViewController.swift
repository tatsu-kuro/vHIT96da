//
//  ViewController.swift
//  vHIT96da
//
//  Created by kuroda tatsuaki on 2018/02/10.
//  Copyright © 2018年 tatsuaki.kuroda. All rights reserved.
//
//faceMarkHiddenをtrueにするとマーク補正機能を削除
import UIKit
import AVFoundation
import AssetsLibrary
import Photos
import MessageUI
//import CoreLocation
//import CoreTelephony
//let noFaceMark=true//facemarkが完成したら削除の予定
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
    let iroiro = myFunctions(albumName: "vHIT_VOG")
    var writingDataNow:Bool = false//videoを解析した値をアレイに書き込み中
    var readingDataNow:Bool = false//VOGimageを作るためにアレイデータを読み込み中
    var vhitCurpoint:Int = 0//現在表示波形の視点（アレイインデックス）
    var vogCurpoint:Int = 0
    var videoPlayer: AVPlayer!
    let vHIT_VOG:String="vHIT_VOG"
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
    var videoCurrent:Int=0

    //album関連、ここまで
    
    var vogImage:UIImage?
    @IBOutlet weak var cameraButton: UIButton!
    var boxiesFlag:Bool=false
//    @IBOutlet weak var modeDispButton: UIButton!
    @IBOutlet weak var changeModeButton: UIButton!
    
    @IBOutlet weak var forwardButton: UIButton!
    @IBOutlet weak var backwardButton: UIButton!

 
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
    @IBAction func onForwardButton(_ sender: Any) {
        forwardBackwardButton(mode: 2)
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
        forwardBackwardButton(mode: 1)
    }
    
    @IBOutlet weak var wakuImg1: UIImageView!
    @IBOutlet weak var wakuImg2: UIImageView!
    @IBOutlet weak var wakuImg3: UIImageView!
    @IBOutlet weak var wakuImg4: UIImageView!
    
    var mailWidth:CGFloat=0//VOG
    var mailHeight:CGFloat=0//VOG
    
    @IBOutlet weak var waveBoxView: UIImageView!
    @IBOutlet weak var vogBoxView: UIImageView!
    
    @IBOutlet weak var vHITBoxView: UIImageView!

    var vHITDisplayMode:Int=0

    var faceMarkHidden:Bool=false
    //faceMarkSwitchの無いプログラムにするには上行をtrueに
    
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
    var faceMark:Bool=false
    var videoGyroZure:Int = 20
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
    
    var eyeWs = [[Int]](repeating:[Int](repeating:0,count:125),count:80)
    var gyroWs = [[Int]](repeating:[Int](repeating:0,count:125),count:80)
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
        let assetCollections = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .smartAlbumVideos, options: assetFetchOptions)
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
            //                    break
            //                }
        }
//    }
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
                        
                    }else{//次がpngでないとき。録画失敗して、gyroデータを保存できなかったとき
                        readGyroFromNul()//5min 0
                    }
                }
            }
        }
    }
    func showModeText(){
        if calcMode==0{
            changeModeButton.setImage(  UIImage(systemName:"arrow.left.arrow.right.circle"), for: .normal)
            changeModeButton.setTitle(" vHIT hoirizontal", for: .normal)
        }
        else if calcMode==1{
            changeModeButton.setImage(  UIImage(systemName:"arrow.left.arrow.right.circle"), for: .normal)
            changeModeButton.setTitle(" vHIT vertical", for: .normal)
        }
        else{
            changeModeButton.setImage(  UIImage(systemName:""), for: .normal)//ないものを指定
            changeModeButton.setTitle(" VOG hor. & vert.", for: .normal)
        }
    }
    @IBAction func onChangeModeButton(_ sender: Any) {
        if calcFlag == true || calcMode == 2 || videoDate.count == 0{
            return
        }

        if calcMode==0{
            calcMode=1
        }else{
            calcMode=0
        }

        showModeText()
        setButtons(mode: true)
        dispWakus()
        showWakuImages()
        calcStartTime=CFAbsoluteTimeGetCurrent()//所要時間の起点 update_vog
        if calcMode != 2{
            if eyePosXFiltered.count>0 && videoCurrent != -1{
                vhitCurpoint=0
                drawOneWave(startcount: 0)
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
        forwardButton.isEnabled=mode
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
            timerCalc = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.update_vog), userInfo: nil, repeats: true)
        }
    }
    func showBoxies(f:Bool){
        if f==true && calcMode == 2{//vog wave
            boxiesFlag=true
            vogBoxView?.isHidden = false

            wave3View?.isHidden=false
            vHITBoxView?.isHidden = true

            waveBoxView?.isHidden = true
            setBacknext(f: false)
            eraseButton.isHidden=true
            playButton.isEnabled=false
        }else if f==true && calcMode != 2{//vhit wave
            boxiesFlag=true
            vogBoxView?.isHidden = true
            wave3View?.isHidden=true
            vHITBoxView?.isHidden = false
            waveBoxView?.isHidden = false
            setBacknext(f: false)
            eraseButton.isHidden=true
            playButton.isEnabled=false
        }else{//no wave
            boxiesFlag=false
            vogBoxView?.isHidden = true
            wave3View?.isHidden=true
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
        }else if vogBoxView?.isHidden==false{//VOG on
            return 2
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
            changeModeButton.isEnabled = true
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
            changeModeButton.isEnabled = false
            cameraButton.isEnabled = false
            cameraButton.isEnabled = false// backgroundColor=UIColor.gray
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
                if self.faceMark==true{
                    self.vHITcalcWithMark()
                }else{
                    self.vHITcalc()
                }
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel,handler:{ action in
                self.setButtons(mode: true)
                //         print("****cancel")
            }))
            // アラート表示
            self.present(alert, animated: true, completion: nil)
            //１：直ぐここと２を通る
        }else{
            if faceMark==true{
                vHITcalcWithMark()
            }else{
                vHITcalc()
            }
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
    
    func vHITcalcWithMark(){
        var cvError:Int = 0
        calcFlag = true
        KalmanInit()
        calcStartTime=CFAbsoluteTimeGetCurrent()
        setButtons(mode: false)
        
        setArraysData(type: 0)//removeAll
        setArraysData(type: 1)//append(0)
        
        showBoxies(f: true)
        setWakuImgs(mode: false)
        waveSlider.isHidden=false
        videoSlider.isHidden=true
        vogImage = makeVOGimgWakulines(width:mailWidth*18,height:mailHeight)//枠だけ
        
        if wave3View != nil{
            wave3View?.removeFromSuperview()
        }

        //videoの次のpngからgyroデータを得る。なければ５分間の０のgyroデータを戻す。
        readGyroFromPngOfVideo(videoDate: videoDate[videoCurrent])
        moveGyroData()//gyroDeltastartframe分をズラして
        timercnt = 0
        UIApplication.shared.isIdleTimerDisabled = true//not sleep
        let eyeborder:CGFloat = CGFloat(eyeBorder)
        //        print("eyeborder:",eyeBorder,faceF)
        startTimerCalc()//resizerectのチェックの時はここをコメントアウト*********************
        //        let options = [CIDetectorAccuracy: CIDetectorAccuracyHigh]
        let avasset = iroiro.requestAVAsset(asset: videoPHAsset[videoCurrent])
        calcDate = currentVideoDate.text!
        //        print("calcdate:",calcDate)
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
        let fX = UnsafeMutablePointer<Int32>.allocate(capacity: 1)
        let fY = UnsafeMutablePointer<Int32>.allocate(capacity: 1)
        var eyeWithBorderCGImage:CGImage!
        var eyeWithBorderUIImage:UIImage!
        var faceCGImage:CGImage!
        var faceUIImage:UIImage!
        var faceWithBorderCGImage:CGImage!
        var faceWithBorderUIImage:UIImage!
        
        let eyeRectOnScreen=CGRect(x:wakuE.origin.x, y:wakuE.origin.y, width: wakuE.width, height: wakuE.height)
        let eyeWithBorderRectOnScreen = expandRectWithBorderWide(rect: eyeRectOnScreen, border: eyeborder)
        let eyeBigRectOnScreen = expandRectWithBorderWide(rect: eyeRectOnScreen, border: view.bounds.width/5)//10)
        
        let faceRectOnScreen=CGRect(x:wakuF.origin.x,y:wakuF.origin.y,width: wakuF.width,height: wakuF.height)
        let faceWithBorderRectOnScreen = expandRectWithBorderWide(rect: faceRectOnScreen, border: eyeborder)
        let faceBigRectOnScreen = expandRectWithBorderWide(rect: faceRectOnScreen, border: view.bounds.width/5)//10)
        
        let context:CIContext = CIContext.init(options: nil)
        //            let up = UIImage.Orientation.right
        var sample:CMSampleBuffer!
        stopButton.isEnabled = true
        sample = readerOutput.copyNextSampleBuffer()
        
        let pixelBuffer:CVPixelBuffer = CMSampleBufferGetImageBuffer(sample!)!
        var frameCIImage:CIImage = CIImage(cvPixelBuffer: pixelBuffer).oriented(CGImagePropertyOrientation.right)
        let eyeRect = resizeR2(eyeRectOnScreen, viewRect:view.frame, image:frameCIImage)
        var eyeWithBorderRect = resizeR2(eyeWithBorderRectOnScreen, viewRect:view.frame, image:frameCIImage)
        let eyeBigRect = resizeR2(eyeBigRectOnScreen, viewRect:view.frame, image:frameCIImage)
        
        let faceRect = resizeR2(faceRectOnScreen, viewRect: view.frame, image:frameCIImage)
        var faceWithBorderRect = resizeR2(faceWithBorderRectOnScreen, viewRect:view.frame, image:frameCIImage)
        let faceBigRect = resizeR2(faceBigRectOnScreen, viewRect: view.frame,image: frameCIImage)
        let eyeWithBorderRect0 = eyeWithBorderRect
        let faceWithBorderRect0 = faceWithBorderRect
        
        let eyeCGImage = context.createCGImage(frameCIImage, from: eyeRect)!
        let eyeUIImage = UIImage.init(cgImage: eyeCGImage)
        faceCGImage = context.createCGImage(frameCIImage, from: faceRect)!
        faceUIImage = UIImage.init(cgImage:faceCGImage)
        
        let offsetEyeX:CGFloat = (eyeWithBorderRect.size.width - eyeRect.size.width) / 2.0
        let offsetEyeY:CGFloat = (eyeWithBorderRect.size.height - eyeRect.size.height) / 2.0
        let offsetFaceX:CGFloat = (faceWithBorderRect.size.width - faceRect.size.width) / 2.0
        let offsetFaceY:CGFloat = (faceWithBorderRect.size.height - faceRect.size.height) / 2.0
     
        var maxEyeV:Double = 0
        var maxFaceV:Double = 0
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
                var faceVeloX:CGFloat = 0
                var faceVeloY:CGFloat = 0
                var facePosX:CGFloat = 0
                var facePosY:CGFloat = 0
                autoreleasepool{
                    let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sample)!//27sec:10sec
                    cvError -= 1
                    if cvError <= 0{
                        //orientation.upとrightは所要時間同じ
                        frameCIImage = CIImage(cvPixelBuffer: pixelBuffer).oriented(.right)
                        eyeWithBorderCGImage = context.createCGImage(frameCIImage, from: eyeWithBorderRect)!
                        eyeWithBorderUIImage = UIImage.init(cgImage: eyeWithBorderCGImage)
                        maxEyeV=openCV.matching(eyeWithBorderUIImage,
                                                narrow: eyeUIImage,
                                                x: eX,
                                                y: eY)
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
                            
                            faceWithBorderCGImage = context.createCGImage(frameCIImage, from:faceWithBorderRect)!
                            faceWithBorderUIImage = UIImage.init(cgImage: faceWithBorderCGImage)
                            maxFaceV=openCV.matching(faceWithBorderUIImage, narrow: faceUIImage, x: fX, y: fY)
                            if maxFaceV<0.7{//この時は終了する
                                calcFlag=false
                                eyeWithBorderRect=eyeWithBorderRect0
                            }else{
                                faceVeloX = CGFloat(fX.pointee) - offsetFaceX
                                faceVeloY = -CGFloat(fY.pointee) + offsetFaceY
                                faceWithBorderRect.origin.x += faceVeloX
                                faceWithBorderRect.origin.y += faceVeloY
                                facePosX = faceWithBorderRect.origin.x - faceWithBorderRect0.origin.x// + ex
                                facePosY = faceWithBorderRect.origin.y - faceWithBorderRect0.origin.y// + ey
                             
                            }
                            let fx=(faceWithBorderRect.minX+faceWithBorderRect.maxX)/2
                            let fy=(faceWithBorderRect.minY+faceWithBorderRect.maxY)/2
                            if fx<faceBigRect.minX ||
                                fx>faceBigRect.maxX ||
                                fy<faceBigRect.minY ||
                                fy>faceBigRect.maxY{
                                
                                faceWithBorderRect=faceWithBorderRect0
                            }
                            
                            let ex=(eyeWithBorderRect.minX+eyeWithBorderRect.maxX)/2
                            let ey=(eyeWithBorderRect.minY+eyeWithBorderRect.maxY)/2
                            if ex<eyeBigRect.minX ||
                                ex>eyeBigRect.maxX ||
                                ey<eyeBigRect.minY ||
                                ey>eyeBigRect.maxY{
                                cvError=5
                                eyeWithBorderRect=eyeWithBorderRect0
                            }
                        }
                        context.clearCaches()
                    }
                    while readingDataNow==true{//--------の間はアレイデータを書き込まない？
                        usleep(1000)//0.001sec
                        print("loop-reeding")
                    }
                    writingDataNow=true
     
                    if cvError<0{//matching well done
                        errArray.append(true)
                        eyePosXFiltered.append( -1.0*Kalman(value:eyePosX-facePosX,num:2))//eyePosXOrig.last!,num:2))
                        eyePosYFiltered.append( -1.0*Kalman(value:eyePosY-facePosY,num:3))//Orig.last!,num:3))
                        let cnt=eyePosXFiltered.count
                        eyeVeloXFiltered.append(12*Kalman(value:eyePosXFiltered[cnt-1]-eyePosXFiltered[cnt-2],num:4))
                        eyeVeloYFiltered.append(12*Kalman(value:eyePosYFiltered[cnt-1]-eyePosYFiltered[cnt-2],num:5))
                        
                    }else{//matching error
                        errArray.append(false)
                        KalmanInit()
                        eyePosXFiltered.append(eyePosXFiltered.last!)// -1.0*eyePosXOrig.last!)
                        eyePosYFiltered.append(eyePosXFiltered.last!)// -1.0*eyePosYOrig.last!)
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
                    
                    if calcFlag==true{
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

    
    func vHITcalc(){
        var cvError:Int = 0
        calcFlag = true
        KalmanInit()
        calcStartTime=CFAbsoluteTimeGetCurrent()
        setButtons(mode: false)
        
        setArraysData(type: 0)//removeAll
        setArraysData(type: 1)//append(0)
        
        showBoxies(f: true)
        setWakuImgs(mode: false)
        waveSlider.isHidden=false
        videoSlider.isHidden=true
        vogImage = makeVOGimgWakulines(width:mailWidth*18,height:mailHeight)//枠だけ
        
        if wave3View != nil{
            wave3View?.removeFromSuperview()
        }

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
    func vHITcalcTest(){
        var cvError:Int = 0
        calcFlag = true
        //        KalmanInit()
        //        calcStartTime=CFAbsoluteTimeGetCurrent()
        setButtons(mode: false)
        
        setWakuImgs(mode: true)
        calcButton.isHidden=false
        stopButton.isHidden=true
        calcButton.isEnabled=false
        waveSlider.isHidden=true
        videoSlider.isHidden=false
        //        timercnt = 0
        UIApplication.shared.isIdleTimerDisabled = true//not sleep
        let eyeborder:CGFloat = CGFloat(eyeBorder)
        //        print("eyeborder:",eyeBorder,faceF)
        startTimerCalc()//resizerectのチェックの時はここをコメントアウト*********************
        //        let options = [CIDetectorAccuracy: CIDetectorAccuracyHigh]
        let avasset = iroiro.requestAVAsset(asset: videoPHAsset[videoCurrent])
        calcDate = currentVideoDate.text!
        //        print("calcdate:",calcDate)
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
        let fX = UnsafeMutablePointer<Int32>.allocate(capacity: 1)
        let fY = UnsafeMutablePointer<Int32>.allocate(capacity: 1)
        var eyeWithBorderCGImage:CGImage!
        var eyeWithBorderUIImage:UIImage!
        var faceCGImage:CGImage!
        var faceUIImage:UIImage!
        var faceWithBorderCGImage:CGImage!
        var faceWithBorderUIImage:UIImage!
        
        let eyeRectOnScreen=CGRect(x:wakuE.origin.x, y:wakuE.origin.y, width: wakuE.width, height: wakuE.height)
        let eyeWithBorderRectOnScreen = expandRectWithBorderWide(rect: eyeRectOnScreen, border: eyeborder)
        let eyeBigRectOnScreen = expandRectWithBorderWide(rect: eyeRectOnScreen, border: view.bounds.width/5)//10)
        
        let faceRectOnScreen=CGRect(x:wakuF.origin.x,y:wakuF.origin.y,width: wakuF.width,height: wakuF.height)
        let faceWithBorderRectOnScreen = expandRectWithBorderWide(rect: faceRectOnScreen, border: eyeborder)
        let faceBigRectOnScreen = expandRectWithBorderWide(rect: faceRectOnScreen, border: view.bounds.width/5)//10)
        
        let context:CIContext = CIContext.init(options: nil)
    
        var sample:CMSampleBuffer!
        stopButton.isEnabled = true
        sample = readerOutput.copyNextSampleBuffer()
        
        let pixelBuffer:CVPixelBuffer = CMSampleBufferGetImageBuffer(sample!)!
        var lastCIImage:CIImage = CIImage(cvPixelBuffer: pixelBuffer).oriented(.right)
        let eyeRect = resizeR2(eyeRectOnScreen, viewRect:view.frame, image:lastCIImage)
        var eyeWithBorderRect = resizeR2(eyeWithBorderRectOnScreen, viewRect:view.frame, image:lastCIImage)
        let eyeBigRect = resizeR2(eyeBigRectOnScreen, viewRect:view.frame, image:lastCIImage)
        let faceRect = resizeR2(faceRectOnScreen, viewRect: view.frame, image:lastCIImage)
        var faceWithBorderRect = resizeR2(faceWithBorderRectOnScreen, viewRect:view.frame, image:lastCIImage)
        let faceBigRect = resizeR2(faceBigRectOnScreen, viewRect: view.frame,image: lastCIImage)
        let eyeWithBorderRect0 = eyeWithBorderRect
        let faceWithBorderRect0 = faceWithBorderRect
        
        let eyeCGImage = context.createCGImage(lastCIImage, from: eyeRect)!
        let eyeUIImage = UIImage.init(cgImage: eyeCGImage)
        faceCGImage = context.createCGImage(lastCIImage, from: faceRect)!
        faceUIImage = UIImage.init(cgImage:faceCGImage)
        
        let offsetEyeX:CGFloat = (eyeWithBorderRect.size.width - eyeRect.size.width) / 2.0
        let offsetEyeY:CGFloat = (eyeWithBorderRect.size.height - eyeRect.size.height) / 2.0
        let offsetFaceX:CGFloat = (faceWithBorderRect.size.width - faceRect.size.width) / 2.0
        let offsetFaceY:CGFloat = (faceWithBorderRect.size.height - faceRect.size.height) / 2.0
        var maxEyeV:Double = 0
        var maxFaceV:Double = 0
//        initSum5XY()//平均加算の初期化
        while reader.status != AVAssetReader.Status.reading {
            //            sleep(UInt32(0.1))
            usleep(1000)//0.001sec
        }
     
        DispatchQueue.global(qos: .default).async { [self] in
            while let sample = readerOutput.copyNextSampleBuffer(), self.calcFlag != false {
                var eyeVeloX:CGFloat = 0
                var eyeVeloY:CGFloat = 0
                var faceVeloX:CGFloat = 0
                var faceVeloY:CGFloat = 0
                //for test display
                var x:CGFloat = debugDisplayX//wakuShowEye_image.frame.maxX
                let y:CGFloat = debugDisplayY//wakuShowEye_image.frame.minY
                autoreleasepool{
                    let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sample)!//27sec:10sec
                    cvError -= 1
                    if cvError <= 0{
                        //orientation.upとrightは所要時間同じ
                        lastCIImage = CIImage(cvPixelBuffer: pixelBuffer).oriented(.right)
                        eyeWithBorderCGImage = context.createCGImage(lastCIImage, from: eyeWithBorderRect)!
                        eyeWithBorderUIImage = UIImage.init(cgImage: eyeWithBorderCGImage)
                        let eye0CGImage = context.createCGImage(lastCIImage, from:eyeWithBorderRect0)!
                        // let eye0CGImage = context.createCGImage(ciImage, from:eyeErrorRect)!
                        let eye0UIImage = UIImage.init(cgImage: eye0CGImage)
                        let face0CGImage = context.createCGImage(lastCIImage, from: faceWithBorderRect0)
                        let face0UIImage = UIImage.init(cgImage:face0CGImage!)
                        DispatchQueue.main.async { [self] in
                            if self.wakuEyeFace==0{
                                self.wakuImg2.frame=CGRect(x:x,y:y,width:eyeWithBorderRect.size.width,height:eyeWithBorderRect.size.height)
                                wakuImg2.image=eyeWithBorderUIImage
                                x += eyeWithBorderRect.size.width
                                wakuImg3.frame=CGRect(x:x,y:y,width:eyeWithBorderRect0.size.width,height:eyeWithBorderRect0.size.height)
                                wakuImg3.image=eye0UIImage
                            }else{
                                wakuImg2.frame=CGRect(x:x,y:y,width:faceWithBorderRect.size.width,height:faceWithBorderRect.size.height)
                                wakuImg2.image=faceWithBorderUIImage
                                x += faceWithBorderRect.size.width
                                wakuImg3.frame=CGRect(x:x,y:y,width:faceWithBorderRect0.size.width,height:faceWithBorderRect0.size.height)
                                wakuImg3.image=face0UIImage
                            }
                        }
                        
                        if wakuEyeFace==0{
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
                            }
                            let ex=(eyeWithBorderRect.minX+eyeWithBorderRect.maxX)/2
                            let ey=(eyeWithBorderRect.minY+eyeWithBorderRect.maxY)/2
                            if ex<eyeBigRect.minX ||
                                ex>eyeBigRect.maxX ||
                                ey<eyeBigRect.minY ||
                                ey>eyeBigRect.maxY{
                                cvError=5
                                eyeWithBorderRect=eyeWithBorderRect0
                            }
                        }else{
                            faceWithBorderCGImage = context.createCGImage(lastCIImage, from:faceWithBorderRect)!
                            faceWithBorderUIImage = UIImage.init(cgImage: faceWithBorderCGImage)
                            maxFaceV=openCV.matching(faceWithBorderUIImage, narrow: faceUIImage, x: fX, y: fY)
                            if maxFaceV<0.9{//faceMarkが検出できない時は終了する
                                if cvError==0{
                                    cvError=1
                                }else{
                                    cvError=5
                                }
                                faceWithBorderRect=faceWithBorderRect0
                            }else{
                                faceVeloX = CGFloat(fX.pointee) - offsetFaceX
                                faceVeloY = -CGFloat(fY.pointee) + offsetFaceY
                                faceWithBorderRect.origin.x += faceVeloX
                                faceWithBorderRect.origin.y += faceVeloY
                            }
                            let fx=(faceWithBorderRect.minX+faceWithBorderRect.maxX)/2
                            let fy=(faceWithBorderRect.minY+faceWithBorderRect.maxY)/2
                            if fx<faceBigRect.minX ||
                                fx>faceBigRect.maxX ||
                                fy<faceBigRect.minY ||
                                fy>faceBigRect.maxY{
                                faceWithBorderRect=faceWithBorderRect0
                            }
                        }
                        
                    }
                    context.clearCaches()
                }
                if calcFlag==true{//faceMatchingErrorでない時
                    while reader.status != AVAssetReader.Status.reading {
                        usleep(1000)//0.001sec
                        
                    }
                }
            }
            calcFlag = false//video 終了
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
        if faceMark==true{//} && calcMode != 2{//vhit,vogどちらでも有効とする
            wakuShowFace_image.isHidden=false
        }else{
            wakuShowFace_image.isHidden=true
        }
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
        var CGfac:CGImage!//face
        var UIfac:UIImage!
        let context:CIContext = CIContext.init(options: nil)
        let orientation = UIImage.Orientation.up//right
        var sample:CMSampleBuffer!
        sample = readerOutput.copyNextSampleBuffer()
        let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sample!)!
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer).oriented(.right)
//        print("waku",wakuE.size.width,wakuE.size.height)
        let eyeR = resizeR2(wakuE, viewRect:view.frame,image:ciImage)
        let facR = resizeR2(wakuF, viewRect:view.frame, image: ciImage)
        CGfac = context.createCGImage(ciImage, from: facR)!
        UIfac = UIImage.init(cgImage: CGfac, scale:1.0, orientation:orientation)
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
        wakuShowFace_image.frame=CGRect(x:5,y:wakuY+wakuSizeH+1,width:wakuSizeW,height:wakuSizeH)// eyeR.size.width*5,height: eyeR.size.height*5)
        wakuShowFace_image.layer.borderWidth = 1.0
        wakuShowFace_image.backgroundColor = UIColor.clear
        wakuShowFace_image.layer.cornerRadius = 3
        wakuShowEye_image.image=UIeye
        wakuShowFace_image.image=UIfac
        if wakuEyeFace == 0{
            wakuShowEye_image.layer.borderColor = UIColor.green.cgColor
            wakuShowFace_image.layer.borderColor = UIColor.gray.cgColor
        }else{
            wakuShowEye_image.layer.borderColor = UIColor.gray.cgColor
            wakuShowFace_image.layer.borderColor = UIColor.green.cgColor
        }
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
     
    override func viewDidLoad() {
        super.viewDidLoad()
        #if DEBUG
        print("viewDidLoad******")
        #endif
        dispFilesindoc()//for debug
           //機種にょって異なるVOG結果サイズだったのを2400*1600に統一した
        mailWidth=2400//240*10
        mailHeight=1600//240*10*2/3
         //vHIT結果サイズは500*200
        getUserDefaults()
        setButtons(mode: true)
        stopButton.isHidden = true
        showModeText()
        showBoxies(f: false)//isVHITに応じてviewを表示
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
    
    func drawVOG2endPt(end:Int){//endまでを画面に表示
        if wave3View != nil{
            wave3View?.removeFromSuperview()
        }
        let ww=view.bounds.width
        let drawImage = vogImage!.resize(size: CGSize(width:ww*18, height:ww*2/3))
        // 画面に表示する
        wave3View = UIImageView(image: drawImage)
        view.addSubview(wave3View!)
        var endPos = CGFloat(end) - 2400
        if CGFloat(end) < 2400{
            endPos=0
        }
        wave3View!.frame=CGRect(x:-endPos*ww/mailWidth,y:vogBoxView!.frame.minY,width:ww*18,height:ww*2/3)
     }
 
    func drawVogall(){//すべてのvogを画面に表示 unwindから呼ばれる
        if wave3View != nil{
            wave3View?.removeFromSuperview()
        }
        let ww=view.bounds.width
        vogImage=makeVOGimgWakulines(width: mailWidth*18,height: mailHeight)
        vogImage = makeVOGImage(startImg:vogImage!,width:0, height:0, start:0, end:eyePosXFiltered4update.count)
//        vogImage = makeVOGImage(startImg:vogImage!,width:mailWidth*18, height:mailHeight, start:0, end:eyePosXFiltered4update.count)
        let drawImage = vogImage!.resize(size: CGSize(width:ww*18, height:ww*2/3))
        // 画面に表示する
        wave3View = UIImageView(image: drawImage)
        view.addSubview(wave3View!)
        wave3View!.frame=CGRect(x:0,y:vogBoxView!.frame.minY,width:ww*18,height:ww*2/3)
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
            let time=Int(CFAbsoluteTimeGetCurrent()-calcStartTime)+1
            let timetxt:String = String(format: "%05df (%.1fs/%@) : %ds",arrayDataCount,CGFloat(arrayDataCount)/240.0,videoDura[videoCurrent],time)
            //print(timetxt)
            
            timetxt.draw(at: CGPoint(x: 20, y: 5), withAttributes: [
                            NSAttributedString.Key.foregroundColor : UIColor.black,
                            NSAttributedString.Key.font : UIFont.monospacedDigitSystemFont(ofSize: 70, weight: UIFont.Weight.regular)])
        }
        
        let str1 = calcDate.components(separatedBy: ":")
        let str2 = "ID:" + idString + "  " + str1[0] + ":" + str1[1]
        let str3 = "2s/scale"
        str2.draw(at: CGPoint(x: 20, y: h-100), withAttributes: [
                    NSAttributedString.Key.foregroundColor : UIColor.black,
                    NSAttributedString.Key.font : UIFont.monospacedDigitSystemFont(ofSize: 70, weight: UIFont.Weight.regular)])
        str3.draw(at: CGPoint(x: w-280, y: h-100), withAttributes: [
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
  
        if width==0{
            UIGraphicsBeginImageContext(startImg.size)
            startImg.draw(at: CGPoint.zero)
        }else{
            let size=CGSize(width:width,height:height)
            UIGraphicsBeginImageContextWithOptions(size,false, 1.0)
        }
        let drawPath = UIGraphicsGetCurrentContext()!
        // Draw a red line
        let h=mailHeight//1600 下文字は120
        drawPath.setLineWidth(2.0)
        var pointListXpos = Array<CGPoint>()
        var pointListXvelo = Array<CGPoint>()
        var pointListYpos = Array<CGPoint>()
        var pointListYvelo = Array<CGPoint>()
        
        let posR=CGFloat(posRatio)/30.0
        let veloR=CGFloat(veloRatio)/10.0
        let py1=(h-120)/5
        let py2=(h-120)*2/5
        let py3=(h-120)*3/5
        let py4=(h-120)*4/5
        let dx = 1// xの間隔
        var endN=end
        
        if end>arrayDataCount-1{
            endN=arrayDataCount-1
        }
        if startN>endN{
            return startImg
        }
        var step:Int = 1
        if fpsIs120==true{
            step=2
        }
        
        for i in stride(from: startN, to: endN, by: step){
            
            let px = CGFloat(dx * i)
            
            let pyXpos = eyePosXFiltered4update[i] * posR + py1
            let pyXvelo = eyeVeloXFiltered4update[i] * veloR + py2
            let pyYpos = eyePosYFiltered4update[i] * posR + py3
            let pyYvelo = eyeVeloYFiltered4update[i] * veloR + py4
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
        drawPath.setStrokeColor(UIColor.red.cgColor)
        drawPath.strokePath()
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
        drawPath.setStrokeColor(UIColor.blue.cgColor)
        drawPath.strokePath()
        drawPath.move(to: pointListYvelo[0])
        pointListYvelo.removeFirst()
        for pt in pointListYvelo {
            drawPath.addLine(to: pt)
        }
        drawPath.setStrokeColor(UIColor.black.cgColor)
        drawPath.strokePath()
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        // イメージ処理の終了
        UIGraphicsEndImageContext()
        return image!
    }
    var initDrawVogBoxFlag:Bool=true
    
    func drawVogBoxView(_ img:UIImage){
        // 画面に表示する
         if initDrawVogBoxFlag==true{
             initDrawVogBoxFlag=false
         }else{
             vogBoxView.layer.sublayers?.removeLast()
         }
         vogBoxView.addSubview(UIImageView(image: img))
    }
    func drawVogtext(){
        let ww=view.bounds.width
        let imageWithText = getVOGText(orgImg:vogImage!,width:mailWidth,height:mailHeight,mail: false)
        let drawImage = imageWithText.resize(size: CGSize(width:ww, height:ww*2/3))
        drawVogBoxView(drawImage!)
    }
    
    
    
    
    var initDrawVhitF:Bool=true
    func drawVHITwaves(){//解析結果のvHITwavesを表示する
        let ww=view.bounds.width
        let drawImage = drawvhitWaves(width:500,height:200)
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
    func drawOneWave(startcount:Int){//vHIT_eye_head
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
        let drawImage = drawLine(num:startcnt,width:ww,height:ww*9/16)// 180)
        // イメージビューに設定する

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

    func averagingData(){
        for i in 0..<eyeVeloXFiltered4update.count-6{
            eyeVeloXFiltered4update[i]=average5(filtered: eyeVeloXFiltered4update, i: i)
            eyeVeloYFiltered4update[i]=average5(filtered: eyeVeloYFiltered4update, i: i)
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
    @objc func update_vog(tm: Timer) {
        timercnt += 1
        if matchingTestMode==true{
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
        }
        arrayDataCount = getArrayData()
        if arrayDataCount < 5 {
            return
        }
        if calcFlag == false {//終わったらここ
            arrayDataCount = getArrayData()//念の為
            timerCalc.invalidate()
            setButtons(mode: true)
            autoreleasepool{
                UIApplication.shared.isIdleTimerDisabled = false//do sleep
                vogImage=makeVOGImage(startImg: vogImage!, width: 0, height: 0,start:lastArraycount-100, end: arrayDataCount)
                drawVOG2endPt(end: 0)
                drawVogtext()//文字を表示
                setWaveSlider()
            }
            //終わり直前で認識されたvhitdataが認識されないこともあるかもしれない
        }else{
            #if DEBUG
            print("debug-update",timercnt)
            #endif
 
            autoreleasepool{
                vogImage=makeVOGImage(startImg: vogImage!, width: 0, height: 0,start:lastArraycount-10, end: arrayDataCount)
                
                lastArraycount=arrayDataCount
                drawVOG2endPt(end: arrayDataCount)
                drawVogtext()
            }
        }
    }

    var lastVhitpoint:Int = -2//これはなんだろう→あとでチェック！！！
    @objc func onWaveSliderValueChange(){
        let mode=checkDispMode()
        let ww=view.bounds.width
//        print("modes:",mode,calcMode)
        if mode==1{//vhit
            vhitCurpoint=Int(waveSlider.value*(waveSlider.maximumValue-Float(view.bounds.width))/waveSlider.maximumValue)
//            print(vhitCurpoint)p
            drawOneWave(startcount: vhitCurpoint)
            lastVhitpoint = vhitCurpoint
            if waveTuple.count>0{
                //setするだけか？
                checksetPos(pos: lastVhitpoint + Int(ww/2), mode:1)
                drawVHITwaves()
            }
        }else if mode==2{//vogalc
            if eyePosXFiltered4update.count<240*10{//240*10以下なら動けない。
                return
            }
            let r = view.bounds.width/CGFloat(mailWidth)
            vogCurpoint = -Int(Float(r)*waveSlider.value*Float(eyePosXFiltered4update.count-2400))/eyePosXFiltered4update.count
            wave3View!.frame=CGRect(x:CGFloat(vogCurpoint),y:vogBoxView!.frame.minY,width:ww*18,height:ww*2/3)
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

    @objc func update_vHIT(tm: Timer) {
        
        if matchingTestMode==true{
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
        }
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
        vogImage=makeVOGImage(startImg: vogImage!, width: 0, height: 0,start:lastArraycount, end: arrayDataCount)
        lastArraycount=arrayDataCount
//        drawRealwave()
        drawOneWave(startcount: arrayDataCount)
        timercnt += 1
        #if DEBUG
        print("debug-update",timercnt)
        #endif
        calcDrawVHIT(tuple: true)//waveTupleは更新する。
        if calcFlag==false{
            drawOneWave(startcount: 0)
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
        assetFetchOptions.predicate = NSPredicate(format: "title == %@", "vHIT_VOG")
        let assetCollections = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .smartAlbumVideos, options: assetFetchOptions)
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
    func getAlbumAssets(){
        gettingAlbumF = true
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
    
    func getAlbumAssets_sub(){
        let requestOptions = PHImageRequestOptions()
        videoPHAsset.removeAll()
        videoDura.removeAll()
//        videoURL.removeAll()
        videoDate.removeAll()
        requestOptions.isSynchronous = false
        requestOptions.isNetworkAccessAllowed = false//これでもicloud上のvideoを取ってしまう
        requestOptions.deliveryMode = .highQualityFormat
        // アルバムをフェッチ
        let assetFetchOptions = PHFetchOptions()
        assetFetchOptions.predicate = NSPredicate(format: "title == %@", "vHIT_VOG")
        let assetCollections = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .smartAlbumVideos, options: assetFetchOptions)
        if (assetCollections.count > 0) {//アルバムが存在しない時
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
            gettingAlbumF = false
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
    func getUserDefaults(){
        widthRange = getUserDefault(str: "widthRange", ret: 30)
        waveWidth = getUserDefault(str: "waveWidth", ret: 80)
        eyeBorder = getUserDefault(str: "eyeBorder", ret: 10)
        eyeRatio = getUserDefault(str: "eyeRatio", ret: 100)
        gyroRatio = getUserDefault(str: "gyroRatio", ret: 100)
        posRatio = getUserDefault(str: "posRatio", ret: 100)
        veloRatio = getUserDefault(str: "veloRatio", ret: 100)
        faceMark = getUserDefaultBool(str: "faceMark", ret:false)
        if faceMarkHidden==true{//マークを使わないプログラムの時はtrue
            faceMark=false
        }
//        getVideoGyryoZureDefault()
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
        UserDefaults.standard.set(posRatio, forKey: "posRatio")
        UserDefaults.standard.set(veloRatio, forKey: "veloRatio")
        UserDefaults.standard.set(faceMark,forKey: "faceMark")
 
        UserDefaults.standard.set(videoGyroZure,forKey:"videoGyroZure")
        
        UserDefaults.standard.set(Int(wakuE.origin.x), forKey: "wakuE_x")
        UserDefaults.standard.set(Int(wakuE.origin.y), forKey: "wakuE_y")
        UserDefaults.standard.set(Int(wakuF.origin.x), forKey: "wakuF_x")
        UserDefaults.standard.set(Int(wakuF.origin.y), forKey: "wakuF_y")
        UserDefaults.standard.set(calcMode,forKey: "calcMode")
        UserDefaults.standard.set(vHITDisplayMode,forKey: "vHITDisplayMode")
    }
    
    func dispWakus(){
        let nullRect:CGRect = CGRect(x:0,y:0,width:0,height:0)
        if faceMark==false{
            wakuEyeFace=0
        }
        //        printR(str:"wakuE:",rct: wakuE)
        eyeWaku_image.frame=CGRect(x:(wakuE.origin.x)-15,y:wakuE.origin.y-15,width:(wakuE.size.width)+30,height: wakuE.size.height+30)
        if faceMark==false{//markによる補整無し
            faceWaku_image.frame=nullRect
        }else{
            faceWaku_image.frame=CGRect(x:(wakuF.origin.x)-15,y:wakuF.origin.y-15,width:wakuF.size.width+30,height: wakuF.size.height+30)
        }
        
        if wakuEyeFace==0{
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
#if DEBUG
     print("drawLine:",num,w,h)
#endif
        // 折れ線にする点の配列
        var pointList0 = Array<CGPoint>()
        var pointList2 = Array<CGPoint>()
        let pointCount = Int(w) // 点の個数
        // xの間隔
        let dx:CGFloat = 1//Int(w)/pointCount
        let gyroMovedCnt=gyroMoved.count
        let y1=view.bounds.width*9/32
        var py0:CGFloat=0
        var step:Int = 1
        if fpsIs120==true{
            step=2
        }
        for n in stride(from: 1, to: pointCount, by: step){
            if num + n < arrayDataCount && num + n < gyroMovedCnt {
                let px = dx * CGFloat(n)
                if calcMode==0{
                    py0 = eyeVeloXFiltered4update[num + n] * CGFloat(eyeRatio)/450.0 + y1
                }else{
                    py0 = eyeVeloYFiltered4update[num + n] * CGFloat(eyeRatio)/450.0 + y1
                }
                
                let py2 = -gyroMoved[num + n] * CGFloat(gyroRatio)/150.0 + y1
                let point0 = CGPoint(x: px, y: py0)
                
                let point2 = CGPoint(x: px, y: py2)
                pointList0.append(point0)
                pointList2.append(point2)
            }
        }
        
        // イメージ処理の開始
//        UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
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
        UIColor.red.setStroke()
        drawPath0.stroke()

        UIColor.black.setStroke()
        drawPath2.stroke()
        let timetxt:String = String(format: "%05df (%.1fs/%@) : %ds",arrayDataCount,CGFloat(arrayDataCount)/240.0,videoDura[videoCurrent],timercnt+1)
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
    func draw1wave(r:CGFloat){//just vHIT
        var redVORGainArray = Array<Double>()
        var blueVORGainArray = Array<Double>()

        var pointList = Array<CGPoint>()
        let drawPath = UIBezierPath()
        var rlPt:CGFloat = 0
        //r:4(mail)  r:1(screen)
        var posY0=135*r
        if vHITDisplayMode==0{//up down
            posY0=90*r
        }
        //15(+12)frame 62.5msでの値(eyeSpeed/headSpeed)を集める.EyeSeeCamに準じて
        let gainPoint:Int=27
        for i in 0..<waveTuple.count{
            if waveTuple[i].2==0{//hidden vhit
                continue
            }
            let tempGain=Double(-eyeWs[i][gainPoint])/Double(gyroWs[i][gainPoint])
            if waveTuple[i].0==0{//
                redVORGainArray.append(tempGain)
            }else{
                blueVORGainArray.append(tempGain)
            }
        }
        let redGainAv=getAve(array: redVORGainArray)
        let redGainSd=getSD(array:redVORGainArray,svvAv: redGainAv)
        let blueGainAv=getAve(array: blueVORGainArray)
        let blueGainSd=getSD(array:blueVORGainArray,svvAv: blueGainAv)
        redGainStr = String(format: "(%d) Gain at 60ms     %.2f sd:%.2f",redVORGainArray.count,redGainAv,redGainSd)
        blueGainStr = String(format:"(%d) Gain at 60ms     %.2f sd:%.2f",blueVORGainArray.count,blueGainAv,blueGainSd)
        
        for i in 0..<waveTuple.count{//blue vHIT

            if waveTuple[i].2 == 0 || waveTuple[i].0 == 0{//waveTuple[i].2==0/hide ==1/disp
                continue
            }
            for n in 0..<120 {
                let px = 260*r + CGFloat(n)*2*r//260 or 0
                var py:CGFloat = 0
                if vHITDisplayMode==1{
                    py = -CGFloat(eyeWs[i][n])*r + posY0
                }else{
                    py = CGFloat(eyeWs[i][n])*r + posY0
                }
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
        var py:CGFloat=0
        for i in 0..<waveTuple.count{//red vHIT
            if waveTuple[i].2 == 0 || waveTuple[i].0 == 1{
                continue
            }
            for n in 0..<120 {
                let px = CGFloat(n*2)*r//260 or 0
//                var py:CGFloat = 0
                if vHITDisplayMode==1{//up down red
                    py = CGFloat(eyeWs[i][n])*r + posY0//表示変更
                }else{
                    py = CGFloat(eyeWs[i][n])*r + posY0
                }
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
        for i in 0..<waveTuple.count{//左右のgyroWsを表示
            if waveTuple[i].2 == 0{//.2 hide
                continue
            }
            if waveTuple[i].0 == 0{//gyro leftside
                rlPt=0
            }else{
                rlPt=260
            }
            
            
            for n in 0..<120 {
                let px = rlPt*r + CGFloat(n*2)*r
                if vHITDisplayMode==1{//up up
//                    py = -CGFloat(gyroWs[i][n])*r + posY0//以下４行　表示変更
                    if waveTuple[i].0 == 0{//left side gyro
                        py = -CGFloat(gyroWs[i][n])*r + posY0
                    }else{//right side gyro
                        py = CGFloat(gyroWs[i][n])*r + posY0

                    }
                }else{//up down
                    py = CGFloat(gyroWs[i][n])*r + posY0//以下４行　表示変更

                }
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
        if r>3{//mailでは太線なし
            return
        }
        for i in 0..<waveTuple.count{//太く表示する
            if waveTuple[i].3 == 1 || (waveTuple[i].3 == 2 && waveTuple[i].2 == 1){
                if waveTuple[i].0 == 0{//left side gyro
                    rlPt=0
                }else{
                    rlPt=260
                }
                for n in 0..<120 {
                    let px = rlPt*r + CGFloat( n*2)*r
                    if vHITDisplayMode==1{//up up
                        py = CGFloat(gyroWs[i][n])*r + posY0//以下４行　表示変更
                        if waveTuple[i].0 == 0{
                            py = -CGFloat(gyroWs[i][n])*r + posY0
                        }
                    }else{
                        py = CGFloat(gyroWs[i][n])*r + posY0
                    }
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
                    if vHITDisplayMode==1{//up up
                        py = -CGFloat(eyeWs[i][n])*r + posY0//以下４行　表示変更
                        if waveTuple[i].0 == 0{
                            py = CGFloat(eyeWs[i][n])*r + posY0
                        }
                    }else{
                        py = CGFloat(eyeWs[i][n])*r + posY0
                    }
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
    @IBAction func onSaveButton(_ sender: Any) {//vhit
        
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
            
            //まずtemp.pngに保存して、それをvHIT_VOGアルバムにコピーする
            saveJpegImage2path(image: drawImage, path: "temp.jpeg")
            while existFile(aFile: "temp.jpeg") == false{
                sleep(UInt32(0.1))
            }
            savePath2album(name:Wave96da,path: "temp.jpeg")
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
    func trimmingImage(_ image: UIImage, trimmingArea: CGRect) -> UIImage {
        let imgRef = image.cgImage?.cropping(to: trimmingArea)
        let trimImage = UIImage(cgImage: imgRef!, scale: image.scale, orientation: image.imageOrientation)
        return trimImage
    }
    
    func getVogImgWithText(_ image:UIImage,curPoint:Int)->UIImage{
        let pos = -CGFloat(curPoint)*mailWidth/view.bounds.width
        let imgRef = image.cgImage?.cropping(to: CGRect(x:pos,y:0,width: mailWidth,height: mailHeight))
        let trimImage = UIImage(cgImage: imgRef!, scale: image.scale, orientation: image.imageOrientation)
        let imgWithText=getVOGText(orgImg: trimImage, width: mailWidth , height: mailHeight,mail:true)
        return imgWithText
    }
    
    func saveResult_vog(_ sender: Any) {//vog
        if calcFlag == true{
            return
        }
        if eyePosXFiltered4update.count == 0{
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
            let trimImgWithText=getVogImgWithText(vogImage!, curPoint: vogCurpoint)
//            let pos = -CGFloat(vogCurpoint)*mailWidth/view.bounds.width
//            let drawImage=trimmingImage(vogImage!, trimmingArea: CGRect(x:pos,y:0,width: mailWidth,height: mailHeight))
//            let imgWithText=getVOGText(orgImg: drawImage, width: mailWidth , height: mailHeight,mail:true)
//
            //まずtemp.pngに保存して、それをvHIT_VOGアルバムにコピーする
            saveJpegImage2path(image: trimImgWithText, path: "temp.jpeg")
            while existFile(aFile: "temp.jpeg") == false{
                sleep(UInt32(0.1))
            }
            savePath2album(name:Wave96da,path: "temp.jpeg")
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
        var r:CGFloat=1//r:倍率magnification
        if w==500*4{//mail
           r=4
        }
        // イメージ処理の開始
        UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
        // パスの初期化
        let drawPath = UIBezierPath()
        
        let str1 = calcDate.components(separatedBy: ":")
        let str2 = "ID:" + idString + "  "// + str1[0] + ":" + str1[1]
        let str3 = str1[0] + ":" + str1[1]// + "   vHIT96da"
        let str4 = "vHIT96da"
        str2.draw(at: CGPoint(x: 5*r, y: 180*r), withAttributes: [
            NSAttributedString.Key.foregroundColor : UIColor.black,
            NSAttributedString.Key.font : UIFont.monospacedDigitSystemFont(ofSize: 15*r, weight: UIFont.Weight.regular)])
        str3.draw(at: CGPoint(x: 258*r, y: 180*r), withAttributes: [
            NSAttributedString.Key.foregroundColor : UIColor.black,
            NSAttributedString.Key.font : UIFont.monospacedDigitSystemFont(ofSize: 15*r, weight: UIFont.Weight.regular)])
        str4.draw(at: CGPoint(x: 425*r, y: 180*r), withAttributes: [
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

        blueGainStr.draw(at: CGPoint(x: 263*r, y: 167*r-167*r), withAttributes: [
            NSAttributedString.Key.foregroundColor : UIColor.black,
            NSAttributedString.Key.font : UIFont.monospacedDigitSystemFont(ofSize: 12*r, weight: UIFont.Weight.regular)])
        redGainStr.draw(at: CGPoint(x: 3*r, y: 167*r-167*r), withAttributes: [
            NSAttributedString.Key.foregroundColor : UIColor.black,
            NSAttributedString.Key.font : UIFont.monospacedDigitSystemFont(ofSize: 12*r, weight: UIFont.Weight.regular)])

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
        vHITBoxView?.frame=CGRect(x:0,y:wh*160/568-ww/5,width :ww,height:ww*2/5)
        
        waveBoxView?.frame=CGRect(x:0,y:wh*340/568-ww*90/320,width:ww,height: ww*180/320)
        vogBoxView?.frame=CGRect(x:0,y:wh/2-ww/3,width:ww,height: ww*2/3)

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
        iroiro.setButtonProperty(cameraButton,x:sp*8+bw*6,y:by0,w:bw,h:bh,UIColor.systemRed)
        
        iroiro.setButtonProperty(backwardButton,x:sp*6+bw*4,y:by1,w:bw,h:bh,UIColor.systemOrange)
        iroiro.setButtonProperty(playButton,x:sp*7+bw*5,y:by1,w:bw,h:bh,UIColor.systemOrange)
        iroiro.setButtonProperty(forwardButton,x:sp*8+bw*6,y:by1,w:bw,h:bh,UIColor.systemOrange)
        iroiro.setButtonProperty(changeModeButton,x:sp*2,y:by1,w:bh*3+sp*2,h:bh,UIColor.darkGray)
        
        if videoDate.count == 0{
            playButton.isEnabled=false
            forwardButton.isEnabled=false
            backwardButton.isEnabled=false
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
            ParametersViewController.faceMarkHidden = faceMarkHidden
            ParametersViewController.widthRange = widthRange
            ParametersViewController.waveWidth = waveWidth
            ParametersViewController.calcMode = calcMode
            ParametersViewController.eyeBorder = eyeBorder
            //            ParametersViewController.gyroDelta = gyroDelta
            ParametersViewController.faceMark = faceMark
            ParametersViewController.wakuLength = wakuLength
//            if calcMode != 2{
                ParametersViewController.eyeRatio = eyeRatio
                ParametersViewController.gyroRatio = gyroRatio
                ParametersViewController.videoGyroZure=videoGyroZure
                ParametersViewController.vHITDisplayMode=vHITDisplayMode
//            }else{
                ParametersViewController.posRatio = posRatio
                ParametersViewController.veloRatio = veloRatio
//            }
            #if DEBUG
            print("prepare para")
            #endif

        }else if let vc = segue.destination as? HelpjViewController{
            let Controller:HelpjViewController = vc
            Controller.calcMode = calcMode
        }else if let vc = segue.destination as? RecordViewController{
            let Controller:RecordViewController = vc
            iroiro.makeAlbum(vHIT_VOG)//なければ作る
            iroiro.makeAlbum(Wave96da)//これもなければ作る
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
            calcMode=ParametersViewController.calcMode
       
            var chanF=false
            eyeRatio=ParametersViewController.eyeRatio
            gyroRatio=ParametersViewController.gyroRatio
            faceMark=ParametersViewController.faceMark
//            if calcMode==2{//vogの時はfaceMarkはなし
//                faceMark=false
//            }
            videoGyroZure=ParametersViewController.videoGyroZure
            vHITDisplayMode=ParametersViewController.vHITDisplayMode
            if posRatio != ParametersViewController.posRatio ||
                veloRatio != ParametersViewController.veloRatio{
                chanF=true
            }
            posRatio=ParametersViewController.posRatio
            veloRatio=ParametersViewController.veloRatio
            setUserDefaults()
            if eyeVeloXFiltered.count > 400 && videoDate.count>0{
                if calcMode != 2{//データがありそうな時は表示
                    moveGyroData()
                    calcDrawVHIT(tuple: false)
                    drawOneWave(startcount: vhitCurpoint)//gyroFileがないとエラー
                }else{
                    if chanF==true{
                        vogCurpoint=0
                        drawVogall()
//                        drawVOG2endPt(end:100000)
                        drawVogtext()
                    }
                }
            }
            dispWakus()
            if boxiesFlag==false{
                showBoxies(f: false)
            }else{
                showBoxies(f: true)
            }
            showModeText()
            #if DEBUG
            print("TATSUAKI-unwind from para")
            #endif
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
//                getVideosAlbumList(name: vHIT_VOG)
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
                //まずtemp.pngに保存して、それをvHIT_VOGアルバムにコピーする
                savePngImage2path(image: gyroImage!, path: "temp.png")
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
//                    getVideosAlbumList(name: vHIT_VOG)
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

    var tapPosleftRight:Int=0//left-eye,right=head最初にタップした位置で
    var startEyeGyroPoint = CGPoint(x:0,y:0)//eye,gyro
    var startZure:CGFloat=0
  //  var startPoint = CGPoint(x:0,y:0)
    var moveThumX:CGFloat=0
    var moveThumY:CGFloat=0
    var wakuEyeFace:Int = 0//0:eye 1:face
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
            moveThumX=0
            moveThumY=0
            if checkDispMode()==0{
                if wakuEyeFace==0{
                    startRect=wakuE
                }else{
                    startRect=wakuF
                }
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
                if videoGyroZure>100{
                    videoGyroZure = 100
                }else if videoGyroZure<1{
                    videoGyroZure = 1
                }
                if eyeRatio>4000{
                    eyeRatio=4000
                }else if eyeRatio<10{
                    eyeRatio=10
                }
                moveGyroData()
                calcDrawVHIT(tuple: false)
                drawOneWave(startcount: vhitCurpoint)
                }
//                print("vhit-1:",videoGyroZure,eyeRatio,gyroRatio)
            }else if calcMode == 2 && vogBoxView?.isHidden == false{//vog

            }else{//枠 changed
                if pos.y>view.bounds.height*3/4{
                    return
                }
                    let ww=view.bounds.width
                    let wh=view.bounds.height
                    if wakuEyeFace == 0 {//eyeRect
                            let et=CGRect(x:ww/10,y:wh/20,width: ww*4/5,height:wh*3/4)
                            wakuE = moveWakus(rect:wakuE,stRect: startRect,movePo: move,hani:et)
                    }else{
                        //let xt=wakuE.origin.x
                        //let w12=view.bounds.width/12
                        let et=CGRect(x:ww/10,y:wh/20,width: ww*4/5,height:wh*3/4)
                        wakuF = moveWakus(rect:wakuF,stRect:startRect,movePo: move,hani:et)
                    }
                    dispWakus()
                    showWakuImages()
                    setUserDefaults()
//                }
            }
        }else if sender.state == .ended{
            setUserDefaults()
            if vHITBoxView?.isHidden == false{//結果が表示されている時
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
    func setWakuImgs(mode:Bool){
        wakuImg1.isHidden = !mode
        wakuImg2.isHidden = !mode
        wakuImg3.isHidden = !mode
        wakuImg4.isHidden = !mode
    }
    @IBAction func tapGesture(_ sender: UITapGestureRecognizer) {
        if videoDate.count==0{
            return
        }
        let loc=sender.location(in: view)
        let eyeFrame=eyeWaku_image.frame
        let faceFrame=faceWaku_image.frame
        //checkDispMode() 1-vHIT 2-VOG 0-non
        let vHIT_VOG=checkDispMode()
        if vHIT_VOG==1 {//vhit
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
                drawOneWave(startcount: vhitCurpoint)
                return
            }else if loc.y<waveBoxView!.frame.maxY && waveTuple.count>0{
                //上に中央vHITwaveをタップで表示させるタップ範囲を設定
                let temp = checksetPos(pos:lastVhitpoint + Int(loc.x),mode: 2)
                if temp >= 0{
                    if waveTuple[temp].2 == 1{
                        waveTuple[temp].2 = 0//hide
                     }else{
                        waveTuple[temp].2 = 1//disp
                    }
//                    print("waveTuple:",waveTuple[temp].2)
                }
                drawVHITwaves()
            }
        }else if vHIT_VOG==2{//vog
            if loc.y<vogBoxView!.frame.minY || (loc.y>vogBoxView!.frame.maxY && loc.y<waveSlider.frame.minY-20){
                if timerCalc?.isValid == false {//計算中でなく、表示枠以外を押した時
                    onWaveButton(0)
                    return
                }
            }
        }else{//波形が表示されていないとき
            if (loc.x>eyeFrame.minX && loc.x<eyeFrame.maxX && loc.y>eyeFrame.minY && loc.y<eyeFrame.maxY && wakuEyeFace==0)||(loc.x>faceFrame.minX && loc.x<faceFrame.maxX && loc.y>faceFrame.minY && loc.y<faceFrame.maxY && wakuEyeFace==1){
                if calcFlag==false && boxiesFlag==false{//within waku
                    matchingTestMode=true
                    vHITcalcTest()
                    nextButton.isHidden=true
                    backButton.isHidden=true
                    eraseButton.isHidden=true
                    videoSlider.isEnabled=false
                    return
                }
            }
            if calcFlag==true {//計算中
                if matchingTestMode==true{//testMode計算中なら
                    calcFlag=false
                    nextButton.isHidden=false
                    backButton.isHidden=false
                    eraseButton.isHidden=false
                    videoSlider.isEnabled=true
                }
                return
            }
            if wakuImg2.isHidden==false||wakuImg3.isHidden==false{//testModeの表示があるとき
                wakuImg2.isHidden=true
                wakuImg3.isHidden=true
                return
            }
            if loc.y > videoSlider.frame.minY-20{//video slide bar と被らないように
                return
            }
            if faceMark==true{//選択枠を変更
                if wakuEyeFace==0{
                    wakuEyeFace=1
                }else{
                    wakuEyeFace=0
                }
//                print("faceMark:",faceMark,wakuEyeFace)
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
        let sl:CGFloat=5//slope:傾き　遠藤様の検査で捕まらないので10->5に変更してみる 20220715
        let g1=g5(st:i+1)-g5(st:i)
        let g2=g5(st:i+2)-g5(st:i+1)
        let g3=g5(st:i+3)-g5(st:i+2)
        let ga=g5(st:i+naf-raf+1)-g5(st:i+naf-raf)
        let gb=g5(st:i+naf-raf+2)-g5(st:i+naf-raf+1)
        let gc=g5(st:i+naf+raf+1)-g5(st:i+naf+raf)
        let gd=g5(st:i+naf+raf+2)-g5(st:i+naf+raf+1)
//        if g1>4 && g2>g1+1 && g3>g2+1 && ga>sl && gb>sl && gc < -sl && gd < -sl  {
//            return 1
//        }else if g1 < -4 && g2<g1+1 && g3<g2+1 && ga < -sl && gb < -sl && gc>sl && gd>sl{
//            return 0
//        }
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
        let t = upDownp(i: number + flatwidth)
        if t != -1 {
            let ws = number// - flatwidth + 12;//波表示開始位置 wavestartpoint
            waveTuple.append((t,ws,1,0))//L/R,frameNumber,disp,current)
            let num=waveTuple.count-1
            
            if calcMode==0{
                for k1 in ws..<ws + 120{
                    eyeWs[num][k1 - ws] = Int(eyeVeloXFiltered4update[k1]*CGFloat(eyeRatio)/300.0)
                }
            }else{
                for k1 in ws..<ws + 120{
                    eyeWs[num][k1 - ws] = Int(eyeVeloYFiltered4update[k1]*CGFloat(eyeRatio)/300.0)
                }
            }

            for k2 in ws..<ws + 120{
                gyroWs[num][k2 - ws] = Int(gyroMoved[k2]*CGFloat(gyroRatio)/100.0)
            }//ここでエラーが出るようだ？
            
        }
        return t
    }
   //wavetuple変更の有無、高さ(%)表示変更の時はwavetupleは変更しない。
    func calcDrawVHIT(tuple:Bool){//true:
        tempTuple.removeAll()
        for i in 0..<waveTuple.count{
            tempTuple.append(waveTuple[i])
        }
//        print(tempTuple.count,waveTuple.count)
        waveTuple.removeAll()
//        print(tempTuple.count,waveTuple.count)
        if arrayDataCount < 400 {
            return
        }
        var skipCnt:Int = 0
        for vcnt in 50..<(arrayDataCount - 130) {// flatwidth + 120 までを表示する。実在しないvHITeyeをアクセスしないように！
            
            if skipCnt > 0{
                skipCnt -= 1
            }else if SetWave2wP(number:vcnt) > -1{
                skipCnt = 30
            }
        }
        if tuple==false{
            waveTuple.removeAll()
            for i in 0..<tempTuple.count{
                waveTuple.append(tempTuple[i])
            }
        }
        drawVHITwaves()
    }
}
