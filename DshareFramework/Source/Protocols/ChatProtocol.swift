import Foundation

public protocol MessageReceivedDelegate: class {
    func messageRecieved(senderID:String, senderName:String, recieversIds:[String], text:String, exitMessage:Bool)
}
