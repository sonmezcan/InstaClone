import UIKit
import Firebase
import SDWebImage
import FirebaseAuth
import FirebaseStorage

class HomeVC: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var likeButtonImg: UIButton!

    var userEmailArray = [String]() // Kullanıcı e-postalarını saklayan dizi
    var userCommentArray = [String]() // Kullanıcı yorumlarını saklayan dizi
    var likeArray = [Int]() // Gönderilerin beğeni sayılarını saklayan dizi
    var userImageArray = [String]() // Gönderi resim URL'lerini saklayan dizi
    var documentIdArray = [String]() // Gönderi document ID'lerini saklayan dizi
    var userProfilePhotoArray = [String]() // Profil fotoğraf URL'lerini saklayan dizi

    let db = Firestore.firestore()
    var posts: [Post] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        
        getDataFromFirestore() // Veri almak için çağırıyoruz
    }

    @IBAction func commentButtonPressed(_ sender: UIButton) {
        // Yorum ekranına geçiş yap
        performSegue(withIdentifier: "toCommentVC", sender: sender)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toCommentVC", let destinationVC = segue.destination as? CommentVC, let button = sender as? UIButton, let cell = button.superview?.superview as? FeedCell, let indexPath = tableView.indexPath(for: cell) {
            destinationVC.postId = documentIdArray[indexPath.row]
        }
    }

    func getDataFromFirestore() {
        let fireStoreDatabase = Firestore.firestore()
        
        fireStoreDatabase.collection("posts").order(by: "timestamp", descending: true).addSnapshotListener { (snapshot, error) in
            if let error = error {
                print("Error getting documents: \(error)")
                return
            }
            guard let documents = snapshot?.documents else {
                print("No documents found in Firestore")
                return
            }
            
            // Dizileri sıfırla
            self.posts.removeAll()
            self.userEmailArray.removeAll()
            self.userCommentArray.removeAll()
            self.likeArray.removeAll()
            self.userImageArray.removeAll()
            self.documentIdArray.removeAll()
            self.userProfilePhotoArray.removeAll()
            
            let group = DispatchGroup()

            for doc in documents {
                let docId = doc.documentID
                
                group.enter()

                if let postedBy = doc.get("postedBy") as? String,
                   let description = doc.get("description") as? String,
                   let imageUrl = doc.get("imageURL") as? String,
                   let userPhotoURL = doc.get("userPhotoURL") as? String,
                   let timestamp = doc.get("timestamp") as? Timestamp {
                    
                    let post = Post(imageURL: imageUrl, description: description, userPhotoURL: userPhotoURL, postedBy: postedBy, timestamp: timestamp)
                    self.posts.append(post)
                    
                    // Diğer verileri dizilere ekle
                    self.userEmailArray.append(post.postedBy)
                    self.userCommentArray.append(post.description)
                    self.userImageArray.append(post.imageURL)
                    self.documentIdArray.append(docId)
                    self.userProfilePhotoArray.append(post.userPhotoURL)
                }

                group.leave()
            }

            group.notify(queue: .main) {
                self.updateUIWithPosts()
            }
        }
    }

    func updateUIWithPosts() {
        self.tableView.reloadData() // Tabloyu güncelliyoruz
    }

    func getProfilePhotoURL(uid: String, completion: @escaping (URL?) -> Void) {
        let storageRef = Storage.storage().reference().child("profile_photos/\(uid).jpg")
        
        storageRef.downloadURL { (url, error) in
            if let error = error {
                print("Profil fotoğrafı URL'si alınırken hata oluştu: \(error.localizedDescription)")
                completion(nil)
            } else {
                completion(url) // URL'yi geri gönder
            }
        }
    }
}

