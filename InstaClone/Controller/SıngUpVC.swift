//
//  SignUpVC.swift
//  InstaClone
//
//  Created by can on 18.10.2024.
//

import UIKit
import FirebaseAuth

class SignUpVC: UIViewController {
    // Outlets for email, password, and confirmation text fields
    @IBOutlet weak var emailTextInput: UITextField!
    @IBOutlet weak var passwordTextInput: UITextField!
    @IBOutlet weak var passwordConfirmation: UITextField!
    
    // Helper class instance
    var brain = Brain()
    
    // Placeholder texts and colors
    let placeholderEmail = "e-mail"
    let placeholderColorEmail = UIColor.gray
    let placeholderPassword = "password"
    let placeholderColorPassword = UIColor.gray
    let placeholderConfirmation = "password again"
    let placeholderColorConfirmation = UIColor.gray

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set text color for the input fields
        emailTextInput.textColor = UIColor.white
        passwordTextInput.textColor = UIColor.white
        passwordConfirmation.textColor = UIColor.white
        
        // Configure placeholder text and colors using helper methods
        brain.placeHolders(textField: emailTextInput, placeholderText: placeholderEmail, placeholderColor: placeholderColorEmail)
        brain.placeHolders(textField: passwordTextInput, placeholderText: placeholderPassword, placeholderColor: placeholderColorPassword)
        brain.placeHolders(textField: passwordConfirmation, placeholderText: placeholderConfirmation, placeholderColor: placeholderColorConfirmation)
    }
    
    @IBAction func signUp(_ sender: UIButton) {
        // Get user inputs
        let email = emailTextInput.text ?? ""
        let password = passwordTextInput.text ?? ""
        let confirmPassword = passwordConfirmation.text ?? ""
        
        // Check if any field is empty
        guard !email.isEmpty, !password.isEmpty, !confirmPassword.isEmpty else {
            showAlert(message: "Please fill in all fields!", title: "Error")
            return
        }
        
        // Check if passwords match
        guard password == confirmPassword else {
            showAlert(message: "Passwords do not match!", title: "Error")
            return
        }
        
        // Attempt to register the user
        registerUser(email: email, password: password) { result in
            switch result {
            case .success(let user):
                // Navigate back and show success message
                self.navigationController?.popViewController(animated: true)
                self.showAlert(message: "Account created successfully!", title: "Success")
                print("User registered successfully: \(user.email ?? "No Email")")
            case .failure(let error):
                // Show error message
                self.showAlert(message: error.localizedDescription, title: "Error")
                print("Failed to register user: \(error.localizedDescription)")
            }
        }
    }
    
    // Method to register a user with Firebase Authentication
    func registerUser(email: String, password: String, completion: @escaping (Result<User, Error>) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error {
                // Return error if registration fails
                completion(.failure(error))
                print("Error during registration: \(error.localizedDescription)")
                return
            }
            
            if let user = authResult?.user {
                // Return the user object if registration succeeds
                completion(.success(user))
                print("Registration successful for user: \(user.email ?? "No Email")")
            }
        }
    }
    
    // Method to show an alert with a message and title
    func showAlert(message: String, title: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
    }
}
