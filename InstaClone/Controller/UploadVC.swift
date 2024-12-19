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
    var activityIndicator: UIActivityIndicatorView!
    
    var photoButton: UIButton?
    var shareButton: UIButton?
    
    var retakeButton: UIButton?
    
    let storage = Storage.storage()
    let db = Firestore.firestore()
    let brain = Brain()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        activityIndicator = UIActivityIndicatorView(style: .large)
                activityIndicator.color = .gray
                activityIndicator.center = view.center
                activityIndicator.hidesWhenStopped = true
                view.addSubview(activityIndicator)
                
                brain.placeHolders(textField: descriptionTextField, placeholderText: "Add comment", placeholderColor: .gray)
                segmentedControl.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.black], for: .selected)
                
        hideElements(shouldHide: false)
                segmentedControl.selectedSegmentIndex = 1
                segmentedControl.addTarget(self, action: #selector(segmentChanged(_:)), for: .valueChanged)
                
                let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(imagePicker))
                imageView.addGestureRecognizer(tapGestureRecognizer)
                imageView.isUserInteractionEnabled = true
                
//                setupCamera()
//                setupCaptureButton()
    }
    
    @objc func dismissKeyboard() {
       
        view.endEditing(true)
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
            print("case story")
            
            hideElements(shouldHide: true)
            setupCamera()
            setupCaptureButton()
            
        case 1:
            print("case post")
            
            hideElements(shouldHide: false)
            if imageView.image == UIImage(named: "add-icon") {
                imagePicker()
            }
            removeFromSuperview()
           
            
        default:
            break
        }
    }
    func removeFromSuperview() {
        // Stop the camera and remove preview layer
        captureSession?.stopRunning()
        previewLayer?.removeFromSuperlayer()
        
        // Remove photoButton, shareButton, and retakeButton
        photoButton?.removeFromSuperview()
        photoButton = nil
        
        shareButton?.removeFromSuperview()
        shareButton = nil
        
        retakeButton?.removeFromSuperview()
        retakeButton = nil
    }
    func hideElements(shouldHide: Bool) {
        imageView.isHidden = shouldHide
        uploadButton.isHidden = shouldHide
        descriptionTextField.isHidden = shouldHide

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
        
        // Progress göstergesini başlat ve UI'yi kilitle
        activityIndicator.startAnimating()
        view.isUserInteractionEnabled = false
        
        let imageName = UUID().uuidString
        let imageRef = storage.reference().child("images/\(imageName).jpg")
        
        imageRef.putData(imageData, metadata: nil) { metadata, error in
            guard error == nil else {
                print("\(String(describing: error))")
                self.showError(message: "Failed to upload image. Please try again.")
                self.activityIndicator.stopAnimating()
                self.view.isUserInteractionEnabled = true
                return
            }
            
            imageRef.downloadURL { url, error in
                guard let downloadURL = url else {
                    print("no url: \(String(describing: error))")
                    self.showError(message: "Failed to retrieve image URL.")
                    self.activityIndicator.stopAnimating()
                    self.view.isUserInteractionEnabled = true
                    return
                }
                
                guard let user = Auth.auth().currentUser else { return }
                let userProfilePhotoURL = user.photoURL?.absoluteString ?? "https://your-default-photo-url.com"
                let postedBy = user.email ?? "Unknown User"
                
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
                ]) { [self] error in
                    // UI'yi tekrar etkinleştir ve progress göstergesini durdur
                    self.activityIndicator.stopAnimating()
                    self.view.isUserInteractionEnabled = true
                    
                    if let error = error {
                        print("Veritabanına kaydedilemedi: \(error)")
                        self.showError(message: "Failed to save post. Please try again.")
                    } else {
                        print("Post başarıyla yüklendi.")
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
//MARK: - Story Feature
extension UploadVC {
    
    func setupCamera() {
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = .photo
        
        guard let backCamera = AVCaptureDevice.default(for: .video) else {
            print("No camera found.")
            return
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: backCamera)
            captureSession.addInput(input)
        } catch {
            print("Error: \(error)")
            return
        }
        
        photoOutput = AVCapturePhotoOutput()
        if captureSession.canAddOutput(photoOutput) {
            captureSession.addOutput(photoOutput)
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        
        // contentView'in yüksekliğinden 80px çıkarıyoruz, segment controller altına boşluk bırakmak için
        let previewHeight = contentView.bounds.height - segmentedControl.bounds.height + 30
        previewLayer.frame = CGRect(x: 0, y: 0, width: contentView.bounds.width, height: previewHeight)
        
        contentView.layer.addSublayer(previewLayer)
        
        captureSession.startRunning()
    }
        
    func setupCaptureButton() {
        let button = UIButton(type: .system)
        button.setTitle(" ", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = .white
        button.layer.cornerRadius = 25
        button.clipsToBounds = true
        button.addTarget(self, action: #selector(capturePhoto), for: .touchUpInside)
        
        contentView.addSubview(button)
        
        NSLayoutConstraint.activate([
            button.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            button.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),
            button.widthAnchor.constraint(equalToConstant: 80),
            button.heightAnchor.constraint(equalToConstant: 80)
        ])
        
        contentView.bringSubviewToFront(button)
        self.photoButton = button
    }
        
    @objc func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        settings.flashMode = .auto
        
        photoOutput.capturePhoto(with: settings, delegate: self)
        
        // Capture button gizleniyor
        photoButton?.isHidden = true
    }
        
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            print("\(error)")
            return
        }
        
        guard let photoData = photo.fileDataRepresentation() else {
            print("no data")
            return
        }
        
        if let capturedImage = UIImage(data: photoData) {
            imageView.image = capturedImage
            imageView.isHidden = false
            
            // Share ve retake butonlarını göster
            setupActionButtons()
            
            // Capture button gizleniyor
            photoButton?.isHidden = true
            
            // Kamera durduruluyor
            captureSession.stopRunning()
        }
    }
        
    func setupActionButtons() {
        // Share button
        let share = UIButton(type: .system)
        share.setTitle("✔️ Share", for: .normal)
        share.setTitleColor(.black, for: .normal)
        share.backgroundColor = .white
        share.layer.cornerRadius = 10
        share.translatesAutoresizingMaskIntoConstraints = false
        share.addTarget(self, action: #selector(sharePhoto), for: .touchUpInside)
        
       
        
        // Retake button
        let retake = UIButton(type: .system)
        retake.setTitle("❌ Retake", for: .normal)
        retake.setTitleColor(.black, for: .normal)
        retake.backgroundColor = .white
        retake.layer.cornerRadius = 10
        retake.translatesAutoresizingMaskIntoConstraints = false
        retake.addTarget(self, action: #selector(retakePhoto), for: .touchUpInside)
        
        // Add buttons to the content view
        contentView.addSubview(share)
        contentView.addSubview(retake)
        
        
        // Layout constraints
        NSLayoutConstraint.activate([
            // Share button
            share.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            share.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),
            share.widthAnchor.constraint(equalToConstant: 120),
            share.heightAnchor.constraint(equalToConstant: 50),
            
           
            
            // Retake button
            retake.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            retake.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),
            retake.widthAnchor.constraint(equalToConstant: 120),
            retake.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        // Save references to buttons
        self.shareButton = share
        self.retakeButton = retake
    }
    
        @objc func sharePhoto() {
            // Upload photo to Firebase and save it in Firestore
            uploadStory()
        }
    
   
        
        @objc func retakePhoto() {
            // Hide the image view and reset the camera
            imageView.image = nil
            imageView.isHidden = true
            captureSession.startRunning()
            photoButton?.isHidden = false
            shareButton?.isHidden = true
            retakeButton?.isHidden = true
           
        }
        
        func uploadStory() {
            guard let image = imageView.image else {
                showError(message: "Please select an image.")
                return
            }
            
            guard let imageData = image.jpegData(compressionQuality: 0.8) else {
                showError(message: "Failed to process image.")
                return
            }

            // Start activity indicator
            activityIndicator.startAnimating()
            view.isUserInteractionEnabled = false
            
            // Upload image to Firebase Storage
            let imageName = UUID().uuidString
            let imageRef = storage.reference().child("stories/\(imageName).jpg")
            
            imageRef.putData(imageData, metadata: nil) { _, error in
                if let error = error {
                    self.showError(message: "Error uploading story: \(error.localizedDescription)")
                    self.activityIndicator.stopAnimating()
                    return
                }
                
                imageRef.downloadURL { url, error in
                    guard let downloadURL = url else {
                        self.showError(message: "Failed to retrieve URL.")
                        self.activityIndicator.stopAnimating()
                        return
                    }
                    
                    // Save the story to Firestore
                    self.saveStoryToFirestore(imageURL: downloadURL.absoluteString)
                }
            }
        }

    func saveStoryToFirestore(imageURL: String) {
        guard let user = Auth.auth().currentUser else {
            self.showError(message: "You must be signed in to upload a story.")
            return
        }
        
        let storyData: [String: Any] = [
            "imageUrl": imageURL,
            "timestamp": Timestamp(date: Date()),
            "userName": user.displayName ?? "Unknown User"
        ]
        
        self.activityIndicator.startAnimating()
        self.view.isUserInteractionEnabled = false
        
        let userStoryRef = db.collection("stories").document(user.uid)
        userStoryRef.setData(storyData) { error in
            self.activityIndicator.stopAnimating()
            self.view.isUserInteractionEnabled = true
            
            if let error = error {
                self.showError(message: "Failed to save story: \(error.localizedDescription)")
            } else {
                print("Story successfully uploaded.")
                
                self.tabBarController?.selectedIndex = 0
            }
        }
    }
}
