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
    
//    var topPadding:CGFloat = 0
//    var bottomPadding:CGFloat = 0
//    var leftPadding:CGFloat = 0
//    var rightPadding:CGFloat = 0
//    override func viewDidLayoutSubviews() {
//        super.viewDidLayoutSubviews()
//        if #available(iOS 11.0, *) {
//            // viewDidLayoutSubviewsではSafeAreaの取得ができている
//            topPadding = self.view.safeAreaInsets.top
//            bottomPadding = self.view.safeAreaInsets.bottom
//            leftPadding = self.view.safeAreaInsets.left
//            rightPadding = self.view.safeAreaInsets.right
//            print("in viewDidLayoutSubviews")
//            print(topPadding,bottomPadding,leftPadding,rightPadding)    // iPhoneXなら44, その他は20.0
//        }
 //        setButtons()
//    }
//    @IBOutlet weak var markdispSwitch: UISwitch!
//    @IBOutlet weak var markdispText: UILabel!
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        setTexts()
    }
    @IBOutlet weak var markText: UILabel!
    @IBOutlet weak var faceFbutton: UISwitch!
    @IBOutlet weak var exitButton: UIButton!
    
    @IBOutlet weak var changeModeButton: UIButton!
    @IBAction func onChangeModeButton(_ sender: Any) {
        if calcMode != 2{
            calcMode=2
        }else{
            calcMode=0
        }
        dispParam()
        setTexts()
    }
    @IBOutlet weak var defaultButton: UIButton!
    
