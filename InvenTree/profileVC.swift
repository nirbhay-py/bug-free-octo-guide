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
    @IBOutlet weak var treesPlantedLbl: UILabel!
    @IBOutlet weak var stormWaterlbl: UILabel!
    @IBOutlet weak var apLbl: UILabel!
    @IBOutlet weak var energylbl: UILabel!
    @IBOutlet weak var avoidedLbl: UILabel!
    @IBOutlet weak var tblbl: UILabel!
    @IBOutlet weak var co2lbl: UILabel!
    let c02:Double = 2.15749
    let stormwater:Double = 3.97053
    let ap:Double = 62.41663
    let energy:Double = 57.76375
    let avoided:Double = 8.32553
    override func viewDidLoad() {
        super.viewDidLoad()
        var trees = Double(globalUser.treesPlanted!)
        profilePic.load(url: URL(string: globalUser.photoUrl)!)
        nameLbl.text = globalUser.name
        treesPlantedLbl.text = "You have planted " + String(Int(trees)) + " trees"
        var co2res = (trees * c02).round(to:2)
        var stormres = (trees * (stormwater)).round(to:2)
        var apres = (trees * (ap)).round(to:2)
        var energyres = (trees * (energy)).round(to:2)
        var avoidedres = (trees * (avoided)).round(to:2)
        co2lbl.text = String("$"+String(co2res))
        stormWaterlbl.text = String("$"+String(stormres))
        energylbl.text = String("$"+String(energyres))
        apLbl.text = String("$"+String(apres))
        avoidedLbl.text = String("$"+String(avoidedres))
        var total = co2res + stormres + apres + energyres + avoidedres
        tblbl.text = String("$"+String(total))
        // Do any additional setup after loading the view.
    }


}
