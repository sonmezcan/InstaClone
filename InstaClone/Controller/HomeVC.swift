import UIKit
import Firebase
import SDWebImage

class HomeVC: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    var userEmailArray = [String]()
    var userCommentArray = [String]()
    var likeArray = [Int]()
    var userImageArray = [String]()
    var documentIdArray = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        getDataFromFirestore()
    }
    @IBAction func likeButton(_ sender: UIButton) {
        print("like button pressed")
    }
    @IBAction func commentButton(_ sender: UIButton) {
        print("comment button pressed")
    }
    
    func getDataFromFirestore() {
       
        let fireStoreDatabase = Firestore.firestore()
        
        fireStoreDatabase.collection("posts").addSnapshotListener { (snapshot, error) in
            if error != nil {
                print(error?.localizedDescription)
            }else {
                if snapshot?.isEmpty == false {
                    
                    self.userEmailArray.removeAll(keepingCapacity: false)
                    self.userImageArray.removeAll(keepingCapacity: false)
                    self.userCommentArray.removeAll(keepingCapacity: false)
                    self.likeArray.removeAll(keepingCapacity: false)
                    self.documentIdArray.removeAll(keepingCapacity: false)
                    
                    
                    for doc in snapshot!.documents {
                        let docId = doc.documentID
                        self.documentIdArray.append(docId)
                        
                        
                        if let postedBy = doc.get("postedBy") as? String {
                            self.userEmailArray.append(postedBy)
                        }
                        
                        if let description = doc.get("description") as? String {
                            self.userCommentArray.append(description)
                        }
                        if let likes = doc.get("likes") as? Int {
                            self.likeArray.append(likes)
                        }
                        if let imageUrl = doc.get("imageURL") as? String {
                            self.userImageArray.append(imageUrl)
                        }
                    }
                    self.tableView.reloadData()
                }
            }
        }
        
        
    }
    
    
}

extension HomeVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return userEmailArray.count
    }
 
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! FeedCell
        
        if indexPath.row < userEmailArray.count {
            cell.userLabel.text = userEmailArray[indexPath.row]
        } else {
            cell.userLabel.text = ""
        }
        
        if indexPath.row < likeArray.count {
            cell.likeCounter.text = "\(likeArray[indexPath.row])"
        } else {
            cell.likeCounter.text = "0"
        }
        
        if indexPath.row < userCommentArray.count {
            cell.userComment.text = userCommentArray[indexPath.row]
        } else {
            cell.userComment.text = ""
        }
        
        if indexPath.row < documentIdArray.count {
            cell.documentIdLabel.text = documentIdArray[indexPath.row]
        } else {
            cell.documentIdLabel.text = ""
        }
        
        if indexPath.row < userImageArray.count {
            if let imageUrl = URL(string: self.userImageArray[indexPath.row]) {
                cell.userImage.sd_setImage(with: imageUrl, placeholderImage: UIImage(named: "placeholder"))
            } else {
                cell.userImage.image = UIImage(named: "placeholder")
            }
        } else {
            cell.userImage.image = UIImage(named: "placeholder")
        }
        
        return cell
    }
}
