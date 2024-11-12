//
//  CommentCell.swift
//  InstaClone
//
//  Created by can on 12.11.2024.
//

import UIKit

class CommentCell: UITableViewCell {
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var userComment: UILabel!
    @IBOutlet weak var userAvatar: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    func configure(with comment: String, userName: String) {
            userComment.text = comment
        userNameLabel.text = userName
        }
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
