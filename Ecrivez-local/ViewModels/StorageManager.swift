//
//  StorageManager.swift
//  Write-It-Down
//
//  Created by Tobias Fu on 4/6/25.
//

import Foundation
import Supabase
import UIKit

@MainActor
class StorageManager {
    static let shared = StorageManager()
    private let supabase = SupabaseManager.shared.client
    
    private init() {}
    
    
    enum StorageError: Error {
        case imageConversionFailed
        case userNotAuthenticated
        case uploadFailed(String)
        case downloadFailed(String)
        
    }
    /// Upload a profile image to Supabase Storage
    func uploadProfileImage(_ image: UIImage, quality: CGFloat = 0.7) async throws -> String {
        // 1. Check if user is authenticated
        guard let userId = try? await supabase.auth.user().id else {
            throw StorageError.userNotAuthenticated
        }
        
        // 2. Convert image to data
        guard let imageData = image.jpegData(compressionQuality: quality) else {
            throw StorageError.imageConversionFailed
        }
        
        // 3. Create a unique filename
        let fileName = "\(userId)/profile_\(UUID().uuidString).jpg"
        
        // 4. Upload the file
        do {
            let response = try await supabase.storage
                .from("profile_images")
                .upload(
                    fileName,
                    data: imageData,
                    options: FileOptions(
                        cacheControl: "3600",
                        upsert: true
                    )
                )
            
            // 5. Return the path of the uploaded file
            return fileName
        } catch {
            throw StorageError.uploadFailed(error.localizedDescription)
        }
    }
    
    /// Get a public URL for a stored profile image
    func getPublicURL(for path: String) throws -> URL {
        do {
            return try supabase.storage
                .from("profile_images")
                .getPublicURL(path: path)
        } catch {
            throw StorageError.downloadFailed(error.localizedDescription)
        }
    }

    /// Delete a profile image
    func deleteProfileImage(path: String) async throws {
        try await supabase.storage
            .from("profile_images")
            .remove(paths: [path])
    }
}
