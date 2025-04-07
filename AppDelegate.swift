////
////  AppDelegate.swift
////  Write-It-Down
////
////  Created by Tobias Fu on 4/7/25.
////
//
//import UIKit
//import UserNotifications
//import Supabase
//
//class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
//    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
//        registerForPushNotifications()
//        return true
//    }
//    
//    func registerForPushNotifications() {
//        UNUserNotificationCenter.current().delegate = self
//        UNUserNotificationCenter.current()
//            .requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
//                guard granted else { return }
//                
//                DispatchQueue.main.async {
//                    UIApplication.shared.registerForRemoteNotifications()
//                }
//            }
//    }
//    
//    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
//        // Convert token to string
//        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
//        let token = tokenParts.joined()
//        print("Device Token: \(token)")
//        
//        // Store this token in Supabase
//        Task {
//            await storeDeviceToken(token)
//        }
//    }
//    
//    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
//        print("Failed to register for notifications: \(error)")
//    }
//    
//    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
//        // Process the notification payload
//        if let noteIDString = userInfo["noteId"] as? String {
//            // Store this to open the right note when the app is opened
//            UserDefaults.standard.set(noteIDString, forKey: "lastNotificationNoteID")
//        }
//        
//        completionHandler(.newData)
//    }
//    
//    // Method to store token in Supabase
//    func storeDeviceToken(_ token: String) async {
//        guard let userID = try? await SupabaseManager.shared.client.auth.user().id else {
//            return
//        }
//        
//        do {
//            // Create a device record with proper types
//            struct DeviceRecord: Encodable {
//                let user_id: String
//                let device_token: String
//                let platform: String
//                let last_updated: String
//            }
//            
//            let deviceRecord = DeviceRecord(
//                user_id: userID.uuidString,
//                device_token: token,
//                platform: "ios",
//                last_updated: ISO8601DateFormatter().string(from: Date())
//            )
//            
//            try await SupabaseManager.shared.client
//                .from("user_devices")
//                .upsert(deviceRecord)
//                .execute()
//            print("Device token stored successfully")
//        } catch {
//            print("Error storing device token: \(error)")
//        }
//    }
//    
//    // These are notification center delegate methods - they must remain nonisolated
//    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
//        // Show notification even when app is in foreground
//        completionHandler([.banner, .sound, .badge])
//    }
//    
//    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
//        let userInfo = response.notification.request.content.userInfo
//        
//        if let noteIDString = userInfo["noteId"] as? String {
//            // Run on main thread when accessing UserDefaults
//            DispatchQueue.main.async {
//                UserDefaults.standard.set(noteIDString, forKey: "lastNotificationNoteID")
//                NotificationCenter.default.post(name: NSNotification.Name("DidReceivePushNotification"), object: nil)
//            }
//        }
//        
//        completionHandler()
//    }
//}
