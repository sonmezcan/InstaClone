//
//  FeedCell.swift
//  InstaClone
//
//  Created by can on 25.10.2024.
//

import UIKit

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
    

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    @IBAction func likePressed(_ sender: UIButton) {
        print("like pressed")
    }
    @IBAction func commentPressed(_ sender: UIButton) {
    }
    
}
