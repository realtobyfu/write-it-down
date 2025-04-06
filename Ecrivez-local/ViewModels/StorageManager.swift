//
//  StorageManager.swift
//  Write-It-Down
//
//  Created by Tobias Fu on 4/6/25.
//

//
//  StorageManager.swift
//  Write-It-Down
//
//  Created by Tobias Fu on 4/6/25.
//

import Foundation
import Supabase
import UIKit

// MARK: - UIImage Extension for Resizing
extension UIImage {
    func resized(to targetSize: CGSize) -> UIImage {
        let size = self.size
        let widthRatio = targetSize.width / size.width
        let heightRatio = targetSize.height / size.height
        
        // Take the smaller ratio to maintain aspect ratio
        let ratio = min(widthRatio, heightRatio)
        
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        self.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage ?? self
    }
}

@MainActor
class StorageManager {
    static let shared = StorageManager()
    private let supabase = SupabaseManager.shared.client
    private let bucketName = "profile_images"
    
    private init() {
        // Create bucket if it doesn't exist (first time setup)
        Task {
            do {
                _ = try await ensureBucketExists()
            } catch {
                print("Error setting up storage bucket: \(error)")
            }
        }
    }
    
    enum StorageError: Error {
        case imageConversionFailed
        case userNotAuthenticated
        case uploadFailed(String)
        case downloadFailed(String)
        case bucketCreationFailed(String)
    }
    
    /// Ensures the profile_images bucket exists
    private func ensureBucketExists() async throws -> Bool {
        do {
            // Try to get the bucket
            _ = try await supabase.storage.getBucket(bucketName)
            return true
        } catch {
            // Bucket doesn't exist, create it
            do {
                _ = try await supabase.storage.createBucket(
                    bucketName,
                    options: BucketOptions(public: true) // Make it public for easier access
                )
                return true
            } catch {
                throw StorageError.bucketCreationFailed(error.localizedDescription)
            }
        }
    }
    
    /// Upload a profile image to Supabase Storage with compression
    func uploadProfileImage(_ image: UIImage, quality: CGFloat = 0.7) async throws -> String {
        // 1. Check if user is authenticated
        guard let userId = try? await supabase.auth.user().id else {
            throw StorageError.userNotAuthenticated
        }
        
        // 2. Resize image for profile use (500x500 max)
        let resizedImage = image.resized(to: CGSize(width: 500, height: 500))
        
        // 3. Convert image to data with compression
        guard let imageData = resizedImage.jpegData(compressionQuality: quality) else {
            throw StorageError.imageConversionFailed
        }
        
        // 4. Create a unique filename with user ID and timestamp
        let fileName = "\(userId)/profile_\(UUID().uuidString).jpg"
        
        // 5. Upload the file
        do {
            try await ensureBucketExists()
            
            let response = try await supabase.storage
                .from(bucketName)
                .upload(
                    path: fileName,
                    file: imageData,
                    options: FileOptions(
                        cacheControl: "3600",
                        upsert: true
                    )
                )
            
            // 6. Return the path of the uploaded file
            return fileName
        } catch {
            throw StorageError.uploadFailed(error.localizedDescription)
        }
    }
    
    /// Get a public URL for a stored profile image
    func getPublicURL(for path: String) throws -> URL {
        do {
            return try supabase.storage
                .from(bucketName)
                .getPublicURL(path: path)
        } catch {
            throw StorageError.downloadFailed(error.localizedDescription)
        }
    }

    /// Delete a profile image
    func deleteProfileImage(path: String) async throws {
        try await supabase.storage
            .from(bucketName)
            .remove(paths: [path])
    }
    
    /// Delete all previous profile images for a user
    func deleteAllUserProfileImages(userId: UUID) async throws {
        do {
            // List all files in the user's folder
            let response = try await supabase.storage
                .from(bucketName)
                .list(path: "\(userId)")
            
            // Extract file paths
            let filePaths = response.map { "\(userId)/\($0.name)" }
            
            // If there are files, remove them
            if !filePaths.isEmpty {
                try await supabase.storage
                    .from(bucketName)
                    .remove(paths: filePaths)
            }
        } catch {
            print("Error deleting previous profile images: \(error)")
            // Continue execution even if this fails
        }
    }
}
