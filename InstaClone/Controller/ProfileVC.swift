//
//  ProfileVC.swift
//  InstaClone
//
//  Created by can on 24.10.2024.
//

import UIKit
import FirebaseAuth

class ProfileVC: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        
    }
    @IBAction func logOut(_ sender: UIButton) {
        logOutUser()
    }
    
    func logOutUser() {
        do {
            try Auth.auth().signOut()
            navigateToLoginScreen()
        } catch let signOutError as NSError {
            print("error signing out: \(signOutError.localizedDescription)")
        }
    }
    func navigateToLoginScreen() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let loginViewController = storyboard.instantiateViewController(withIdentifier: "LaunchVC") as! LaunchVC
        
        
        let navigationController = UINavigationController(rootViewController: loginViewController)
        
        
        self.view.window?.rootViewController = navigationController
        self.view.window?.makeKeyAndVisible()
    }
}
