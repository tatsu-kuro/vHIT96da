//
//  ParametersViewController.swift
//  vHIT96da
//
//  Created by kuroda tatsuaki on 2018/02/11.
//  Copyright © 2018年 tatsuaki.kuroda. All rights reserved.
//

import UIKit

class ParametersViewController: UIViewController, UITextFieldDelegate {
    
    var topPadding:CGFloat = 0
    var bottomPadding:CGFloat = 0
    var leftPadding:CGFloat = 0
    var rightPadding:CGFloat = 0
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if #available(iOS 11.0, *) {
            // viewDidLayoutSubviewsではSafeAreaの取得ができている
            topPadding = self.view.safeAreaInsets.top
            bottomPadding = self.view.safeAreaInsets.bottom
            leftPadding = self.view.safeAreaInsets.left
            rightPadding = self.view.safeAreaInsets.right
            print("in viewDidLayoutSubviews")
            print(topPadding,bottomPadding,leftPadding,rightPadding)    // iPhoneXなら44, その他は20.0
        }
//        setButtons()
    }
//    @IBOutlet weak var markdispSwitch: UISwitch!
//    @IBOutlet weak var markdispText: UILabel!
    @IBOutlet weak var markText: UILabel!
    @IBOutlet weak var faceFbutton: UISwitch!
    @IBOutlet weak var exitButton: UIButton!
    
    @IBOutlet weak var defaultButton: UIButton!
    
    @IBOutlet weak var damyTop: UILabel!
 
    var okpMode:Int = 0

    var faceF:Int?
    var widthRange:Int = 0
    var waveWidth:Int = 0
    var eyeBorder:Int = 0
    var videoGyroZure:Int = 0
    var ratio1:Int = 0
    var ratio2:Int = 0
    var isVHIT:Bool?
    @IBOutlet weak var gyroText: UILabel!
    @IBOutlet weak var paraText1: UILabel!
    @IBOutlet weak var paraText2: UILabel!
    @IBOutlet weak var paraText3: UILabel!
    @IBOutlet weak var paraText4: UILabel!

    @IBOutlet weak var paraText6: UILabel!
    
    @IBOutlet weak var videoGyroZureinput: UITextField!
    @IBOutlet weak var paraText7: UILabel!
    @IBOutlet weak var vhitpng: UIImageView!
    @IBOutlet weak var keyDown: UIButton!
    @IBOutlet weak var widthRangeinput: UITextField!
    @IBOutlet weak var waveWidthinput: UITextField!
    @IBOutlet weak var eyeBinput: UITextField!

    @IBOutlet weak var ratio1input: UITextField!
    @IBOutlet weak var ratio2input: UITextField!
    
    @IBAction func faceFchan(_ sender: UISwitch) {
        if sender.isOn{
            faceF=1
        }else{
            faceF=0
        }
    }
    // became first responder
    func textFieldDidBeginEditing(_ textField: UITextField) {
        keyDown.isHidden = false
    }

    @IBAction func tapBack(_ sender: Any) {
        numpadOff(0)
    }

    @IBAction func numpadOff(_ sender: Any) {
 
        widthRangeinput.endEditing(true)
        waveWidthinput.endEditing(true)
        eyeBinput.endEditing(true)
        videoGyroZureinput.endEditing(true)
        ratio1input.endEditing(true)
        ratio2input.endEditing(true)
        keyDown.isHidden = true
    }

    @IBAction func setDefault(_ sender: Any) {
        if isVHIT==true{
            widthRange = 30
            waveWidth = 80
            eyeBorder=10
            okpMode=0
            faceFbutton.isOn=false
            faceF=0
//            markdispSwitch.isOn=false
//            gyroDelta = 50
            videoGyroZure = 10
            ratio1 = 100
            ratio2 = 100
        }else{
            eyeBorder=10
            okpMode=0
            faceFbutton.isOn=false
//            markdispSwitch.isOn=false
            ratio1 = 100
            ratio2 = 100
        }
        dispParam()
    }
    func Field2value(field:UITextField) -> Int {
        if field.text?.count != 0 {
            return Int(field.text!)!
        }else{
            return 0
        }
    }


    @IBAction func widthRangeButton(_ sender: Any) {
        widthRange = Field2value(field:widthRangeinput)
    }
    @IBAction func waveWidthButton(_ sender: Any) {
        waveWidth = Field2value(field: waveWidthinput)
    }
    
    @IBAction func eyeBorderButton(_ sender: Any) {
        eyeBorder = Field2value(field: eyeBinput)
    }
    
    @IBAction func videoGyroZurechange(_ sender: Any) {
        videoGyroZure=Field2value(field: videoGyroZureinput)
    }
    //    @IBAction func gyroDeltaButton(_  sender: Any) {
