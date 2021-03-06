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
import SafariServices

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

    @IBOutlet weak var thumbnail: UIImageView!
    
    @IBOutlet weak var heightTf: UITextField!
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if(segue.identifier=="proceed")
        {
            let destVC = segue.destination as! add2VC
            destVC.age = self.ageTf.text ?? "Empty"
            destVC.species = self.searchTxtBox.text ?? "Empty"
            destVC.diameter = self.diameterTf.text ?? "Empty"
            destVC.height = self.heightTf.text ?? "Empty"
            destVC.imgData = self.imgData
            destVC.coord = self.coord
            
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        infoLbl.text = "Hi, "+globalUser.givenName+". Follow the instructions below to add a tree to our servers."
        setUpLocation()
        setUpSearchBox()
        self.hideKeyboardWhenTappedAround()
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
        let item7 = SearchTextFieldItem(title:"Khair", subtitle:"Acacia catechu")
        let item8 = SearchTextFieldItem(title:"Haar Singaar", subtitle:"Nyctanthes arbor-tristis")
        let item9 = SearchTextFieldItem(title:"Bel", subtitle:"Aegle marmelos")
        let item10 = SearchTextFieldItem(title:"Saptaparni", subtitle:"Alstonia Scholars")
        let item11 = SearchTextFieldItem(title:"Ankol", subtitle:"Alangium salvifolium")
        let item12 = SearchTextFieldItem(title:"Agar", subtitle:"Aquilaria agallocha")
        let item13 = SearchTextFieldItem(title:"Hingan, Ingudi", subtitle:"Balanties aegyptiaca")
        let item14 = SearchTextFieldItem(title:"Bhurja, Bhojpatra", subtitle:"Betula utilis")
        let item15 = SearchTextFieldItem(title:"Salai guggul", subtitle:"Bowellia serrata")
        let item16 = SearchTextFieldItem(title:"Chironji", subtitle:"Buchanania cochinchinensis")
        let item17 = SearchTextFieldItem(title:"Palash", subtitle:"Butea monosperma")
        let item18 = SearchTextFieldItem(title:"Dhup", subtitle:"Canarium stricturn")
        

        searchTxtBox.filterItems([item1, item2, item3, item4, item5, item6, item7,item8,item9,item10,item11,item12,item13,item14,item15,item16,item17,item18])
        searchTxtBox.theme.font = UIFont.systemFont(ofSize: 18)
        searchTxtBox.theme.bgColor = UIColor (red: 0.9, green: 0.9, blue: 0.9, alpha: 1)
        searchTxtBox.theme.borderColor = UIColor (red: 0.9, green: 0.9, blue: 0.9, alpha: 1)
        searchTxtBox.theme.separatorColor = UIColor (red: 0.9, green: 0.9, blue: 0.9, alpha: 1)
        searchTxtBox.theme.cellHeight = 50

    }
    @IBAction func cameraBtn(_ sender: Any) {
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        imagePicker.sourceType = .camera
        present(imagePicker, animated: true, completion: nil)
    }
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let pickedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
            let img = pickedImage.jpeg(.low)
            self.imgData = img
            print(pickedImage.size)
            thumbnail.image = pickedImage
            self.imagePicker.dismiss(animated: true, completion: nil)
        }

    }
    @IBAction func proceedClicked(_ sender: Any) {
        if(self.imgData==nil){
            showAlert(msg: "You cannot proceed without selecting an image to upload.")
        }else{
            self.performSegue(withIdentifier: "proceed", sender: nil)
        }
    }
    func resetFields(){
        self.imgData = nil
        self.searchTxtBox.text = ""
        self.heightTf.text = ""
    }
    @IBAction func openLink(_ sender: Any) {
        
        let svc = SFSafariViewController(url: URL(string:"http://flowersofindia.net/treeid/index.html")!)
        present(svc, animated: true, completion: nil)
    }
}

