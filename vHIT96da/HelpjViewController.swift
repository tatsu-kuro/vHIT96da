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
    func setHelpImage(){
        let top=CGFloat(UserDefaults.standard.float(forKey: "top"))
        if jap_eng==1{
            if calcMode != 2{
                currentImageName="vHITen"
            }else{
                currentImageName="VOGen"
            }
        }else{
            if calcMode != 2{
                currentImageName="vHITja"
            }else{
                currentImageName="VOGja"
            }
        }
        helpView.image = UIImage(named:currentImageName)!
        let image:UIImage = UIImage(named:currentImageName)!
        // 画像の縦横サイズを取得
        let imgWidth:CGFloat = image.size.width
        let imgHeight:CGFloat = image.size.height
        // 画像サイズをスクリーン幅に合わせる
        let scale:CGFloat = imgHeight / imgWidth
        helpView.frame=CGRect(x:0,y:top,width:view.bounds.width,height: view.bounds.width*scale)
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
    override var prefersStatusBarHidden: Bool {
        return true
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        print("viewdidload")
        if Locale.preferredLanguages.first!.contains("ja"){
            jap_eng=1//langChan()で表示するので０でなくて１
        }else{
            jap_eng=0
        }
        langChan(0)//contains setHelpImage()
        UserDefaults.standard.set(0,forKey:"currentHelpY")
        setButtons()
    }

    func getUserDefaultFloat(str:String,ret:Float) -> Float{
        if (UserDefaults.standard.object(forKey: str) != nil){
            return UserDefaults.standard.float(forKey: str)
        }else{//keyが設定してなければretをセット
            UserDefaults.standard.set(ret, forKey: str)
            return ret
        }
    }
  
    var posYlast:CGFloat=0
    @IBAction func panGestuer(_ sender: UIPanGestureRecognizer) {
        let move=sender.translation(in: self.view)
        let top=CGFloat(UserDefaults.standard.float(forKey: "top"))
        let height=helpView.frame.size.height
        let exitY=exitButton.frame.minY
        if height < exitY-top{
            return
        }
        if sender.state == .began {
            posYlast=helpView.frame.origin.y
        }else if sender.state == .changed {
            let temp=posYlast+move.y
            if temp>top{
                helpView.frame.origin.y=top
            }else if temp+height < exitY{//} && height < exitY-top{
                helpView.frame.origin.y = -height+exitY
            }else{
                helpView.frame.origin.y=temp
            }
            print("helpview:",helpView.frame.origin.y,move.y)
         }else if sender.state == .ended{
        }
    }

    func setButtons(){
        let bottomPadding=CGFloat(UserDefaults.standard.float(forKey: "bottom"))
        let sp:CGFloat=5
        let butw=(view.bounds.width-sp*7)/4
        let buth=butw/2
        let buty=view.bounds.height-sp-buth-bottomPadding
        langButton.frame=CGRect(x:2*sp,y:buty,width:butw,height: buth)
        exitButton.frame=CGRect(x:butw*3+5*sp,y:buty,width:butw,height: buth)
        langButton.layer.cornerRadius = 5
        exitButton.layer.cornerRadius = 5
    }
}
