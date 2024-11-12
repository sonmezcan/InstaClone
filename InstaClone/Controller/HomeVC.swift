import UIKit
import Firebase
import SDWebImage
import FirebaseAuth

class HomeVC: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var likeButtonImg: UIButton!
    
    var userEmailArray = [String]() // Array to store user emails
    var userCommentArray = [String]() // Array to store user comments
    var likeArray = [Int]() // Array to store the like counts for each post
    var userImageArray = [String]() // Array to store image URLs for each post
    var documentIdArray = [String]() // Array to store the document IDs for each post
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        getDataFromFirestore() // Fetch the data from Firestore
    }
    
    @IBAction func commentButtonPressed(_ sender: UIButton) {
        // Perform segue to the comment view controller, passing the button as the sender
        performSegue(withIdentifier: "toCommentVC", sender: sender)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toCommentVC",
           let destinationVC = segue.destination as? CommentVC,
           let button = sender as? UIButton,
           let cell = button.superview?.superview as? FeedCell,
           let indexPath = tableView.indexPath(for: cell) {
            destinationVC.postId = documentIdArray[indexPath.row] // Pass postId to CommentVC
        }
    }
    
    @IBAction func likeButton(_ sender: UIButton) {
        // Get the index path of the cell that triggered the like action
        guard let cell = sender.superview?.superview as? FeedCell,
              let indexPath = tableView.indexPath(for: cell) else { return }
        
        let postId = documentIdArray[indexPath.row] // Post ID of the current post
        if let userId = Auth.auth().currentUser?.uid { // Get the current user's ID
            toggleLike(postId: postId, userId: userId, index: indexPath.row) // Toggle the like status
        }
    }
    
    func getDataFromFirestore() {
        let fireStoreDatabase = Firestore.firestore()
        
        fireStoreDatabase.collection("posts").addSnapshotListener { (snapshot, error) in
            if let error = error {
                print("Error getting documents: \(error)") // Handle Firestore fetch error
            } else {
                self.userEmailArray.removeAll() // Clear existing data
                self.userCommentArray.removeAll()
                self.likeArray.removeAll()
                self.userImageArray.removeAll()
                self.documentIdArray.removeAll()
                
                let group = DispatchGroup() // Create a dispatch group for fetching like counts
                
                // Loop through the Firestore documents (posts)
                for doc in snapshot!.documents {
                    let docId = doc.documentID
                    self.documentIdArray.append(docId) // Store document ID
                    
                    if let postedBy = doc.get("postedBy") as? String {
                        self.userEmailArray.append(postedBy) // Store user email (who posted)
                    }
                    if let description = doc.get("description") as? String {
                        self.userCommentArray.append(description) // Store comment text
                    }
                    
                    // Fetch like count for the post
                    group.enter()
                    self.getLikesCount(forPostId: docId) { likeCount in
                        self.likeArray.append(likeCount) // Store like count
                        group.leave()
                    }

                    if let imageUrl = doc.get("imageURL") as? String {
                        self.userImageArray.append(imageUrl) // Store image URL
                    }
                }
                
                group.notify(queue: .main) {
                    self.tableView.reloadData() // Refresh table when all data is fetched
                }
            }
        }
    }

    func getLikesCount(forPostId postId: String, completion: @escaping (Int) -> Void) {
        // Fetch like count from the "likes" collection
        let likesRef = Firestore.firestore().collection("likes").document(postId)
        
        likesRef.getDocument { (document, error) in
            if let error = error {
                print("Error getting likes: \(error)") // Handle likes fetch error
                completion(0) // Return 0 in case of error
            } else if let document = document, document.exists {
                let likeCount = document.data()?["likeCount"] as? Int ?? 0
                completion(likeCount) // Return the like count
            } else {
                completion(0) // Return 0 if the document doesn't exist
            }
        }
    }
    
    func toggleLike(postId: String, userId: String, index: Int) {
        // Toggle the like/unlike action for a post
        let likesRef = Firestore.firestore().collection("likes").document(postId)

        likesRef.getDocument { (document, error) in
            if let error = error {
                print("Error checking likes: \(error)") // Handle error
                return
            }

            if let document = document, document.exists {
                var likedBy = document.data()?["likedBy"] as? [String] ?? []
                var likeCount = document.data()?["likeCount"] as? Int ?? 0

                if likedBy.contains(userId) {
                    // Remove the user's like
                    likedBy.removeAll(where: { $0 == userId })
                    likeCount -= 1
                } else {
                    // Add the user's like
                    likedBy.append(userId)
                    likeCount += 1
                }

                // Update the "likes" document in Firestore
                likesRef.setData([
                    "likedBy": likedBy,
                    "likeCount": likeCount
                ], merge: true) { error in
                    if let error = error {
                        print("Error updating like: \(error)") // Handle like update error
                    } else {
                        print("Like toggled")
                        self.updateLikeCount(for: index) // Update like count in table
                    }
                }
            } else {
                // If no "likes" document exists, create one
                likesRef.setData([
                    "likedBy": [userId],
                    "likeCount": 1
                ]) { error in
                    if let error = error {
                        print("Error adding like: \(error)") // Handle like creation error
                    } else {
                        print("Like added")
                        self.updateLikeCount(for: index) // Update like count in table
                    }
                }
            }
        }
    }
    
    func updateLikeCount(for index: Int) {
        // Update the like count for the post at the specified index
        let postId = documentIdArray[index]
        let likesRef = Firestore.firestore().collection("likes").document(postId)

        likesRef.getDocument { document, error in
            if let document = document, document.exists, let likeCount = document.data()?["likeCount"] as? Int {
                self.likeArray[index] = likeCount // Update like count in array
                self.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none) // Reload the row
            }
        }
    }
}

extension HomeVC: UITableViewDelegate, UITableViewDataSource {
    // Return the number of rows (posts) in the table view
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return userEmailArray.count
    }
    
    // Configure the cell for each row with data
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! FeedCell
        
        // Set cell data
        cell.userLabel.text = userEmailArray[indexPath.row]
        cell.likeCounter.text = "\(likeArray[indexPath.row])"
        cell.userComment.text = userCommentArray[indexPath.row]
        cell.documentIdLabel.text = documentIdArray[indexPath.row]
        
        // Set image for the post using SDWebImage
        if let imageUrl = URL(string: userImageArray[indexPath.row]) {
            cell.userImage.sd_setImage(with: imageUrl, placeholderImage: UIImage(named: "placeholder"))
        } else {
            cell.userImage.image = UIImage(named: "placeholder") // Placeholder image if no URL
        }
        
        return cell
    }
}
