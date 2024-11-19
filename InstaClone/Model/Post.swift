import Foundation
import FirebaseCore
import FirebaseFirestore

struct Post {
    var imageURL: String
    var description: String
    var userPhotoURL: String
    var postedBy: String
    var timestamp: Timestamp

    // Post modeline Firebase'den veri alırken timestamp verisini Date'e dönüştürme
    var date: Date {
        return timestamp.dateValue()
    }
}
