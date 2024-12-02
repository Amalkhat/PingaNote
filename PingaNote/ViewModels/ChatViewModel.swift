//
//  ChatViewModel.swift
//  PingaNote
//
//  Created by Malek Alkhatib on 2024-10-22.
//

import Foundation
import Combine
import UIKit

class ChatViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var chat: Chat
    @Published var messageText: String = ""
    @Published var selectedImage: UIImage?
    @Published var showingImagePicker = false
    
    // New Published property to track editing
    @Published var editingMessage: Message? = nil
    
    // Published property for error messages
    @Published var errorMessage: String? = nil
    
    // Dependencies
    private let dataService: DataService
    private weak var homeViewModel: HomeViewModel?
    
    // Cancellables for Combine
    private var cancellables = Set<AnyCancellable>()
    
    // Initializer
    init(chat: Chat, homeViewModel: HomeViewModel? = nil, dataService: DataService = DataService.shared) {
        self.chat = chat
        self.dataService = dataService
        self.homeViewModel = homeViewModel
        setupBindings()
        
        // Observe changes in Chat and forward them
        chat.objectWillChange
            .sink { [weak self] in self?.objectWillChange.send() }
            .store(in: &cancellables)
    }
        
        // MARK: - Methods
        
        /// Sends a text message. If `isEditing` is true, updates the existing message.
        /// - Parameter isEditing: A flag indicating whether the message is being edited.
        func sendMessage(isEditing: Bool = false) {
            let trimmedText = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedText.isEmpty else { return }
            
            if isEditing, let editingMessage = editingMessage {
                // Update the existing message
                if let index = chat.messages.firstIndex(where: { $0.id == editingMessage.id }) {
                    chat.messages[index].text = trimmedText
                    chat.messages[index].timestamp = Date() // Optionally update timestamp
                }
                messageText = ""
                self.editingMessage = nil
            } else {
                // Create a new message
                let message = Message(text: trimmedText, type: .text)
                chat.messages.append(message)
                messageText = ""
            }
        }
        
        /// Saves the provided UIImage to the documents directory.
        /// - Parameter image: The UIImage to save.
        /// - Returns: The relative path (filename) to the saved image, or nil if saving fails.
        private func saveImage(_ image: UIImage) -> String? {
            do {
                let imagePath = try dataService.saveImage(image) // Save and get filename
                return imagePath
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to save image: \(error.localizedDescription)"
                }
                return nil
            }
        }
        
        /// Retrieves the URL to the app's documents directory.
        /// - Returns: The URL of the documents directory.
        private func getDocumentsDirectory() -> URL {
            FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        }
        
        /// Deletes a specific message from the chat.
        /// - Parameter message: The message to delete.
    func deleteMessage(_ message: Message) {
        if let index = chat.messages.firstIndex(where: { $0.id == message.id }) {
            if let imagePath = message.imagePath {
                DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                    do {
                        try self?.dataService.deleteImage(at: imagePath)
                        DispatchQueue.main.async {
                            self?.chat.messages.remove(at: index)
                        }
                    } catch {
                        DispatchQueue.main.async {
                            self?.errorMessage = "Failed to delete image: \(error.localizedDescription)"
                        }
                    }
                }
            } else {
                // For text messages, remove directly on main thread
                chat.messages.remove(at: index)
            }
        }
    }
        
        /// Prepares a message for editing by setting it as the current `editingMessage` and populating `messageText`.
        /// - Parameter message: The message to edit.
        func prepareEditMessage(_ message: Message) {
            editingMessage = message
            messageText = message.text ?? ""
        }
        
        /// Sets up bindings for observed properties.
        private func setupBindings() {
            // Observe selectedImage changes
            $selectedImage
                .sink { [weak self] newImage in
                    if let image = newImage {
                        self?.addImageMessage(image: image)
                    }
                }
                .store(in: &cancellables)
        }
        
        /// Adds an image message by saving the image and appending the message to the chat.
        /// - Parameter image: The UIImage to add as a message.
    func addImageMessage(image: UIImage) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            do {
                let imagePath = try self.dataService.saveImage(image)
                let newMessage = Message(imagePath: imagePath, type: .image)
                DispatchQueue.main.async {
                    self.chat.messages.append(newMessage)
                    print("Added image message with path: \(imagePath)")
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to save image: \(error.localizedDescription)"
                    print("Error adding image message: \(error.localizedDescription)")
                }
            }
        }
    }
}

