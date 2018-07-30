import Foundation

class SearchModel {
    let searchesRef = Database.database().reference().child("searches")
    var observers:[DatabaseReference] = []
    
    func addNewSearch(search:SchemaProtocol, completionBlock:@escaping (NSError?) -> Void) {
        let searchRef = searchesRef.child(search.id)
        
        searchRef.setValue(search.toJson()) {(error, dbref) in
            if(error != nil) {
                completionBlock(NSError(domain: "There was an error while saving your search. Please try again later.", code: 500, userInfo: nil))
            } else {
                completionBlock(nil)
            }
        }
    }
    
    func getAllSearches<T: SchemaProtocol>(type: T.Type, callback:@escaping ([T])->Void) {
        searchesRef.observeSingleEvent(of: .value) {(snapshot: DataSnapshot) in
            var searches = [T]();
            for search in snapshot.children.allObjects {
                if let searchData = search as? DataSnapshot {
                    if let json = searchData.value as? Dictionary<String,Any> {
                        searches.append(T(fromJson: json))
                    }
                }
            }
            callback(searches)
        }
    }
    
    func startObserveSearches<T: SchemaProtocol>(type: T.Type, callback:@escaping(T?,String) -> Void) {
        let ref = Database.database().reference()
        ref.child("searches").observe(.childAdded, with: { (snapshot) in
            callback(T(fromJson: (snapshot.value as? [String : Any])!), "Added")
        })
        
        ref.child("searches").observe(.childRemoved, with: { (snapshot) in
            callback(T(fromJson: (snapshot.value as? [String : Any])!), "Removed")
        })
        
        ref.child("searches").observe(.childChanged, with: { (snapshot) in
            callback(T(fromJson: (snapshot.value as? [String : Any])!), "Changed")
        })
        
        observers.append(ref.child("searches"))
    }
    
    func getCurrentUserSearches<T: SchemaProtocol>(type: T.Type, id:String, callback:@escaping([T]) -> Void) {
        searchesRef.queryOrdered(byChild: "userId").queryEqual(toValue: id).observeSingleEvent(of: .value) {(snapshot:DataSnapshot) in
            var searches = [T]()
            for search in snapshot.children.allObjects {
                if let searchData = search as? DataSnapshot {
                    if let json = searchData.value as? Dictionary<String,Any> {
                        searches.append(T(fromJson: json))
                    }
                }
            }
            
            callback(searches)
        }
    }
    
    func stopObserves() {
        for observe in observers {
            observe.removeAllObservers()
        }
        observers.removeAll()
    }
}
