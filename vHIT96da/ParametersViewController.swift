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
    }
}

class ParametersViewController: UIViewController, UITextFieldDelegate {
    var bottomPadding:CGFloat=0
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if #available(iOS 11.0, *) {
            bottomPadding = self.view.safeAreaInsets.bottom
        }
        setTexts()
    }
    @IBOutlet weak var exitButton: UIButton!
    
    @IBOutlet weak var registerButton: UIButton!
    func getUserDefault(str:String,ret:Int) -> Int{//getUserDefault_one
        if (UserDefaults.standard.object(forKey: str) != nil){//keyが設定してなければretをセット
            return UserDefaults.standard.integer(forKey:str)
        }else{
            UserDefaults.standard.set(ret, forKey: str)
            return ret
        }
    }
    
    @IBAction func unwindPara(_ segue: UIStoryboardSegue){
    }
    
    
    @IBAction func onExitButton(_ sender: Any) {
        performSegue(withIdentifier: "fromParamsToMain", sender: nil)
        
    }
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    @IBOutlet weak var defaultButton: UIButton!
    
    @IBOutlet weak var vhitDisplayLabel: UILabel!
    @IBOutlet weak var parallelButton: UIButton!
    
    @IBOutlet weak var oppositeButton: UIButton!
    
    @IBOutlet weak var parallelLabel: UILabel!
    @IBOutlet weak var lowPassText: UILabel!
    
    @IBOutlet weak var lowPassFilterSwitch: UISegmentedControl!
    @IBOutlet weak var oppositeLabel: UILabel!
    @IBAction func onLowPassFilterSwitch(_ sender: Any) {
        let index=lowPassFilterSwitch.selectedSegmentIndex
        UserDefaults.standard.set(index, forKey: "lowPassFilterCnt")
        print("selectedSegmentIndex",index)
    }
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
    
    var widthRange:Int = 0
    var waveWidth:Int = 0
    var eyeBorder:Int = 0
    var videoGyroZure:Int = 0
    
    var eyeRatio:Int = 0
    var gyroRatio:Int = 0
    
    var wakuLength:Int = 0
    var calcMode:Int?
    var vHITDisplayMode:Int = 0
    
    @IBOutlet weak var A2DLabel: UILabel!
    @IBOutlet weak var B2CLabel: UILabel!
    
    @IBOutlet weak var wakuLengthLabel: UILabel!
    @IBOutlet weak var eyeBorderLabel: UILabel!
    @IBOutlet weak var wakuLengthInput: UITextField!
    
    @IBOutlet weak var vhitpng: UIImageView!
    @IBOutlet weak var keyDown: UIButton!
    @IBOutlet weak var B2CInput: UITextField!
    @IBOutlet weak var A2DInput: UITextField!
    @IBOutlet weak var eyeBorderInput: UITextField!
    
    
    @IBAction func wakuLengthAction(_ sender: Any) {
        wakuLength = Field2value(field: wakuLengthInput)
    }
    
    // became first responder
    func textFieldDidBeginEditing(_ textField: UITextField) {
        keyDown.isHidden = false
    }
    
    @IBAction func tapBack(_ sender: Any) {
        numpadOff(0)
    }
    func setMaxMin(){
        
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
        
    }
    @IBAction func numpadOff(_ sender: Any) {
        wakuLengthInput.endEditing(true)
        B2CInput.endEditing(true)
        A2DInput.endEditing(true)
        eyeBorderInput.endEditing(true)
        
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
            videoGyroZure = 2
            eyeRatio = 300
            gyroRatio = 170
            wakuLength = 3
            
        }else{
            eyeBorder=10
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
    }
    
    func dispParam(){
        self.B2CInput.text = "\(widthRange)"
        self.A2DInput.text = "\(waveWidth)"
        self.eyeBorderInput.text = "\(eyeBorder)"
        
        self.wakuLengthInput.text = "\(wakuLength)"
        
    }
    
    func setTexts(){
        let ww=view.bounds.width
        let bottom=CGFloat( UserDefaults.standard.float(forKey: "bottom"))
        
        let sp:CGFloat=5
        let topY = CGFloat( UserDefaults.standard.float(forKey: "top"))+sp*2//keyDown.frame.minY// vhitpng.frame.minY
        let bw:CGFloat=55
        let bh:CGFloat=25
        let bh1=bh+7
        
        let tw:CGFloat=ww-bw-10
        let x1:CGFloat=3
        let x2=x1+bw+5
        
        let butw=(view.bounds.width-sp*7)/4
        let buth=butw/2
        let butw1=(view.bounds.width-sp*8)/5
        let buth1=butw1/2
        let buty1=view.bounds.height-sp-buth1-bottom
        
        keyDown.frame=CGRect(x:ww-butw-sp*2,y:topY,width: butw,height: buth)
        
        
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
        
        parallelButton.isHidden=false
        parallelLabel.isHidden=false
        oppositeLabel.isHidden=false
        oppositeButton.isHidden=false
        vhitDisplayLabel.isHidden=false
        
        A2DLabel.frame = CGRect(x:x2,   y: topY+bh1*5 ,width: tw, height: bh)
        B2CLabel.frame = CGRect(x:x2,   y: topY+bh1*6 ,width: tw, height: bh)
        wakuLengthLabel.frame = CGRect(x:x2,   y: topY+bh1*3 ,width: tw, height: bh)
        eyeBorderLabel.frame = CGRect(x:x2,   y: topY+bh1*4 ,width: tw, height: bh)
        var vhitpngH=(ww-10)*440/940
        A2DInput.frame =  CGRect(x:x1,y: topY+bh1*5 ,width: bw, height: bh)
        B2CInput.frame = CGRect(x:x1,y: topY+bh1*6 ,width: bw, height: bh)
        wakuLengthInput.frame = CGRect(x:x1,y: topY+bh1*3 ,width: bw, height: bh)
        eyeBorderInput.frame =       CGRect(x:x1,y: topY+bh1*4 ,width: bw, height: bh)
        vhitpng.frame = CGRect(x:5,y:topY+bh1*7-5,width:ww-10,height:vhitpngH)
        vhitpngH -= 5
        vhitDisplayLabel.frame = CGRect(x:butw*2+4*sp,y: topY+bh1*7+vhitpngH+5 ,width: tw, height: bh)
        parallelLabel.frame = CGRect(x:2*sp,y: topY+bh1*7+vhitpngH,width: butw, height: 3)
        parallelButton.frame = CGRect(x:2*sp,y: topY+bh1*7+vhitpngH+5 ,width: butw, height: bh)
        parallelButton.layer.cornerRadius=3
        oppositeLabel.frame = CGRect(x:butw+3*sp,y:topY+bh1*7+vhitpngH,width:butw,height:3)
        oppositeButton.frame = CGRect(x:butw+3*sp,y:topY+bh1*7+vhitpngH+5,width:butw,height:bh)
        oppositeButton.layer.cornerRadius=3
        lowPassText.frame=CGRect(x:2*sp,y: parallelButton.frame.maxY+3*sp,width: ww, height: lowPassFilterSwitch.frame.height)
        lowPassFilterSwitch.frame = CGRect(x:2*sp,y: lowPassText.frame.maxY ,width: bw*3, height: bh)
        lowPassFilterSwitch.selectedSegmentIndex=getUserDefault(str: "lowPassFilterCnt", ret: 4)

        displayMode()
        
        defaultButton.frame=CGRect(x:2*sp,y:buty1,width:butw1,height: buth1)
        exitButton.frame=CGRect(  x:butw1*4+6*sp,y:buty1,width:butw1,height: buth1)
        registerButton.isHidden=true
    }
    
    let iroiro = myFunctions(albumName: "vHIT_VOG")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        B2CInput.delegate = self
        A2DInput.delegate = self
        eyeBorderInput.delegate = self
        wakuLengthInput.delegate = self
        self.B2CInput.keyboardType = UIKeyboardType.numberPad
        self.A2DInput.keyboardType = UIKeyboardType.numberPad
        self.eyeBorderInput.keyboardType = UIKeyboardType.numberPad
        self.wakuLengthInput.keyboardType = UIKeyboardType.numberPad
        dispParam()
        defaultButton.layer.cornerRadius = 5
        exitButton.layer.cornerRadius = 5
        keyDown.layer.cornerRadius = 5
        
        keyDown.isHidden = true
        lowPassFilterSwitch.selectedSegmentIndex=getUserDefault(str: "lowPassFilterCnt", ret: 4)

        setMaxMin()//念の為パラメータを正常範囲にしておく。
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

