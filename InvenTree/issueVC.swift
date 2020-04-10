//
//  issueVC.swift
//  InvenTree
//
//  Created by Nirbhay Singh on 18/03/20.
//  Copyright © 2020 Nirbhay Singh. All rights reserved.
//

import UIKit
import CoreLocation
import Firebase
import GoogleMaps
import JGProgressHUD

class issueVC: UIViewController,CLLocationManagerDelegate,UIPickerViewDataSource,UIPickerViewDelegate,UINavigationControllerDelegate,UIImagePickerControllerDelegate{
    @IBOutlet weak var otherDetailstf: UITextField!
    
    @IBOutlet weak var mapView: GMSMapView!
    
    @IBOutlet weak var infoLbl: UILabel!
    @IBOutlet weak var addressLbl: UILabel!
    @IBOutlet weak var picker: UIPickerView!
    let imagePicker = UIImagePickerController()

    @IBOutlet weak var thumbnail: UIImageView!
    
    
    var issues:[String]=["Logging","Dead tree","Tree needs water","Tree growing on a road","Other"]
    var issue:String = ""
    
    let locationManager = CLLocationManager()
    let hud = JGProgressHUD.init()
    var imgData:Data!
    var coord:CLLocationCoordinate2D!
    override func viewDidLoad() {
        self.hideKeyboardWhenTappedAround()
        super.viewDidLoad()
        _ = UITapGestureRecognizer(target: self.view, action: #selector(UIView.endEditing))
        infoLbl.text = "Hi, " + globalUser.givenName + ". Here you can upload issues such as tree logging, dead trees, and other concerns in your vicinity. Press and hold the marker to edit location."
        setUpLocation()
        self.picker.delegate = self
        self.picker.dataSource = self
        
        
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
                self.initMap()
            }
        })
    }
    func initMap(){
        print(self.coord)
        print("initMap called to thread.")
        let hud = JGProgressHUD.init()
        hud.show(in: self.view)
        let cam = GMSCameraPosition.camera(withTarget: coord, zoom: 16)
        let mapView = GMSMapView.map(withFrame: self.mapView.frame, camera: cam)
        mapView.isMyLocationEnabled = true
        let marker = GMSMarker(position: coord)
        mapView.layer.cornerRadius = 15
        marker.title = "Issue location"
        marker.isDraggable = true
        marker.map = mapView
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
    
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return issues.count
    }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        issue = issues[row]
    }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return issues[row]
    }
    @IBAction func takePhoto(_ sender: Any) {
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        imagePicker.sourceType = .camera
        present(imagePicker, animated: true, completion: nil)
    }
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let pickedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
            self.imgData = pickedImage.pngData()
            self.thumbnail.image = pickedImage
            print(pickedImage.size)
            self.imagePicker.dismiss(animated: true, completion: nil)
        }
    }
    @IBAction func submit(_ sender: Any) {
        let localHud = JGProgressHUD.init()
        if(self.imgData==nil){
            showAlert(msg: "You can't proceed without selecting an image.")
        }else if(self.issue==""){
            showAlert(msg: "You must select an issue type")
        }else if(self.issue=="Other" && otherDetailstf.text==""){
            showAlert(msg: "You must enter some details.")
        }
        else{
            localHud.show(in: self.view)
            var downloadUrl:URL!
            let storage = Storage.storage()
            let ref = Database.database().reference().child("issue-node").childByAutoId()
            let st_ref = storage.reference().child("issue-imgs").child(ref.key!)
            _ = st_ref.putData(self.imgData, metadata: nil) { (metadata, error) in
                           if(error != nil){
                               showAlert(msg: error!.localizedDescription)
                               localHud.dismiss()
                               self.resetFields()
                           }else{
                              st_ref.downloadURL { (url, error) in
                                if(error != nil){
                                    showAlert(msg: error!.localizedDescription)
                                    localHud.dismiss()
                                   self.resetFields()
                                }else if(url != nil){
                                   print("URL fetched with success.\n")
                                   downloadUrl = url!
                                   let issueDic:[String:Any]=[
                                       "issue-type":self.issue as Any,
                                       "issue-details":self.otherDetailstf.text ?? "no-details",
                                       "issue-upvotes":1,
                                       "issue-resolved":false as Any,
                                       "user-email":globalUser.email as Any,
                                       "location-lat":self.coord.latitude as Any,
                                       "location-lon":self.coord.longitude as Any,
                                       "user-given-name":globalUser.givenName as Any,
                                       "photo-url":downloadUrl.absoluteString
                                   ];
                                   ref.setValue(issueDic) { (error, ref) -> Void in
                                       if(error == nil){
                                            showSuccess(msg: "This issue has been uploaded to our servers with success!")
                                            localHud.dismiss()
                                       }
                                       else{
                                           localHud.dismiss()
                                           showAlert(msg: error!.localizedDescription)
                                           self.resetFields()
                                       }
                                   }
                                }
                                else{
                                   showAlert(msg: "Check your network, you may have issues.")
                                    localHud.dismiss()
                               }
                               }
                           }
                       }
            
        }
    }
    
    func resetFields(){
        self.issue = ""
        self.imgData = nil
    }
    @IBAction func showUpp(_ sender: Any) {
        showInfo(msg: "We're committed to solving all tree-related issues that pop up on te map. In that spirit, we forward all issues to the local environmental/development body in the city, and they ensure that it is resolved with their resources.")
    }
    
    
}
