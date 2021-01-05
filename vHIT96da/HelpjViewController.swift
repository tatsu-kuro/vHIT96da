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
    var isVHIT:Bool?
    var jap_eng:Int=0
    
    @IBOutlet weak var helpView: UIImageView!
    @IBOutlet weak var exitButton: UIButton!
    @IBOutlet weak var langButton: UIButton!
    
    @IBAction func langChan(_ sender: Any) {
        if jap_eng==0{
            jap_eng=1
            helpView.image=UIImage(named:"help2")
            langButton.setTitle("Japanese", for: .normal)
            
        }else{
            jap_eng=0
            helpView.image=UIImage(named:"help1")
            langButton.setTitle("English", for: .normal)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        scrollView.delegate = self
//        scrollView.maximumZoomScale = 2.0
//        scrollView.minimumZoomScale = 1.0
        langButton.layer.cornerRadius = 5
        exitButton.layer.cornerRadius = 5
//        self.view.addSubview(scrollView)
        if isVHIT == true{
            helpView.image = UIImage(named: "help1")
        }else{
            helpView.image = UIImage(named: "help3")
            langButton.isHidden=true
        }
//        print(helpView.frame)
//        hView.frame.origin.x=0
//        hView.frame.origin.y=0
//        hView.frame.size.width=self.view.bounds.width
//        hView.frame.size.height=self.view.bounds.height - 45
        //        imageView.frame = scrollView.frame
//        scrollView.addSubview(hView)
    }
    
//    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
//        return self.hView
//    }

}
