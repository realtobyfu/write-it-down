////
////  AuthViewModel.swift
////  Ecrivez-local
////
////  Created by Tobias Fu on 11/28/24.
////
//
//import SwiftUI
//import SwiftData
//
//class AuthViewModel: ObservableObject {
//    @Published var currentUser: User?
//    @Published var isLoggedIn: Bool = false
//    
//    func fetchCurrentUser() {
//        let container = CKContainer.default()
//        container.fetchUserRecordID { recordID, error in
//            guard let recordID = recordID, error == nil else {
//                DispatchQueue.main.async {
//                    self.isLoggedIn = false
//                }
//                return
//            }
//            self.loadUserProfile(userRecordID: recordID)
//        }
//    }
//    
//    func loadUserProfile(userRecordID: CKRecord.ID) {
//        let publicDB = CKContainer.default().publicCloudDatabase
//        let predicate = NSPredicate(format: "creatorUserRecordID == %@", userRecordID)
//        let query = CKQuery(recordType: "User", predicate: predicate)
//        
//        publicDB.perform(query, inZoneWith: nil) { records, error in
//            if let record = records?.first {
//                DispatchQueue.main.async {
//                    self.currentUser = User(
//                        id: record.recordID,
//                        username: record["username"] as? String ?? ""
//                    )
//                    self.isLoggedIn = true
//                }
//            } else {
//                DispatchQueue.main.async {
//                    self.isLoggedIn = false
//                }
//            }
//        }
//    }
//    
//    func createUserProfile(username: String) {
//        let userRecord = CKRecord(recordType: "User")
//        userRecord["username"] = username as CKRecordValue
//        
//        let publicDB = CKContainer.default().publicCloudDatabase
//        publicDB.save(userRecord) { record, error in
//            if let record = record, error == nil {
//                DispatchQueue.main.async {
//                    self.currentUser = User(
//                        id: record.recordID,
//                        username: username
//                    )
//                    self.isLoggedIn = true
//                }
//            } else {
//                // Handle error
//            }
//        }
//    }
//}
