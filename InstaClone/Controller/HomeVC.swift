//
//  HomeVC.swift
//  InstaClone
//
//  Created by can on 25.10.2024.
//

import UIKit

class HomeVC: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        
    }
   
}

//MARK: - TableView

extension HomeVC: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 10
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! FeedCell
        cell.userComment.text = "Hello World"
        cell.likeCounter.text = "100 likes"
        cell.userLabel.text = "Username"
        cell.commentCounter.text = "See all 99 comments"
        cell.timeLabel.text = "1 hour ago"
        return cell
        
    }
    
    
}
