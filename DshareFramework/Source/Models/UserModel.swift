import Foundation

class UserModel {
    var storageRef = Storage.storage().reference(forURL: Initialization.instance.getStorageName()!)
    
    func isLoggedIn(completionBlock:@escaping (Bool)->Void) {
        if Auth.auth().currentUser == nil {
            completionBlock(false)
        }
        else {
            let fcmToken:String? = _getFcmToken()
            _updateFcmToken(fcmToken: fcmToken);
            
            completionBlock(true)
        }
    }
    
    func addNewUser(email:String?, password:String?, rePassword:String?, fName:String?, lName:String?, phoneNum:String?, gender:String?, userImage:UIImage?, completionBlock:@escaping (String?, NSError?) -> Void){
        do {
            try _validateRegisterUser(email: email, password: password, rePassword: rePassword, fName: fName, lName: lName, phoneNum: phoneNum)
            
            let imagePath = Initialization.instance.getDefaultIcon()
            
            let fcmToken:String? = _getFcmToken()
            let user = UserSchema(email:email!, password:password!, fName:fName!, lName:lName!, phoneNum:phoneNum!, gender:gender, imagePath:imagePath, fcmToken: fcmToken);
            
            if userImage != nil {
                saveImage(image: userImage!, name: user.id) { (url) in
                    user.imagePath = url
                }
            }
            
            Auth.auth().createUser(withEmail: user.email, password: user.password) { (newUser, error) in
                user.id = (newUser?.user.uid)!
                if newUser == nil {
                    completionBlock(user.id, nil)
                }
                else {
                    let ref = Database.database().reference().child("users").child(user.id)
                    ref.setValue(user.toJson()){(error, dbref) in
                        
                    }
                    completionBlock(user.id, nil)
                }
            }
        } catch {
            completionBlock(nil, error as NSError)
        }
    }
    
    func signInUser(email:String?, password:String?, completionBlock:@escaping (NSError?) -> Void){
        do {
            try _validateLoginUser(email: email, password: password)
            
            Auth.auth().signIn(withEmail: email!, password: password!) { (newUser, error) in
                if newUser == nil {
                    completionBlock(NSError(domain: "There was a problem while logging in. Please try again later.", code: 500, userInfo: nil))
                }
                else {
                    let fcmToken:String? = self._getFcmToken()
                    self._updateFcmToken(fcmToken: fcmToken);
                    
                    completionBlock(nil)
                }
            }
        } catch {
            completionBlock(error as NSError)
        }
    }
    
    func signOutUser(completionBlock:@escaping (Error?)->Void) {
        let firebaseAuth = Auth.auth()
        do {
            try firebaseAuth.signOut()
            completionBlock(nil)
        } catch let signOutError as NSError {
            completionBlock(signOutError)
        }
    }
    
    func getCurrentUserId() -> String? {
        let user = Auth.auth().currentUser
        
        if user != nil {
            return user?.uid
        } else {
            return nil
        }
    }
    
    func saveImage(image:UIImage, name:(String), callback:@escaping (String?) -> Void) {
        let filesRef = storageRef.child(name)
        if let data = UIImageJPEGRepresentation(image, 0.8) {
            filesRef.putData(data, metadata: nil) { metadata, error in
                if (error != nil) {
                    callback(nil)
                } else {
                    filesRef.downloadURL(completion: { (url, error) in
                        if error == nil && url != nil {
                            callback(url!.absoluteString)
                        } else {
                            callback(nil)
                        }
                    })
                    
                }
            }
        }
    }
    
    func getUserById(id:String, callback:@escaping (UserSchema?) -> Void) {
        Database.database().reference().child("users").child(id).observeSingleEvent(of: .value, with: { (snapshot) in
            let value = snapshot.value as? NSDictionary
            let fName = value?["fName"] as? String ?? ""
            let lName = value?["lName"] as? String ?? ""
            let email = value?["email"] as? String ?? ""
            let gender = value?["gender"] as? String ?? ""
            let imagePath = value?["imagePath"] as? String ?? ""
            let phoneNum = value?["phoneNum"] as? String ?? ""
            let fcmToken = value?["fcmToken"] as? String ?? ""
            let user = UserSchema(id:id, email:email, fName:fName, lName:lName, phoneNum:phoneNum, gender:gender, imagePath:imagePath, fcmToken:fcmToken)
            
            callback(user)
        })
    }
    
    func updateUserDetails(fName:String?, lName:String?, email:String?, phoneNum:String?, gender:String, image:UIImage?, completionBlock:@escaping (NSError?)->Void) {
        do {
            try _validateUpdateUser(fName: fName, lName: lName, email: email, phoneNum: phoneNum)
            
            let id:String? = getCurrentUserId()
            let db = Database.database().reference().child("users").child(id!)
            
            if image != nil {
                saveImage(image: image!, name: id!) { (url) in
                    db.updateChildValues(["imagePath": url!])
                }
            }
            
            db.updateChildValues(["fName": fName!])
            db.updateChildValues(["lName": lName!])
            db.updateChildValues(["email": email!])
            db.updateChildValues(["phoneNum": phoneNum!])
            db.updateChildValues(["gender": gender])
            Auth.auth().currentUser?.updateEmail(to: email!) { (error) in
                completionBlock(NSError(domain: "Error while updating email", code: 400, userInfo: nil))
            }
        } catch {
            completionBlock(error as NSError)
        }
    }
    
