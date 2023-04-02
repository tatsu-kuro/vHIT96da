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
    @IBOutlet weak var mailAddressText: UITextField!
    @IBOutlet weak var keyText: UITextField!
    
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var statementLabel: UILabel!
    func hashSora(str:String)->String{//get 20char
        let soraStr=str+"sora"
        guard let data = soraStr.data(using: .utf8) else { return "0"}
        let digest = SHA256.hash(data: data)
 //       print("digest.data:",digest.data) // 32 bytes
   //     print("digest.hexStr:",digest.hexStr) // B94D27B9934D3E08A52E52D7DA7DABFAC484EFE37A5380EE9088F7ACE2EFCDE9
        return String(digest.hexStr.prefix(20))
    }
    @IBAction func eMailMe(_ sender: Any) {
        print("mailoneButton")
        let mailViewController = MFMailComposeViewController()
        mailViewController.mailComposeDelegate = self
        mailViewController.setSubject("vHIT96da Key")
        mailViewController.setToRecipients(["tatsuakikuroda@me.com"])
        if !Locale.preferredLanguages.first!.contains("ja"){
            mailViewController.setMessageBody("name:\neMail:\naffiliation:", isHTML: false)
        }else{
            mailViewController.setMessageBody("所属:\n氏名:\nEメール:", isHTML: false)
        }
        present(mailViewController, animated: true, completion: nil)
    }
    
    func keyTextSet(){
        if UserDefaults.standard.bool(forKey: "keyGet")==false{
            if Locale.preferredLanguages.first!.contains("ja"){
                keyStatusText.text = "キーはセットされていません!"
            }else{
                keyStatusText.text = "Key is not set yet!"
            }
            print("keyGet:false")
        }else{
            if Locale.preferredLanguages.first!.contains("ja"){
                keyStatusText.text = "キーはセットされました!"
            }else{
                keyStatusText.text = "Key is set already!"
            }
            print("kegyGet:true")
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
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
   
        statementLabel.frame=CGRect(x:10,y:top+20,width: ww-20,height: wh-top-bottom-20-sp-bh*2)
        if Locale.preferredLanguages.first!.contains("ja"){
            statementLabel.text="医師、理学療法士が利用するvHITアプリです。自作可能なiPhone固定ゴーグルとiPhoneでvHITが行えます。日本国内で研究用として承認されています。\n使用に際しては、参加者または未成年の場合はその親または保護者から同意を得る必要があります。その同意には、\n（a）研究の性質、目的および期間\n（b）手順、参加者に対するリスクおよび利益\n（c）データの機密保持および取り扱い（第三者との共有を含む）に関する情報\n（d）参加者からの質問に対する連絡先\n（e）撤回手続\nが含まれなければなりません。"
        }else{
            statementLabel.text="This application is used by physicians and physical therapists. With this app, vHIT can be perfomed with goggles that can be made by the user and an iPhone. This vHIT has been approved for reserch use in Japnan.\nBefore using this application obtain consent from participants or, in the case of minors, their parent or guardian. Such consent must include \n(a) nature, purpose\nduration of the research\n(b) procedures, risks, and benefits to the participant\n(c) information about confidentiality and handling of data (including any sharing with third parties)\na point of contact for participant questions\n(e) the withdrawal process."
        }
        nextButton.frame=CGRect(x:ww/2-bw/2,y:wh-bottom-2*sp-bh,width: bw,height: bh)
        nextButton.layer.cornerRadius=5
        exitButton.frame=CGRect(x:ww/2-bw,y:wh-bottom-2*sp-bh*2,width: bw*2,height: bh*2)
        exitButton.layer.cornerRadius=5
        keyStatusText.frame=CGRect(x:30,y:wh-bottom-2*sp-bh*2-34-10,width:ww-60,height: 34)
        exitButton.isHidden=true
//        statementLabel.isHidden=true
        mailAddressText.keyboardType = .emailAddress
        keyTextSet()
    }
    
    @IBAction func onNextButton(_ sender: Any) {
        statementLabel.isHidden=true
        nextButton.isHidden=true
        exitButton.isHidden=false
        exitButton.isEnabled=false
        exitButton.alpha=0.1
    }
    /*
     var mess="This application is used by physicians and physical therapists. With this app, vHIT can be perfomed with goggles that can be made by the user and an iPhone. This vHIT has been approved for reserch use in Japnan.\nBefore using this application obtain consent from participants or, in the case of minors, their parent or guardian. Such consent must include the (a) nature, purpose, and duration of the research; (b) procedures, risks, and benefits to the participant; (c) information about confidentiality and handling of data (including any sharing with third parties); (d) a point of contact for participant questions; and (e) the withdrawal process.\nTo use this app, you must go to the registration page from the Settings page and set up a key. Please apply for a key with your name, email address, and affiliation. Once the key is set, all functions will be available."
//        if Locale.preferredLanguages.first!.contains("ja"){
//            title="vHITアプリ"
//            okText="OK"
//            mess="医師、理学療法士が利用するvHITアプリです。自作可能なiPhone固定ゴーグルとiPhoneでvHITが行えます。日本国内で研究用として承認されています。\n使用に際しては、参加者または未成年の場合はその親または保護者から同意を得る必要があります。その同意には、（a）研究の性質、目的および期間、（b）手順、参加者に対するリスクおよび利益、（c）データの機密保持および取り扱い（第三者との共有を含む）に関する情報、（d）参加者からの質問に対する連絡先、および（e）撤回手続が含まれなければなりません。このアプリを使用するためには、設定ページから登録ページに行き、キーを設定する必要があります。氏名、メールアドレス、所属を記載してキーを申請して下さい。キーを設定すると全ての機能が利用可能となります。"

     */
    @IBAction func onSetKeyButton(_ sender: Any) {
        keyText.endEditing(true)
        mailAddressText.endEditing(true)
        let str=hashSora(str: mailAddressText.text!)
        print("hash20:",str)
        if str == keyText.text{
            UserDefaults.standard.set(true,forKey: "keyGet")
//            exitButton.isHidden=false
            exitButton.isEnabled=true
            exitButton.alpha=1.0
        }
        keyTextSet()
    }
  
    @IBAction func panGestureRec(_ sender: UIPanGestureRecognizer) {
   
        if sender.state == .ended{
            let move = sender.translation(in: self.view)
            if ( move.y > 5 || move.y < -5)
            {
                mailAddressText.endEditing(true)
                keyText.endEditing(true)
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

