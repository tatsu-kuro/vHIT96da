//
//  HelpjViewController.swift
//  vHIT96da
//
//  Created by kuroda tatsuaki on 2018/10/26.
//  Copyright © 2018年 tatsuaki.kuroda. All rights reserved.
//

import UIKit

class HelpjViewController: UIViewController{
//    @IBOutlet weak var hView:UIImageView!
//    @IBOutlet weak var scrollView: UIScrollView!
    var calcMode:Int?
    var jap_eng:Int=0
//    let noFaceMark=true
//    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var helpView: UIImageView!
    //    @IBOutlet weak var helpView: UIImageView!
    @IBOutlet weak var exitButton: UIButton!
    @IBOutlet weak var langButton: UIButton!
    var currentImageName:String!
    var currentHelpY:CGFloat=0
    func setHelpImage(){
        if jap_eng==1{
//            jap_eng=1
            if calcMode != 2{
                //                helpView.image=UIImage(named:"vHITen")
//                initHelpView(img: "vHITen")
                currentImageName="vHITen"
            }else{
//                initHelpView(img:"VOGen")
//                helpView.image=UIImage(named:"VOGen")
                currentImageName="VOGen"
            }
            langButton.setTitle("Japanese", for: .normal)
            
        }else{
//            jap_eng=0
            if calcMode != 2{
                //                helpView.image=UIImage(named:"vHITja")
//                initHelpView(img: "vHITja")
                currentImageName="vHITja"
            }else{
//                initHelpView(img: "VOGja")
//                helpView.image=UIImage(named:"VOGja")
                currentImageName="VOGja"
            }
              langButton.setTitle("English", for: .normal)
        }
        initHelpView(img:currentImageName,move:0)
    }
    @IBAction func langChan(_ sender: Any) {
        if jap_eng==0{
            jap_eng=1
        }else{
            jap_eng=0
        }
        UserDefaults.standard.set(0,forKey:"currentHelpY")
        setHelpImage()
    }
    func firstLang() -> String {
        let prefLang = Locale.preferredLanguages.first
        return prefLang!
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        print("language:",firstLang())
        if firstLang().contains("ja"){
            jap_eng=1//langChan()で表示するので０でなくて１
        }else{
            jap_eng=0
        }
        langButton.layer.cornerRadius = 5
        exitButton.layer.cornerRadius = 5
        langChan(0)
        UserDefaults.standard.set(0,forKey:"currentHelpY")
    }
    
    func getUserDefaultFloat(str:String,ret:Float) -> Float{
        if (UserDefaults.standard.object(forKey: str) != nil){
            return UserDefaults.standard.float(forKey: str)
        }else{//keyが設定してなければretをセット
            UserDefaults.standard.set(ret, forKey: str)
            return ret
        }
    }
//    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
//        return self.hView
//    }
//    func initImageView(img:String){
//        // UIImage インスタンスの生成
//        let image1:UIImage = UIImage(named:img)!
//        
//        // UIImageView 初期化
//        let imageView = UIImageView(image:image1)
//        
//        // スクリーンの縦横サイズを取得
//        let screenWidth:CGFloat = view.frame.size.width
//        let screenHeight:CGFloat = view.frame.size.height
//        
//        // 画像の縦横サイズを取得
//        let imgWidth:CGFloat = image1.size.width
//        let imgHeight:CGFloat = image1.size.height
//        
//        // 画像サイズをスクリーン幅に合わせる
//        let scale:CGFloat = screenWidth / imgWidth
//        let rect:CGRect =
//            CGRect(x:0, y:0, width:imgWidth*scale, height:imgHeight*scale)
//        
//        // ImageView frame をCGRectで作った矩形に合わせる
//        imageView.frame = rect;
//        
//        // 画像の中心を画面の中心に設定
//        imageView.center = CGPoint(x:screenWidth/2, y:screenHeight/2)
//        
//        // UIImageViewのインスタンスをビューに追加
//        self.view.addSubview(imageView)
//        
//    }
    func initHelpView(img:String,move:CGFloat){
        var moveY=move
        // UIImage インスタンスの生成
        let image1:UIImage = UIImage(named:img)!
        
        // UIImageView 初期化
        let imageView = UIImageView(image:image1)
        
        // スクリーンの縦横サイズを取得
        let screenWidth:CGFloat = view.bounds.width//helpView.frame.size.width
        let screenHeight:CGFloat = view.bounds.height//helpView.frame.size.height
        
        // 画像の縦横サイズを取得
        let imgWidth:CGFloat = image1.size.width
        let imgHeight:CGFloat = image1.size.height
        
        // 画像サイズをスクリーン幅に合わせる
        let scale:CGFloat = screenWidth / imgWidth
        
//        if moveY>0{
//            moveY=0
//        }else if moveY < -150{//helpView.frame.height-screenHeight{
//            moveY = -150//helpView.frame.height-screenHeight
//        }
        
        let rect:CGRect =
            CGRect(x:0, y:moveY, width:imgWidth*scale, height:imgHeight*scale)
   //     print(screenHeight,helpView.frame.height,moveY)
     //   print(rect,view.bounds,helpView.frame)
        // ImageView frame をCGRectで作った矩形に合わせる
        imageView.frame = rect;
        
        // 画像の中心を画面の中心に設定
//        imageView.center = CGPoint(x:screenWidth/2, y:screenHeight/2)
        
        // UIImageViewのインスタンスをビューに追加
        helpView.addSubview(imageView)
    }
    
    var startPoint:CGPoint!
    @IBAction func panGestuer(_ sender: UIPanGestureRecognizer) {
        let pos = sender.location(in: self.view)
       
        if sender.state == .began {
            
            currentHelpY=CGFloat(UserDefaults.standard.integer(forKey:"currentHelpY"))
            startPoint = sender.location(in: self.view)

        } else if sender.state == .changed {
            let move=pos.y-startPoint.y
//            if move < -100{
//                move = -100
//            }else if move>0{
//                move=0
//            }
            currentHelpY += move
            if currentHelpY < -100{
                currentHelpY = -100
            }else if currentHelpY>0{
                currentHelpY=0
            }
            UserDefaults.standard.set(currentHelpY, forKey:"currentHelpY")
            initHelpView(img: currentImageName, move:currentHelpY)
        }else if sender.state == .ended{
         
        }
    }
}
