//
//  StoryCell.swift
//  InstaClone
//
//  Created by can on 18.12.2024.
//

import UIKit

class StoryCell: UICollectionViewCell {
    @IBOutlet weak var storyImageView: UIImageView!
    @IBOutlet weak var userNameLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        storyImageView.layer.cornerRadius = storyImageView.frame.size.width / 2
        storyImageView.clipsToBounds = true
    }
}
