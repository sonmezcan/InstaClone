import UIKit
import Firebase

class FeedCell: UITableViewCell {
    @IBOutlet weak var userAvatar: UIImageView!
    @IBOutlet weak var userLabel: UILabel!
    @IBOutlet weak var userImage: UIImageView!
    @IBOutlet weak var likeButton: UIButton!
    @IBOutlet weak var commentButton: UIButton!
    @IBOutlet weak var likeCounter: UILabel!
    @IBOutlet weak var userComment: UILabel!
    @IBOutlet weak var commentCounter: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var documentIdLabel: UILabel!
    
    var postId: String?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    @IBAction func commentPressed(_ sender: UIButton) {
        // Handle comment button press
    }
    
    @IBAction func likePressed(_ sender: UIButton) {
        // Handle like button press
    }
    
    func timeAgoSinceDate(_ date: Date) -> String {
        let calendar = Calendar.current
        let unitFlags: Set<Calendar.Component> = [.minute, .hour, .day, .month, .year]
        let now = Date()
        
        let components = calendar.dateComponents(unitFlags, from: date, to: now)
        
        if let year = components.year, year > 0 {
            return "\(year) years ago"
        }
        if let month = components.month, month > 0 {
            return "\(month) months ago"
        }
        if let day = components.day, day > 0 {
            return "\(day) days ago"
        }
        if let hour = components.hour, hour > 0 {
            return "\(hour) hours ago"
        }
        if let minute = components.minute, minute > 0 {
            return "\(minute) minutes ago"
        }
        if let second = components.second, second > 0 {
            return "\(second) seconds ago"
        }
        return "Just now"
    }
    
    func updatePostTime(timestamp: Timestamp) {
        let postDate = timestamp.dateValue()
        let timeString = timeAgoSinceDate(postDate)
        timeLabel.text = "\(timeString) "
    }
    
    func getPostDataFromFirestore() {
        guard let postId = postId else { return }
        
        let fireStoreDatabase = Firestore.firestore()
        
        fireStoreDatabase.collection("posts").document(postId).getDocument { (document, error) in
            if let error = error {
                print("Error fetching post: \(error)")
            } else if let document = document, document.exists {
                if let timestamp = document.get("timestamp") as? Timestamp {
                    self.updatePostTime(timestamp: timestamp) // Update the timeLabel
                }
            }
        }
    }
    
    // This function should be called from HomeVC when the cell is configured
    func configureCell(postId: String) {
        self.postId = postId
        getPostDataFromFirestore() // Call this function to get the post data
    }
}
