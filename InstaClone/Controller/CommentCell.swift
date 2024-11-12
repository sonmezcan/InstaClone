//
//  CommentCell.swift
//  InstaClone
//
//  Created by can on 12.11.2024.
//

import UIKit

class CommentCell: UITableViewCell {
    @IBOutlet weak var userComment: UILabel!
    @IBOutlet weak var userAvatar: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
