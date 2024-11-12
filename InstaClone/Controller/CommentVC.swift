//
//  CommentVC.swift
//  InstaClone
//
//  Created by can on 12.11.2024.
//

import UIKit

class CommentVC: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var mainAvatar: UIImageView!
    @IBOutlet weak var mainCommentField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 70
    }
    


}

extension CommentVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 10
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CommentCell", for: indexPath) as! CommentCell
        
        cell.userComment.text = "Hello World"
        
      
        
        return cell
    }
}