// MARK: - TableView Delegate ve DataSource
extension HomeVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return userEmailArray.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! FeedCell

            // Diğer alanları doldur
            cell.userLabel.text = userEmailArray[indexPath.row]
            cell.userComment.text = userCommentArray[indexPath.row]
            cell.documentIdLabel.text = documentIdArray[indexPath.row]

            // Beğeni sayısı, eğer `likeArray` boşsa 0 olarak ayarlanabilir
            if likeArray.count > indexPath.row {
                cell.likeCounter.text = "\(likeArray[indexPath.row])"
            } else {
                cell.likeCounter.text = "0" // Eğer likeArray'de veri yoksa, 0 göster
            }

            // Profil fotoğrafı ve diğer içerikleri yükle
            let profilePhotoUrlString = userProfilePhotoArray[indexPath.row]
            if !profilePhotoUrlString.isEmpty, let profilePhotoUrl = URL(string: profilePhotoUrlString) {
                cell.userAvatar.sd_setImage(with: profilePhotoUrl, placeholderImage: UIImage(named: "defaultProfile"))
            } else {
                cell.userAvatar.image = UIImage(named: "defaultProfile")
            }

            let imageUrlString = userImageArray[indexPath.row]
            if !imageUrlString.isEmpty, let imageUrl = URL(string: imageUrlString) {
                cell.userImage.sd_setImage(with: imageUrl, placeholderImage: UIImage(named: "placeholder"))
            } else {
                cell.userImage.image = UIImage(named: "placeholder")
            }

            return cell
    }
}

// MARK: - Beğeni Fonksiyonu
extension HomeVC {
    @IBAction func likeButton(_ sender: UIButton) {
        // Beğeni işlemini gerçekleştir
        guard let cell = sender.superview?.superview as? FeedCell,
              let indexPath = tableView.indexPath(for: cell) else { return }
        
        let postId = documentIdArray[indexPath.row]
        if let userId = Auth.auth().currentUser?.uid {
            toggleLike(postId: postId, userId: userId, index: indexPath.row)
        }
    }

    func getLikesCount(forPostId postId: String, completion: @escaping (Int) -> Void) {
        let likesRef = Firestore.firestore().collection("likes").document(postId)
        
        likesRef.getDocument { document, error in
            if let error = error {
                print("Beğeniler alınırken hata oluştu: \(error)")
                completion(0)
            } else if let document = document, document.exists {
                let likeCount = document.data()?["likeCount"] as? Int ?? 0
                completion(likeCount)
            } else {
                completion(0)
            }
        }
    }

    func toggleLike(postId: String, userId: String, index: Int) {
        let likesRef = Firestore.firestore().collection("likes").document(postId)
        
        likesRef.getDocument { document, error in
            if let error = error {
                print("Beğeni durumu kontrol edilirken hata oluştu: \(error)")
                return
            }
            
            if let document = document, document.exists {
                var likedBy = document.data()?["likedBy"] as? [String] ?? []
                var likeCount = document.data()?["likeCount"] as? Int ?? 0
                
                if likedBy.contains(userId) {
                    likedBy.removeAll(where: { $0 == userId })
                    likeCount -= 1
                } else {
                    likedBy.append(userId)
                    likeCount += 1
                }
                
                likesRef.setData([
                    "likedBy": likedBy,
                    "likeCount": likeCount
                ], merge: true) { error in
                    if let error = error {
                        print("Beğeni güncellenirken hata oluştu: \(error)")
                    } else {
                        self.updateLikeCount(for: index)
                    }
                }
            } else {
                likesRef.setData([
                    "likedBy": [userId],
                    "likeCount": 1
                ]) { error in
                    if let error = error {
                        print("Beğeni eklenirken hata oluştu: \(error)")
                    } else {
                        self.updateLikeCount(for: index)
                    }
                }
            }
        }
    }

    func updateLikeCount(for index: Int) {
        let postId = documentIdArray[index]
        let likesRef = Firestore.firestore().collection("likes").document(postId)
        
        likesRef.getDocument { document, error in
            if let error = error {
                print("Beğeni sayısı alınırken hata oluştu: \(error)")
                return
            }
            
            if let document = document, document.exists {
                let likeCount = document.data()?["likeCount"] as? Int ?? 0
                self.likeArray[index] = likeCount
                self.tableView.reloadData()
            }
        }
    }
}
