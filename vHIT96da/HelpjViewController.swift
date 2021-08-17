//
//  HelpjViewController.swift
//  vHIT96da
//
//  Created by kuroda tatsuaki on 2018/10/26.
//  Copyright © 2018年 tatsuaki.kuroda. All rights reserved.
//

import UIKit

class HelpjViewController: UIViewController, UIScrollViewDelegate   {
//    @IBOutlet weak var hView:UIImageView!
//    @IBOutlet weak var scrollView: UIScrollView!
    var calcMode:Int?
    var jap_eng:Int=0
    
    @IBOutlet weak var helpView: UIImageView!
    @IBOutlet weak var exitButton: UIButton!
    @IBOutlet weak var langButton: UIButton!
    
    @IBAction func langChan(_ sender: Any) {
        if jap_eng==0{
            jap_eng=1
            if calcMode != 2{
                helpView.image=UIImage(named:"vHITen")
            }else{
                helpView.image=UIImage(named:"VOGen")
            }
            langButton.setTitle("Japanese", for: .normal)
            
        }else{
            jap_eng=0
            if calcMode != 2{
                helpView.image=UIImage(named:"vHITja")
            }else{
                helpView.image=UIImage(named:"VOGja")
            }
            langButton.setTitle("English", for: .normal)
        }
    }
    func firstLang() -> String {
        let prefLang = Locale.preferredLanguages.first
        return prefLang!
    }
//    func langArray() -> [String] {
//            let prefLang = Locale.preferredLanguages
//            print(prefLang)
//            return prefLang
//    }
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
    }
    
//    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
//        return self.hView
//    }

}
