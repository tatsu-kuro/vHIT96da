//
//  PlayVideoViewController.swift
//  vHIT96da
//
//  Created by kuroda tatsuaki on 2018/04/06.
//  Copyright © 2018年 tatsuaki.kuroda. All rights reserved.
//

import UIKit

class PlayVideoViewController: UIViewController {
    var videoPath:String = ""
    
    @IBOutlet weak var pathLabel: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        print(videoPath)
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
