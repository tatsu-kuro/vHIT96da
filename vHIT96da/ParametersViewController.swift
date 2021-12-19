//
//  ParametersViewController.swift
//  vHIT96da
//
//  Created by kuroda tatsuaki on 2018/02/11.
//  Copyright © 2018年 tatsuaki.kuroda. All rights reserved.
//
import UIKit
extension String {
    // 半角数字の判定
    func isAlphanumeric() -> Bool {
        return self.range(of: "[^0-9]+", options: .regularExpression) == nil && self != ""
//        return self.range(of: "[^,:0123456789]", options: .regularExpression) == nil && self != ""
    }
}

class ParametersViewController: UIViewController, UITextFieldDelegate {
    var bottomPadding:CGFloat=0
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if #available(iOS 11.0, *) {
             bottomPadding = self.view.safeAreaInsets.bottom
//            UserDefaults.standard.set(bottomPadding,forKey: "bottomPadding")
        }
        setTexts()
    }
    @IBOutlet weak var markText: UILabel!
    @IBOutlet weak var faceFbutton: UISwitch!
    @IBOutlet weak var exitButton: UIButton!
    
    @IBOutlet weak var greenItemLabel: UILabel!
    @IBOutlet weak var vHITLabel: UILabel!
    @IBOutlet weak var toVOGButton: UIButton!
    
    @IBAction func onTovHITButton(_ sender: Any) {
        if calcMode == 0{
            return
        }
        calcMode=0
        dispParam()
        setTexts()
    }
    @IBAction func onToVOGButton(_ sender: Any) {
        if calcMode == 2{
            return
        }
        calcMode=2
        dispParam()
        setTexts()
    }
    @IBOutlet weak var defaultButton: UIButton!
 
    var okpMode:Int = 0

    @IBOutlet weak var vhitDisplayLabel: UILabel!
    @IBOutlet weak var parallelButton: UIButton!
