//
//  addTreeVC.swift
//  InvenTree
//
//  Created by Nirbhay Singh on 21/02/20.
//  Copyright © 2020 Nirbhay Singh. All rights reserved.
//

import UIKit
import CoreLocation
import Firebase
import GoogleMaps
import SearchTextField
import JGProgressHUD

class addTreeVC: UIViewController,CLLocationManagerDelegate,UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    
    @IBOutlet weak var searchTxtBox: SearchTextField!
    @IBOutlet weak var infoLbl: UILabel!
    @IBOutlet weak var addressLbl: UILabel!
    @IBOutlet weak var ageTf: UITextField!
    @IBOutlet weak var diameterTf: UITextField!
    let locationManager = CLLocationManager()
    let hud = JGProgressHUD.init()
    var coord:CLLocationCoordinate2D!
    var imgData:Data!
    let imagePicker = UIImagePickerController()

    
    @IBOutlet weak var heightTf: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        infoLbl.text = "Hi, "+globalUser.givenName+". Follow the instructions below to add a tree to our servers. Your current location will be used to mark the tree on our map."
        setUpLocation()
        setUpSearchBox()
        let tap = UITapGestureRecognizer(target: self.view, action: #selector(UIView.endEditing))
        view.addGestureRecognizer(tap)
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
            }
        })
    }
    
    func setUpSearchBox(){

        let item1 = SearchTextFieldItem(title: "Khejri", subtitle: "Prosopis cineraria")
        let item2 = SearchTextFieldItem(title: "Desert Date", subtitle: "Balanites aegyptiaca")
        let item3 = SearchTextFieldItem(title: "Jujube", subtitle: "Ziziphus jujuba")
        let item4 = SearchTextFieldItem(title:"Castor", subtitle:"Ricinus communis")
        let item5 = SearchTextFieldItem(title:"Sheesham", subtitle:"Tecomella Undulata")
        let item6 = SearchTextFieldItem(title:"Kair", subtitle:"Capparis decidua")
        let item7 = SearchTextFieldItem(title:"Haar Singaar", subtitle:"Nyctanthes arbor-tristis")


        searchTxtBox.filterItems([item1, item2, item3, item4, item5, item6, item7])
        searchTxtBox.theme.font = UIFont.systemFont(ofSize: 18)
        searchTxtBox.theme.bgColor = UIColor (red: 0.9, green: 0.9, blue: 0.9, alpha: 1)
        searchTxtBox.theme.borderColor = UIColor (red: 0.9, green: 0.9, blue: 0.9, alpha: 1)
        searchTxtBox.theme.separatorColor = UIColor (red: 0.9, green: 0.9, blue: 0.9, alpha: 1)
        searchTxtBox.theme.cellHeight = 50

    }
    @IBAction func cameraBtn(_ sender: Any) {
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        imagePicker.sourceType = .photoLibrary
        present(imagePicker, animated: true, completion: nil)
    }
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let pickedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
            self.imgData = pickedImage.pngData()
            print(pickedImage.size)
            self.imagePicker.dismiss(animated: true, completion: nil)
        }
    }
    @IBAction func submitBtnPressed(_ sender: Any) {
        let localHud = JGProgressHUD.init()
        let species = searchTxtBox.text ?? "Empty"
        let height = heightTf.text ?? "Empty"
        let age = ageTf.text ?? "Empty"
        let diameter = diameterTf.text ?? "Empty"
        if(self.imgData==nil){
            showAlert(msg: "You can't proceed without selecting an image.")
        }else{
            localHud.show(in: self.view)
            var downloadUrl:URL!
            let storage = Storage.storage()
            let ref = Database.database().reference().child("trees-node").childByAutoId()
            let st_ref = storage.reference().child("tree-imgs").child(ref.key!)
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
                                   let treeDic:[String:Any]=[
                                       "species":species as Any,
                                       "height":height as Any,
                                       "user-email":globalUser.email as Any,
                                       "location-lat":self.coord.latitude as Any,
                                       "location-lon":self.coord.longitude as Any,
                                       "user-given-name":globalUser.givenName as Any,
                                       "age":age as Any,
                                       "diameter":diameter as Any,
                                       "photo-url":downloadUrl.absoluteString
                                   ];
                                   ref.setValue(treeDic) { (error, ref) -> Void in
                                       if(error == nil){
                                           globalUser.treesPlanted += 1
                                           let user_ref = Database.database().reference().child("user-node").child(splitString(str: globalUser.email, delimiter: "."))
                                        user_ref.observeSingleEvent(of: .value, with: {(snapshot) in
                                            let value = snapshot.value as! NSDictionary
                                            var count = value["trees-planted"] as! Int
                                            count += 1
                                            let updates : [String:Int] = ["trees-planted":count]
                                            user_ref.updateChildValues(updates)
                                        })
                                           showSuccess(msg: "This tree has been uploaded!")
                                           localHud.dismiss()
                                           self.resetFields()
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
                               }
                               }
                           }
                       }
            
        }
    }
    func resetFields(){
        self.imgData = nil
        self.searchTxtBox.text = ""
        self.heightTf.text = ""
    }
    
}
