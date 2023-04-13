//
//  KeySettingViewController.swift
//  vHIT96da
//
//  Created by 黒田建彰 on 2023/03/29.
//  Copyright © 2023 tatsuaki.kuroda. All rights reserved.
//

import UIKit
import MessageUI
import Foundation
import CryptoKit

// CryptoKit.Digest utils
extension Digest {
    var bytes: [UInt8] { Array(makeIterator()) }
    var data: Data { Data(bytes) }
    var hexStr: String {
        bytes.map { String(format: "%02X", $0) }.joined()
    }
}
class KeySettingViewController: UIViewController,MFMailComposeViewControllerDelegate {
    @IBOutlet weak var keyStatusText: UILabel!
    @IBOutlet weak var exitButton: UIButton!
    
    @IBOutlet weak var how2MailText: UILabel!
    @IBOutlet weak var mailMeButton: UIButton!
    @IBOutlet weak var setKeyButton: UIButton!
    @IBOutlet weak var mailAddressInput: UITextField!
    @IBOutlet weak var passWordInput: UITextField!
//    var userID:String = "x"
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var statementText: UILabel!
    func hashSora(str:String)->String{//get 5char
        let soraStr=str+"sora"
        guard let data = soraStr.data(using: .utf8) else { return "0"}
        let digest = SHA256.hash(data: data)//str2.lowercased()
        return String(digest.hexStr.prefix(5).lowercased())
    }
    @IBAction func onMailMeButton(_ sender: Any) {
        print("mailoneButton")
        
//        let df = DateFormatter()
//        df.locale = Locale(identifier: "ja_JP")
//        df.dateFormat = "HHmmss"
//        print(df.string(from: Date()))
//        UserDefaults.standard.set(df.string(from:Date()), forKey:"userID")
        
        let mailViewController = MFMailComposeViewController()
        mailViewController.mailComposeDelegate = self
        mailViewController.setSubject("vHIT96da PassWowd")
        mailViewController.setToRecipients(["tatsuakikuroda@me.com"])
        if !Locale.preferredLanguages.first!.contains("ja"){
            mailViewController.setMessageBody("name:\neMail:\naffiliation:", isHTML: false)
        }else{
            mailViewController.setMessageBody("所属:\n氏名:\nEメール:", isHTML: false)
        }
        present(mailViewController, animated: true, completion: nil)
    }
    
    @IBAction func passTouchDown(_ sender: Any) {
        keyStatusText.isHidden=true
    }
    @IBAction func mailTouchDown(_ sender: Any) {
        keyStatusText.isHidden=true
    }
    func keyTextSet(){
//        let str=UserDefaults.standard.string(forKey: "passWord")
        let str1=mailAddressInput.text
        let str2=passWordInput.text
        if str1 != str2{//}"nil" || str=="???"{
            if Locale.preferredLanguages.first!.contains("ja"){
                keyStatusText.text = "ID-PassWord ??"
            }else{
                keyStatusText.text = "ID-PassWord ??"
            }
            print("keyGet:false")
            
        }else{
            if Locale.preferredLanguages.first!.contains("ja"){
                keyStatusText.text = "ID-PassWord OK!"
            }else{
                keyStatusText.text = "ID-PassWord OK!"
            }
            print("kegyGet:true")
         }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
//        let passWord=UserDefaults.standard.string(forKey:"passWord")!
//        print("passWord:",passWord)
//        let df = DateFormatter()
//        df.locale = Locale(identifier: "ja_JP")
//        df.dateFormat = "HHmmss"
//        print(df.string(from: Date()))
        
 
        let wh=view.bounds.height
        let ww=view.bounds.width
        let bottom=CGFloat( UserDefaults.standard.float(forKey: "bottom"))
        let top=CGFloat(UserDefaults.standard.float(forKey: "top"))
        print("top:",top)
//        let bottom:CGFloat=10
//        let top:CGFloat=10
        let sp:CGFloat=5
        let bw:CGFloat=60
        let bh:CGFloat=30
   
        statementText.frame=CGRect(x:20,y:top+20,width: ww-40,height:wh-bottom-2*sp-bh*2-top-20)
        if Locale.preferredLanguages.first!.contains("ja"){
            statementText.text="医師、理学療法士が利用するvHITアプリです。自作可能なiPhone固定ゴーグルとiPhoneでvHITが行えます。日本国内で研究用として承認されています。\nこのアプリは研究用としてのみご利用ください。"/*使用に際しては、参加者または未成年の場合はその親または保護者から同意を得る必要があります。その同意には、\n（a）研究の性質、目的および期間\n（b）手順、参加者に対するリスクおよび利益\n（c）データの機密保持および取り扱い（第三者との共有を含む）に関する情報\n（d）参加者からの質問に対する連絡先\n（e）撤回手続\nが含まれなければなりません。*/
        }else{
            statementText.text="This application is used by physicians and physical therapists. With this app, vHIT can be perfomed with goggles that can be made by the user. This vHIT has been approved for reserch use in Japnan.\nThis application is for research use only."/*Before using this application obtain consent from participants or, in the case of minors, their parent or guardian. Such consent must include \n(a) nature, purpose\nduration of the research\n(b) procedures, risks, and benefits to the participant\n(c) information about confidentiality and handling of data (including any sharing with third parties)\na point of contact for participant questions\n(e) the withdrawal process."*/
        }//This application is for research use only.
        nextButton.frame=CGRect(x:ww/2-bw,y:wh-bottom-2*sp-bh*2,width: bw*2,height: bh*2)
        nextButton.layer.cornerRadius=5
        exitButton.frame=CGRect(x:ww/2-bw,y:wh-bottom-2*sp-bh*2,width: bw*2,height: bh*2)
        exitButton.layer.cornerRadius=5
//        keyStatusText.frame=CGRect(x:30,y:wh-bottom-2*sp-bh*2-34-10,width:ww-60,height: 34)
        mailAddressInput.keyboardType = .emailAddress
        passWordInput.keyboardType = .asciiCapable
        exitButton.isHidden=true
//        if passWord=="nil"{
//            exitButton.isHidden=true
            keyStatusText.isHidden=true
//        }else{//mailAdd=="???"
//            statementText.isHidden=true
////            exitButton.isHidden=true
//            nextButton.isHidden=true
//            mailMeButton.isHidden=true
//            how2MailText.isHidden=true
//            keyStatusText.isHidden=true
//        }
        keyTextSet()
    }
    
