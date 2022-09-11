//
//  ARKitViewController.swift
//  vHIT96da
//
//  Created by 黒田建彰 on 2022/09/08.
//  Copyright © 2022 tatsuaki.kuroda. All rights reserved.
//

import UIKit

class ARKitViewController: UIViewController {
    let iroiro = myFunctions(albumName: "vHIT_VOG")

    @IBOutlet weak var progressFaceView: UIProgressView!
    @IBOutlet weak var progressEyeView: UIProgressView!
    @IBOutlet weak var labelButton: UIButton!
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var waveBoxView: UIImageView!
    @IBOutlet weak var vHITBoxView: UIImageView!
    @IBOutlet weak var helpButton: UIButton!
    @IBOutlet weak var settingButton: UIButton!
    @IBOutlet weak var ARKitButton: UIButton!
    @IBOutlet weak var pauseButton: UIButton!
    @IBOutlet weak var mailButton: UIButton!
    @IBOutlet weak var waveSlider: UISlider!
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
//        //        if #available(iOS 11.0, *) {
//        // viewDidLayoutSubviewsではSafeAreaの取得ができている
//        let topPadding = self.view.safeAreaInsets.top
//        let bottomPadding = self.view.safeAreaInsets.bottom
//        //            let leftPadding = self.view.safeAreaInsets.left
//        //            let rightPadding = self.view.safeAreaInsets.right
//        //            print("in viewDidLayoutSubviews")
//        UserDefaults.standard.set(topPadding, forKey: "top")
//        UserDefaults.standard.set(bottomPadding, forKey: "bottom")
//        //            UserDefaults.standard.set(leftPadding, forKey: "left")
//        //            UserDefaults.standard.set(rightPadding, forKey: "right")
//        //            print(topPadding,bottomPadding,leftPadding,rightPadding)    // iPhoneXなら44, その他は20.0
        //        }
        setButtons()
    }
    override func viewDidLoad() {
        super.viewDidLoad()
//        setButtons()

        // Do any additional setup after loading the view.
    }
    func setButtons(){
        
        let ww=view.bounds.width
        let wh=view.bounds.height
        let top=CGFloat(UserDefaults.standard.float(forKey: "top"))
        let bottom=CGFloat( UserDefaults.standard.float(forKey: "bottom"))
        let sp:CGFloat=5
        let bw:CGFloat=(ww-10*sp)/7//最下段のボタンの高さ、幅と同じ
        let bh=bw
        let by0=wh-bottom-2*sp-bh
        let by1=by0-bh-sp//2段目
        let by2=by1-bh-sp//videoSlider
       /*
        let ww=view.bounds.width
        let wh=view.bounds.height
        let bottom=CGFloat( UserDefaults.standard.float(forKey: "bottom"))
        let sp:CGFloat=5
        let bw:CGFloat=(ww-10*sp)/7//最下段のボタンの高さ、幅と同じ
        let bh=bw
        let by0=wh-bottom-2*sp-bh
        let by1=by0-bh-sp//2段目
        */
        
        iroiro.setButtonProperty(mailButton,x:sp*2+bw*0,y:by0,w:bw,h:bh,UIColor.systemBlue)
        iroiro.setButtonProperty(saveButton,x:sp*3+bw*1,y:by0,w:bw,h:bh,UIColor.systemBlue)
        iroiro.setButtonProperty(pauseButton,x:sp*4+bw*2,y:by0,w:bw,h: bh,UIColor.systemBlue)
//        iroiro.setButtonProperty(calcButton,x:sp*5+bw*3,y:by0-sp/2-bh/2,w:bw,h: bh,UIColor.systemBlue)
        iroiro.setButtonProperty(labelButton, x: sp*2, y: by1, w: bw*3+sp*2, h: bh, UIColor.darkGray)
        iroiro.setButtonProperty(ARKitButton,x:sp*5+bw*3,y:by0-sp/2-bh/2,w:bw,h:bh,UIColor.systemBlue)
        iroiro.setButtonProperty(settingButton,x:sp*6+bw*4,y:by0,w:bw,h: bh,UIColor.systemBlue)
        iroiro.setButtonProperty(helpButton,x:sp*7+bw*5,y:by0,w:bw,h: bh,UIColor.systemBlue)
        iroiro.setButtonProperty(deleteButton,x:sp*8+bw*6,y:by0,w:bw,h: bh,UIColor.systemRed)
        waveBoxView.frame=CGRect(x:0,y:wh*340/568-ww*90/320,width:ww,height: ww*180/320)
        vHITBoxView.frame=CGRect(x:0,y:wh*160/568-ww/5,width :ww,height:ww*2/5)
        waveSlider.frame=CGRect(x:sp*2,y:by2,width: ww-sp*4,height:20)//とりあえず
        let sliderHeight=waveSlider.frame.height
        waveSlider.frame=CGRect(x:sp*2,y:(waveBoxView.frame.maxY+by1)/2-sliderHeight/2,width:ww-sp*4,height:sliderHeight)
        
        progressFaceView.frame=CGRect(x:20,y:(top+vHITBoxView.frame.minY)/2-10,width: ww-40,height: 20)
        progressEyeView.frame=CGRect(x:20,y:(top+vHITBoxView.frame.minY)/2+10,width: ww-40,height: 20)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
