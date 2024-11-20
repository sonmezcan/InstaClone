//
//  ProfileVC.swift
//  InstaClone
//
//  Created by can on 24.10.2024.
//

import UIKit
import FirebaseAuth
import FirebaseStorage

class ProfileVC: UIViewController {
    // Outlet for profile photo image view
    @IBOutlet weak var profilePhoto: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Check if there is a currently logged-in user
        if let currentUser = Auth.auth().currentUser {
            print("User ID: \(currentUser.uid)")
        } else {
            print("No user is logged in.")
        }

        // Add a tap gesture recognizer to the profile photo for opening the image picker
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(imagePicker))
        profilePhoto.addGestureRecognizer(tapGestureRecognizer)
        profilePhoto.isUserInteractionEnabled = true // Enable user interaction for the image view
        
        // Load and display the current user's profile photo if available
        if let photoURL = Auth.auth().currentUser?.photoURL {
            URLSession.shared.dataTask(with: photoURL) { data, response, error in
                if let error = error {
                    print("Error loading profile photo: \(error.localizedDescription)")
                    return
                }

                if let data = data, let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self.profilePhoto.image = image
                    }
                }
            }.resume()
        }
    }
    
    // Log out the current user
    @IBAction func logOut(_ sender: UIButton) {
        logOutUser()
    }
    
    // Update the user's profile photo in Firebase
    @IBAction func updatePhotoPressed(_ sender: Any) {
        // Ensure an image has been selected
        guard let image = profilePhoto.image else {
            print("No image selected")
            return
        }

        // Convert the selected image to JPEG data
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            print("Failed to convert image to data")
            return
        }
        
        // Reference to the storage location for the profile photo
        let storageRef = Storage.storage().reference().child("profile_photos/\(Auth.auth().currentUser!.uid).jpg")
        
        // Upload the image to Firebase Storage
        storageRef.putData(imageData, metadata: nil) { metadata, error in
            if let error = error {
                print("Error uploading image: \(error.localizedDescription)")
                return
            }
            
            // Retrieve the download URL for the uploaded image
            storageRef.downloadURL { url, error in
                if let error = error {
                    print("Error getting download URL: \(error.localizedDescription)")
                    return
                }
                
                guard let downloadURL = url else {
                    print("Download URL is nil")
                    return
                }
                
                // Update the user's profile photo URL in Firebase Authentication
                self.updateUserProfilePhoto(url: downloadURL.absoluteString)
            }
        }
    }
    
    // Update the user's profile photo URL in Firebase Authentication
    func updateUserProfilePhoto(url: String) {
        let changeRequest = Auth.auth().currentUser?.createProfileChangeRequest()
        changeRequest?.photoURL = URL(string: url)
        changeRequest?.commitChanges { error in
            if let error = error {
                print("Error updating profile photo: \(error.localizedDescription)")
            } else {
                print("Profile photo updated successfully")
            }
        }
    }
    
    // Log out the user and navigate to the login screen
    func logOutUser() {
        do {
            try Auth.auth().signOut()
            navigateToLoginScreen()
        } catch let signOutError as NSError {
            print("Error signing out: \(signOutError.localizedDescription)")
        }
    }
    
    // Navigate to the login screen after logging out
    func navigateToLoginScreen() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let loginViewController = storyboard.instantiateViewController(withIdentifier: "LaunchVC") as! LaunchVC
        
        let navigationController = UINavigationController(rootViewController: loginViewController)
        
        self.view.window?.rootViewController = navigationController
        self.view.window?.makeKeyAndVisible()
    }
}

// MARK: - Image Picker Extension
extension ProfileVC: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    // Handle the image selection from the photo library
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let selectedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            profilePhoto.image = selectedImage
        }
        dismiss(animated: true, completion: nil)
    }
    
    // Handle cancellation of the image picker
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    // Open the photo library for selecting an image
    @objc func imagePicker() {
        let imagePickerController = UIImagePickerController()
        imagePickerController.sourceType = .photoLibrary
        imagePickerController.delegate = self
        imagePickerController.allowsEditing = false
        present(imagePickerController, animated: true, completion: nil)
    }
}
