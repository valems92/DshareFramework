import Foundation

class ChatModel {
    var newMessageRefHandle: DatabaseHandle?
    let messagesRef = Database.database().reference().child("messages")
    
    weak var delegate:MessageReceivedDelegate?
    
    func sendMessage(senderID:String, senderName:String, recieversIds:[String], text:String, exitMessage:Bool) {
        let data:Dictionary<String,Any> = ["senderID":senderID, "senderName": senderName, "recieversIds": recieversIds, "text": text, "exitMessage":exitMessage]
        
        messagesRef.childByAutoId().setValue(data)
    }
    
    func observeMessages() {
        newMessageRefHandle = messagesRef.observe(.childAdded, with: { (snapshot) in
            let messageData = snapshot.value as! Dictionary<String, Any>
            
            if let senderID = messageData["senderID"] as! String?, let senderName = messageData["senderName"] as! String?, let recieversIds = messageData["recieversIds"] as! [String]?, let text = messageData["text"] as! String?, let exitMessage = messageData["exitMessage"] as! Bool? {
                self.delegate?.messageRecieved(senderID: senderID, senderName:senderName, recieversIds:recieversIds, text: text, exitMessage: exitMessage)
            }
        })
    }
    
    func removeObserver(){
        messagesRef.removeObserver(withHandle: newMessageRefHandle!)
    }
}
