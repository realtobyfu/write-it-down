//
//  ImagePicker.swift
//  Ecrivez-local
//
//  Created by Tobias Fu on 7/31/24.
//

import SwiftUI
import UIKit
import PhotosUI

/// A simple struct to pick an image from the device's camera
struct CameraImagePicker: UIViewControllerRepresentable {
    @Environment(\.presentationMode) var presentationMode
    
    // Support both UIImage and Data bindings
    @Binding var image: UIImage?
    @Binding var imageData: Data?
    
    var sourceType: UIImagePickerController.SourceType = .camera
    
    // Initialize with either UIImage or Data binding
    init(image: Binding<UIImage?>, sourceType: UIImagePickerController.SourceType = .camera) {
        self._image = image
        self._imageData = .constant(nil)
        self.sourceType = sourceType
    }
    
    init(imageData: Binding<Data?>, sourceType: UIImagePickerController.SourceType = .camera) {
        self._image = .constant(nil)
        self._imageData = imageData
        self.sourceType = sourceType
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = sourceType
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) { }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraImagePicker

        init(_ parent: CameraImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            defer { parent.presentationMode.wrappedValue.dismiss() }
            guard let uiImage = info[.originalImage] as? UIImage else { return }
            
            // Update either image or imageData binding
            if parent.image != nil {
                parent.image = uiImage
            }
            
            if parent.imageData != nil {
                parent.imageData = uiImage.jpegData(compressionQuality: 0.8)
                print("Camera picker: Image data set with size: \(parent.imageData?.count ?? 0) bytes")
            }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

/// A simple struct to pick an image from the user's photo library
struct PhotoLibraryPicker: UIViewControllerRepresentable {
    // Support both UIImage and Data bindings
    @Binding var selectedImage: UIImage?
    @Binding var selectedImageData: Data?
    
    // Initialize with either UIImage or Data binding
    init(selectedImage: Binding<UIImage?>) {
        self._selectedImage = selectedImage
        self._selectedImageData = .constant(nil)
    }
    
    // IMPORTANT FIX: The parameter name here is misleading - it accepts Data, not UIImage
    init(selectedImage: Binding<Data?>) {
        self._selectedImage = .constant(nil)
        self._selectedImageData = selectedImage
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) { }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PhotoLibraryPicker

        init(_ parent: PhotoLibraryPicker) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)

            guard let provider = results.first?.itemProvider,
                  provider.canLoadObject(ofClass: UIImage.self) else {
                print("PhotoLibraryPicker: No image provider found or cannot load UIImage")
                return
            }

            provider.loadObject(ofClass: UIImage.self) { object, error in
                if let error = error {
                    print("PhotoLibraryPicker error: \(error.localizedDescription)")
                    return
                }
                
                if let image = object as? UIImage {
                    DispatchQueue.main.async {
                        // Update either image or imageData binding
                        if self.parent.selectedImage != nil {
                            self.parent.selectedImage = image
                            print("PhotoLibraryPicker: UIImage set successfully")
                        }
                        
                        if self.parent.selectedImageData != nil {
                            let imageData = image.jpegData(compressionQuality: 0.8)
                            self.parent.selectedImageData = imageData
                            print("PhotoLibraryPicker: Image data set with size: \(imageData?.count ?? 0) bytes")
                        }
                    }
                } else {
                    print("PhotoLibraryPicker: Failed to cast object to UIImage")
                }
            }
        }
    }
}
