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
    
    func hashSora(str:String)->String{
        let soraStr=str+"sora"
        guard let data = soraStr.data(using: .utf8) else { return "0"}
        let digest = SHA256.hash(data: data)
 //       print("digest.data:",digest.data) // 32 bytes
   //     print("digest.hexStr:",digest.hexStr) // B94D27B9934D3E08A52E52D7DA7DABFAC484EFE37A5380EE9088F7ACE2EFCDE9
        return digest.hexStr
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
        if !Locale.preferredLanguages.first!.contains("ja"){
            if UserDefaults.standard.bool(forKey: "keyGet")==false{
                keyStatusText.text = "Key is not set yet!"
            }else{
                keyStatusText.text = "Key is set already!"
            }
        }else{
            if UserDefaults.standard.bool(forKey: "keyGet")==false{
                keyStatusText.text = "キーはセットされていません!"
            }else{
                keyStatusText.text = "キーはセットされました!"
            }
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        exitButton.layer.cornerRadius=5
        keyTextSet()
    }
    
    @IBAction func onSetKeyButton(_ sender: Any) {
        keyText.endEditing(true)
        mailAddressText.endEditing(true)
        let str=hashSora(str: mailAddressText.text!)
        if str.contains(keyText.text!) && keyText.text!.utf8.count>25{
            UserDefaults.standard.set(true,forKey: "keyGet")
        }
        print("**key**:",str)
        keyTextSet()
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

