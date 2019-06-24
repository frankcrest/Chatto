//
//  Register.swift
//  Vinder
//
//  Created by Dayson Dong on 2019-06-21.
//  Copyright © 2019 Frank Chen. All rights reserved.
//

import Foundation
import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage

protocol UpdateProgressDelegate: AnyObject {
    func updateProgress(progress: Double)
}


class WebService {
    
    //MARK: PROPERTIES
    
    var updateProgressDelegate: UpdateProgressDelegate?
    
    private var downloadURL: URL!
    private let ref = Database.database().reference()
    private let ud = UserDefaults.standard
    
    let currentUserID = UserDefaults.standard.string(forKey: "currentUserID")
  
    private var storageRef: StorageReference {
        return Storage.storage().reference(forURL: "gs://vinder-2a778.appspot.com")
    }
    private var profileVideosStorageRef: StorageReference {
        return storageRef.child("profileVideos")
    }
    
    //download fileURL needs to be changed
    private var fileURL: URL = {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let fileURL = paths[0].appendingPathComponent("sample.mov")
        try? FileManager.default.removeItem(at: fileURL)
        return fileURL
    }()
    
    
    
    //MARK: FIREBASE DATABASE AND STORAGE
    
    func changeProfile(_ url: String, completion: @escaping (Error?) -> Void) {
        guard let userID = currentUserID else {
            return
        }
        ref.child("users").child(userID).setValue(["profileVideo": url]) { (err, ref) in
            completion(err)
        }
    }
    
    func sendMessage(_ url: String, to user: User,completion: @escaping  (Error?) -> Void)  {
        
        guard let senderID = currentUserID else {
            return
        }
        let messageID = UUID().uuidString
        
        self.ref.child("messages").child(user.uid).child(messageID).setValue(["senderID": senderID, "messageURL": url, "messageID": messageID]) { (err, ref) in
            completion(err)
        }
        
    }
    
    func uploadVideo(atURL url: URL,  completion: @escaping (URL) -> (Void)) {
       
        let videoName = "\(NSUUID().uuidString)\(url)"
        let ref = profileVideosStorageRef.child(videoName)
        let metaData = StorageMetadata()
        metaData.contentType = "video/quicktime"
        
        let uploadTask = ref.putFile(from: url, metadata: metaData) { (metaData, error) in
            if error != nil {
                print("cant upload video: \(String(describing: error))")
                return
            } else {
                ref.downloadURL { (url, err) in
                    guard let downloadURL = url else {
                        return
                    }
                    print("url: \(downloadURL)")
                    completion(downloadURL)
                }
            }
        }
        
        uploadTask.observe(.progress) { (snapshot) in
            let percent = 100.0 * Double(snapshot.progress!.completedUnitCount) / Double(snapshot.progress!.totalUnitCount)
            print("uploading: \(percent)")
            DispatchQueue.main.async {
                self.updateProgressDelegate?.updateProgress(progress: percent)
            }
        }
    }
    
    func register(withProfileURL url: URL, registered: @escaping (Bool, Error?) -> Void) {
        
      guard let email = ud.string(forKey: "email") else {return}
      guard let password = ud.string(forKey: "password") else {return}
      guard let name = ud.string(forKey: "name") else {return}
      guard let username = ud.string(forKey: "username") else {return}
      guard let token = ud.string(forKey: "fcmToken") else {return}
      
      Auth.auth().createUser(withEmail: email, password: password) { (user, error) in
            
            guard error == nil else {
                registered(false, error)
                return
            }
            
            guard let uid = user?.user.uid else { return }
            registered(true, nil)
            
        self.ref.child("users").child(uid).setValue((["uid": uid, "token": token, "email":email, "username":username, "name":name, "profileVideo": "\(url)"]), withCompletionBlock: { (error, ref) in
                
                if let error = error{
                    print("can not set ref error \(error)")
                    return
                }
            })
        }
    }
    
    //MARK: DOWNLOAD VIDEO
    
    func fetchProfileVideo(of user: User, completion: @escaping (URL?, Error?) -> (Void)) {
        
        let storage = Storage.storage()
        let url = user.profileVideoUrl //need to change this cuz I made it optional for now
        /*
         testing url
         let url = "https://firebasestorage.googleapis.com/v0/b/vinder-2a778.appspot.com/o/profileVideos%2F5EBB1ED9-1380-47ED-93CB-61673D36BF05file:%2Fvar%2Fmobile%2FContainers%2FData%2FApplication%2FBF733337-2314-452A-B52F-E2975DDDD60A%2FDocuments%2Fprofile.mov?alt=media&token=f9770383-1903-435e-8903-ff2a87867f86"
         */
        let httpReference = storage.reference(forURL: url)
        let downloadTask = httpReference.write(toFile: fileURL) { (url, error) in
            completion(url,error)
        }
        downloadTask.observe(.progress) { (snapshot) in
            let percent = 100.0 * Double(snapshot.progress!.completedUnitCount) / Double(snapshot.progress!.totalUnitCount)
            print("downloading: \(percent)%")
        }
    }
    
    func fetchAllMessages(completion: @escaping ([Messages]?) ->(Void)) {
        
        guard let userID = currentUserID else {
            return
        }
        var messages: [Messages] = []
        ref.child("messages").child(userID).observe(DataEventType.value) { (snapshot) in
                        for messageID in snapshot.children.allObjects as! [DataSnapshot] {
                guard let message = messageID.value as? [String: String] else { return }
                guard let messageURL = message["messageURL"] else { return }
                guard let senderID = message["senderID"] else { return }
                guard let msgID = message["messageID"] else {return}
                
                let msg = Messages(messageID: msgID, senderID: senderID, messageURL: messageURL)
                messages.append(msg)
            }
            completion(messages)
        }
    }
    
    func fetchUsers(completion: @escaping ([User]?) -> Void) {
        
        var users: [User] = []
        ref.child("users").observe(.value) { (snapshot) in
            for user in snapshot.children.allObjects as! [DataSnapshot]{
                guard let userObject = user.value as? [String:AnyObject] else{return}
                
                guard let name = userObject["name"] as? String else {return}
                guard let username = userObject["username"] as? String else{return}
                guard let uid = userObject["uid"] as? String else {return}
                guard let lat = userObject["latitude"] as? String else {return}
                guard let lon = userObject["longitude"] as? String else{return}
                
                let user = User(uid: uid, token: "" , username: username, name: name , imageUrl: "kawhi", gender: .female, lat: lat, lon: lon, profileVideoUrl: "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4")
                users.append(user)
            }
            completion(users)
        }
        
        
    }
    
    
    //MARK:  JOKE API
    
    func fetchJokes(completion: @escaping (Data) -> (Void)) {
        
        let url = URL(string: "https://icanhazdadjoke.com/")
        let request = NSMutableURLRequest(url: url!)
        
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        let task = URLSession.shared.dataTask(with: request as URLRequest) { (data, response, err) in
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("bad response: \(String(describing: response))")
                return
            }
            
            guard httpResponse.statusCode == 200 else {
                print("http reponse: \(httpResponse.statusCode)")
                return
            }
            
            guard err == nil else {
                print("cant fetch jokes error: \(String(describing: err))")
                return
            }
            
            guard let data = data else {
                print("bad data")
                return
            }
            
            completion(data)
            
        }
        
        task.resume()
        
    }
    
    /*
     
     import SwiftyJSON
     
     networkManager.fetchJokes { (data) -> (Void) in
     let json = JSON(data)
     print("joke : \(json["joke"])")
     }
     
     
     */
    
    
    
    
    
    
    
    
}
