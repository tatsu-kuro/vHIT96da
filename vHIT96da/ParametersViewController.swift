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
    @IBOutlet weak var faceMarkSwitch: UISwitch!
    @IBOutlet weak var exitButton: UIButton!
    
    @IBOutlet weak var registerButton: UIButton!
    @IBOutlet weak var lowPassText: UILabel!
    @IBOutlet weak var lowPassFilterSwitch: UISegmentedControl!
    func getUserDefault(str:String,ret:Int) -> Int{//getUserDefault_one
        if (UserDefaults.standard.object(forKey: str) != nil){//keyが設定してなければretをセット
            return UserDefaults.standard.integer(forKey:str)
        }else{
            UserDefaults.standard.set(ret, forKey: str)
            return ret
        }
    }
    
    @IBAction func onLowPassFilterSwitch(_ sender: Any) {
        let index=lowPassFilterSwitch.selectedSegmentIndex
        UserDefaults.standard.set(index, forKey: "lowPassFilterCnt")
        print("selectedSegmentIndex",index)
    }
    
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
    @IBAction func unwindPara(_ segue: UIStoryboardSegue){
    }
    //    @IBAction func unwindPara(_ segue: UIStoryboardSegue) {
    //        calcMode=3
    //    }
        
   
    @IBAction func onExitButton(_ sender: Any) {
        performSegue(withIdentifier: "fromParamsToMain", sender: nil)

    }
    override var prefersStatusBarHidden: Bool {
        return true
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
 
//    var okpMode:Int = 0

    @IBOutlet weak var vhitDisplayLabel: UILabel!
    @IBOutlet weak var parallelButton: UIButton!
    
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
    var faceMarkHidden:Bool=true
    var faceMark:Bool=true
    //これでmarkswitch,marktextの表示をオンオフする。
//    var useFaceMark:Int?
    var widthRange:Int = 0
    var waveWidth:Int = 0
    var eyeBorder:Int = 0
    var videoGyroZure:Int = 0
    var vorGainCorrection:Int = 100
    var eyeRatio:Int = 0
    var gyroRatio:Int = 0
    var posRatio:Int = 0
    var veloRatio:Int = 0
    var wakuLength:Int = 0
    var calcMode:Int?
    var vHITDisplayMode:Int = 0
    @IBOutlet weak var gyroText: UILabel!
    @IBOutlet weak var A2DLabel: UILabel!
    @IBOutlet weak var B2CLabel: UILabel!
    
    @IBOutlet weak var eyeVelocityLabel: UILabel!
    @IBOutlet weak var headVelocityLabel: UILabel!
    @IBOutlet weak var eyePositionLabelVOG: UILabel!
    @IBOutlet weak var eyeVelocityLabelVOG: UILabel!
    
    @IBOutlet weak var tovHITButton: UIButton!
    @IBOutlet weak var VOGLabel: UILabel!
    @IBOutlet weak var wakuLengthLabel: UILabel!
    @IBOutlet weak var eyeBorderLabel: UILabel!
    @IBOutlet weak var wakuLengthInput: UITextField!
    
    @IBOutlet weak var vorGainCorrectionInput: UITextField!
    @IBOutlet weak var VorGainCorrectionLabel: UILabel!
    @IBOutlet weak var vhitpng: UIImageView!
    @IBOutlet weak var keyDown: UIButton!
    @IBOutlet weak var B2CInput: UITextField!
    @IBOutlet weak var A2DInput: UITextField!
    @IBOutlet weak var eyeBorderInput: UITextField!

    @IBOutlet weak var eyeVelocityInput: UITextField!
    @IBOutlet weak var headVelocityInput: UITextField!

    @IBAction func wakuLengthAction(_ sender: Any) {
        wakuLength = Field2value(field: wakuLengthInput)
    }
    
    @IBAction func faceFchan(_ sender: UISwitch) {
        if sender.isOn{
            faceMark=true
        }else{
            faceMark=false
        }
    }
    // became first responder
    func textFieldDidBeginEditing(_ textField: UITextField) {
        keyDown.isHidden = false
    }

    @IBAction func tapBack(_ sender: Any) {
        numpadOff(0)
    }
    func setMaxMin(){
        if vorGainCorrection<50{
            vorGainCorrection=50
        }else if vorGainCorrection>150{
            vorGainCorrection=150
        }
        if waveWidth<40{
            waveWidth=40
        }else if waveWidth>200{
            waveWidth=200
        }
        if widthRange<5{
            widthRange=5
        }else if widthRange>50{
            widthRange=50
        }
        if wakuLength<3{
            wakuLength=3
        }else if wakuLength>15{
            wakuLength=15
        }
        
        if eyeBorder<5{
            eyeBorder=5
        }else if eyeBorder>30{
            eyeBorder=30
        }
        if eyeRatio<10{
            eyeRatio=10
        }else if eyeRatio>4000{
            eyeRatio=4000
        }
        if gyroRatio<10{
            gyroRatio=10
        }else if gyroRatio>4000{
            gyroRatio=4000
        }
        if veloRatio<10{
            veloRatio=10
        }else if veloRatio>4000{
            veloRatio=4000
        }
    }
    @IBAction func numpadOff(_ sender: Any) {
        wakuLengthInput.endEditing(true)
        B2CInput.endEditing(true)
        A2DInput.endEditing(true)
        eyeBorderInput.endEditing(true)
        vorGainCorrectionInput.endEditing(true)
        eyeVelocityInput.endEditing(true)
        headVelocityInput.endEditing(true)
        keyDown.isHidden = true
        setMaxMin()
        dispParam()
    }

    @IBAction func setDefault(_ sender: Any) {
        if calcMode==3{
            return
        }
        if calcMode != 2{
            widthRange = 30
            waveWidth = 80
            eyeBorder=10
            faceMarkSwitch.isOn=false
            faceMark=false
            videoGyroZure = 2
            vorGainCorrection = 100
            eyeRatio = 300
            gyroRatio = 170
            wakuLength = 3
            lowPassFilterSwitch.selectedSegmentIndex=4//getUserDefault(str: "lowPassFilterCnt", ret: 4)
            onLowPassFilterSwitch(0)
        }else{
            eyeBorder=10
            faceMarkSwitch.isOn=false
            posRatio = 100
            veloRatio = 100
            wakuLength = 3
            lowPassFilterSwitch.selectedSegmentIndex=4//getUserDefault(str: "lowPassFilterCnt", ret: 4)
            onLowPassFilterSwitch(0)
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
    }
    
    @IBAction func vorGainCorrectionChange(_ sender: Any) {
        vorGainCorrection=Field2value(field: vorGainCorrectionInput)
    }
 
    @IBAction func ratio1Button(_ sender: Any) {
        if calcMode == 0 || calcMode==3{
            eyeRatio = Field2value(field: eyeVelocityInput)
        }else{
            posRatio = Field2value(field: eyeVelocityInput)
        }
    }
    
    @IBAction func ratio2Button(_ sender: Any) {
        if calcMode == 0 || calcMode==3{
            gyroRatio = Field2value(field: headVelocityInput)
        }else{
            veloRatio = Field2value(field: headVelocityInput)
        }
    }
    
    func dispParam(){
        self.B2CInput.text = "\(widthRange)"
        self.A2DInput.text = "\(waveWidth)"
        self.eyeBorderInput.text = "\(eyeBorder)"
        self.vorGainCorrectionInput.text = "\(vorGainCorrection)"
        if calcMode == 0 || calcMode==3{//vHIT
            self.eyeVelocityInput.text = "\(eyeRatio)"
            self.headVelocityInput.text = "\(gyroRatio)"
        }else{//vog
            self.eyeVelocityInput.text = "\(posRatio)"
            self.headVelocityInput.text = "\(veloRatio)"
        }
        self.wakuLengthInput.text = "\(wakuLength)"
        if faceMark==false{
            self.faceMarkSwitch.isOn=false
        }else{
            self.faceMarkSwitch.isOn=true
        }
    }
  
    func setTexts(){
        let ww=view.bounds.width
//        let wh=view.bounds.height
        let bottom=CGFloat( UserDefaults.standard.float(forKey: "bottom"))

        let sp:CGFloat=5
        //        let wh:CGFloat=view.bounds.height
        let topY = CGFloat( UserDefaults.standard.float(forKey: "top"))+sp*2//keyDown.frame.minY// vhitpng.frame.minY
        let bw:CGFloat=55
        let bh:CGFloat=25
        let bh1=bh+7
        
        let tw:CGFloat=ww-bw-10
        let x1:CGFloat=3
        let x2=x1+bw+5
        
        let butw=(view.bounds.width-sp*7)/4
        let buth=butw/2
//        let buty=view.bounds.height-sp-buth-bottom
        let butw1=(view.bounds.width-sp*8)/5
        let buth1=butw1/2
        let buty1=view.bounds.height-sp-buth1-bottom

        keyDown.frame=CGRect(x:ww-butw-sp*2,y:topY,width: butw,height: buth)
        eyeVelocityLabel.frame   = CGRect(x:x2,   y: topY+bh1*1,width: tw, height: bh)
        headVelocityLabel.frame   = CGRect(x:x2,   y: topY+bh1*2 ,width: tw, height: bh)
        eyePositionLabelVOG.frame   = CGRect(x:x2,   y: topY+bh1*1,width: tw, height: bh)
        eyeVelocityLabelVOG.frame   = CGRect(x:x2,   y: topY+bh1*2 ,width: tw, height: bh)
        lowPassText.isHidden=true
        lowPassFilterSwitch.isHidden=true
        if calcMode==2{//VOG
            eyeVelocityLabel.isHidden=true
            headVelocityLabel.isHidden=true
            eyePositionLabelVOG.isHidden=false
            eyeVelocityLabelVOG.isHidden=false
            eyeVelocityLabel.backgroundColor=UIColor.white
            eyeVelocityLabel.textColor=UIColor.black
            headVelocityLabel.backgroundColor=UIColor.white
            headVelocityLabel.textColor=UIColor.black
            vhitpng.isHidden=true
            A2DLabel.isHidden=true
            B2CLabel.isHidden=true
            eyeBorderLabel.isHidden=false
            A2DInput.isHidden = true
            B2CInput.isHidden = true
            eyeBorderInput.isHidden = false
            vorGainCorrectionInput.isHidden = true
            eyeVelocityInput.isHidden = false
            headVelocityInput.isHidden = false
            VorGainCorrectionLabel.isHidden = true
            wakuLengthLabel.frame   = CGRect(x:x2,   y: topY+bh1*3 ,width: tw, height: bh)
            eyeBorderLabel.frame   = CGRect(x:x2,   y: topY+bh1*4 ,width: tw, height: bh)
            gyroText.frame = CGRect(x:5,y:topY+bh1*5,width:ww-10,height: bh*3 )
            gyroText.isHidden=true
            eyeVelocityInput.frame = CGRect(x:x1,y: topY+bh1*1 ,width: bw, height: bh)
            headVelocityInput.frame = CGRect(x:x1,y: topY+bh1*2 ,width: bw, height: bh)
            eyeBorderInput.frame = CGRect(x:x1,y: topY+bh1*4 ,width: bw, height: bh)
            wakuLengthInput.frame = CGRect(x:x1,y: topY+bh1*3 ,width: bw, height: bh)
            
            faceMarkSwitch.frame =     CGRect(x:x1,y: topY+bh1*5 ,width: bw, height: bh)
            markText.frame  = CGRect(x:x2,  y: topY+bh1*5,width:tw,height: bh)
            
            parallelButton.isHidden=true
            parallelLabel.isHidden=true
            oppositeLabel.isHidden=true
            oppositeButton.isHidden=true
            vhitDisplayLabel.isHidden=true
                        
            vHITLabel.isHidden=true
            VOGLabel.isHidden=false
            greenItemLabel.isHidden=true
        }else if calcMode==0 || calcMode==1{//vhit
            eyeVelocityLabel.isHidden=false
            headVelocityLabel.isHidden=false
            lowPassText.isHidden=false
            lowPassFilterSwitch.isHidden=false
            eyePositionLabelVOG.isHidden=true
            eyeVelocityLabelVOG.isHidden=true
            gyroText.isHidden=true
            greenItemLabel.isHidden=false
            vhitpng.isHidden=false
            if Locale.preferredLanguages.first!.contains("ja"){
                vhitpng.image=UIImage(named:"vhit_ja")!
            }else{
                vhitpng.image=UIImage(named:"vhit")!
            }
            A2DLabel.isHidden=false
            B2CLabel.isHidden=false
            eyeBorderLabel.isHidden=false
            A2DInput.isHidden = false
            B2CInput.isHidden = false
            eyeBorderInput.isHidden = false
            vorGainCorrectionInput.isHidden = false
            eyeVelocityInput.isHidden = false
            headVelocityInput.isHidden = false
            VorGainCorrectionLabel.isHidden = false
                
            parallelButton.isHidden=false
            parallelLabel.isHidden=false
            oppositeLabel.isHidden=false
            oppositeButton.isHidden=false
            vhitDisplayLabel.isHidden=false
            
            eyeVelocityLabel.backgroundColor=UIColor.white
            eyeVelocityLabel.textColor=UIColor.systemGreen
            headVelocityLabel.backgroundColor=UIColor.white
            headVelocityLabel.textColor=UIColor.systemGreen
//            timeLagLabel.backgroundColor=UIColor.white
//            timeLagLabel.textColor=UIColor.systemGreen
            vhitDisplayLabel.textColor=UIColor.systemGreen
            vhitDisplayLabel.backgroundColor=UIColor.white
            
            A2DLabel.frame = CGRect(x:x2,   y: topY+bh1*5 ,width: tw, height: bh)
            B2CLabel.frame = CGRect(x:x2,   y: topY+bh1*6 ,width: tw, height: bh)
            eyeVelocityLabel.frame = CGRect(x:x2,   y: topY+bh1*0 ,width: tw, height: bh)
            headVelocityLabel.frame = CGRect(x:x2,   y: topY+bh1*1 ,width: tw, height: bh)
            wakuLengthLabel.frame = CGRect(x:x2,   y: topY+bh1*3 ,width: tw, height: bh)
            eyeBorderLabel.frame = CGRect(x:x2,   y: topY+bh1*4 ,width: tw, height: bh)
            VorGainCorrectionLabel.frame = CGRect(x:x2,   y: topY+bh1*2,width: tw,height:bh)
            var vhitpngH=(ww-10)*440/940
            gyroText.frame  = CGRect(x:5,y: topY+bh1*7+25+ww/4,width:0,height:0)
            A2DInput.frame =  CGRect(x:x1,y: topY+bh1*5 ,width: bw, height: bh)
            B2CInput.frame = CGRect(x:x1,y: topY+bh1*6 ,width: bw, height: bh)
            eyeVelocityInput.frame =     CGRect(x:x1,y: topY+bh1*0 ,width: bw, height: bh)
            headVelocityInput.frame =     CGRect(x:x1,y: topY+bh1*1 ,width: bw, height: bh)
            wakuLengthInput.frame = CGRect(x:x1,y: topY+bh1*3 ,width: bw, height: bh)
            eyeBorderInput.frame =       CGRect(x:x1,y: topY+bh1*4 ,width: bw, height: bh)
            vorGainCorrectionInput.frame = CGRect(x:x1,y: topY+bh1*2 ,width: bw, height: bh)
            vhitpng.frame = CGRect(x:5,y:topY+bh1*7-5,width:ww-10,height:vhitpngH)
            vhitpngH -= 5
            vhitDisplayLabel.frame = CGRect(x:butw*2+4*sp,y: topY+bh1*7+vhitpngH+5 ,width: tw, height: bh)
            parallelLabel.frame = CGRect(x:2*sp,y: topY+bh1*7+vhitpngH,width: butw, height: 3)
            parallelButton.frame = CGRect(x:2*sp,y: topY+bh1*7+vhitpngH+5 ,width: butw, height: bh)
            parallelButton.layer.cornerRadius=3
            oppositeLabel.frame = CGRect(x:butw+3*sp,y:topY+bh1*7+vhitpngH,width:butw,height:3)
            oppositeButton.frame = CGRect(x:butw+3*sp,y:topY+bh1*7+vhitpngH+5,width:butw,height:bh)
            oppositeButton.layer.cornerRadius=3
            greenItemLabel.frame = CGRect(x:x1,y: topY+bh1*8+vhitpngH+5 ,width: view.bounds.width-x1*2, height: bh*2)
            greenItemLabel.layer.masksToBounds = true
            greenItemLabel.layer.cornerRadius = 3
            faceMarkSwitch.frame =     CGRect(x:x1,y: topY+bh1*10+vhitpngH-5 ,width: bw, height: bh)
            lowPassFilterSwitch.frame =     CGRect(x:x1,y: faceMarkSwitch.frame.maxY+sp ,width: bw*3, height: bh)
            lowPassText.frame=CGRect(x:lowPassFilterSwitch.frame.maxX+sp,y: faceMarkSwitch.frame.maxY+sp,width: bw*3, height: lowPassFilterSwitch.frame.height)
            markText.frame  = CGRect(x:x2,  y: topY+bh1*10+vhitpngH-5,width:tw,height: faceMarkSwitch.frame.height)

            displayMode()
            vHITLabel.isHidden=false
            VOGLabel.isHidden=true
            vHITLabel.layer.masksToBounds=true
            greenItemLabel.layer.borderColor = UIColor.green.cgColor
            greenItemLabel.layer.borderWidth = 1.0
        }
        
        defaultButton.frame=CGRect(x:2*sp,y:buty1,width:butw1,height: buth1)
        tovHITButton.frame=CGRect(x:ww/2-butw1-sp/2,y:buty1,width:butw1,height: buth1)
        iroiro.setLabelTopRectangle(vHITLabel, rect: tovHITButton.frame, UIColor.systemRed)
        toVOGButton.frame=CGRect( x:ww/2+sp/2,y:buty1,width:butw1,height: buth1)
        iroiro.setLabelTopRectangle(VOGLabel, rect: toVOGButton.frame, UIColor.systemRed)
        exitButton.frame=CGRect(  x:butw1*4+6*sp,y:buty1,width:butw1,height: buth1)
        registerButton.frame=CGRect(x:butw1*3+5*sp,y:buty1,width:butw1,height: buth1)
        registerButton.isHidden=true
        toVOGButton.isHidden=true
        tovHITButton.isHidden=true
        VOGLabel.isHidden=true
        vHITLabel.isHidden=true
        faceMarkSwitch.isHidden=true
        markText.isHidden=true
        lowPassText.isHidden=true
        lowPassFilterSwitch.isHidden=true
    }
    
    let iroiro = myFunctions(albumName: "vHIT_VOG")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if faceMarkHidden==true{
            markText.isHidden=true
            faceMarkSwitch.isHidden=true
        }
        B2CInput.delegate = self
        A2DInput.delegate = self
        eyeBorderInput.delegate = self
        vorGainCorrectionInput.delegate = self
        eyeVelocityInput.delegate = self
        headVelocityInput.delegate = self
        wakuLengthInput.delegate = self
        lowPassFilterSwitch.selectedSegmentIndex=getUserDefault(str: "lowPassFilterCnt", ret: 4)
        self.B2CInput.keyboardType = UIKeyboardType.numberPad
        self.A2DInput.keyboardType = UIKeyboardType.numberPad
        self.eyeBorderInput.keyboardType = UIKeyboardType.numberPad
        self.wakuLengthInput.keyboardType = UIKeyboardType.numberPad
        self.eyeVelocityInput.keyboardType = UIKeyboardType.numberPad
        self.headVelocityInput.keyboardType = UIKeyboardType.numberPad
        self.vorGainCorrectionInput.keyboardType = UIKeyboardType.numberPad
        dispParam()
        defaultButton.layer.cornerRadius = 5
        exitButton.layer.cornerRadius = 5
        keyDown.layer.cornerRadius = 5
        toVOGButton.layer.cornerRadius=5
        tovHITButton.layer.cornerRadius=5
        registerButton.layer.cornerRadius=5
        keyDown.isHidden = true
        setMaxMin()//念の為パラメータを正常範囲にしておく。
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

