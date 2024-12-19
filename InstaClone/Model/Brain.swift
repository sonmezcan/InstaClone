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
    func dissMissKeyboard(_ view: UIView) {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
    }
    @objc func dismissKeyboard(view: UIView) {
            // Klavyeyi kapatır
            view.endEditing(true)
    }
}

