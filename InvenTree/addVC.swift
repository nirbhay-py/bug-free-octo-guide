//
//  addVC.swift
//  InvenTree
//
//  Created by Nirbhay Singh on 23/03/20.
//  Copyright © 2020 Nirbhay Singh. All rights reserved.
//

import UIKit

class addVC: UIViewController {
    @IBOutlet weak var welcomeLbl: UILabel!
    
    @IBOutlet weak var addEps: UIButton!
    @IBOutlet weak var addIssue: UIButton!
    @IBOutlet weak var addTree: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        welcomeLbl.text = "Hi, "+globalUser.givenName+". You can add issues, trees, and empty planting sites to the InvenTree Map by following the directions below."
        let backButton = UIBarButtonItem(title: "", style: .plain, target: navigationController, action: nil)
        navigationItem.leftBarButtonItem = backButton
        addIssue.layer.cornerRadius = 15
        addEps.layer.cornerRadius = 15
        addTree.layer.cornerRadius = 15
        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.navigationItem.setHidesBackButton(true, animated: true);
    }
    override func viewDidDisappear(_ animated: Bool) {
         navigationController?.setNavigationBarHidden(false, animated: animated)
    }


}
