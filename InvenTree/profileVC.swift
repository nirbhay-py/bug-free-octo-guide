//
//  profileVC.swift
//  InvenTree
//
//  Created by Nirbhay Singh on 30/03/20.
//  Copyright © 2020 Nirbhay Singh. All rights reserved.
//

import UIKit

class profileVC: UIViewController {
    @IBOutlet weak var nameLbl: UILabel!
    @IBOutlet weak var profilePic: UIImageView!
    @IBOutlet weak var treeLbl: UILabel!
    @IBOutlet weak var treesPlantedLbl: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        profilePic.load(url: URL(string: globalUser.photoUrl)!)
        nameLbl.text = globalUser.name
        treeLbl.text = String(globalUser.treesPlanted) + " trees"
        // Do any additional setup after loading the view.
    }


}
