//
//  SıngUpVC.swift
//  InstaClone
//
//  Created by can on 18.10.2024.
//

import UIKit
import FirebaseAuth

class SignUpVC: UIViewController {
    @IBOutlet weak var emailTextInput: UITextField!
    @IBOutlet weak var passwordTextInput: UITextField!
    @IBOutlet weak var passwordConfirmation: UITextField!
    
    var brain = Brain()
    
    let placeholderEmail = "e-mail"
    let placeholderColorEmail = UIColor.gray
    let placeholderPassword = "password"
    let placeholderColorPassword = UIColor.gray
    let placeholderConfirmation = "password again"
    let placeholderColorConfirmation = UIColor.gray
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        emailTextInput.textColor = UIColor.white
        passwordTextInput.textColor = UIColor.white
        passwordConfirmation.textColor = UIColor.white
        
        brain.placeHolders(textField: emailTextInput, placeholderText: placeholderEmail, placeholderColor: placeholderColorEmail)
        brain.placeHolders(textField: passwordTextInput, placeholderText: placeholderPassword, placeholderColor: placeholderColorPassword)
        brain.placeHolders(textField: passwordConfirmation, placeholderText: placeholderConfirmation, placeholderColor: placeholderColorConfirmation)
        
    }
    @IBAction func signUp(_ sender: UIButton) {
        let email = emailTextInput.text ?? ""
        let password = passwordTextInput.text ?? ""
        let confirmPassword = passwordConfirmation.text ?? ""
        guard !email.isEmpty, !password.isEmpty, !confirmPassword.isEmpty else {
            showAlert(message: "Please fill all the lines!", title: "Fail")
                return
        }
        guard password == confirmPassword else {
            showAlert(message: "Please match the passwords!", title: "Fail")
                return
        }
        registerUser(email: email, password: password) { result in
                switch result {
                case .success(let user):
                    self.navigationController?.popViewController(animated: true)
                    self.showAlert(message: "Account has been created successfully!", title: "Success!")
                case .failure(let error):
                    self.showAlert(message: error.localizedDescription, title: "Fail")
                }
        }
    }
    
    func registerUser(email: String, password: String, completion: @escaping (Result<User, Error>) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error {
                
                completion(.failure(error))
                return
            }
            
            if let user = authResult?.user {
                
                completion(.success(user))
            }
        }
    }
    func showAlert(message: String, title: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
    }
}
