import UIKit
import AVFoundation

class UploadVC: UIViewController {
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var containerView: UIView! 
    @IBOutlet weak var imageView: UIImageView!
    
    var captureSession: AVCaptureSession!
    var videoPreviewLayer: AVCaptureVideoPreviewLayer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        openCamera()
        imageView.isHidden = true
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.addTarget(self, action: #selector(segmentChanged(_:)), for: .valueChanged)
        self.containerView.addSubview(segmentedControl)
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(imagePicker))
                
        imageView.addGestureRecognizer(tapGestureRecognizer)
    }
    
    @objc func segmentChanged(_ sender: UISegmentedControl) {
            switch sender.selectedSegmentIndex {
            case 0:
                print("Option 1 seçildi")
                imageView.isHidden = true
                openCamera()
            case 1:
                imageView.isHidden = false
                imageView.isUserInteractionEnabled = true
                if imageView.image == UIImage(named: "add-icon") {
                    imagePicker()
                }
            default:
            break
        }
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