    @IBAction func onNextButton(_ sender: Any) {
        UserDefaults.standard.set("ok",forKey: "passWord")

        performSegue(withIdentifier: "KeySet2Main", sender: self)

//        statementText.isHidden=true
//        nextButton.isHidden=true
    }
    /*
     var mess="This application is used by physicians and physical therapists. With this app, vHIT can be perfomed with goggles that can be made by the user and an iPhone. This vHIT has been approved for reserch use in Japnan.\nBefore using this application obtain consent from participants or, in the case of minors, their parent or guardian. Such consent must include the (a) nature, purpose, and duration of the research; (b) procedures, risks, and benefits to the participant; (c) information about confidentiality and handling of data (including any sharing with third parties); (d) a point of contact for participant questions; and (e) the withdrawal process.\nTo use this app, you must go to the registration page from the Settings page and set up a key. Please apply for a key with your name, email address, and affiliation. Once the key is set, all functions will be available."
//        if Locale.preferredLanguages.first!.contains("ja"){
//            title="vHITアプリ"
//            okText="OK"
//            mess="医師、理学療法士が利用するvHITアプリです。自作可能なiPhone固定ゴーグルとiPhoneでvHITが行えます。日本国内で研究用として承認されています。\n使用に際しては、参加者または未成年の場合はその親または保護者から同意を得る必要があります。その同意には、（a）研究の性質、目的および期間、（b）手順、参加者に対するリスクおよび利益、（c）データの機密保持および取り扱い（第三者との共有を含む）に関する情報、（d）参加者からの質問に対する連絡先、および（e）撤回手続が含まれなければなりません。このアプリを使用するためには、設定ページから登録ページに行き、キーを設定する必要があります。氏名、メールアドレス、所属を記載してキーを申請して下さい。キーを設定すると全ての機能が利用可能となります。"

     */
    @IBAction func onSetKeyButton(_ sender: Any) {
        passWordInput.endEditing(true)
        mailAddressInput.endEditing(true)
        keyStatusText.isHidden=true
        let str=hashSora(str: mailAddressInput.text!)
        print("hash5:",str)
        print("pwd:",passWordInput.text)
        if str == passWordInput.text{
            UserDefaults.standard.set(str,forKey: "passWord")
            exitButton.isEnabled=true
            exitButton.alpha=1.0
            keyStatusText.isHidden=true
  //          keyTextSet()
            performSegue(withIdentifier: "KeySet2Main", sender: self)
        }else{
            keyStatusText.isHidden=false
            keyTextSet()
        }
    }
  
    @IBAction func panGestureRec(_ sender: UIPanGestureRecognizer) {
   
        if sender.state == .ended{
            let move = sender.translation(in: self.view)
            if ( move.y > 5 || move.y < -5 || move.x > 5 || move.x < -5)
            {
                mailAddressInput.endEditing(true)
                passWordInput.endEditing(true)
            }
        }
    }
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {//errorの時に通る
        
        switch result {
        case .cancelled:
            print("cancel1")
        case .saved:
            print("save")
        case .sent:
            print("send")
        case .failed:
            print("fail")
        @unknown default:
            print("unknown error")
        }
        self.dismiss(animated: true, completion: nil)
    }
}

