import UIKit
import AVFoundation
import FirebaseStorage
import FirebaseFirestore

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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        segmentedControl.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.black], for: .selected)
        
        openCamera()
        hideElements(Bool: true)
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.addTarget(self, action: #selector(segmentChanged(_:)), for: .valueChanged)
        self.containerView.addSubview(segmentedControl)
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(imagePicker))
        
        imageView.addGestureRecognizer(tapGestureRecognizer)
    }
    @IBAction func uploadButton(_ sender: UIButton) {
        uploadPhoto()
    }
    
    @objc func segmentChanged(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            print("Option 1 seçildi")
            
            hideElements(Bool: true)
            openCamera()
        case 1:
            hideElements(Bool: false)
            imageView.isUserInteractionEnabled = true
            if imageView.image == UIImage(named: "add-icon") {
                imagePicker()
            }
        default:
            break
        }
    }
    func hideElements (Bool: Bool) {
        imageView.isHidden = Bool
        uploadButton.isHidden = Bool
        descriptionTextField.isHidden = Bool
    }
    func openCamera () {
        // CaptureSession'i başlatıyoruz
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = .high
        
        // Cihazın arka kamerasını seçiyoruz
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            print("Kamera bulunamadı")
            return
        }
        
        // Video girişi oluşturma
        let videoInput: AVCaptureDeviceInput
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            print("Kamera girişini oluşturma hatası: \(error)")
            return
        }
        
        // CaptureSession'a video girişi ekleme
        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        } else {
            print("Video girişi eklenemedi")
            return
        }
        
        // Video çıktısını oluşturuyoruz
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        videoPreviewLayer.videoGravity = .resizeAspectFill
        videoPreviewLayer.frame = contentView.bounds
        
        // Video görüntüsünü cameraView'e ekliyoruz
        contentView.layer.addSublayer(videoPreviewLayer)
        
        // Kamera görüntüsünü başlatıyoruz
        captureSession.startRunning()
    }
    
    func uploadPhoto(){
        guard let image = imageView.image else { return }
        guard let imageData = image.jpegData(compressionQuality: 0.8) else { return }
        guard let description = descriptionTextField.text else { return }
        
        // Fotoğrafı Firebase Storage'a yükleyelim
        let imageName = UUID().uuidString // Benzersiz bir isim
        let imageRef = storage.reference().child("images/\(imageName).jpg")
        
        imageRef.putData(imageData, metadata: nil) { metadata, error in
            guard error == nil else {
                print("Fotoğraf yüklenirken hata oluştu: \(String(describing: error))")
                return
            }
            
            // Fotoğrafın URL'sini alalım
            imageRef.downloadURL { url, error in
                guard let downloadURL = url else {
                    print("URL alınamadı: \(String(describing: error))")
                    return
                }
                
                // Firestore'a açıklama ve tarih bilgisiyle birlikte kaydedelim
                self.db.collection("posts").addDocument(data: [
                    "imageURL": downloadURL.absoluteString,
                    "description": description,
                    "timestamp": Timestamp(date: Date())
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
}




//MARK: - Picker
extension UploadVC:  UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        // Seçilen fotoğrafı al
        if let selectedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            imageView.image = selectedImage // Seçilen resmi UIImageView'a atıyoruz
        }
        
        // Fotoğraf seçiciyi kapat
        dismiss(animated: true, completion: nil)
    }
    
    // Kullanıcı iptal ederse bu fonksiyon tetiklenir
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil) // Fotoğraf seçiciyi kapat
    }
    @objc func imagePicker() {
        let imagePickerController = UIImagePickerController()
        imagePickerController.sourceType = .photoLibrary
        imagePickerController.delegate = self
        imagePickerController.allowsEditing = false // Fotoğrafın kırpılmasına izin vermiyoruz
        
        // Fotoğraf seçici ekranını göster
        present(imagePickerController, animated: true, completion: nil)
    }
}
