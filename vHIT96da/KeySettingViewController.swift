//
//  KeySettingViewController.swift
//  vHIT96da
//
//  Created by 黒田建彰 on 2023/03/29.
//  Copyright © 2023 tatsuaki.kuroda. All rights reserved.
//

import UIKit

class KeySettingViewController: UIViewController {
    @IBOutlet weak var keyStatusText: UILabel!
    @IBOutlet weak var exitButton: UIButton!
    @IBOutlet weak var mailAddressText: UITextField!
    @IBOutlet weak var keyText: UITextField!
    
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
                keyStatusText.text = "キーはセットされています!"
            }
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        exitButton.layer.cornerRadius=5
        keyTextSet()
    }
    
    @IBAction func onSetKyeButton(_ sender: Any) {
        keyText.endEditing(true)
        mailAddressText.endEditing(true)
        if true{//keyが正しければ
            UserDefaults.standard.set(true,forKey: "keyGet")
        }
        keyTextSet()
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller
    }
    */

}
