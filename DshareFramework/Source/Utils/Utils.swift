import Foundation

class Utils {
    static let instance = Utils();
    
    func isValidEmailAddress(emailAddressString:String) -> Bool {
        var returnValue = true
        let emailRegEx = "[A-Z0-9a-z.-_]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,3}"
        
        do {
            let regex = try NSRegularExpression(pattern: emailRegEx)
            let nsString = emailAddressString as NSString
            let results = regex.matches(in: emailAddressString, range: NSRange(location: 0, length: nsString.length))
            
            if results.count == 0 {
                returnValue = false
            }
        } catch let error as NSError {
            print("invalud regex: \(error.localizedDescription)")
            returnValue = false
        }
        
        return returnValue
    }

    func isValidPhoneNumber(phoneNumberString:String) -> Bool {
        var returnValue = true
        let phoneRegEx = "^[0-9]{10}$"
        
        do {
            let regex = try NSRegularExpression(pattern: phoneRegEx)
            let nsString = phoneNumberString as NSString
            let results = regex.matches(in: phoneNumberString, range: NSRange(location: 0, length: nsString.length))
            
            if results.count == 0 {
                returnValue = false
            }
        } catch let error as NSError {
            print("invalud regex: \(error.localizedDescription)")
            returnValue = false
        }
        
        return returnValue
    }

    func isValidPassword(passwordString:String) -> Bool {
        var returnValue = true
        let passwordRegEx = "^.{6,}$"
        
        do {
            let regex = try NSRegularExpression(pattern: passwordRegEx)
            let nsString = passwordString as NSString
            let results = regex.matches(in: passwordString, range: NSRange(location: 0, length: nsString.length))
            
            if results.count == 0 {
                returnValue = false
            }
        } catch let error as NSError {
            print("invalud regex: \(error.localizedDescription)")
            returnValue = false
        }
        
        return returnValue
    }
}
