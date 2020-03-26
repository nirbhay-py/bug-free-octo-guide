//
//  hostDriveVC.swift
//  InvenTree
//
//  Created by Nirbhay Singh on 24/03/20.
//  Copyright © 2020 Nirbhay Singh. All rights reserved.
//

import UIKit
import CoreLocation
import Firebase
import GoogleMaps
import JGProgressHUD
class hostDriveVC: UIViewController,CLLocationManagerDelegate,GMSMapViewDelegate{
    @IBOutlet weak var viewForMap: GMSMapView!
    let locationManager=CLLocationManager()
    
    @IBOutlet weak var phoneTf: UITextField!
    
    let hud = JGProgressHUD.init()
    var coord:CLLocationCoordinate2D!
    var strDate:String!
    @IBOutlet weak var volunteersTf: UITextField!
    @IBOutlet weak var treesTf: UITextField!
    @IBOutlet weak var datePicker: UIDatePicker!
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpLocation()
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
        hud.dismiss()
        initMap()
    }
    
    override func viewDidAppear(_ animated: Bool) {
         navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    override func viewDidDisappear(_ animated: Bool) {
         navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    func initMap(){
        print(self.coord as Any)
        print("initMap called to thread.")
        let hud = JGProgressHUD.init()
        hud.show(in: self.view)
        let cam = GMSCameraPosition.camera(withTarget: coord, zoom: 16)
        let mapView = GMSMapView.map(withFrame: self.viewForMap.frame, camera: cam)
        let marker = GMSMarker(position: coord)
        viewForMap.layer.cornerRadius = 15
        marker.title = "Drive Location"
        marker.isDraggable = true
        marker.map = mapView
        mapView.delegate = self
        mapView.isMyLocationEnabled = true
        do {
             mapView.mapStyle = try GMSMapStyle(jsonString: mapStyle)
        } catch {
             NSLog("One or more of the map styles failed to load. \(error)")
        }
        self.view.addSubview(mapView)
        hud.dismiss()
    }
    func mapView(_ mapView: GMSMapView, didDrag marker: GMSMarker) {
        coord = marker.position
        print("Marker moved to \(coord as Any)")
    }
    @IBAction func datePicked(_ sender: Any) {
        let dateFormatter = DateFormatter()

           dateFormatter.dateStyle = DateFormatter.Style.short
           dateFormatter.timeStyle = DateFormatter.Style.short

            strDate = dateFormatter.string(from: datePicker.date)
    }
    @IBAction func submit(_ sender: Any) {
        let hud = JGProgressHUD.init()
       
    if(treesTf.text==""||volunteersTf.text==""||phoneTf.text==""){
            showAlert(msg: "You can't leave fields blank.")
    }else if(phoneTf.text?.count != 10){
            showAlert(msg: "Please enter a 10 digit phone number.")
        }else{
         hud.show(in: self.view)
           
        let user_ref = Database.database().reference().child("user-node").child(splitString(str: globalUser.email, delimiter: ".")).child("drives").childByAutoId()
        let drive_ref = Database.database().reference().child("drives-node").childByAutoId()
        let driveDic:[String:Any]=[
                       "user-name":globalUser.name,
                       "user-email":globalUser.email,
                       "phone-no":phoneTf.text!,
                       "volunteers-req":volunteersTf.text!,
                       "tree-goal":treesTf.text!,
                       "location-lat":coord.latitude,
                       "location-lon":coord.longitude,
                       "time":strDate as Any,
                       "attendees":"1",
                       "drive-node-key":drive_ref.key as Any,
                       "user-node-key":user_ref.key as Any
            ]
        user_ref.setValue(driveDic) { (error, ref) -> Void in
            if(error != nil){
                showAlert(msg: "An error occured. \(error?.localizedDescription)")
                hud.dismiss()
            }else{
                drive_ref.setValue(driveDic) { (error,ref) -> Void in
                    if(error != nil){
                        showAlert(msg: "An error occured. \(error?.localizedDescription)")
                        hud.dismiss()
                    }else{
                        showSuccess(msg: "Your drive has been uploaded with success.")
                        hud.dismiss()
                    }
                }
            }
        }
        
        }
    }
}
