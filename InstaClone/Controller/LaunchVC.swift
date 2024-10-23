//
//  ViewController.swift
//  InstaClone
//
//  Created by can on 18.10.2024.
//

import UIKit
import FirebaseAuth

class LaunchVC: UIViewController {
    @IBOutlet weak var emailTextInput: UITextField!
    @IBOutlet weak var passwordTextInput: UITextField!
    
    var brain = Brain()
    
    let placeholderEmail = "e-mail"
    let placeholderColorEmail = UIColor.gray
    let placeholderPassword = "password"
    let placeholderColorPassword = UIColor.gray
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let currentUser = Auth.auth().currentUser
        
        if currentUser != nil {
            self.performSegue(withIdentifier: "toFeedVC", sender: self)
        }
        
        emailTextInput.textColor = UIColor.white
        passwordTextInput.textColor = UIColor.white
        
        brain.placeHolders(textField: emailTextInput, placeholderText: placeholderEmail, placeholderColor: placeholderColorEmail)
        brain.placeHolders(textField: passwordTextInput, placeholderText: placeholderPassword, placeholderColor: placeholderColorPassword)
    }

    @IBAction func logIn(_ sender: UIButton) {
        
        let email = emailTextInput.text ?? ""
        let password = passwordTextInput.text ?? ""
           
        loginUser(email: email, password: password) { result in
               switch result {
               case .success(let user):
                   self.performSegue(withIdentifier: "toFeedVC", sender: nil)
               case .failure(let error):
                   self.showAlert(message: error.localizedDescription, title: "Fail")
               }
        }
        
    }
    
    
    @IBAction func signUp(_ sender: UIButton) {
        performSegue(withIdentifier: "toSignUpVC", sender: nil)
    }
    
    func loginUser(email: String, password: String, completion: @escaping (Result<User, Error>) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            if let error = error {
                // Hata durumunu handle et
                completion(.failure(error))
                return
            }
            
            if let user = authResult?.user {
                // Başarılı giriş
                completion(.success(user))
            }
        }
    }
    
    func showAlert(message: String, title: String) {
        let alertController = UIAlertController(title: title , message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
    }
}

