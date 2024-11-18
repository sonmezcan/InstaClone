import UIKit
import AVFoundation
import FirebaseStorage
import FirebaseFirestore
import FirebaseAuth

class UploadVC: UIViewController {
    @IBOutlet weak var uploadButton: UIButton!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var descriptionTextField: UITextField!
    
    var captureSession: AVCaptureSession!
    var videoPreviewLayer: AVCaptureVideoPreviewLayer!
    
    let storage = Storage.storage()
    let db = Firestore.firestore()
    let brain = Brain()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        brain.placeHolders(textField: descriptionTextField, placeholderText: "Add comment", placeholderColor: .gray)
        segmentedControl.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.black], for: .selected)
        
        openCamera()
        hideElements(shouldHide: true)
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.addTarget(self, action: #selector(segmentChanged(_:)), for: .valueChanged)
        self.containerView.addSubview(segmentedControl)
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(imagePicker))
        imageView.addGestureRecognizer(tapGestureRecognizer)
        imageView.isUserInteractionEnabled = true // Kullanıcı etkileşimini etkinleştir
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        captureSession.stopRunning()  // Kamera sesi kapanırken durdurulmalı
    }
    
    @IBAction func uploadButton(_ sender: UIButton) {
        uploadPhoto()
    }
    
    @objc func segmentChanged(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            hideElements(shouldHide: true)
            openCamera()
        case 1:
            hideElements(shouldHide: false)
            if imageView.image == UIImage(named: "add-icon") {
                imagePicker()
            }
        default:
            break
        }
    }
    
    func hideElements(shouldHide: Bool) {
        imageView.isHidden = shouldHide
        uploadButton.isHidden = shouldHide
        descriptionTextField.isHidden = shouldHide
    }
    
    func openCamera() {
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = .high
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            print("Kamera bulunamadı")
            return
        }
        
        do {
            let videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
            if captureSession.canAddInput(videoInput) {
                captureSession.addInput(videoInput)
            } else {
                print("Video girişi eklenemedi")
                return
            }
        } catch {
            print("Kamera girişini oluşturma hatası: \(error)")
            return
        }
        
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        videoPreviewLayer.videoGravity = .resizeAspectFill
        videoPreviewLayer.frame = contentView.bounds
        contentView.layer.addSublayer(videoPreviewLayer)
        captureSession.startRunning()
    }
    
    func uploadPhoto() {
        guard let image = imageView.image else {
            showError(message: "Please select an image.")
            return
        }
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            showError(message: "Failed to process image.")
            return
        }
        guard let description = descriptionTextField.text, !description.isEmpty else {
            showError(message: "Please provide a description.")
            return
        }
        
        let imageName = UUID().uuidString
        let imageRef = storage.reference().child("images/\(imageName).jpg")
        
        imageRef.putData(imageData, metadata: nil) { metadata, error in
            guard error == nil else {
                print("Fotoğraf yüklenirken hata oluştu: \(String(describing: error))")
                return
            }
            
            imageRef.downloadURL { url, error in
                guard let downloadURL = url else {
                    print("URL alınamadı: \(String(describing: error))")
                    return
                }

                // Profil fotoğrafı URL'sini Firestore'a kaydedin
                guard let user = Auth.auth().currentUser else { return }
                let userProfilePhotoURL = user.photoURL?.absoluteString ?? ""
                let postedBy = user.email ?? "Unknown User"  // Fallback if the email is nil
                
                // 'Post' modelini kullanarak veri kaydedelim
                let post = Post(
                    imageURL: downloadURL.absoluteString,
                    description: description,
                    userPhotoURL: userProfilePhotoURL,
                    postedBy: postedBy,
                    timestamp: Timestamp(date: Date())
                )
                
                // Veriyi Firestore'a ekleyelim
                self.db.collection("posts").addDocument(data: [
                    "imageURL": post.imageURL,
                    "description": post.description,
                    "timestamp": post.timestamp,
                    "postedBy": post.postedBy,
                    "uid": user.uid,
                    "userPhotoURL": post.userPhotoURL
                ]) { error in
                    if let error = error {
                        print("Veritabanına kaydedilemedi: \(error)")
                    } else {
                        print("Fotoğraf başarıyla yüklendi ve Firestore'a kaydedildi!")
                        self.tabBarController?.selectedIndex = 0
                    }
                }
            }
        }
    }
    
    func showError(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}

//MARK: - Picker
extension UploadVC: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let selectedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            imageView.image = selectedImage
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
