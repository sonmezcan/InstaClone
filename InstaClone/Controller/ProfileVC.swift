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
    @IBOutlet weak var profilePhoto: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let currentUser = Auth.auth().currentUser {
            print("User ID: \(currentUser.uid)")
        } else {
            print("User is not logged in.")
        }

        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(imagePicker))
        profilePhoto.addGestureRecognizer(tapGestureRecognizer)
        profilePhoto.isUserInteractionEnabled = true // Kullanıcı etkileşimini etkinleştir
        
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
    @IBAction func logOut(_ sender: UIButton) {
        logOutUser()
    }
    @IBAction func updatePhotoPressed(_ sender: Any) {
        
        
        guard let image = profilePhoto.image else {
            print("No image selected")
            return
        }

        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            print("Failed to convert image to data")
            return
        }
        
        let storageRef = Storage.storage().reference().child("profile_photos/\(Auth.auth().currentUser!.uid).jpg")
        
        storageRef.putData(imageData, metadata: nil) { metadata, error in
            if let error = error {
                print("Error uploading image: \(error.localizedDescription)")
                return
            }
            
            storageRef.downloadURL { url, error in
                if let error = error {
                    print("Error getting download URL: \(error.localizedDescription)")
                    return
                }
                
                guard let downloadURL = url else {
                    print("URL is nil")
                    return
                }
                
                self.updateUserProfilePhoto(url: downloadURL.absoluteString)
            }
        }
    }
    
    func updateUserProfilePhoto(url: String) {
        let changeRequest = Auth.auth().currentUser?.createProfileChangeRequest()
        changeRequest?.photoURL = URL(string: url)
        changeRequest?.commitChanges { error in
            if let error = error {
                print("Error updating profile: \(error.localizedDescription)")
            } else {
                print("Profile photo updated successfully")
            }
        }
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

//MARK: - Picker
extension ProfileVC: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let selectedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            profilePhoto.image = selectedImage
        }
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    @objc func imagePicker() {
        let imagePickerController = UIImagePickerController()
        imagePickerController.sourceType = .photoLibrary
        imagePickerController.delegate = self
        imagePickerController.allowsEditing = false
        present(imagePickerController, animated: true, completion: nil)
    }
}
