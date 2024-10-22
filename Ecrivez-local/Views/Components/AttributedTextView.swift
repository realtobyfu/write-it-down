//
//  AttributedTextView.swift
//  Ecrivez-local
//
//  Created by Tobias Fu on 9/17/24.
//

import SwiftUI
import PhotosUI

struct AttributedTextView: UIViewRepresentable {
    let attributedText: NSAttributedString
    
    @Binding var dynamicHeight: CGFloat // Add a binding to adjust height dynamically
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.isSelectable = false
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.backgroundColor = UIColor.clear
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        
        // Adjust the dynamic height initially
        textView.delegate = context.coordinator
        
        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        uiView.attributedText = attributedText
        uiView.textColor = UIColor.white
        
        // Calculate the size of the text and adjust the height
        DispatchQueue.main.async {
            let size = uiView.sizeThatFits(CGSize(width: uiView.frame.size.width, height: CGFloat.greatestFiniteMagnitude))
            if dynamicHeight != size.height {
                dynamicHeight = size.height // Update the height if it has changed
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UITextViewDelegate {
        var parent: AttributedTextView

        init(_ parent: AttributedTextView) {
            self.parent = parent
        }
    }
}
