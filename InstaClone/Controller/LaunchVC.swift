//
//  ViewController.swift
//  InstaClone
//
//  Created by can on 18.10.2024.
//

import UIKit
import FirebaseAuth

class LaunchVC: UIViewController {
    @IBOutlet weak var emailTextInput: UITextField! // Email input field
    @IBOutlet weak var passwordTextInput: UITextField! // Password input field
    
    var brain = Brain() // Custom brain object for placeholder handling
    
    // Placeholder texts for email and password input fields
    let placeholderEmail = "e-mail"
    let placeholderColorEmail = UIColor.gray
    let placeholderPassword = "password"
    let placeholderColorPassword = UIColor.gray
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let currentUser = Auth.auth().currentUser // Check if there's a current logged-in user
        
        // If a user is logged in, perform segue to the feed view controller
        if currentUser != nil {
            self.performSegue(withIdentifier: "toFeedVC", sender: self)
        }
        
        // Set the text color of input fields to white
        emailTextInput.textColor = UIColor.white
        passwordTextInput.textColor = UIColor.white
        
        // Set placeholders for email and password input fields
        brain.placeHolders(textField: emailTextInput, placeholderText: placeholderEmail, placeholderColor: placeholderColorEmail)
        brain.placeHolders(textField: passwordTextInput, placeholderText: placeholderPassword, placeholderColor: placeholderColorPassword)
    }

    // Action triggered when the user taps the login button
    @IBAction func logIn(_ sender: UIButton) {
        
        let email = emailTextInput.text ?? "" // Get the email text input
        let password = passwordTextInput.text ?? "" // Get the password text input
           
        // Attempt to log the user in with the provided email and password
        loginUser(email: email, password: password) { result in
               switch result {
               case .success(let user):
                   // If login is successful, perform segue to the feed view controller
                   self.performSegue(withIdentifier: "toFeedVC", sender: nil)
               case .failure(let error):
                   // If login fails, show an alert with the error message
                   self.showAlert(message: error.localizedDescription, title: "Fail")
               }
        }
    }
    
    // Action triggered when the user taps the sign-up button
    @IBAction func signUp(_ sender: UIButton) {
        // Perform segue to the sign-up view controller
        performSegue(withIdentifier: "toSignUpVC", sender: nil)
    }
    
    // Function to log in the user using Firebase Authentication
    func loginUser(email: String, password: String, completion: @escaping (Result<User, Error>) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            if let error = error {
                // If an error occurs during login, pass the error to the completion handler
                completion(.failure(error))
                return
            }
            
            if let user = authResult?.user {
                // If login is successful, pass the user to the completion handler
                completion(.success(user))
            }
        }
    }
    
    // Function to show an alert with a given message and title
    func showAlert(message: String, title: String) {
        let alertController = UIAlertController(title: title , message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
    }
}
