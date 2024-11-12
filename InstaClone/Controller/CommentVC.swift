import UIKit
import Firebase
import FirebaseAuth

class CommentVC: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var mainAvatar: UIImageView!
    @IBOutlet weak var mainCommentField: UITextField!

    var postId: String? // HomeVC'den doğru şekilde aktarıldığından emin olun
    var userCommentArray = [String]() // Yorumları tutmak için bir dizi tanımlandı
    var userNameArray = [String]() // Yorum yapanların adlarını/e-posta adreslerini tutmak için bir dizi tanımlandı

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 70
        getDataFromFirestore() // Yorumları almak için
    }

    @IBAction func sendButton(_ sender: UIButton) {
        guard let commentText = mainCommentField.text, !commentText.isEmpty else {
            print("Comment text is empty") // Hata mesajı
            return
        }
        
        saveComment(commentText: commentText)
        mainCommentField.text = "" // Yorum gönderildikten sonra metin kutusunu temizle
    }
    
    func saveComment(commentText: String) {
        guard let postId = postId else {
            print("Error: postId is nil") // Hata mesajı
            return
        }
        
        let firestore = Firestore.firestore()
        let commentData = [
            "commentText": commentText,
            "commentedBy": Auth.auth().currentUser?.email ?? "Anonymous",
            "timestamp": FieldValue.serverTimestamp()
        ] as [String: Any]
        
        firestore.collection("posts").document(postId).collection("comments").addDocument(data: commentData) { error in
            if let error = error {
                print("Error adding comment: \(error)")
            } else {
                print("Comment added successfully")
                self.getDataFromFirestore() // Yeni yorumları yüklemek için tabloyu yenile
            }
        }
    }

    func getDataFromFirestore() {
        guard let postId = postId else {
            print("Error: postId is nil when fetching comments") // Hata mesajı
            return
        }
        
        let fireStoreDatabase = Firestore.firestore()
        fireStoreDatabase.collection("posts").document(postId).collection("comments").order(by: "timestamp", descending: false).addSnapshotListener { (snapshot, error) in
            if let error = error {
                print("Error getting comments: \(error)")
            } else {
                self.userCommentArray.removeAll()
                self.userNameArray.removeAll()

                for doc in snapshot!.documents {
                    if let commentText = doc.get("commentText") as? String {
                        self.userCommentArray.append(commentText)
                    }
                    if let commentedBy = doc.get("commentedBy") as? String {
                        self.userNameArray.append(commentedBy)
                    }
                }
                self.tableView.reloadData() // Tabloyu yeni yorumlarla güncelle
            }
        }
    }
}

extension CommentVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return userCommentArray.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CommentCell", for: indexPath) as! CommentCell
        
        cell.userNameLabel.text = userNameArray[indexPath.row] // Yorumu yapanın adını göster
        cell.userComment.text = userCommentArray[indexPath.row] // Yorum metnini göster
        
        return cell
    }
}
