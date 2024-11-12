import UIKit
import Firebase
import FirebaseAuth

class CommentVC: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var mainAvatar: UIImageView!
    @IBOutlet weak var mainCommentField: UITextField!

    var postId: String? // Ensure that postId is correctly passed from HomeVC
    var userCommentArray = [String]() // Array to store the comments
    var userNameArray = [String]() // Array to store the names/emails of the users who commented

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 70
        getDataFromFirestore() // Fetch the comments from Firestore
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
    
    func saveComment(commentText: String) {
        // Ensure the postId is available before saving the comment
        guard let postId = postId else {
            print("Error: postId is nil") // Error message
            return
        }
        
        let firestore = Firestore.firestore()
        // Prepare the comment data to be saved in Firestore
        let commentData = [
            "commentText": commentText,
            "commentedBy": Auth.auth().currentUser?.email ?? "Anonymous", // Store email of the user who commented
            "timestamp": FieldValue.serverTimestamp() // Store the current timestamp
        ] as [String: Any]
        
        firestore.collection("posts").document(postId).collection("comments").addDocument(data: commentData) { error in
            if let error = error {
                print("Error adding comment: \(error)") // Handle errors while saving the comment
            } else {
                print("Comment added successfully")
                self.getDataFromFirestore() // Refresh the table to show the newly added comment
            }
        }
    }

    func getDataFromFirestore() {
        // Ensure the postId is available before fetching comments
        guard let postId = postId else {
            print("Error: postId is nil when fetching comments") // Error message
            return
        }
        
        let fireStoreDatabase = Firestore.firestore()
        // Fetch the comments from Firestore, ordered by timestamp
        fireStoreDatabase.collection("posts").document(postId).collection("comments").order(by: "timestamp", descending: false).addSnapshotListener { (snapshot, error) in
            if let error = error {
                print("Error getting comments: \(error)") // Handle errors while fetching comments
            } else {
                self.userCommentArray.removeAll() // Clear previous comments
                self.userNameArray.removeAll() // Clear previous usernames

                // Loop through the snapshot to extract comment data
                for doc in snapshot!.documents {
                    if let commentText = doc.get("commentText") as? String {
                        self.userCommentArray.append(commentText) // Add the comment text to the array
                    }
                    if let commentedBy = doc.get("commentedBy") as? String {
                        self.userNameArray.append(commentedBy) // Add the username/email to the array
                    }
                }
                self.tableView.reloadData() // Reload the table to display new comments
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
        
        // Display the username of the person who commented
        cell.userNameLabel.text = userNameArray[indexPath.row]
        // Display the comment text
        cell.userComment.text = userCommentArray[indexPath.row]
        
        return cell
    }
}
