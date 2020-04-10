//
//  signInVC.swift
//  InvenTree
//
//  Created by Nirbhay Singh on 21/02/20.
//  Copyright © 2020 Nirbhay Singh. All rights reserved.
//

import UIKit
import Firebase
import GoogleSignIn
import SCLAlertView
import AuthenticationServices
import JGProgressHUD

var globalUser:GlobalUser = GlobalUser(name: "", email: "", photoUrl: "", treesPlanted: 0, givenName: "")

class signInVC: UIViewController,GIDSignInDelegate,ASAuthorizationControllerDelegate,ASAuthorizationControllerPresentationContextProviding

{
    
    @IBOutlet weak var googleConst: NSLayoutConstraint!
    

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return self.view.window!
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        setupSOAppleSignIn()
        GIDSignIn.sharedInstance().clientID = FirebaseApp.app()?.options.clientID
        GIDSignIn.sharedInstance().delegate = self
        GIDSignIn.sharedInstance()?.presentingViewController = self
        self.hideKeyboardWhenTappedAround()
    }
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        if let error = error {
            print(error.localizedDescription)
            return
        }
        guard let authentication = user.authentication else { return }
        let credential = GoogleAuthProvider.credential(withIDToken: authentication.idToken, accessToken: authentication.accessToken)
        Auth.auth().signIn(with: credential) { (authResult, error) in
            if let error = error {
                showAlert(msg: error.localizedDescription)
                return
            }
        let hud = JGProgressHUD.init()
        hud.show(in: self.view,animated: true)
        let userID = user.userID
        let name = user.profile.name
        let email = user.profile.email
        let givenName = user.profile.givenName
        let photoURL = user.profile.imageURL(withDimension: 150)?.absoluteString
        let userDic = [
              "userID":userID!,
              "givenName":givenName ?? "Empty",
              "name":name!,
              "email":email!,
              "photoURL":photoURL ?? "Empty",
              "trees-planted": 0
              ] as [String : Any]
          let strippedEmail = splitString(str:email!, delimiter:".")
          let ref = Database.database().reference().child("user-node").child(strippedEmail)
          ref.setValue(userDic) { (error, ref) -> Void in
              if(error != nil){
                  hud.dismiss()
                  showAlert(msg: error?.localizedDescription ?? "There seems to be something wrong with your connection.")
              }else{
                  globalUser.name = name!
                  globalUser.email = email!
                  globalUser.givenName = givenName!
                  globalUser.photoUrl = photoURL!
                  globalUser.treesPlanted = 0
                  hud.dismiss()
                  showSuccess(msg: "Signed in with success!")
                  self.performSegue(withIdentifier: "toDashboard", sender: self)
            }
          }
        }
    }
    @available(iOS 9.0, *)
    func application(_ application: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any])
      -> Bool {
        return GIDSignIn.sharedInstance().handle(url)
    }
    override func viewDidAppear(_ animated: Bool) {
           if(Auth.auth().currentUser != nil){
               print("user not nil")
               let localHud = JGProgressHUD.init()
               localHud.show(in: self.view,animated: true)
               //MARK:FETCH DATA FROM FIREBASE, INITIALISE A USERCLASS OBJECT AND PASS IT IN THE SEGUE
               var email = Auth.auth().currentUser?.email
               email = splitString(str: email!, delimiter: ".")
               let ref = Database.database().reference().child("user-node").child(email!)
               ref.observeSingleEvent(of: .value, with: {(snapshot) in
                   let value = snapshot.value as? NSDictionary
                   let givenName=value!["givenName"] as! String
                   let name = value!["name"] as! String
                   let email = value!["email"] as! String
                   let photoURL = value!["photoURL"] as! String
                   let treesPlanted = value!["trees-planted"] as! Int
                   globalUser = GlobalUser(name: name, email: email, photoUrl: photoURL, treesPlanted: treesPlanted, givenName: givenName)
                   localHud.dismiss()
                   self.performSegue(withIdentifier: "toDashboard", sender: self)
               }){ (error) in
                   print(error.localizedDescription)
                   showAlert(msg: error.localizedDescription)
               }
           }
       }
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.setNavigationBarHidden(true, animated: animated)
          
    }
    func setupSOAppleSignIn() {

           let btnAuthorization = ASAuthorizationAppleIDButton()

            btnAuthorization.frame = CGRect(x: 0, y: 0, width: 300, height: 48)
        
        btnAuthorization.center = CGPoint(x: self.view.center.x, y: self.view.bounds.height-115)

           btnAuthorization.addTarget(self, action: #selector(actionHandleAppleSignin), for: .touchUpInside)

           self.view.addSubview(btnAuthorization)

       }
    @objc func actionHandleAppleSignin(){
        let appleIDProvider = ASAuthorizationAppleIDProvider()

        let request = appleIDProvider.createRequest()

        request.requestedScopes = [.fullName, .email]

        let authorizationController = ASAuthorizationController(authorizationRequests: [request])

        authorizationController.delegate = self

        authorizationController.presentationContextProvider = self

        authorizationController.performRequests()
    }
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {

        print(error.localizedDescription)
        showAlert(msg: error.localizedDescription)

    }

       // ASAuthorizationControllerDelegate function for successful authorization

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        let hud = JGProgressHUD.init()
        hud.show(in: self.view)
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            // Create an account as per your requirement
            let appleId = appleIDCredential.user
            let appleUserFirstName = appleIDCredential.fullName?.givenName
            let appleUserEmail = appleIDCredential.email
            if(appleUserEmail==nil){
                let ref = Database.database().reference().child("user-node").child(splitString(str: appleId, delimiter: "."))
                ref.observeSingleEvent(of: .value, with: {(snapshot) in
                    let val = snapshot.value as? [String:Any]
                    let givenName = val!["givenName"] as! String
                    let email = val!["email"] as! String
                    let trees_planted = val!["trees-planted"] as! Int
                    globalUser = GlobalUser(name: givenName as! String, email: appleId, photoUrl: "", treesPlanted: trees_planted, givenName: givenName)
                    hud.dismiss()
                    showSuccess(msg: "Signed in with success")
                    self.performSegue(withIdentifier: "toDashboard", sender: nil)
                }) { (error) in
                    print(error.localizedDescription)
                    showAlert(msg: "Check your connection, you may have problems.")
                    hud.dismiss()
                    
                }
                
            }else{
                let userDic = [
                    "userID":appleId,
                    "givenName":appleUserFirstName,
                    "name":appleUserFirstName,
                    "email":appleUserEmail,
                    "photoURL": "",
                    "trees-planted": 0
                    ] as [String : Any]
                let ref = Database.database().reference().child("user-node").child(splitString(str: appleId, delimiter: "."))
                ref.setValue(userDic) { (error, ref) -> Void in
                    if(error != nil){
                        hud.dismiss()
                        showAlert(msg: error?.localizedDescription ?? "There seems to be something wrong with your connection.")
                    }else{
                        globalUser.name = appleUserFirstName ?? appleUserEmail
                        globalUser.email = appleId
                        globalUser.givenName = appleUserFirstName ?? appleUserEmail
                        globalUser.photoUrl = ""
                        globalUser.treesPlanted = 0
                        hud.dismiss()
                        showSuccess(msg: "Signed in with success!")
                        self.performSegue(withIdentifier: "toDashboard", sender: self)
                  }
                }
            }
        }
    }
    
    
}
