import Foundation

public class Notifications {
    public static var instance = Notifications()
    
    public func sendNotification(tokens:[String], messageTitle:String, messageText: String, url:String, method: HttpMethod, callback:@escaping (Any?, Error?)->Void) {
        var paramsDictionary = [String:Any]()
        paramsDictionary["tokens"] = tokens
        paramsDictionary["title"] = messageTitle
        paramsDictionary["body"] = messageText
        
        HttpClientApi.instance.makeAPICall(url: url, params:paramsDictionary, method: .POST, success: { (data, response, error) in
            callback(response, nil)
        }, failure: { (data, response, error) in
            callback(nil, error)
        })
    }
}
