//
//  FeedCell.swift
//  InstaClone
//
//  Created by can on 25.10.2024.
//

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
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    @IBAction func commentPressed(_ sender: UIButton) {
        
    }
    @IBAction func likePressed(_ sender: UIButton) {
//        if likeButton.currentImage == UIImage(systemName: "heart") {
//            likeButton.setImage(UIImage(systemName: "heart.fill"), for: .normal)
//        }else {
//            likeButton.setImage(UIImage(systemName: "heart"), for: .normal)
//        }
//        let fireStoreDatabase = Firestore.firestore()
//        if let likeCount = Int(likeCounter.text!) {
//            let likeStore = ["likes" : likeCount + 1 ] as [String : Any]
//            fireStoreDatabase.collection("posts").document(documentIdLabel.text!).setData(likeStore, merge: true)
//        }
//       
        
    }
    
    
}
