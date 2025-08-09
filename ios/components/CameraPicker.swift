//
//  CameraPicker.swift
//  DigiDoe Business Banking
//
//  Created by Михайло Картмазов on 27.01.2025.
//
import Foundation
import SwiftUI

struct CameraPickerView: UIViewControllerRepresentable {
    private var sourceType: UIImagePickerController.SourceType = .camera
    private let onImagePicked: (UIImage) -> Void
    private let onDismiss: () -> Void
    
    @Environment(\.presentationMode) private var presentationMode
    
    public init(onDismiss: @escaping () -> Void, onImagePicked: @escaping (UIImage) -> Void) {
        self.onDismiss = onDismiss
        self.onImagePicked = onImagePicked
    }
    
    public func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = self.sourceType
        picker.delegate = context.coordinator
        return picker
    }
    
    public func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(
            onDismiss: self.onDismiss,
            onImagePicked: self.onImagePicked
        )
    }
    
    final public class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        private let onDismiss: () -> Void
        private let onImagePicked: (UIImage) -> Void
        
        init(onDismiss: @escaping () -> Void, onImagePicked: @escaping (UIImage) -> Void) {
            self.onDismiss = onDismiss
            self.onImagePicked = onImagePicked
        }
        
        public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.editedImage] as? UIImage{
                self.onImagePicked(image)
            }else if let image = info[.originalImage] as? UIImage {
                self.onImagePicked(image)
            }
            self.onDismiss()
        }
        
        public func imagePickerControllerDidCancel(_: UIImagePickerController) {
            self.onDismiss()
        }
    }
}
