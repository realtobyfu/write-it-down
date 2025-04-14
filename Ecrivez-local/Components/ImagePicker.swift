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
    @Binding var image: UIImage? // Binding to hold the selected image
    
    var sourceType: UIImagePickerController.SourceType // Specifies the source type for the image
    
    // This method creates a Coordinator instance which handles the delegation of UIImagePickerController
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    // This method called when the view is created
    func makeUIViewController(context: UIViewControllerRepresentableContext<CameraImagePicker>) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator // set the delegate to handle image picker events
        picker.sourceType = sourceType // set the source type to photo library
        picker.mediaTypes = ["public.image"]
        picker.modalPresentationStyle = .fullScreen
        return picker
    }
    
    // This method is used to update this struct when SwiftUI view update, but not used in this case
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        
    }
    
    // Coordinator class to handle the delegate methods of UIImagePickerController
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: CameraImagePicker
        
        init(_ parent: CameraImagePicker) {
            self.parent = parent
        }
        
       
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        // This delegate method is called when the image picker is cancelled
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

/// A simple struct to pick an image from the user's photo library
struct PhotoLibraryPicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage? // Binding to hold the selected image
    let limitImageSelection = 1
    
    // This method creates a Coordinator instance which handles the delegation of PHPickerViewController
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    // This method called when the view is created
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        
        configuration.selectionLimit = limitImageSelection // limit selection to one image
        configuration.filter = .images // filtering for images only
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }
    
    // This method is used to update this struct when SwiftUI view update, but not used in this case
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {
        
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        var parent: PhotoLibraryPicker
        
        init(_ parent: PhotoLibraryPicker) {
            self.parent = parent
        }
        
        // this delegate method is called when an image is selected
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            if let result = results.first {
                result.itemProvider.loadObject(ofClass: UIImage.self) { object, error in
                    if let uiImage = object as? UIImage {
                        DispatchQueue.main.async {
                            self.parent.selectedImage = uiImage
                            print("Image successfully inserted")
                        }
                    }
                }
            }
            picker.dismiss(animated: true, completion: nil) // Dismiss the photo picker
        }
    }
}
