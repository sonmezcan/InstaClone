import UIKit
import Firebase
import SDWebImage
import FirebaseAuth
import FirebaseStorage

class HomeVC: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var likeButtonImg: UIButton!
    @IBOutlet weak var commentCounter: UILabel!
    
    var userEmailArray = [String]() // Array to store user emails
    var userCommentArray = [String]() // Array to store user comments
    var likeArray = [Int]() // Array to store like counts for posts
    var userImageArray = [String]() // Array to store image URLs of posts
    var documentIdArray = [String]() // Array to store document IDs of posts
    var userProfilePhotoArray = [String]() // Array to store profile photo URLs

    let db = Firestore.firestore()
    var posts: [Post] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        
        getDataFromFirestore() // Fetch data from Firestore
    }

    @IBAction func commentButtonPressed(_ sender: UIButton) {
        // Navigate to the comment screen
        performSegue(withIdentifier: "toCommentVC", sender: sender)
    }

    func getCommentCount(forPostId postId: String, completion: @escaping (Int) -> Void) {
        let commentsRef = Firestore.firestore().collection("posts").document(postId).collection("comments")
        
        commentsRef.getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching comment count: \(error)")
                completion(0)
            } else {
                let commentCount = snapshot?.documents.count ?? 0
                completion(commentCount)
            }
        }
    }
    func observeComments(forPostId postId: String, completion: @escaping (Int) -> Void) {
        let commentsRef = Firestore.firestore().collection("posts").document(postId).collection("comments")
        
        commentsRef.addSnapshotListener { snapshot, error in
            if let error = error {
                print("Error observing comments: \(error)")
                completion(0)
            } else {
                let commentCount = snapshot?.documents.count ?? 0
                completion(commentCount)
            }
        }
    }
    func updateCommentCounter(count: Int) {
        commentCounter.text = "\(count) comments"
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

    func getDataFromFirestore() {
        let fireStoreDatabase = Firestore.firestore()
        
        fireStoreDatabase.collection("posts").order(by: "timestamp", descending: true).addSnapshotListener { (snapshot, error) in
            if let error = error {
                print("Error fetching documents: \(error)")
                return
            }
            guard let documents = snapshot?.documents else {
                print("No documents found in Firestore")
                return
            }
            
            // Clear arrays
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
                
                group.enter() // Start async task
                
                if let postedBy = doc.get("postedBy") as? String,
                   let description = doc.get("description") as? String,
                   let imageUrl = doc.get("imageURL") as? String,
                   let userPhotoURL = doc.get("userPhotoURL") as? String,
                   let timestamp = doc.get("timestamp") as? Timestamp {
                    
                    let post = Post(imageURL: imageUrl, description: description, userPhotoURL: userPhotoURL, postedBy: postedBy, timestamp: timestamp)
                    self.posts.append(post)
                    
                    // Append data to respective arrays
                    self.userEmailArray.append(post.postedBy)
                    self.userCommentArray.append(post.description)
                    self.userImageArray.append(post.imageURL)
                    self.documentIdArray.append(docId)
                    self.userProfilePhotoArray.append(post.userPhotoURL)
                    
                    // Set default like count to 0
                    self.likeArray.append(0)
                    
                    // Fetch like count from Firestore
                    self.getLikesCount(forPostId: docId) { likeCount in
                        if let index = self.documentIdArray.firstIndex(of: docId) {
                            self.likeArray[index] = likeCount
                        }
                        group.leave() // End async task after getting like count
                    }
                }
            }
            
            // Reload UI when all async tasks are done
            group.notify(queue: .main) {
                self.updateUIWithPosts()
            }
        }
    }

    func updateUIWithPosts() {
        self.tableView.reloadData() // Refresh table view
    }

    func getProfilePhotoURL(uid: String, completion: @escaping (URL?) -> Void) {
        let storageRef = Storage.storage().reference().child("profile_photos/\(uid).jpg")
        
        storageRef.downloadURL { (url, error) in
            if let error = error {
                print("Error fetching profile photo URL: \(error.localizedDescription)")
                completion(nil)
            } else {
                completion(url) // Return the URL
            }
        }
    }
}

// MARK: - TableView Delegate and DataSource
extension HomeVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return userEmailArray.count
    }
    
    
        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! FeedCell
            
            cell.userLabel.text = userEmailArray[indexPath.row]
            cell.userComment.text = userCommentArray[indexPath.row]
            cell.documentIdLabel.text = documentIdArray[indexPath.row]
            cell.likeCounter.text = "\(likeArray[indexPath.row])"
            
            if let profilePhotoUrl = URL(string: userProfilePhotoArray[indexPath.row]) {
                cell.userAvatar.sd_setImage(with: profilePhotoUrl, placeholderImage: UIImage(named: "defaultProfile"))
            } else {
                cell.userAvatar.image = UIImage(named: "defaultProfile")
            }
            
            if let imageUrl = URL(string: userImageArray[indexPath.row]) {
                cell.userImage.sd_setImage(with: imageUrl, placeholderImage: UIImage(named: "placeholder"))
            } else {
                cell.userImage.image = UIImage(named: "placeholder")
            }
            
            // Pass the postId to the cell and call configureCell
            let postId = documentIdArray[indexPath.row]
            cell.configureCell(postId: postId)
            
            
                getCommentCount(forPostId: postId) { commentCount in
                    DispatchQueue.main.async {
                        cell.commentCounter.text = "\(commentCount) comments"
                    }
                }
            observeComments(forPostId: postId) { commentCount in
                DispatchQueue.main.async {
                    cell.commentCounter.text = "\(commentCount) comments"
                }
            }
            
            return cell
            
        
    }
}

// MARK: - Like Feature
extension HomeVC {
    @IBAction func likeButton(_ sender: UIButton) {
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
                print("Error fetching like count: \(error)")
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
                print("Error toggling like: \(error)")
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
            if let error = error {
                print("Error updating like count: \(error)")
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
