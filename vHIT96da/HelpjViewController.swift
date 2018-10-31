//
//  HelpjViewController.swift
//  vHIT96da
//
//  Created by kuroda tatsuaki on 2018/10/26.
//  Copyright © 2018年 tatsuaki.kuroda. All rights reserved.
//

import UIKit

class HelpjViewController: UIViewController {
    @IBOutlet weak var hView:UIImageView!
    @IBOutlet weak var scrollView: UIScrollView!
 //1900/3508
    override func viewDidLoad() {
        super.viewDidLoad()
        scrollView.isHidden=true
        hView.isHidden=false
//        if UIApplication.shared.isIdleTimerDisabled == true{
//            UIApplication.shared.isIdleTimerDisabled = false//監視する
//        }
     }
    @IBAction func pinchGes(_ sender: UIPinchGestureRecognizer) {
        if sender.state == .changed {
            if sender.scale < 1.0 {
                hView.isHidden=false
                scrollView.isHidden=true
            } else if sender.scale > 1.1{
                hView.isHidden=true
                scrollView.isHidden=false
            }
        }
    }
}
