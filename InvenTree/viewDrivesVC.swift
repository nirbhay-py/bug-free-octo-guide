//
//  viewDrivesVC.swift
//  InvenTree
//
//  Created by Nirbhay Singh on 26/03/20.
//  Copyright © 2020 Nirbhay Singh. All rights reserved.
//

import UIKit
import Firebase
import JGProgressHUD
import CoreLocation
import GoogleMaps

class tableCell:UITableViewCell{
    var drive:Drive!
    @IBOutlet weak var organiserName: UILabel!
    @IBOutlet weak var goalLbl: UILabel!
    @IBOutlet weak var attendeesLbl: UILabel!
    @IBOutlet weak var phoneLbl: UILabel!
    @IBOutlet weak var distLbl: UILabel!
    @IBOutlet weak var dateLbl: UILabel!
    @IBAction func joinBtnPressed(_ sender: Any) {
        let hud = JGProgressHUD.init()
        hud.show(in:self.contentView)
        let drive_ref = Database.database().reference().child("drives-node").child(drive.driveKey)
        let user_ref = Database.database().reference().child("user-node").child(drive.email).child(drive.userKey)
        if(drive.email==splitString(str: globalUser.email, delimiter: ".")){
            showAlert(msg: "You can't join your own drive!")
            hud.dismiss()
        }else{
            var attendees:String!
            drive_ref.observeSingleEvent(of: .value, with: { (snapshot) in
                let drive = snapshot.value as? NSDictionary
                attendees = drive!["attendees"] as! String
                var int_attendees = Int(attendees) ?? 0
                int_attendees += 1
                attendees = String(int_attendees)
                let updates : [String:String] = ["attendees":attendees]
                drive_ref.updateChildValues(updates) {(error,ref) -> Void in
                    if(error == nil){
                        user_ref.updateChildValues(updates) {(error,ref) -> Void in
                            if(error == nil){
                                hud.dismiss()
                            }else{
                                hud.dismiss()
                                showAlert(msg: error!.localizedDescription)
                            }
                        }
                    }else{
                        hud.dismiss()
                        showAlert(msg: error!.localizedDescription)
                    }
                }
                
              }) { (error) in
                hud.dismiss()
                showAlert(msg: "An error occured.")
                print(error.localizedDescription)
            }
        }
    }
    
}
class viewDrivesVC: UIViewController,UITableViewDelegate,UITableViewDataSource,CLLocationManagerDelegate{
    @IBOutlet weak var addressLbl: UILabel!
    @IBOutlet weak var tableView: UITableView!
    var drives:[Drive]=[]
    let locationManager = CLLocationManager()
    var coord:CLLocationCoordinate2D!
    let hud = JGProgressHUD.init()
    var driveCount:Int = 0
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return driveCount
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "driveCell", for: indexPath) as! tableCell
        let i = indexPath.row
        cell.drive = drives[i]
        let attendeesStr:String = cell.drive.attendees + "/" + cell.drive.needed
        cell.attendeesLbl.text = attendeesStr
        cell.organiserName.text = cell.drive.name
        cell.phoneLbl.text =  cell.drive.phone
        cell.distLbl.text = String(cell.drive.distance) + " km away"
        cell.goalLbl.text = cell.drive.goal + " trees"
        cell.dateLbl.text = cell.drive.date
        return cell
    }
    func setUpLocation(){
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        hud.show(in: self.view,animated: true)
        locationManager.startUpdatingLocation()
    }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("called")
        let location:CLLocation = locations[0]
        coord = location.coordinate
        let coordinate:CLLocationCoordinate2D = location.coordinate
        locationManager.stopUpdatingLocation()
        let geocoder = GMSGeocoder()
        geocoder.reverseGeocodeCoordinate(coordinate, completionHandler:{(resp,error)  in
            self.hud.dismiss()
            if(error != nil || resp==nil ){
                showAlert(msg: "You may have connectivity issues :"+error!.localizedDescription)
            }else{
                print(resp?.results()?.first as Any)
                self.addressLbl.text = resp?.results()?.first?.lines![0]
                self.populateTable()
            }
        })
       
    }

    

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpLocation()
        tableView.delegate = self
        tableView.dataSource = self
    }
    func populateTable(){
        print("populateTable() called to thread.")
        let hud = JGProgressHUD()
        hud.show(in: self.view)
        let ref = Firebase.Database.database().reference().child("drives-node")
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
                let drives = snapshot.value as! [String:AnyObject]
                print(drives)
                self.driveCount = drives.count
                print("self.driveCount=\(self.driveCount)")
                for drive in drives{
                    print(drive)
                    let lat = drive.value["location-lat"] as! Double
                    let lon = drive.value["location-lon"] as! Double
                    let user_name = drive.value["user-name"] as! String
                    let phone = drive.value["phone-no"] as! String
                    let date = drive.value["time"] as! String
                    let attendees = drive.value["attendees"] as! String
                    let needed = drive.value["volunteers-req"] as! String
                    let goal = drive.value["tree-goal"] as! String
                    let loc = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                    let uKey = drive.value["user-node-key"] as! String
                    let dKey = drive.value["drive-node-key"] as! String
                    var email = drive.value["user-email"] as! String
                    email = splitString(str: email, delimiter: ".")
                    let distance = self.distance(lat1: self.coord.latitude, lon1: self.coord.longitude, lat2:loc.latitude, lon2: loc.longitude, unit: "K")
                    let thisDrive = Drive(name: user_name, location: loc, attendees: attendees, needed: needed, phone: phone, distance: Float(distance), date: date, goal: goal,userKey:uKey,driveKey:dKey,email:email)
                    self.drives.append(thisDrive)
                    self.tableView.reloadData()
                }
            print("self.drives=\(self.drives)")
            hud.dismiss()
            }) { (error) in
                hud.dismiss()
                showAlert(msg: "An error occured -> \(error.localizedDescription)")
                print(error.localizedDescription)
        }
    }
    
    func rad2deg(rad:Double) -> Double {
        return rad * 180.0 / Double.pi
    }
    func distance(lat1:Double, lon1:Double, lat2:Double, lon2:Double, unit:String) -> Double {
        let theta = lon1 - lon2
        var dist = sin(deg2rad(deg: lat1)) * sin(deg2rad(deg:lat2)) + cos(deg2rad(deg:lat1)) * cos(deg2rad(deg:lat2)) * cos(deg2rad(deg:theta))
        dist = acos(dist)
        dist = rad2deg(rad: dist)
        dist = dist * 60 * 1.1515
        if (unit == "K") {
            dist = dist * 1.609344
        }
        else if (unit == "N") {
            dist = dist * 0.8684
        }
        return dist
    }
    func deg2rad(deg:Double) -> Double {
        return deg * Double.pi / 180
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 320
    }
}
