//
//  ViewController.swift
//  InstaClone
//
//  Created by can on 18.10.2024.
//

import UIKit
import FirebaseAuth

class LaunchVC: UIViewController {
    // Outlets for email and password input fields
    @IBOutlet weak var emailTextInput: UITextField! // Email input field
    @IBOutlet weak var passwordTextInput: UITextField! // Password input field
    
    // Instance of Brain for handling placeholder configurations
    var brain = Brain()
    
    // Placeholder text and color properties for email and password input fields
    let placeholderEmail = "e-mail"
    let placeholderColorEmail = UIColor.gray
    let placeholderPassword = "password"
    let placeholderColorPassword = UIColor.gray
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Check if a user is already logged in
        let currentUser = Auth.auth().currentUser
        if currentUser != nil {
            // Navigate to FeedVC if a user is logged in
            self.performSegue(withIdentifier: "toFeedVC", sender: self)
        }
        
        // Configure text color for input fields
        emailTextInput.textColor = UIColor.white
        passwordTextInput.textColor = UIColor.white
        
        // Set up placeholder text and color for email and password fields
        brain.placeHolders(textField: emailTextInput, placeholderText: placeholderEmail, placeholderColor: placeholderColorEmail)
        brain.placeHolders(textField: passwordTextInput, placeholderText: placeholderPassword, placeholderColor: placeholderColorPassword)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc func dismissKeyboard() {
       
        view.endEditing(true)
    }
    // Action for login button tap
    @IBAction func logIn(_ sender: UIButton) {
        // Retrieve email and password from text fields
        let email = emailTextInput.text ?? ""
        let password = passwordTextInput.text ?? ""
           
        // Attempt to log in the user with provided credentials
        loginUser(email: email, password: password) { result in
            switch result {
            case .success(let user):
                // Navigate to FeedVC on successful login
                print("Login successful for user: \(user.email ?? "unknown")")
                self.performSegue(withIdentifier: "toFeedVC", sender: nil)
            case .failure(let error):
                // Show an error alert if login fails
                print("Login failed: \(error.localizedDescription)")
                self.showAlert(message: error.localizedDescription, title: "Fail")
            }
        }
    }
    
    // Action for sign-up button tap
    @IBAction func signUp(_ sender: UIButton) {
        // Navigate to SignUpVC
        performSegue(withIdentifier: "toSignUpVC", sender: nil)
    }
    
    // Function to handle user login using Firebase Authentication
    func loginUser(email: String, password: String, completion: @escaping (Result<User, Error>) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            if let error = error {
                // Pass error to completion handler if login fails
                print("Firebase login error: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            if let user = authResult?.user {
                // Pass the logged-in user to the completion handler
                completion(.success(user))
            }
        }
    }
    
    // Function to display an alert with a given message and title
    func showAlert(message: String, title: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
    }
}