//    override func viewDidLayoutSubviews() {
//        super.viewDidLayoutSubviews()
//        if #available(iOS 11.0, *) {
//            // viewDidLayoutSubviewsではSafeAreaの取得ができている
////            let topPadding = self.view.safeAreaInsets.top
//            let bottomPadding = self.view.safeAreaInsets.bottom
////            let leftPadding = self.view.safeAreaInsets.left
////            let rightPadding = self.view.safeAreaInsets.right
////            UserDefaults.standard.set(topPadding,forKey: "topPadding")
//            UserDefaults.standard.set(bottomPadding,forKey: "bottomPadding")
////            UserDefaults.standard.set(leftPadding,forKey: "leftPadding")
////            UserDefaults.standard.set(rightPadding,forKey: "rightPadding")
////            let left=UserDefaults.standard.integer(forKey:"leftPadding")
////            print("top,bottom,right,left,(int Left)",topPadding,bottomPadding,rightPadding,leftPadding,left)    // iPhoneXなら44, その他は20.0
//        }
//    }
    
    @IBOutlet weak var oppositeButton: UIButton!
    
    @IBOutlet weak var parallelLabel: UILabel!
    
    @IBOutlet weak var oppositeLabel: UILabel!
    func displayMode(){
        if vHITDisplayMode == 0{
            parallelLabel.isHidden=true
            oppositeLabel.isHidden=false
        }else{
            parallelLabel.isHidden=false
            oppositeLabel.isHidden=true
            
        }
    }
    @IBAction func onOppositButton(_ sender: Any) {
        vHITDisplayMode=0
        parallelLabel.isHidden=true
        oppositeLabel.isHidden=false
    }
    @IBAction func onParallelButton(_ sender: Any) {
        vHITDisplayMode=1
        parallelLabel.isHidden=false
        oppositeLabel.isHidden=true
    }
    var useFaceMark:Int?
    var widthRange:Int = 0
    var waveWidth:Int = 0
    var eyeBorder:Int = 0
    var videoGyroZure:Int = 0
    var eyeRatio:Int = 0
    var gyroRatio:Int = 0
    var posRatio:Int = 0
    var veloRatio:Int = 0
    var wakuLength:Int = 0
    var calcMode:Int?
    var vHITDisplayMode:Int = 0
    @IBOutlet weak var gyroText: UILabel!
    @IBOutlet weak var A2BLabel: UILabel!
    @IBOutlet weak var B2CLabel: UILabel!
    @IBOutlet weak var eyeVelocityLabel: UILabel!
    @IBOutlet weak var headVelocityLabel: UILabel!

    @IBOutlet weak var tovHITButton: UIButton!
    @IBOutlet weak var VOGLabel: UILabel!
    @IBOutlet weak var wakuLengthLabel: UILabel!
    @IBOutlet weak var eyeBorderLabel: UILabel!
    @IBOutlet weak var wakuLengthInput: UITextField!
    
    @IBOutlet weak var timeLagInput: UITextField!
    @IBOutlet weak var timeLagLabel: UILabel!
    @IBOutlet weak var vhitpng: UIImageView!
    @IBOutlet weak var keyDown: UIButton!
    @IBOutlet weak var B2CInput: UITextField!
    @IBOutlet weak var A2DInput: UITextField!
    @IBOutlet weak var eyeBorderInput: UITextField!

    @IBOutlet weak var eyeVelocityInput: UITextField!
    @IBOutlet weak var headVelocityInput: UITextField!

  
    
    @IBAction func wakuLengthAction(_ sender: Any) {
        wakuLength = Field2value(field: wakuLengthInput)
        if wakuLength<3{
            wakuLength=3
//            dispParam()
        }else if wakuLength>15{
            wakuLength=15
//            dispParam()
        }
        UserDefaults.standard.set(wakuLength, forKey: "wakuLength")
    }
    
    @IBAction func faceFchan(_ sender: UISwitch) {
        if sender.isOn{
            useFaceMark=1
        }else{
            useFaceMark=0
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
        wakuLengthInput.endEditing(true)
        B2CInput.endEditing(true)
        A2DInput.endEditing(true)
        eyeBorderInput.endEditing(true)
        timeLagInput.endEditing(true)
        eyeVelocityInput.endEditing(true)
        headVelocityInput.endEditing(true)
        keyDown.isHidden = true
        dispParam()
    }

    @IBAction func setDefault(_ sender: Any) {
        if calcMode != 2{
            widthRange = 30
            waveWidth = 80
            eyeBorder=10
            okpMode=0
            faceFbutton.isOn=false
            useFaceMark=0
            videoGyroZure = 20
            eyeRatio = 100
            gyroRatio = 100
            wakuLength = 3
        }else{
            eyeBorder=10
            okpMode=0
            faceFbutton.isOn=false
            posRatio = 100
            veloRatio = 100
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
        widthRange = Field2value(field:B2CInput)
    }
    @IBAction func waveWidthButton(_ sender: Any) {
        waveWidth = Field2value(field: A2DInput)
    }
    
    @IBAction func eyeBorderButton(_ sender: Any) {
        eyeBorder = Field2value(field: eyeBorderInput)
        if eyeBorder<5{
            eyeBorder=5
//            dispParam()
        }else if eyeBorder>30{
            eyeBorder=30
//            dispParam()
        }
//        print("eyeBorder:",eyeBorder)
    }
    
    @IBAction func videoGyroZurechange(_ sender: Any) {
        videoGyroZure=Field2value(field: timeLagInput)
    }
 
    @IBAction func ratio1Button(_ sender: Any) {
        if calcMode != 2{
            eyeRatio = Field2value(field: eyeVelocityInput)
        }else{
            posRatio = Field2value(field: eyeVelocityInput)
        }
    }
    
    @IBAction func ratio2Button(_ sender: Any) {
        if calcMode != 2{
            gyroRatio = Field2value(field: headVelocityInput)
        }else{
            veloRatio = Field2value(field: headVelocityInput)
        }
    }
    
    func dispParam(){
        self.B2CInput.text = "\(widthRange)"
        self.A2DInput.text = "\(waveWidth)"
        self.eyeBorderInput.text = "\(eyeBorder)"
        self.timeLagInput.text = "\(videoGyroZure)"
        if calcMode != 2{//vHIT
            self.eyeVelocityInput.text = "\(eyeRatio)"
            self.headVelocityInput.text = "\(gyroRatio)"
        }else{
            self.eyeVelocityInput.text = "\(posRatio)"
            self.headVelocityInput.text = "\(veloRatio)"
        }
        self.wakuLengthInput.text = "\(wakuLength)"
        if useFaceMark==0{
            self.faceFbutton.isOn=false
        }else{
            self.faceFbutton.isOn=true
        }
    }
  
    func setTexts(){
        let topY = keyDown.frame.minY// vhitpng.frame.minY
        let ww:CGFloat=view.bounds.width
        //        let wh:CGFloat=view.bounds.height
        let bw:CGFloat=55
        let bh:CGFloat=25
        let bh1=bh+7
        
        wakuLengthLabel.text = "matching square width"
        eyeBorderLabel.text = "max moving width / frame"
        let tw:CGFloat=ww-bw-10
        let x1:CGFloat=3
        let x2=x1+bw+5
        
        let sp:CGFloat=5
        let butw=(view.bounds.width-sp*7)/4
        let buth=butw/2
        let buty=view.bounds.height-sp-buth-bottomPadding
        
        if calcMode==2{//VOG
            eyeVelocityLabel.text = "height of position waveform ％"
            headVelocityLabel.text = "height of speed waveform ％"
            eyeVelocityLabel.backgroundColor=UIColor.white
            eyeVelocityLabel.textColor=UIColor.black
            headVelocityLabel.backgroundColor=UIColor.white
            headVelocityLabel.textColor=UIColor.black
            markText.isHidden = true
            faceFbutton.isHidden = true
            vhitpng.isHidden=true
            A2BLabel.isHidden=true
            eyeBorderLabel.isHidden=false
            A2DInput.isHidden = true
            B2CInput.isHidden = true
            eyeBorderInput.isHidden = false
            timeLagInput.isHidden = true
            eyeVelocityInput.isHidden = false
            headVelocityInput.isHidden = false
            timeLagLabel.isHidden = true
            B2CLabel.text = " ** VOG wave height **"
            B2CLabel.frame   = CGRect(x:x2,   y: topY ,width: tw, height: bh)
            eyeVelocityLabel.frame   = CGRect(x:x2,   y: topY+bh1*1,width: tw, height: bh)
            headVelocityLabel.frame   = CGRect(x:x2,   y: topY+bh1*2 ,width: tw, height: bh)
            wakuLengthLabel.frame   = CGRect(x:x2,   y: topY+bh1*3 ,width: tw, height: bh)
            eyeBorderLabel.frame   = CGRect(x:x2,   y: topY+bh1*4 ,width: tw, height: bh)
            gyroText.frame = CGRect(x:5,y:topY+bh1*5,width:ww-10,height: bh*3 )
            gyroText.isHidden=true
            eyeVelocityInput.frame = CGRect(x:x1,y: topY+bh1*1 ,width: bw, height: bh)
            headVelocityInput.frame = CGRect(x:x1,y: topY+bh1*2 ,width: bw, height: bh)
            eyeBorderInput.frame = CGRect(x:x1,y: topY+bh1*4 ,width: bw, height: bh)
            wakuLengthInput.frame = CGRect(x:x1,y: topY+bh1*3 ,width: bw, height: bh)
            parallelButton.isHidden=true
            parallelLabel.isHidden=true
            oppositeLabel.isHidden=true
            oppositeButton.isHidden=true
            vhitDisplayLabel.isHidden=true
                        
            vHITLabel.isHidden=true
            VOGLabel.isHidden=false
            greenItemLabel.isHidden=true
        }else{//vhit
            greenItemLabel.isHidden=false
            markText.isHidden = false
            faceFbutton.isHidden = false
            vhitpng.isHidden=false
            A2BLabel.isHidden=false
            eyeBorderLabel.isHidden=false
            A2DInput.isHidden = false
            B2CInput.isHidden = false
            eyeBorderInput.isHidden = false
            timeLagInput.isHidden = false
            eyeVelocityInput.isHidden = false
            headVelocityInput.isHidden = false
            timeLagLabel.isHidden = false
                
            parallelButton.isHidden=false
            parallelLabel.isHidden=false
            oppositeLabel.isHidden=false
            oppositeButton.isHidden=false
            vhitDisplayLabel.isHidden=false

            A2BLabel.text = "(1) time(ms) from A to D"
            B2CLabel.text = "(2) time(ms) from B to C"
            eyeVelocityLabel.text = "(1*)height of eye waveform ％"
            headVelocityLabel.text = "(1*)height of head waveform ％"
            timeLagLabel.text = "(1*)time lag: eye & head waveforms"
            
            eyeVelocityLabel.backgroundColor=UIColor.white
            eyeVelocityLabel.textColor=UIColor.systemGreen
            headVelocityLabel.backgroundColor=UIColor.white
            headVelocityLabel.textColor=UIColor.systemGreen
            timeLagLabel.backgroundColor=UIColor.white
            timeLagLabel.textColor=UIColor.systemGreen
            vhitDisplayLabel.textColor=UIColor.systemGreen
            vhitDisplayLabel.backgroundColor=UIColor.white
            
            markText.text = "use of the mark on face"
            A2BLabel.frame = CGRect(x:x2,   y: topY+bh1*5 ,width: tw, height: bh)
            B2CLabel.frame = CGRect(x:x2,   y: topY+bh1*6 ,width: tw, height: bh)
            eyeVelocityLabel.frame = CGRect(x:x2,   y: topY+bh1*0 ,width: tw, height: bh)
            headVelocityLabel.frame = CGRect(x:x2,   y: topY+bh1*1 ,width: tw, height: bh)
            wakuLengthLabel.frame = CGRect(x:x2,   y: topY+bh1*3 ,width: tw, height: bh)
            eyeBorderLabel.frame = CGRect(x:x2,   y: topY+bh1*4 ,width: tw, height: bh)
            timeLagLabel.frame = CGRect(x:x2,   y: topY+bh1*2,width: tw,height:bh)
            let vhitpngH=(ww-10)*440/940
            gyroText.frame  = CGRect(x:5,y: topY+bh1*7+25+ww/4,width:0,height:0)
            A2DInput.frame =  CGRect(x:x1,y: topY+bh1*5 ,width: bw, height: bh)
            B2CInput.frame = CGRect(x:x1,y: topY+bh1*6 ,width: bw, height: bh)
            eyeVelocityInput.frame =     CGRect(x:x1,y: topY+bh1*0 ,width: bw, height: bh)
            headVelocityInput.frame =     CGRect(x:x1,y: topY+bh1*1 ,width: bw, height: bh)
            wakuLengthInput.frame = CGRect(x:x1,y: topY+bh1*3 ,width: bw, height: bh)
            eyeBorderInput.frame =       CGRect(x:x1,y: topY+bh1*4 ,width: bw, height: bh)
            timeLagInput.frame = CGRect(x:x1,y: topY+bh1*2 ,width: bw, height: bh)
            vhitpng.frame = CGRect(x:5,y:topY+bh1*7,width:ww-10,height:vhitpngH)
            faceFbutton.frame =     CGRect(x:x1,y: topY+bh1*8+vhitpngH+10 ,width: bw, height: bh)
            markText.frame  = CGRect(x:x2,  y: topY+bh1*8+vhitpngH+10,width:tw,height: bh)
            
            vhitDisplayLabel.frame = CGRect(x:butw*2+4*sp,y: topY+bh1*7+vhitpngH+10 ,width: tw, height: bh)
            parallelLabel.frame = CGRect(x:2*sp,y: topY+bh1*7+vhitpngH+5 ,width: butw, height: 3)
            parallelButton.frame = CGRect(x:2*sp,y: topY+bh1*7+vhitpngH+10 ,width: butw, height: bh)
            parallelButton.layer.cornerRadius=3
            oppositeLabel.frame = CGRect(x:butw+3*sp,y:topY+bh1*7+vhitpngH+5,width:butw,height:3)
            oppositeButton.frame = CGRect(x:butw+3*sp,y:topY+bh1*7+vhitpngH+10,width:butw,height:bh)
            oppositeButton.layer.cornerRadius=3
            greenItemLabel.frame = CGRect(x:x1,y: topY+bh1*8+vhitpngH+10 ,width: view.bounds.width-x1*2, height: bh*2)
            greenItemLabel.layer.masksToBounds = true
            greenItemLabel.layer.cornerRadius = 3
            if noFaceMark==true{
                markText.isHidden=true
                faceFbutton.isHidden=true
            }
            displayMode()
            vHITLabel.isHidden=false
            VOGLabel.isHidden=true
            vHITLabel.layer.masksToBounds=true
            greenItemLabel.layer.borderColor = UIColor.green.cgColor
            greenItemLabel.layer.borderWidth = 1.0
        }
        //
//        let sp:CGFloat=5
//        let butw=(view.bounds.width-sp*7)/4
//        let buth=butw/2
//        let buty=view.bounds.height-sp-buth-bottomPadding
        defaultButton.frame=CGRect(x:2*sp,y:buty,width:butw,height: buth)
        tovHITButton.frame=CGRect(x:butw+3*sp,y:buty,width:butw,height: buth)
        vHITLabel.frame=CGRect(x:butw+3*sp,y:buty-7,width:butw,height: 5)
        toVOGButton.frame=CGRect(x:butw*2+4*sp,y:buty,width:butw,height: buth)
        VOGLabel.frame=CGRect(x:butw*2+4*sp,y:buty-7,width:butw,height: 5)
        exitButton.frame=CGRect(x:butw*3+5*sp,y:buty,width:butw,height: buth)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        B2CInput.delegate = self
        A2DInput.delegate = self
        eyeBorderInput.delegate = self
        timeLagInput.delegate = self
        eyeVelocityInput.delegate = self
        headVelocityInput.delegate = self
        wakuLengthInput.delegate = self

        self.B2CInput.keyboardType = UIKeyboardType.numberPad
        self.A2DInput.keyboardType = UIKeyboardType.numberPad
        self.eyeBorderInput.keyboardType = UIKeyboardType.numberPad
        self.wakuLengthInput.keyboardType = UIKeyboardType.numberPad
        self.eyeVelocityInput.keyboardType = UIKeyboardType.numberPad
        self.headVelocityInput.keyboardType = UIKeyboardType.numberPad
        self.timeLagInput.keyboardType = UIKeyboardType.numberPad
        dispParam()
        defaultButton.layer.cornerRadius = 5
        exitButton.layer.cornerRadius = 5
        keyDown.layer.cornerRadius = 5
        toVOGButton.layer.cornerRadius=5
        tovHITButton.layer.cornerRadius=5
        keyDown.isHidden = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

