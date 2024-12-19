import UIKit
import Firebase
import FirebaseAuth
import SDWebImage

class CommentVC: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var mainAvatar: UIImageView!
    @IBOutlet weak var mainCommentField: UITextField!
    @IBOutlet weak var commentCountLabel: UILabel!
    
    var postId: String? // Ensure that postId is correctly passed from HomeVC
    var userCommentArray = [String]() // Array to store the comments
    var userNameArray = [String]() // Array to store the names/emails of the users who commented
    var userProfilePhotoUrl: String?
    var userProfilePhotoArray = [String]() // Array to store the profile photo URLs
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 70
        setupCurrentUserAvatar()
        getDataFromFirestore() // Fetch the comments from Firestore
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc func dismissKeyboard() {
        
        view.endEditing(true)
    }
    
    @IBAction func sendButton(_ sender: UIButton) {
        // Check if the comment field is not empty
        guard let commentText = mainCommentField.text, !commentText.isEmpty else {
            print("Comment text is empty") // Error message
            return
        }
        
        saveComment(commentText: commentText) // Save the comment to Firestore
        mainCommentField.text = "" // Clear the comment field after sending
    }
    func setupCurrentUserAvatar() {
        if let currentUser = Auth.auth().currentUser,
           let profilePhotoUrl = currentUser.photoURL?.absoluteString {
            mainAvatar.sd_setImage(with: URL(string: profilePhotoUrl), placeholderImage: UIImage(named: "defaultProfile"))
        } else {
            mainAvatar.image = UIImage(named: "defaultProfile")
        }
    }
    func saveComment(commentText: String) {
        guard let postId = postId else {
            print("Error: postId is nil")
            return
        }
        
        let firestore = Firestore.firestore()
        let commentData = [
            "commentText": commentText,
            "commentedBy": Auth.auth().currentUser?.email ?? "Anonymous",
            "profilePhotoUrl": Auth.auth().currentUser?.photoURL?.absoluteString ?? "",
            "timestamp": FieldValue.serverTimestamp()
        ] as [String: Any]
        
        firestore.collection("posts").document(postId).collection("comments").addDocument(data: commentData) { error in
            if let error = error {
                print("Error adding comment: \(error)")
            } else {
                print("Comment added successfully")
                self.getDataFromFirestore()
            }
        }
    }
    
    
    func getDataFromFirestore() {
        guard let postId = postId else {
            print("Error: postId is nil when fetching comments")
            return
        }
        
        let fireStoreDatabase = Firestore.firestore()
        fireStoreDatabase.collection("posts").document(postId).collection("comments").order(by: "timestamp", descending: false).addSnapshotListener { (snapshot, error) in
            if let error = error {
                print("Error getting comments: \(error)")
            } else {
                self.userCommentArray.removeAll()
                self.userNameArray.removeAll()
                self.userProfilePhotoArray.removeAll() // Clear previous profile photo URLs
                
                for doc in snapshot!.documents {
                    if let commentText = doc.get("commentText") as? String {
                        self.userCommentArray.append(commentText)
                    }
                    if let commentedBy = doc.get("commentedBy") as? String {
                        self.userNameArray.append(commentedBy)
                    }
                    if let profilePhotoUrl = doc.get("profilePhotoUrl") as? String {
                        self.userProfilePhotoArray.append(profilePhotoUrl)
                    } else {
                        // Add a placeholder URL if no profile photo URL is available
                        self.userProfilePhotoArray.append("")
                    }
                }
                
                self.tableView.reloadData()
            }
        }
    }
    func updateCommentCount() {
        guard let postId = postId else {
            return
        }
        
        let fireStoreDatabase = Firestore.firestore()
        fireStoreDatabase.collection("posts").document(postId).collection("comments").getDocuments { (snapshot, error) in
            if let error = error {
                print("Error fetching comment count: \(error)")
            } else {
                let commentCount = snapshot?.documents.count ?? 0
                
                if let commentCountLabel = self.commentCountLabel {
                    commentCountLabel.text = "\(commentCount) comments"
                } else {
                    print("commentCountLabel is nil!")
                }
            }
        }
    }
}

extension CommentVC: UITableViewDelegate, UITableViewDataSource {
    // Return the number of comments (rows) to display in the table view
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return userCommentArray.count
    }
    
    // Set up the cells to display the username and the comment text
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CommentCell", for: indexPath) as! CommentCell
        
        cell.userNameLabel.text = userNameArray[indexPath.row]
        cell.userComment.text = userCommentArray[indexPath.row]
        
        if let profilePhotoUrl = URL(string: userProfilePhotoArray[indexPath.row]), !userProfilePhotoArray[indexPath.row].isEmpty {
            cell.userAvatar.sd_setImage(with: profilePhotoUrl, placeholderImage: UIImage(named: "defaultProfile"))
        } else {
            cell.userAvatar.image = UIImage(named: "defaultProfile")
        }
        
        return cell
    }
}
