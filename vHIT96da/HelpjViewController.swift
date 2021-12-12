//
//  HelpjViewController.swift
//  vHIT96da
//
//  Created by kuroda tatsuaki on 2018/10/26.
//  Copyright © 2018年 tatsuaki.kuroda. All rights reserved.
//

import UIKit

class HelpjViewController: UIViewController{
    var calcMode:Int?
    var jap_eng:Int=0
    @IBOutlet weak var helpView: UIImageView!
    @IBOutlet weak var exitButton: UIButton!
    @IBOutlet weak var langButton: UIButton!
    var currentImageName:String!
//    var currentHelpY:CGFloat=0
    func setHelpImage(){
        if jap_eng==1{
            if calcMode != 2{
                 currentImageName="vHITen"
            }else{
                currentImageName="VOGen"
            }
            langButton.setTitle("Japanese", for: .normal)
            
        }else{
            if calcMode != 2{
                 currentImageName="vHITja"
            }else{
                currentImageName="VOGja"
            }
              langButton.setTitle("English", for: .normal)
        }
        helpView.image = UIImage(named:currentImageName)!
        let image:UIImage = UIImage(named:currentImageName)!
        // 画像の縦横サイズを取得
        let imgWidth:CGFloat = image.size.width
        let imgHeight:CGFloat = image.size.height
        // 画像サイズをスクリーン幅に合わせる
        let scale:CGFloat = imgHeight / imgWidth
        helpView.frame=CGRect(x:0,y:20,width:view.bounds.width,height: view.bounds.width*scale)
        helpHlimit=view.bounds.width*scale-view.bounds.height
    }
    @IBAction func langChan(_ sender: Any) {
        if jap_eng==0{
            jap_eng=1
        }else{
            jap_eng=0
        }
        setHelpImage()
        UserDefaults.standard.set(0,forKey:"currentHelpY")
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
        langChan(0)//contains setHelpImage()
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

    var helpHlimit:CGFloat=0
    var posYlast:CGFloat=0
    @IBAction func panGestuer(_ sender: UIPanGestureRecognizer) {
        if sender.state == .began {
            posYlast=sender.location(in: self.view).y
        } else if sender.state == .changed {
            let posY = sender.location(in: self.view).y
            let h=helpView.frame.origin.y - posYlast + posY
            if h < 20 && h > -helpHlimit{
                helpView.frame.origin.y -= posYlast-posY
                posYlast=posY
            }
//            print("panGest:",helpHlimit,helpView.frame.origin.y,posY,posYlast)
        }else if sender.state == .ended{
        }
    }
}
