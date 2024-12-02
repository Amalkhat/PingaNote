//
//  DynamicHeightTextEditor.swift
//  PingaNote
//
//  Created by Malek Alkhatib on 2024-10-25.
//

import SwiftUI
import UIKit

struct DynamicHeightTextEditor: UIViewRepresentable {
    @Binding var text: String
    @Binding var calculatedHeight: CGFloat

    var placeholder: String
    var maxHeight: CGFloat = 120 // Set your desired maximum height

    func makeUIView(context: Context) -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = .clear

        let textView = UITextView()
        textView.delegate = context.coordinator

        // Basic Configuration
        textView.isScrollEnabled = false // Initially false
        textView.isEditable = true
        textView.font = UIFont.preferredFont(forTextStyle: .body)
        textView.backgroundColor = UIColor.clear
        textView.translatesAutoresizingMaskIntoConstraints = false

        // Text Container Configuration
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 4, bottom: 8, right: 4)
        textView.textContainer.lineFragmentPadding = 0
        textView.textContainer.lineBreakMode = .byWordWrapping
        textView.textContainer.widthTracksTextView = true

        // Placeholder Handling
        textView.text = text.isEmpty ? placeholder : text
        textView.textColor = text.isEmpty ? UIColor.placeholderText : UIColor.label

        // Add the textView to the containerView
        containerView.addSubview(textView)

        // Set constraints to make textView fill the containerView
        NSLayoutConstraint.activate([
            textView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            textView.topAnchor.constraint(equalTo: containerView.topAnchor),
            textView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])

        return containerView
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        guard let textView = uiView.subviews.first as? UITextView else { return }

        if textView.text != self.text && !(self.text.isEmpty && textView.text == placeholder) {
            textView.text = self.text
            textView.textColor = UIColor.label
        }

        // Schedule height recalculation asynchronously to avoid modifying state during view update
        DispatchQueue.main.async {
            DynamicHeightTextEditor.recalculateHeight(view: uiView, result: self.$calculatedHeight, maxHeight: self.maxHeight)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, height: $calculatedHeight, placeholder: placeholder, maxHeight: maxHeight)
    }

    class Coordinator: NSObject, UITextViewDelegate {
        @Binding var text: String
        @Binding var height: CGFloat
        var placeholder: String
        var maxHeight: CGFloat

        init(text: Binding<String>, height: Binding<CGFloat>, placeholder: String, maxHeight: CGFloat) {
            _text = text
            _height = height
            self.placeholder = placeholder
            self.maxHeight = maxHeight
        }

        func textViewDidChange(_ textView: UITextView) {
            self.text = textView.text

            // Recalculate height
            DynamicHeightTextEditor.recalculateHeight(view: textView.superview ?? textView, result: self.$height, maxHeight: self.maxHeight)

            // Adjust isScrollEnabled based on content size and maxHeight
            if textView.contentSize.height >= self.maxHeight {
                textView.isScrollEnabled = true
            } else {
                textView.isScrollEnabled = false
            }

            // Scroll to the caret position if scrolling is enabled
            if textView.isScrollEnabled {
                let selectedRange = textView.selectedRange
                textView.scrollRangeToVisible(selectedRange)
            }
        }

        func textViewDidBeginEditing(_ textView: UITextView) {
            if textView.text == placeholder {
                textView.text = ""
                textView.textColor = UIColor.label
            }
        }

        func textViewDidEndEditing(_ textView: UITextView) {
            if textView.text.isEmpty {
                textView.text = placeholder
                textView.textColor = UIColor.placeholderText
            }
        }
    }

    static func recalculateHeight(view: UIView, result: Binding<CGFloat>, maxHeight: CGFloat) {
        guard let textView = view.subviews.first as? UITextView else { return }

        // Force layout to ensure the view has the correct dimensions
        view.layoutIfNeeded()

        let fixedWidth = view.bounds.width

        if fixedWidth <= 0 {
            // Width is invalid; defer the height calculation
            DispatchQueue.main.async {
                recalculateHeight(view: view, result: result, maxHeight: maxHeight)
            }
            return
        }

        let newSize = textView.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.greatestFiniteMagnitude))

        // Adjust isScrollEnabled based on newSize.height and maxHeight
        textView.isScrollEnabled = newSize.height >= maxHeight

        if !newSize.height.isNaN && result.wrappedValue != newSize.height {
            // Schedule state update asynchronously to avoid modifying state during view updates
            DispatchQueue.main.async {
                result.wrappedValue = newSize.height
            }
        }
    }
}
