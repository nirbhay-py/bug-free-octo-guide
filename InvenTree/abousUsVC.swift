//
//  abousUsVC.swift
//  InvenTree
//
//  Created by Nirbhay Singh on 08/04/20.
//  Copyright © 2020 Nirbhay Singh. All rights reserved.
//

import UIKit
import JGProgressHUD
class abousUsVC: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.hideKeyboardWhenTappedAround()
        // Do any additional setup after loading the view.
    }
    @IBAction func submit(_ sender: Any) {
        let hud = JGProgressHUD.init()
        hud.show(in:self.view)
        do {
            sleep(1)
        }
        hud.dismiss()
        showSuccess(msg: "Your message has been recorded!")
    }
    
}