//        gyroDelta = Field2value(field: gyroDinput)
//    }
//    @IBAction func outerBorderButton(_ sender: Any) {
////        outerBorder = Field2value(field: outerBinput)
//    }

    @IBAction func ratio1Button(_ sender: Any) {
        ratio1 = Field2value(field: ratio1input)
    }
    
    @IBAction func ratio2Button(_ sender: Any) {
        ratio2 = Field2value(field: ratio2input)
    }
    
    func dispParam(){
        self.widthRangeinput.text = "\(widthRange)"
        self.waveWidthinput.text = "\(waveWidth)"
        self.eyeBinput.text = "\(eyeBorder)"
        self.videoGyroZureinput.text = "\(videoGyroZure)"
        self.ratio1input.text = "\(ratio1)"
        self.ratio2input.text = "\(ratio2)"
        if faceF==0{
            self.faceFbutton.isOn=false
        }else{
            self.faceFbutton.isOn=true
        }
    }
    func setTexts(){
        let topY:CGFloat=0//damyTop.frame.maxY
        let ww:CGFloat=view.bounds.width
        let wh:CGFloat=view.bounds.height
//        print("windowHeight",wh)//8:667 x:812 se:568
        let bw:CGFloat=50
        let bh:CGFloat=25
        let bh1=bh+7
        let versionNumber = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
//         print(versionNumber)
//        gyroText.text! += "\n\nvHIT96da Version " + versionNumber

        let tw:CGFloat=ww-bw-10
//        let vhit_h:CGFloat=ww/4
        var by:CGFloat=20//vhit_h+20
        if wh>666{//iPhone8の縦以上の大きさの場合
              by=60
        }
        let x1:CGFloat=3
        let x2=x1+bw+5
        if isVHIT==false{
            markText.isHidden = true
            faceFbutton.isHidden = true
            vhitpng.isHidden=true
            paraText1.isHidden=true
            paraText6.isHidden=false
            waveWidthinput.isHidden = true
            widthRangeinput.isHidden = true
            eyeBinput.isHidden = false
            videoGyroZureinput.isHidden = true
            ratio1input.isHidden = false
            ratio2input.isHidden = false
            paraText7.isHidden = true
//            gyroText.isHidden = true
            paraText2.text = " ** VOG 波形表示高さの調整 **"
            paraText3.text = "眼球偏位位置表示の高さ％"
            paraText4.text = "眼球偏位速度表示の高さ％"
            paraText6.text="角膜上反射光源の移動（検出）幅"
            paraText2.frame   = CGRect(x:x2,   y: topY+by ,width: tw, height: bh)
            paraText3.frame   = CGRect(x:x2,   y: topY+by+bh1*1,width: tw, height: bh)
            paraText4.frame   = CGRect(x:x2,   y: topY+by+bh1*2 ,width: tw, height: bh)
            paraText6.frame   = CGRect(x:x2,   y: topY+by+bh1*3 ,width: tw, height: bh)
            gyroText.frame = CGRect(x:5,y:topY+by+bh1*4,width:ww-10,height: bh*3 )
            
            gyroText.text! = "vHIT96da Version " + versionNumber

            ratio1input.frame = CGRect(x:x1,y: topY+by+bh1*1 ,width: bw, height: bh)
            ratio2input.frame = CGRect(x:x1,y: topY+by+bh1*2 ,width: bw, height: bh)
            eyeBinput.frame = CGRect(x:x1,y: topY+by+bh1*3 ,width: bw, height: bh)
        }else{//vhit
            paraText1.frame = CGRect(x:x2,   y: topY+by ,width: tw, height: bh)
            paraText2.frame = CGRect(x:x2,   y: topY+by+bh1 ,width: tw, height: bh)
            paraText3.frame = CGRect(x:x2,   y: topY+by+bh1*2 ,width: tw, height: bh)
            paraText4.frame = CGRect(x:x2,   y: topY+by+bh1*3 ,width: tw, height: bh)
            paraText6.frame = CGRect(x:x2,   y: topY+by+bh1*4 ,width: tw, height: bh)
            paraText7.frame = CGRect(x:x2, y:topY+by+bh1*5,width: tw,height:bh)
            markText.frame  = CGRect(x:x2+4, y: topY+by+bh1*6+3,width:tw,height:bh)
            vhitpng.frame   = CGRect(x:0,    y: topY+by+bh1*7+10 ,width: ww, height: ww*9/32)
            gyroText.frame = CGRect(x:5,     y: topY+by+bh1*7+25+ww/5,width:ww-10,height:bh*6)
            gyroText.text! += "\n\nvHIT96da Version " + versionNumber
            waveWidthinput.frame = CGRect(x:x1,y: topY+by,width: bw, height: bh)
            widthRangeinput.frame = CGRect(x:x1,y:topY+by+bh1 ,width: bw, height: bh)
            ratio1input.frame = CGRect(x:x1,y: topY+by+bh1*2 ,width: bw, height: bh)
            ratio2input.frame = CGRect(x:x1,y: topY+by+bh1*3 ,width: bw, height: bh)
            eyeBinput.frame = CGRect(x:x1,y: topY+by+bh1*4 ,width: bw, height: bh)
            videoGyroZureinput.frame = CGRect(x:x1,y: topY+by+bh1*5 ,width: bw, height: bh)
            faceFbutton.frame =  CGRect(x:x1,y: topY+by+bh1*6 ,width: bw, height: bh)
        }
        keyDown.frame = CGRect(x:ww-80-10, y: topY+by,width: 80, height: 40)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
//        let versionNumber = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
////         print(versionNumber)
//        gyroText.text! += "\n\nvHIT96da Version " + versionNumber
        widthRangeinput.delegate = self
        waveWidthinput.delegate = self
        eyeBinput.delegate = self
        videoGyroZureinput.delegate = self
        ratio1input.delegate = self
        ratio2input.delegate = self

        self.widthRangeinput.keyboardType = UIKeyboardType.numberPad
        self.waveWidthinput.keyboardType = UIKeyboardType.numberPad
        self.eyeBinput.keyboardType = UIKeyboardType.numberPad

        self.ratio1input.keyboardType = UIKeyboardType.numberPad
        self.ratio2input.keyboardType = UIKeyboardType.numberPad
        self.videoGyroZureinput.keyboardType = UIKeyboardType.numberPad
        setTexts()
        dispParam()
        defaultButton.layer.cornerRadius = 5
        exitButton.layer.cornerRadius = 5
        keyDown.layer.cornerRadius = 5
        keyDown.isHidden = true
    }
    override func viewDidAppear(_ animated: Bool) {
//        setTexts()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

