import UIKit
import AVFoundation
import FirebaseStorage
import FirebaseFirestore
import FirebaseAuth

class UploadVC: UIViewController, AVCapturePhotoCaptureDelegate {
    @IBOutlet weak var uploadButton: UIButton!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var descriptionTextField: UITextField!
    
    var captureSession: AVCaptureSession!
    var photoOutput: AVCapturePhotoOutput!
    var previewLayer: AVCaptureVideoPreviewLayer!
    var capturedImageView: UIImageView!
    
    let storage = Storage.storage()
    let db = Firestore.firestore()
    let brain = Brain()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        
        brain.placeHolders(textField: descriptionTextField, placeholderText: "Add comment", placeholderColor: .gray)
        segmentedControl.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.black], for: .selected)
        
        
        hideElements(shouldHide: true)
        segmentedControl.selectedSegmentIndex = 1
        segmentedControl.addTarget(self, action: #selector(segmentChanged(_:)), for: .valueChanged)
        self.containerView.addSubview(segmentedControl)
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(imagePicker))
        imageView.addGestureRecognizer(tapGestureRecognizer)
        imageView.isUserInteractionEnabled = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        captureSession.stopRunning()
    }
    
    @IBAction func uploadButton(_ sender: UIButton) {
        uploadPost()
    }
    
    @objc func segmentChanged(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            hideElements(shouldHide: true)
            setupCamera()
            setupCaptureButton()
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
    
    func setupCamera() {
        
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = .photo
        
        // Arka kamerayı ayarla
        guard let backCamera = AVCaptureDevice.default(for: .video) else {
            print("Kamera bulunamadı.")
            return
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: backCamera)
            captureSession.addInput(input)
        } catch {
            print("Kamera girişini eklerken hata: \(error)")
            return
        }
        
        
        photoOutput = AVCapturePhotoOutput()
        if captureSession.canAddOutput(photoOutput) {
            captureSession.addOutput(photoOutput)
        }
        
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = contentView.bounds
        contentView.layer.addSublayer(previewLayer)
        
        
        captureSession.startRunning()
    }
    
    func setupCaptureButton() {
        
        let photoButton = UIButton(type: .system)
        photoButton.setTitle("Çek", for: .normal)
        photoButton.translatesAutoresizingMaskIntoConstraints = false // Önemli!
        photoButton.backgroundColor = .white
        photoButton.setTitleColor(.black, for: .normal)
        photoButton.layer.cornerRadius = 25
        photoButton.clipsToBounds = true
        photoButton.addTarget(self, action: #selector(capturePhoto), for: .touchUpInside)
        
        contentView.addSubview(photoButton)
        
        NSLayoutConstraint.activate([
            photoButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            photoButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),
            photoButton.widthAnchor.constraint(equalToConstant: 80),
            photoButton.heightAnchor.constraint(equalToConstant: 80)
        ])
        
        contentView.bringSubviewToFront(photoButton)
    }
    
    @objc func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        settings.flashMode = .auto
        
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            print("Fotoğraf çekme hatası: \(error)")
            return
        }
        
        guard let photoData = photo.fileDataRepresentation() else {
            print("Fotoğraf verisi alınamadı.")
            return
        }
        
        if let capturedImage = UIImage(data: photoData) {
            imageView.image = capturedImage
            imageView.isHidden = false
            
            
            hideElements(shouldHide: false)
        }
        
        
        captureSession.stopRunning()
    }
    
    
    
    func uploadPost() {
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
                self.showError(message: "Failed to upload image. Please try again.")
                return
            }
            
            imageRef.downloadURL { url, error in
                guard let downloadURL = url else {
                    print("URL alınamadı: \(String(describing: error))")
                    self.showError(message: "Failed to retrieve image URL.")
                    return
                }
                
                
                guard let user = Auth.auth().currentUser else { return }
                let userProfilePhotoURL = user.photoURL?.absoluteString ?? "https://your-default-photo-url.com"
                let postedBy = user.email ?? "Unknown User"  // Fallback if the email is nil
                
               
                let post = Post(
                    imageURL: downloadURL.absoluteString,
                    description: description,
                    userPhotoURL: userProfilePhotoURL,
                    postedBy: postedBy,
                    timestamp: Timestamp(date: Date())
                )
                
               
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
                        self.showError(message: "Failed to save post. Please try again.")
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
