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
        setTexts()
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
    var wakuLength:Int = 0
    var calcMode:Int?
    @IBOutlet weak var gyroText: UILabel!
    @IBOutlet weak var paraText1: UILabel!
    @IBOutlet weak var paraText2: UILabel!
    @IBOutlet weak var paraText3: UILabel!
    @IBOutlet weak var paraText4: UILabel!

    @IBOutlet weak var paraText5: UILabel!
    @IBOutlet weak var paraText6: UILabel!
    @IBOutlet weak var wakuLengthInput: UITextField!
    
    @IBOutlet weak var videoGyroZureinput: UITextField!
    @IBOutlet weak var paraText7: UILabel!
    @IBOutlet weak var vhitpng: UIImageView!
    @IBOutlet weak var keyDown: UIButton!
    @IBOutlet weak var widthRangeinput: UITextField!
    @IBOutlet weak var waveWidthinput: UITextField!
    @IBOutlet weak var eyeBinput: UITextField!

    @IBOutlet weak var ratio1input: UITextField!
    @IBOutlet weak var ratio2input: UITextField!
    @IBAction func wakuLengthAction(_ sender: Any) {
        wakuLength = Field2value(field: wakuLengthInput)
        if wakuLength<3{
            wakuLength=3
        }
        UserDefaults.standard.set(wakuLength, forKey: "wakuLength")
    }
    
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
//    override var prefersStatusBarHidden: Bool {
//          return true
//      }
    @IBAction func numpadOff(_ sender: Any) {
        wakuLengthInput.endEditing(true)
        widthRangeinput.endEditing(true)
        waveWidthinput.endEditing(true)
        eyeBinput.endEditing(true)
        videoGyroZureinput.endEditing(true)
        ratio1input.endEditing(true)
        ratio2input.endEditing(true)
        keyDown.isHidden = true
    }

    @IBAction func setDefault(_ sender: Any) {
        if calcMode != 2{
            widthRange = 30
            waveWidth = 80
            eyeBorder=10
            okpMode=0
            faceFbutton.isOn=false
            faceF=0
            videoGyroZure = 20
            ratio1 = 100
            ratio2 = 100
            wakuLength = 3
        }else{
            eyeBorder=10
            okpMode=0
            faceFbutton.isOn=false
            ratio1 = 100
            ratio2 = 100
            wakuLength = 3
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
        self.wakuLengthInput.text = "\(wakuLength)"
        if faceF==0{
            self.faceFbutton.isOn=false
        }else{
            self.faceFbutton.isOn=true
        }
    }
    func setTexts(){
        print("toppadding:",topPadding,vhitpng.frame.minY,vhitpng.frame.maxY)
        let topYVOG=vhitpng.frame.minY
        var topYvHIT=vhitpng.frame.maxY+10//:CGFloat=0//damyTop.frame.maxY
        let ww:CGFloat=view.bounds.width
        let wh:CGFloat=view.bounds.height
        let bw:CGFloat=55
        let bh:CGFloat=25
        let bh1=bh+7
        
        paraText5.text = "matching square width"
        paraText6.text = "max moving width / frame"

//        let versionNumber = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
        let tw:CGFloat=ww-bw-10
        let by:CGFloat=10//vhit_h+20
//        if wh>666{//iPhone8の縦以上の大きさの場合
//              by=60
//        }
        let x1:CGFloat=3
        let x2=x1+bw+5
//        paraText5.text = "角膜反射光源枠の幅"
//        paraText6.text="角膜上反射光源の移動（検出）幅"

        if calcMode==2{
            paraText3.text = "eye position height ％"
            paraText4.text = "eye velocity height ％"
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
            paraText2.text = " ** VOG wave height **"
            paraText2.frame   = CGRect(x:x2,   y: topYVOG+by ,width: tw, height: bh)
            paraText3.frame   = CGRect(x:x2,   y: topYVOG+by+bh1*1,width: tw, height: bh)
            paraText4.frame   = CGRect(x:x2,   y: topYVOG+by+bh1*2 ,width: tw, height: bh)
            paraText5.frame   = CGRect(x:x2,   y: topYVOG+by+bh1*3 ,width: tw, height: bh)
            paraText6.frame   = CGRect(x:x2,   y: topYVOG+by+bh1*4 ,width: tw, height: bh)
            gyroText.frame = CGRect(x:5,y:topYVOG+by+bh1*5,width:ww-10,height: bh*3 )
            
//            gyroText.text! = "vHIT96da Version " + versionNumber
            gyroText.isHidden=true

            ratio1input.frame = CGRect(x:x1,y: topYVOG+by+bh1*1 ,width: bw, height: bh)
            ratio2input.frame = CGRect(x:x1,y: topYVOG+by+bh1*2 ,width: bw, height: bh)
            eyeBinput.frame = CGRect(x:x1,y: topYVOG+by+bh1*4 ,width: bw, height: bh)
            wakuLengthInput.frame = CGRect(x:x1,y: topYVOG+by+bh1*3 ,width: bw, height: bh)
        }else{//vhit
//            topY=ww*390/937
            paraText1.text = "(1) from A to D msec"
            paraText2.text = "(2) from B to C msec"
            paraText3.text = "eye velocity height ％"
            paraText4.text = "head velocity height ％"
            paraText7.text = "gyro and video time lag"
            paraText1.frame = CGRect(x:x2,   y: topYvHIT+by ,width: tw, height: bh)
            paraText2.frame = CGRect(x:x2,   y: topYvHIT+by+bh1 ,width: tw, height: bh)
            paraText3.frame = CGRect(x:x2,   y: topYvHIT+by+bh1*2 ,width: tw, height: bh)
            paraText4.frame = CGRect(x:x2,   y: topYvHIT+by+bh1*3 ,width: tw, height: bh)
            paraText5.frame = CGRect(x:x2,   y: topYvHIT+by+bh1*4 ,width: tw, height: bh)
            paraText6.frame = CGRect(x:x2,   y: topYvHIT+by+bh1*5 ,width: tw, height: bh)
            paraText7.frame = CGRect(x:x2,   y: topYvHIT+by+bh1*6,width: tw,height:bh)
            faceFbutton.isHidden=true
            markText.isHidden=true
//            markText.frame  = CGRect(x:x2+4, y: topY+by+bh1*7+3,width:tw,height:bh)
//            vhitpng.frame   = CGRect(x:5,    y: topPadding/*topY+by+bh1*7+10*/ ,width: ww-10, height: (ww-10)*390/937)
            gyroText.frame  = CGRect(x:5,    y: topYvHIT+by+bh1*7+25+ww/4,width:0,height:0)//ww-10,height:bh*6)
            waveWidthinput.frame =  CGRect(x:x1,y: topYvHIT+by,width: bw, height: bh)
            widthRangeinput.frame = CGRect(x:x1,y:topYvHIT+by+bh1 ,width: bw, height: bh)
            ratio1input.frame =     CGRect(x:x1,y: topYvHIT+by+bh1*2 ,width: bw, height: bh)
            ratio2input.frame =     CGRect(x:x1,y: topYvHIT+by+bh1*3 ,width: bw, height: bh)
            wakuLengthInput.frame = CGRect(x:x1,y: topYvHIT+by+bh1*4 ,width: bw, height: bh)
            eyeBinput.frame =       CGRect(x:x1,y: topYvHIT+by+bh1*5 ,width: bw, height: bh)
            videoGyroZureinput.frame = CGRect(x:x1,y: topYvHIT+by+bh1*6 ,width: bw, height: bh)
            faceFbutton.frame =     CGRect(x:x1,y: topYvHIT+by+bh1*7 ,width: bw, height: bh)
        }
        keyDown.frame = CGRect(x:ww-80-10, y: topYvHIT+by,width: 80, height: 40)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
//        let versionNumber = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
////         print(versionNumber)
//        gyroText.text! += "\n\nvHIT96da Version " + versionNumber
//        UserDefaults.standard.set(wakuLength, forKey: "wakuLength")
//print("wakulength:",wakuLength)
        widthRangeinput.delegate = self
        waveWidthinput.delegate = self
        eyeBinput.delegate = self
        videoGyroZureinput.delegate = self
        ratio1input.delegate = self
        ratio2input.delegate = self
        wakuLengthInput.delegate = self

        self.widthRangeinput.keyboardType = UIKeyboardType.numberPad
        self.waveWidthinput.keyboardType = UIKeyboardType.numberPad
        self.eyeBinput.keyboardType = UIKeyboardType.numberPad
        self.wakuLengthInput.keyboardType = UIKeyboardType.numberPad
        self.ratio1input.keyboardType = UIKeyboardType.numberPad
        self.ratio2input.keyboardType = UIKeyboardType.numberPad
        self.videoGyroZureinput.keyboardType = UIKeyboardType.numberPad
//        setTexts()
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

