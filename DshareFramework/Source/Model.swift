import Foundation

public class ModelNotificationBase<T>{
    var name:String?
    
    init(name:String) {
        self.name = name
    }
    
    public func observe(callback:@escaping (T?, Any?)->Void)->Any {
        return NotificationCenter.default.addObserver(forName: NSNotification.Name(name!), object: nil, queue: nil) { (data) in
            if let dataContent = data.userInfo?["data"] as? T {
                callback(dataContent, data.userInfo?["params"])
            }
        }
    }
    
    public func post(data:T, params:Any?){
        NotificationCenter.default.post(name: NSNotification.Name(name!), object: self, userInfo: ["data": data, "params": params ?? ""])
    }
}

public class ModelNotification {
    public static let SuggestionsUpdate = ModelNotificationBase<SchemaProtocol>(name: "SuggestionsUpdateNotification")
    public static let SearchUpdate = ModelNotificationBase<[String]>(name: "SearchUpdateNotification")
    
    public static func removeObserver(observer:Any){
        NotificationCenter.default.removeObserver(observer)
    }
}

public class Model {
    public static let instance = Model()
    
    lazy private var userModel:UserModel? = UserModel()
    lazy private var searchModel:SearchModel? = SearchModel()
    lazy private var chatModel:ChatModel? = ChatModel()
 
    
    /*************************** Model Notification ***************************/
    
    public func observeSearchUpdate() {
        
    }
    
    /*************************** Chat ***************************/
    
    public func delegateChatModel(clss: MessageReceivedDelegate) {
        chatModel?.delegate = clss
    }
    
    public func observeMessages() {
        chatModel?.observeMessages()
    }
    
    public func sendMessage(senderID:String, senderName:String, recieversIds:[String], text:String, exitMessage:Bool) {
        chatModel?.sendMessage(senderID: senderID, senderName: senderName, recieversIds: recieversIds, text: text, exitMessage: exitMessage)
    }
    
    func removeMessegesObserver() {
        chatModel?.removeObserver()
    }
    
    /*************************** User ***************************/
    
    public func isLoggedIn(completionBlock:@escaping (Bool)->Void){
        userModel?.isLoggedIn {(isLiggedIn) in
            completionBlock(isLiggedIn)
        }
    }
    
    public func addNewUser(email:String?, password:String?, rePassword:String?, fName:String?, lName:String?, phoneNum:String?, gender:String?, userImage:UIImage?, completionBlock:@escaping (String?, NSError?) -> Void) {
        userModel?.addNewUser(email: email, password: password, rePassword: rePassword, fName: fName, lName: lName, phoneNum: phoneNum, gender: gender, userImage: userImage, completionBlock: { (newUserID, err) in
            completionBlock(newUserID, err)
        })
    }
    
    public func signInUser(email:String?, password:String?, completionBlock:@escaping (NSError?) -> Void){
        userModel?.signInUser(email: email, password: password){(error) in
            completionBlock(error)
        }
    }
    
    public func getCurrentUserId() -> String {
        return (userModel?.getCurrentUserId())!
    }
    
    public func getUserById(id:String, callback:@escaping ([String: Any]?)->Void){
        userModel?.getUserById(id: id){(user) in
            if user != nil {
                callback(user?.toJson())
            } else {
                callback(nil)
            }
        }
    }
    
    public func getCurrentUser(callback:@escaping ([String: Any]?)->Void){
        let id:String = self.getCurrentUserId();
        userModel?.getUserById(id:id){(user) in
            callback(user?.toJson())
        }
    }
    
    public func signOutUser(completionBlock:@escaping (Error?)->Void) {
        userModel?.signOutUser {(error) in
            completionBlock(error)
        }
    }
    
    public func updateUserDetails(fName:String?, lName:String?, email:String?, phoneNum:String?, gender:String, image:UIImage?, completionBlock:@escaping (Error?)->Void) {
        userModel?.updateUserDetails(fName: fName, lName: lName, email: email, phoneNum: phoneNum, gender: gender, image: image, completionBlock: { (error) in
            completionBlock(error)
        })
    }
    
    public func updatePassword(oldPassword: String?, newPassword: String?, reNewPassword: String?, completionBlock:@escaping (NSError?)->Void) {
        userModel?.updatePassword(oldPassword: oldPassword, newPassword: newPassword, reNewPassword: reNewPassword, completionBlock: { (error) in
            completionBlock(error)
        })
    }
    
    /*************************** Images ***************************/
    
    public func getImage(urlStr:String, callback:@escaping (UIImage?)->Void) {
        let finalUrlStr = (urlStr == "") ? Initialization.instance.getDefaultIcon() : urlStr
        
        let url = URL(string: finalUrlStr!)
        let localImageName = url!.lastPathComponent
        if let image = self.getImageFromFile(name: localImageName){
            callback(image)
        }else{
            userModel?.getImage(url: urlStr, callback: { (image) in
                if (image != nil){
                    self.saveImageToFile(image: image!, name: localImageName)
                }
                callback(image)
            })
        }
    }
    
    private func getImageFromFile(name:String) -> UIImage? {
        let filename = getDocumentsDirectory().appendingPathComponent(name)
        return UIImage(contentsOfFile:filename.path)
    }
    
    private func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in:
            .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
    
    private func saveImageToFile(image:UIImage, name:String){
        if let data = UIImageJPEGRepresentation(image, 0.8) {
            let filename = getDocumentsDirectory().appendingPathComponent(name)
            try? data.write(to: filename)
        }
    }
    
    /*************************** Search ***************************/
    
    public func addNewSearch(search: SchemaProtocol, completionBlock:@escaping (NSError?) -> Void){
        searchModel?.addNewSearch(search: search, completionBlock: { (error) in
            completionBlock(error)
        })
    }
    
    public func FilterSuggestions<T: SchemaProtocol>(type: T.Type, observe:Bool, suggClass: SuggestionsProtocol, callback:@escaping ([T], [String : [String: Any]?])->Void) {
        searchModel?.getAllSearches(type: T.self, callback: { (suggestions) in
            let group = DispatchGroup()
            
            var usersData = [String : [String: Any]?]()
            var filteredSuggestions = [T]()
            
            for suggestion in suggestions {
                let filter = suggClass.filterSuggestion(suggestion)
                if filter {
                    filteredSuggestions.append(suggestion)
                    
                    group.enter()
                    if usersData[suggestion.userId] == nil {
                        self.getUserById(id: suggestion.userId, callback: { (json) in
                            usersData[suggestion.userId] = json
                            group.leave()
                        })
                    } else {
                        group.leave()
                    }
                }
            }
            
            group.notify(queue: .main) {
                if observe {
                    self.searchModel?.startObserveSearches(type: T.self, callback: { (search, status) in
                        let filter = suggClass.filterSuggestion(search!)
                        if filter {
                            ModelNotification.SuggestionsUpdate.post(data: search!, params: status)
                        }
                    })
                }
                
                callback(filteredSuggestions, usersData)
            }
        })
    }
    
    public func getCurrentUserSearches<T: SchemaProtocol>(type: T.Type, completionBlock:@escaping ([T]) -> Void) {
        let id = getCurrentUserId()
        searchModel?.getCurrentUserSearches(type: T.self, id: id, callback: { (searches) in
            completionBlock(searches)
        })
    }

    public func clear() {
        self.searchModel?.stopObserves()
    }
}
