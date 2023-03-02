//
//  HelpjViewController.swift
//  vHIT96da
//
//  Created by kuroda tatsuaki on 2018/10/26.
//  Copyright © 2018年 tatsuaki.kuroda. All rights reserved.
//

import UIKit

class HelpjViewController: UIViewController {
//    let someFunctions = myFunctions()
    let iroiro = myFunctions(albumName: "vHIT_VOG")
  
    var calcMode:Int?

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var exitButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let top=CGFloat(UserDefaults.standard.float(forKey: "top"))
        let bottom=CGFloat(UserDefaults.standard.float(forKey: "bottom"))
        let ww=view.bounds.width
        let wh=view.bounds.height - (top+bottom)
        let sp:CGFloat=5
        let bw=(ww-sp*10)/7//ボタン幅
        let bh=bw
        let by=view.bounds.height-bottom-2*sp-bh

        // 画面サイズ取得
        scrollView.frame = CGRect(x:0,y:top,width: ww,height: wh)
        iroiro.setButtonProperty(exitButton,x:bw*6+sp*8,y:by,w:bw,h:bh,UIColor.darkGray)

        var img = UIImage(named:"vHITen")!
    
        if Locale.preferredLanguages.first!.contains("ja"){
            if calcMode != 2{
                img = UIImage(named:"vHITja")!
            }else{
                img = UIImage(named: "VOGja")!// currentImageName="VOGen"
            }
        }else{
            if calcMode != 2{
                img = UIImage(named:"vHITja")!//currentImageName="vHITja"
            }else{
                img = UIImage(named:"VOGja")!//currentImageName="VOGja"
            }
        }
        
        // 画像のサイズ
        let imgW = img.size.width
        let imgH = img.size.height
        let image = img.resize(size: CGSize(width:ww, height:ww*imgH/imgW))
        // UIImageView 初期化
        let imageView = UIImageView(image: image)
        // UIScrollViewに追加
        scrollView.addSubview(imageView)
        // UIScrollViewの大きさを画像サイズに設定
        scrollView.contentSize = CGSize(width: ww, height: ww*imgH/imgW)
        // スクロールの跳ね返り無し
        scrollView.bounces = true
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }
}
