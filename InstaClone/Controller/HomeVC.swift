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
        getDataFromFirestore()
        
        print("userEmailArray.count: \(userEmailArray.count)")
        print("userCommentArray.count: \(userCommentArray.count)")
        print("likeArray.count: \(likeArray.count)")
        print("userImageArray.count: \(userImageArray.count)")
        print("userProfilePhotoArray.count: \(userProfilePhotoArray.count)")
    }
    
    @IBAction func commentButtonPressed(_ sender: UIButton) {
        // Yorum ekranına geçiş yap
        performSegue(withIdentifier: "toCommentVC", sender: sender)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toCommentVC",
           let destinationVC = segue.destination as? CommentVC,
           let button = sender as? UIButton,
           let cell = button.superview?.superview as? FeedCell,
           let indexPath = tableView.indexPath(for: cell) {
            destinationVC.postId = documentIdArray[indexPath.row]
        }
    }
    
    @IBAction func likeButton(_ sender: UIButton) {
        // Beğeni işlemini gerçekleştir
        guard let cell = sender.superview?.superview as? FeedCell,
              let indexPath = tableView.indexPath(for: cell) else { return }
        
        let postId = documentIdArray[indexPath.row]
        if let userId = Auth.auth().currentUser?.uid {
            toggleLike(postId: postId, userId: userId, index: indexPath.row)
        }
    }
    func fetchPosts() {
        db.collection("posts").getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Veri alırken hata oluştu: \(error.localizedDescription)")
            } else {
                var posts: [Post] = []
                for document in querySnapshot!.documents {
                    let data = document.data()
                    // Burada Post modelini kullanarak veriyi alıp posts dizisine ekleyin
                    if let imageURL = data["imageURL"] as? String,
                       let description = data["description"] as? String,
                       let timestamp = data["timestamp"] as? Timestamp,
                       let postedBy = data["postedBy"] as? String,
                       let userPhotoURL = data["userPhotoURL"] as? String {
                        let post = Post(imageURL: imageURL, description: description, userPhotoURL: userPhotoURL, postedBy: postedBy, timestamp: timestamp)
                        posts.append(post)
                    }
                }
                self.updateUIWithPosts(posts)  // Posts dizisini UI'ya gönderiyoruz
            }
        }
    }
    
    func getDataFromFirestore() {
        let fireStoreDatabase = Firestore.firestore()

        fireStoreDatabase.collection("posts").addSnapshotListener { (snapshot, error) in
            if let error = error {
                print("Error getting documents: \(error)")
                return
            }

            guard let documents = snapshot?.documents else {
                print("No documents found in Firestore")
                return
            }

            // Dizileri sıfırla
            self.userEmailArray.removeAll()
            self.userCommentArray.removeAll()
            self.likeArray.removeAll()
            self.userImageArray.removeAll()
            self.documentIdArray.removeAll()
            self.userProfilePhotoArray.removeAll()

            let group = DispatchGroup() // Eşzamanlı işlemler için DispatchGroup

            for doc in documents {
                let docId = doc.documentID
                self.documentIdArray.append(docId)

                if let postedBy = doc.get("postedBy") as? String {
                    self.userEmailArray.append(postedBy)
                } else {
                    self.userEmailArray.append("") // Varsayılan değer
                }

                if let description = doc.get("description") as? String {
                    self.userCommentArray.append(description)
                } else {
                    self.userCommentArray.append("") // Varsayılan değer
                }

                if let imageUrl = doc.get("imageURL") as? String {
                    self.userImageArray.append(imageUrl)
                } else {
                    self.userImageArray.append("") // Varsayılan değer
                }

                group.enter()
                self.getLikesCount(forPostId: docId) { likeCount in
                    self.likeArray.append(likeCount)
                    group.leave()
                }

                if let uid = doc.get("uid") as? String {
                    group.enter()
                    self.getProfilePhotoURL(uid: uid) { profilePhotoURL in
                        if let profilePhotoURL = profilePhotoURL {
                            self.userProfilePhotoArray.append(profilePhotoURL.absoluteString)
                        } else {
                            self.userProfilePhotoArray.append("") // Varsayılan değer
                        }
                        group.leave()
                    }
                } else {
                    self.userProfilePhotoArray.append("") // Varsayılan değer
                }
            }

            group.notify(queue: .main) {
                // UI güncellemesi
                self.updateUIWithPosts(self.posts)
            }
        }
    }

    func updateUIWithPosts(_ posts: [Post]) {
        // Verilerin doğru şekilde eşleştiğini kontrol et
        guard self.userEmailArray.count == self.userProfilePhotoArray.count,
              self.userEmailArray.count == self.userImageArray.count else {
            print("Veri dizileri eşleşmiyor!")
            return
        }

        self.tableView.reloadData() // Table view'ı yenileyerek doğru verilerle görüntüleme yapıyoruz
    }
    
    
    
    func getProfilePhotoURL(uid: String, completion: @escaping (URL?) -> Void) {
        let storageRef = Storage.storage().reference().child("profile_photos/\(uid).jpg")
        
        storageRef.downloadURL { (url, error) in

            if let error = error {
                print("Error fetching profile photo URL: \(error.localizedDescription)")
                completion(nil)
            } else {
                completion(url)
            }
        }
    }
    
    func getLikesCount(forPostId postId: String, completion: @escaping (Int) -> Void) {
        let likesRef = Firestore.firestore().collection("likes").document(postId)
        
        likesRef.getDocument { document, error in
            if let error = error {
                print("Error getting likes: \(error)")
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
                print("Error checking likes: \(error)")
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
                        print("Error updating like: \(error)")
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
                        print("Error adding like: \(error)")
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
            if let document = document, document.exists, let likeCount = document.data()?["likeCount"] as? Int {
                self.likeArray[index] = likeCount
                self.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
            }
        }
    }
    
}

extension HomeVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return userEmailArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! FeedCell

        // Profil fotoğrafı URL'si
        let profilePhotoUrlString = userProfilePhotoArray[safe: indexPath.row] ?? "" // Güvenli erişim
        if !profilePhotoUrlString.isEmpty, let profilePhotoUrl = URL(string: profilePhotoUrlString) {
            // Profil fotoğrafı varsa, SDWebImage ile yükleme yap
            cell.userAvatar.sd_setImage(with: profilePhotoUrl, placeholderImage: UIImage(named: "defaultProfile"))
        } else {
            // Eğer profil fotoğrafı yoksa, varsayılan fotoğrafı göster
            cell.userAvatar.image = UIImage(named: "defaultProfile")
        }

        // Diğer alanlar
        cell.userLabel.text = userEmailArray[safe: indexPath.row] ?? "Unknown"
        cell.likeCounter.text = "\(likeArray[safe: indexPath.row] ?? 0)"
        cell.userComment.text = userCommentArray[safe: indexPath.row] ?? "No description"
        cell.documentIdLabel.text = documentIdArray[safe: indexPath.row] ?? ""

        if !userImageArray[safe: indexPath.row]!.isEmpty, let imageUrl = URL(string: userImageArray[safe: indexPath.row]!) {
            cell.userImage.sd_setImage(with: imageUrl, placeholderImage: UIImage(named: "placeholder"))
        } else {
            cell.userImage.image = UIImage(named: "placeholder")
        }

        return cell
    }
}

extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

extension UIImageView {
    func loadImage(from urlString: String) {
        guard let url = URL(string: urlString) else { return }
        DispatchQueue.global().async {
            if let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.image = image
                }
            }
        }
    }
}
