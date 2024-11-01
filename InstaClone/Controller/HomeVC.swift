import UIKit
import Firebase
import SDWebImage
import FirebaseAuth

class HomeVC: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    var userEmailArray = [String]()
    var userCommentArray = [String]()
    var likeArray = [Int]()
    var userImageArray = [String]()
    var documentIdArray = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        getDataFromFirestore()
    }
    
    @IBAction func commentButtonPressed(_ sender: UIButton) {
        // Yorum butonuna tıklama eylemi
    }
    
    @IBAction func likeButton(_ sender: UIButton) {
        guard let cell = sender.superview?.superview as? FeedCell,
              let indexPath = tableView.indexPath(for: cell) else { return }
        
        let postId = documentIdArray[indexPath.row] // Gönderinin ID'si
        if let userId = Auth.auth().currentUser?.uid { // Giriş yapan kullanıcının ID'si
            toggleLike(postId: postId, userId: userId, index: indexPath.row)
        }
    }
    func getDataFromFirestore() {
        let fireStoreDatabase = Firestore.firestore()
        
        fireStoreDatabase.collection("posts").addSnapshotListener { (snapshot, error) in
            if let error = error {
                print("Error getting documents: \(error)")
            } else {
                self.userEmailArray.removeAll()
                self.userCommentArray.removeAll()
                self.likeArray.removeAll() // Her seferinde temizle
                self.userImageArray.removeAll()
                self.documentIdArray.removeAll()
                
                let group = DispatchGroup() // Beğeni sayısını almak için grup oluştur

                for doc in snapshot!.documents {
                    let docId = doc.documentID
                    self.documentIdArray.append(docId)
                    
                    if let postedBy = doc.get("postedBy") as? String {
                        self.userEmailArray.append(postedBy)
                    }
                    if let description = doc.get("description") as? String {
                        self.userCommentArray.append(description)
                    }
                    
                    // Likes koleksiyonundan beğeni sayısını al
                    group.enter()
                    self.getLikesCount(forPostId: docId) { likeCount in
                        self.likeArray.append(likeCount)
                        group.leave()
                    }

                    if let imageUrl = doc.get("imageURL") as? String {
                        self.userImageArray.append(imageUrl)
                    }
                }
                
                group.notify(queue: .main) {
                    self.tableView.reloadData() // Tüm veriler alındıktan sonra tabloyu güncelle
                }
            }
        }
    }

    func getLikesCount(forPostId postId: String, completion: @escaping (Int) -> Void) {
        let likesRef = Firestore.firestore().collection("likes").document(postId)
        
        likesRef.getDocument { (document, error) in
            if let error = error {
                print("Error getting likes: \(error)")
                completion(0) // Hata durumunda 0 döndür
            } else if let document = document, document.exists {
                let likeCount = document.data()?["likeCount"] as? Int ?? 0
                completion(likeCount)
            } else {
                completion(0) // Belge yoksa 0 döndür
            }
        }
    }
    
    func toggleLike(postId: String, userId: String, index: Int) {
        let likesRef = Firestore.firestore().collection("likes").document(postId)

        likesRef.getDocument { (document, error) in
            if let error = error {
                print("Error checking likes: \(error)")
                return
            }

            if let document = document, document.exists {
                var likedBy = document.data()?["likedBy"] as? [String] ?? []
                var likeCount = document.data()?["likeCount"] as? Int ?? 0

                if likedBy.contains(userId) {
                    // Kullanıcı beğeniyi kaldır
                    likedBy.removeAll(where: { $0 == userId })
                    likeCount -= 1
                } else {
                    // Kullanıcı beğeniyi ekle
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
                        print("Like toggled")
                        self.updateLikeCount(for: index)
                    }
                }
            } else {
                // Yeni belge oluştur
                likesRef.setData([
                    "likedBy": [userId],
                    "likeCount": 1
                ]) { error in
                    if let error = error {
                        print("Error adding like: \(error)")
                    } else {
                        print("Like added")
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
                self.likeArray[index] = likeCount // Beğeni sayısını güncelle
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
                
                cell.userLabel.text = userEmailArray[indexPath.row]
                cell.likeCounter.text = "\(likeArray[indexPath.row])"
                cell.userComment.text = userCommentArray[indexPath.row]
                cell.documentIdLabel.text = documentIdArray[indexPath.row]
                
                if let imageUrl = URL(string: userImageArray[indexPath.row]) {
                    cell.userImage.sd_setImage(with: imageUrl, placeholderImage: UIImage(named: "placeholder"))
                } else {
                    cell.userImage.image = UIImage(named: "placeholder")
                }
                
                return cell
            }
        }
