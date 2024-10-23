//
//  Brain.swift
//  InstaClone
//
//  Created by can on 23.10.2024.
//

import Foundation
import UIKit


class Brain {
    
    func placeHolders(textField: UITextField, placeholderText: String, placeholderColor: UIColor) {
        textField.attributedPlaceholder = NSAttributedString(
            string: placeholderText,
            attributes: [NSAttributedString.Key.foregroundColor: placeholderColor]
        )
    }
}