//    @IBOutlet weak var damyTop: UILabel!
 
    var okpMode:Int = 0

    @IBOutlet weak var changeDisplayLabel: UILabel!
    @IBOutlet weak var changeDisplayButton: UIButton!
    func displayMode(){
        if vHITDisplayMode == 0{
            changeDisplayLabel.text="type A"
        }else{
            changeDisplayLabel.text="type B"
        }
    }
    @IBAction func onChangeDisplayButton(_ sender: Any) {
        if vHITDisplayMode == 0{
           vHITDisplayMode=1
        }else{
            vHITDisplayMode=0
        }
        displayMode()
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
        if calcMode != 2{
            eyeRatio = Field2value(field: ratio1input)
        }else{
            posRatio = Field2value(field: ratio1input)
        }
    }
    
    @IBAction func ratio2Button(_ sender: Any) {
        if calcMode != 2{
            gyroRatio = Field2value(field: ratio2input)
        }else{
            veloRatio = Field2value(field: ratio2input)
        }
    }
    
    func dispParam(){
        self.widthRangeinput.text = "\(widthRange)"
        self.waveWidthinput.text = "\(waveWidth)"
        self.eyeBinput.text = "\(eyeBorder)"
        self.videoGyroZureinput.text = "\(videoGyroZure)"
        if calcMode != 2{
            self.ratio1input.text = "\(eyeRatio)"
            self.ratio2input.text = "\(gyroRatio)"
        }else{
            self.ratio1input.text = "\(posRatio)"
            self.ratio2input.text = "\(veloRatio)"
        }
        self.wakuLengthInput.text = "\(wakuLength)"
        if useFaceMark==0{
            self.faceFbutton.isOn=false
        }else{
            self.faceFbutton.isOn=true
        }
    }
    /*
    func onEditEttParaButton() {
        
        let alert = UIAlertController(title: "", message: "", preferredStyle: .alert)
//        alert.textFields![0].text!="kiiii"
        let saveAction = UIAlertAction(title: "OK", style: .default) { [self] (action:UIAlertAction!) -> Void in
            // 入力したテキストをコンソールに表示
            let textField = alert.textFields![0] as UITextField
            let ettString:String = textField.text!
            if ettString.isAlphanumeric(){//} isOnly(structuredBy: "0123456789:,") == true
//                if ettMode==0{
//                    ettModeTxt0=ettString
//                }else if ettMode==1{
//                    ettModeTxt1=ettString
//                }else if ettMode==2{
//                    ettModeTxt2=ettString
//                }else{
//                    ettModeTxt3=ettString
//                }
//                setUserDefaults()
//                paraTxt6.text=ettString
                print(ettString)
            }else{
                let dialog = UIAlertController(title: "", message: "0123456789 only.", preferredStyle: .alert)
                //ボタンのタイトル
                dialog.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                //実際に表示させる
                self.present(dialog, animated: true, completion: nil)
//                print(",:0123456789以外は受け付けません")
            }
//            print("\(String(describing: textField.text))")
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .default) { (action:UIAlertAction!) -> Void in
        }
        // UIAlertControllerにtextFieldを追加
        alert.addTextField { (textField:UITextField!) -> Void in
            textField.keyboardType = UIKeyboardType.default//.numberPad
//            if self.ettMode==0{
//                textField.text=self.ettModeTxt0
//            }else if self.ettMode==1{
//                textField.text=self.ettModeTxt1
//            }else if self.ettMode==2{
//                textField.text=self.ettModeTxt2
//            }else{
//                textField.text=self.ettModeTxt3
//            }
        }
        alert.addAction(cancelAction)//この行と下の行の並びを変えるとCancelとOKの左右が入れ替わる。
        alert.addAction(saveAction)
        present(alert, animated: true, completion: nil)
    }
    */
    func setTexts(){
        let topY = keyDown.frame.minY// vhitpng.frame.minY
        let ww:CGFloat=view.bounds.width
//        let wh:CGFloat=view.bounds.height
        let bw:CGFloat=55
        let bh:CGFloat=25
        let bh1=bh+7
        
        paraText5.text = "matching square width"
        paraText6.text = "max moving width / frame"

//        let versionNumber = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
        let tw:CGFloat=ww-bw-10
        let x1:CGFloat=3
        let x2=x1+bw+5
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
            paraText2.frame   = CGRect(x:x2,   y: topY ,width: tw, height: bh)
            paraText3.frame   = CGRect(x:x2,   y: topY+bh1*1,width: tw, height: bh)
            paraText4.frame   = CGRect(x:x2,   y: topY+bh1*2 ,width: tw, height: bh)
            paraText5.frame   = CGRect(x:x2,   y: topY+bh1*3 ,width: tw, height: bh)
            paraText6.frame   = CGRect(x:x2,   y: topY+bh1*4 ,width: tw, height: bh)
            gyroText.frame = CGRect(x:5,y:topY+bh1*5,width:ww-10,height: bh*3 )
//            gyroText.text! = "vHIT96da Version " + versionNumber
            gyroText.isHidden=true
            ratio1input.frame = CGRect(x:x1,y: topY+bh1*1 ,width: bw, height: bh)
            ratio2input.frame = CGRect(x:x1,y: topY+bh1*2 ,width: bw, height: bh)
            eyeBinput.frame = CGRect(x:x1,y: topY+bh1*4 ,width: bw, height: bh)
            wakuLengthInput.frame = CGRect(x:x1,y: topY+bh1*3 ,width: bw, height: bh)
            changeDisplayButton.isHidden=true
            changeDisplayLabel.isHidden=true
        }else{//vhit
//            topY=ww*390/937
            
            
            markText.isHidden = false
            faceFbutton.isHidden = false
            vhitpng.isHidden=false
            paraText1.isHidden=false
            paraText6.isHidden=false
            waveWidthinput.isHidden = false
            widthRangeinput.isHidden = false
            eyeBinput.isHidden = false
            videoGyroZureinput.isHidden = false
            ratio1input.isHidden = false
            ratio2input.isHidden = false
            paraText7.isHidden = false
            changeDisplayButton.isHidden=false
            changeDisplayLabel.isHidden=false

            paraText1.text = "(1) time(ms) from A to D"
            paraText2.text = "(2) time(ms) from B to C"
            paraText3.text = "eye velocity height ％"
            paraText4.text = "head velocity height ％"
            paraText7.text = "eye and head time lag"
            markText.text = "use of the mark on face"
            paraText1.frame = CGRect(x:x2,   y: topY+bh1*5 ,width: tw, height: bh)
            paraText2.frame = CGRect(x:x2,   y: topY+bh1*6 ,width: tw, height: bh)
            paraText3.frame = CGRect(x:x2,   y: topY+bh1*0 ,width: tw, height: bh)
            paraText4.frame = CGRect(x:x2,   y: topY+bh1*1 ,width: tw, height: bh)
            paraText5.frame = CGRect(x:x2,   y: topY+bh1*3 ,width: tw, height: bh)
            paraText6.frame = CGRect(x:x2,   y: topY+bh1*4 ,width: tw, height: bh)
            paraText7.frame = CGRect(x:x2,   y: topY+bh1*2,width: tw,height:bh)
            let vhitpngH=(ww-10)*440/940
            markText.frame  = CGRect(x:x2,  y: topY+bh1*7+vhitpngH+10,width:tw,height: bh)
//            faceFbutton.isHidden=true
//            markText.isHidden=true
//            markText.frame  = CGRect(x:x2+4, y: topY+by+bh1*7+3,width:tw,height:bh)
            gyroText.frame  = CGRect(x:5,y: topY+bh1*7+25+ww/4,width:0,height:0)
            waveWidthinput.frame =  CGRect(x:x1,y: topY+bh1*5 ,width: bw, height: bh)
            widthRangeinput.frame = CGRect(x:x1,y: topY+bh1*6 ,width: bw, height: bh)
            ratio1input.frame =     CGRect(x:x1,y: topY+bh1*0 ,width: bw, height: bh)
            ratio2input.frame =     CGRect(x:x1,y: topY+bh1*1 ,width: bw, height: bh)
            wakuLengthInput.frame = CGRect(x:x1,y: topY+bh1*3 ,width: bw, height: bh)
            eyeBinput.frame =       CGRect(x:x1,y: topY+bh1*4 ,width: bw, height: bh)
            videoGyroZureinput.frame = CGRect(x:x1,y: topY+bh1*2 ,width: bw, height: bh)
            faceFbutton.frame =     CGRect(x:x1,y: topY+bh1*7+vhitpngH+10 ,width: bw, height: bh)
            vhitpng.frame = CGRect(x:5,y:topY+bh1*7,width:ww-10,height:vhitpngH)
            changeDisplayLabel.frame = CGRect(x:x1+ww/2+5,y: topY+bh1*8+vhitpngH+20 ,width: ww/2, height: bh)
            changeDisplayButton.frame = CGRect(x:x1,y: topY+bh1*8+vhitpngH+20 ,width: ww/2, height: bh)
            changeDisplayButton.layer.cornerRadius=3
            displayMode()
        }
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
        dispParam()
        defaultButton.layer.cornerRadius = 5
        exitButton.layer.cornerRadius = 5
        keyDown.layer.cornerRadius = 5
        changeModeButton.layer.cornerRadius=5
        keyDown.isHidden = true
//        setTexts()
    }
//    override func viewDidAppear(_ animated: Bool) {
//        setTexts()
//    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

