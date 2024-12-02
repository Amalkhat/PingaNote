//
//  MessageBubbleView.swift
//  PingaNote
//
//  Created by Malek Alkhatib on 2024-10-22.
//

import SwiftUI

struct MessageBubble: View {
    let message: Message
    let onDelete: (Message) -> Void
    let onEdit: (Message) -> Void

    @State private var showingActionSheet = false

    // Computed property to load the image
    private var uiImage: UIImage? {
        guard message.type == .image, let imagePath = message.imagePath else { return nil }
        // Construct the full file path
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentsDirectory.appendingPathComponent(imagePath)
        // Debug print statement (optional)
        print("Attempting to load image from path: \(fileURL.path)")
        // Load the image
        return UIImage(contentsOfFile: fileURL.path)
    }

    var body: some View {
        HStack {
            Spacer()
            VStack(alignment: .trailing) {
                if message.type == .text, let messageText = message.text {
                    Text(messageText)
                        .padding()
                        .foregroundColor(.white)
                        .background(Color.blue)
                        .cornerRadius(15)
                } else if message.type == .image {
                    if let uiImage = uiImage {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: UIScreen.main.bounds.width * 0.75)
                            .cornerRadius(15)
                    } else {
                        Text("Image could not be loaded")
                            .padding()
                            .foregroundColor(.white)
                            .background(Color.gray)
                            .cornerRadius(15)
                    }
                }
                // Handle other message types if needed
            }
        }
        .padding(.vertical, 5)
        .padding(.horizontal, 10)
        // Add long-press gesture
        .onLongPressGesture {
            showingActionSheet = true
        }
        // Present the action sheet
        .confirmationDialog("Choose an action", isPresented: $showingActionSheet, titleVisibility: .visible) {
            Button("Edit") {
                onEdit(message)
            }
            Button("Delete", role: .destructive) {
                onDelete(message)
            }
            Button("Cancel", role: .cancel) {}
        }
    }
}
