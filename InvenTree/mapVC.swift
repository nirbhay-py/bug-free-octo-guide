//
//  mapVC.swift
//  InvenTree
//
//  Created by Nirbhay Singh on 21/02/20.
//  Copyright © 2020 Nirbhay Singh. All rights reserved.
//

import UIKit
import GoogleMaps
import CoreLocation
import JGProgressHUD
import Firebase
import Alamofire
import SwiftyJSON



class mapVC: UIViewController,CLLocationManagerDelegate,GMSMapViewDelegate{
    let locationManager = CLLocationManager()
    var coords:CLLocationCoordinate2D!
    let hud = JGProgressHUD.init()
    var data:JSON!
    let aqiHUd = JGProgressHUD.init()
    let key:String = "f022a338-cfee-4723-a329-f111260f10f4"
    let camera = GMSCameraPosition.camera(withLatitude: 60, longitude:60, zoom: 16.0)
    lazy var mapView = GMSMapView.map(withFrame: CGRect.zero, camera: camera)
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpLocation()
        self.view = mapView
        do {
             mapView.mapStyle = try GMSMapStyle(jsonString: mapStyle)
        } catch {
             NSLog("One or more of the map styles failed to load. \(error)")
        }
        mapView.isMyLocationEnabled = true
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
        coords = location.coordinate
        print(coords.longitude)
        locationManager.stopUpdatingLocation()
        hud.dismiss()
        refreshMap()
    }
    func refreshMap(){
        print(coords.latitude,coords.longitude)
        let cam = GMSCameraPosition.camera(withLatitude: coords.latitude, longitude:coords.longitude, zoom: 16.0)
        mapView.camera = cam
        populateMap()
    }
    func populateMap(){
        let ref = Database.database().reference().child("trees-node")
        _ = ref.observe(DataEventType.value, with: { (snapshot) in
            let reports = snapshot.value as! [String:AnyObject]
            let markerImg = UIImage(named: "tree")
            for report in reports{
                let lat = report.value["location-lat"] as! Double
                let lon = report.value["location-lon"] as! Double
                let email = report.value["user-email"] as! String
                let species = report.value["species"] as! String
                let height = report.value["height"] as! String
                let position = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                let marker = GMSMarker(position: position)
                marker.title = species
                marker.icon = markerImg
                marker.snippet = "Height:"+height+"m\nEmail:"+email
                marker.map = self.mapView
            }
        })
        let issue_ref = Database.database().reference().child("issue-node")
        _ = issue_ref.observe(DataEventType.value, with: { (snapshot) in
            let reports = snapshot.value as! [String:AnyObject]
            let warningImg = UIImage(named: "warning")
            let resolvedImg = UIImage(named:"resolved")
            for report in reports{
                let lat = report.value["location-lat"] as! Double
                let lon = report.value["location-lon"] as! Double
                let email = report.value["user-email"] as! String
                let name = report.value["user-given-name"] as! String
                let desc = report.value["issue-type"] as! String
                let upvotes = report.value["issue-upvotes"] as! Int
                let resolved = report.value["issue-resolved"] as! Bool
                let position = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                let marker = GMSMarker(position: position)
                marker.title = desc
                if(resolved){
                    marker.icon = resolvedImg
                }else{
                    marker.icon = warningImg
                }
                var str = "Uploaded by:" + String(name)
                str += "\nEmail:" + email
                str += "\nUpvotes:" + String(upvotes)
                marker.snippet = str
                marker.map = self.mapView
            }
        })
        let eps_ref = Database.database().reference().child("eps-node")
        _ = eps_ref.observe(DataEventType.value, with: { (snapshot) in
            let reports = snapshot.value as! [String:AnyObject]
            let markerImg = UIImage(named: "empty")
            for report in reports{
                let lat = report.value["location-lat"] as! Double
                let lon = report.value["location-lon"] as! Double
                let email = report.value["user-email"] as! String
                let approx_area = report.value["approx-area"] as! NSNumber
                let position = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                let marker = GMSMarker(position: position)
                marker.title = "Empty planting site"
                marker.icon = markerImg
                marker.snippet = "Uploaded by: \(email)\nApproximate area: \(approx_area) square mt."
                marker.map = self.mapView
            }
            
        })

        fetchAQI()
    }
    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
        print(marker.snippet as Any)
        return true
    }
    func fetchAQI(){
        aqiHUd.show(in: self.view)
        var finalURL:String = "https://api.airvisual.com/v2/nearest_city?lat="+String(coords.latitude)+"&lon="+String(coords.longitude)
        finalURL += ("&key="+key)
        print(finalURL)
        AF.request(finalURL).response { response in
            if(response.value==nil){
                showAlert(msg: "We could not fetch AQI data at this time.")
                self.aqiHUd.dismiss()
            }else{
                self.data = JSON(response.value as! Any)
                self.displayAQI()
                
            }
        }
    }
    func displayAQI(){
        let aqi = self.data["data"]["current"]["pollution"]["aqius"].stringValue
        let city = self.data["data"]["city"].stringValue
        print(aqi,city)
       let v = UIView(frame: CGRect(x:self.view.frame.width-120,y:self.view.frame.height-200,width:100,height: 80))
        v.backgroundColor = UIColor.white
        v.layer.cornerRadius = 15
        v.layer.borderWidth = 2
        v.layer.borderColor = UIColor.systemGreen.cgColor
       let aqiLbl = UILabel(frame: CGRect(x:0,y:0,width:90,height:40))
       aqiLbl.center = CGPoint(x:v.frame.width/2, y:v.frame.height/2-10)
       aqiLbl.font = aqiLbl.font.withSize(40)
       aqiLbl.textAlignment = .center
       aqiLbl.textColor = UIColor.systemGreen
       aqiLbl.text = aqi
       v.addSubview(aqiLbl)
       let catLbl = UILabel(frame: CGRect(x:0,y:0,width:200,height:20))
       catLbl.center = CGPoint(x:v.frame.width/2, y:v.frame.height/2+15)
       catLbl.font = catLbl.font.withSize(15)
       catLbl.textAlignment = .center
       catLbl.textColor = UIColor.systemGreen
       catLbl.text = "AQI"
       v.addSubview(catLbl)
       self.mapView.addSubview(v)
       aqiHUd.dismiss()
    }


}
