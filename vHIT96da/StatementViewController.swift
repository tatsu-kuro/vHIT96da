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

class StatementViewController: UIViewController{
    @IBOutlet weak var exitButton: UIButton!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var statementText: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        let wh=view.bounds.height
        let ww=view.bounds.width
        let bottom=CGFloat( UserDefaults.standard.float(forKey: "bottom"))
        let top=CGFloat(UserDefaults.standard.float(forKey: "top"))
        print("top:",top)
        let sp:CGFloat=5
        let bw:CGFloat=60
        let bh:CGFloat=30
   
        statementText.frame=CGRect(x:20,y:top+20,width: ww-40,height:wh-bottom-2*sp-bh*2-top-20)
        if Locale.preferredLanguages.first!.contains("ja"){
            statementText.text="医師、理学療法士が利用するvHITアプリです。自作可能なiPhone固定ゴーグルとiPhoneでvHITが行えます。日本国内で研究用として承認されています。\nこのアプリは研究用としてのみご利用ください。"
        }else{
            statementText.text="This application is used by physicians and physical therapists. With this app, vHIT can be perfomed with goggles that can be made by the user. This vHIT has been approved for reserch use in Japnan.\nThis application is for research use only."
        }//This application is for research use only.
        nextButton.frame=CGRect(x:ww/2-bw,y:wh-bottom-2*sp-bh*2,width: bw*2,height: bh*2)
        nextButton.layer.cornerRadius=5
        exitButton.frame=CGRect(x:ww/2-bw,y:wh-bottom-2*sp-bh*2,width: bw*2,height: bh*2)
        exitButton.layer.cornerRadius=5
        exitButton.isHidden=true

    }
    
    @IBAction func onNextButton(_ sender: Any) {
        UserDefaults.standard.set("yes",forKey: "installed")
        performSegue(withIdentifier: "KeySet2Main", sender: self)
    }
}