    func updatePassword(oldPassword: String?, newPassword: String?, reNewPassword: String?, completionBlock:@escaping (NSError?)->Void) {
        do {
            try _validateUpdatePassword(oldPass: oldPassword, newPass: newPassword, reNewPass: reNewPassword)
            
            getUserById(id: getCurrentUserId()!) { (user) in
                if user != nil {
                    let credential = EmailAuthProvider.credential(withEmail: user!.email, password: oldPassword!)
                    Auth.auth().currentUser?.reauthenticateAndRetrieveData(with: credential, completion: { (data, error) in
                        if error != nil {
                            completionBlock(NSError(domain: (error?.localizedDescription)!, code: 400, userInfo: nil))
                        } else {
                            Auth.auth().currentUser?.updatePassword(to: newPassword!) { (error) in
                                if error != nil {
                                    completionBlock(NSError(domain: (error?.localizedDescription)!, code: 400, userInfo: nil))
                                } else {
                                    completionBlock(nil)
                                }
                            }
                        }
                    })
                } else {
                    completionBlock(NSError(domain: "Error while getting your personal data", code: 400, userInfo: nil))
                }
            }
        } catch {
            completionBlock(error as NSError)
        }
    }
    
    /********************* Help functions ************************/
    
    func _getFcmToken() -> String? {
        let preferences = UserDefaults.standard
        var fcmToken:String? = nil
        
        if preferences.string(forKey: "fcmToken") != nil {
            fcmToken = preferences.string(forKey: "fcmToken")
        }
        
        return fcmToken
    }
    
    func _updateFcmToken(fcmToken:String?){
        let id:String? = getCurrentUserId()
        if id != nil && fcmToken != nil {
            let db = Database.database().reference().child("users").child(id!)
            db.updateChildValues(["fcmToken": fcmToken!])
        }
    }
    
    func _validateUpdatePassword(oldPass:String?, newPass:String?, reNewPass:String?) throws {
        let validOldPassword:Bool = !((oldPass ?? "").isEmpty)
        let validNewPassword:Bool = _validatePassword(password: newPass, rePassword: reNewPass)
        
        if !validOldPassword {
            throw NSError(domain: "Old password is not valid", code: 400, userInfo: nil)
        } else if !validNewPassword {
            throw NSError(domain: "New password is not valid", code: 400, userInfo: nil)
        }
    }
    
    func _validateUpdateUser(fName:String?, lName:String?, email:String?, phoneNum:String?) throws {
        let validEmail:Bool = _validateEmail(email: email)
        let validPhoneNum:Bool = _validatePhoneNumber(phoneNum: phoneNum)
        let validName:Bool = _validateName(fName: fName, lName: lName)
        
        if !validEmail {
            throw NSError(domain: "Email address is not valid", code: 400, userInfo: nil)
        } else if !validName {
            throw NSError(domain: "First name or last name are not valid", code: 400, userInfo: nil)
        } else if !validPhoneNum {
            throw NSError(domain: "Phone number is not valid", code: 400, userInfo: nil)
        }
    }
    
    func _validateLoginUser (email:String?, password:String?) throws {
        let validEmail:Bool = _validateEmail(email: email)
        let validPassword:Bool = !((password ?? "").isEmpty)
        
        if !validEmail || !validPassword {
             throw NSError(domain: "There is an error with the email or password", code: 400, userInfo: nil)
        }
    }
    
    func _validateRegisterUser(email:String?, password:String?, rePassword:String?, fName:String?, lName:String?, phoneNum:String?) throws {
        let validEmail:Bool = _validateEmail(email: email)
        let validPassword:Bool = _validatePassword(password: password, rePassword: rePassword)
        let validName:Bool = _validateName(fName: fName, lName: lName)
        let validPhoneNum:Bool = _validatePhoneNumber(phoneNum: phoneNum)
        
        if !validEmail {
            throw NSError(domain: "Email address is not valid", code: 400, userInfo: nil)
        } else if !validPassword {
            throw NSError(domain: "There is an error with the password or re-password", code: 400, userInfo: nil)
        } else if !validName {
            throw NSError(domain: "You have to enter your first name and last name", code: 400, userInfo: nil)
        } else if !validPhoneNum {
            throw NSError(domain: "Phone number is not valid", code: 400, userInfo: nil)
        }
    }
    
    func _validateEmail(email:String?) -> Bool {
        var valid:Bool = true
        
        if (email ?? "").isEmpty {
            valid = false
        } else {
            let isEmailAddressValid = Utils.instance.isValidEmailAddress(emailAddressString: email!)
            if !isEmailAddressValid {
                valid = false
            }
        }
        
        return valid
    }
    
    func _validatePassword(password:String?, rePassword:String?) -> Bool {
        var valid:Bool = true
        
        if ((password ?? "").isEmpty || (rePassword ?? "").isEmpty) {
            valid = false
        } else {
            if rePassword!.contains(password!) {
                valid = false
            }
        }
        
        return valid
    }
    
    func _validateName(fName:String?, lName:String?) -> Bool {
        var valid:Bool = true
        
        if ((fName ?? "").isEmpty || (lName ?? "").isEmpty) {
            valid = false
        }
        
        return valid
    }
    
    func _validatePhoneNumber(phoneNum:String?) -> Bool {
        var valid:Bool = true
        
        if ((phoneNum ?? "").isEmpty) {
            valid = false
        } else {
            let isPhoneNumberValid = Utils.instance.isValidPhoneNumber(phoneNumberString: phoneNum!)
            if !isPhoneNumberValid {
                valid = false
            }
        }
        
        return valid
    }
    
    func getImage(url:String, callback:@escaping (UIImage?) -> Void) {
        let ref = Storage.storage().reference(forURL: url)
        ref.getData(maxSize: 10000000, completion: {(data, error) in
            if (error == nil && data != nil){
                let image = UIImage(data: data!)
                callback(image)
            } else {
                callback(nil)
            }
        })
    }
}
