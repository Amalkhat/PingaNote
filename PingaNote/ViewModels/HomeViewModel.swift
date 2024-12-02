//
//  HomeViewModel.swift
//  PingaNote
//
//  Created by Malek Alkhatib on 2024-10-22.
//

import SwiftUI
import Foundation
import Combine

/// ViewModel responsible for managing the home screen's data and navigation.
class HomeViewModel: ObservableObject {
    // MARK: - Published Properties

    /// Holds the list of all chats.
    @Published private(set) var chats: [Chat] = []

    /// Manages the navigation stack for SwiftUI navigation.
    @Published var navigationPath = NavigationPath()

    /// Tracks the currently selected chat.
    @Published var selectedChat: Chat?

    /// Holds error messages to display to the user.
    @Published var errorMessage: String? = nil

    // MARK: - Dependencies

    /// Handles data persistence and image deletion.
    private let dataService: DataService

    /// Manages Combine subscriptions.
    private var cancellables = Set<AnyCancellable>()
    private var chatCancellables = Set<AnyCancellable>() // New set for chat subscriptions

    // MARK: - Initialization

    /// Initializes the HomeViewModel with an optional DataService for dependency injection.
    /// - Parameter dataService: The data service to use. Defaults to `DataService.shared`.
    init(initialChats: [Chat] = [], dataService: DataService = DataService.shared, initialErrorMessage: String? = nil) {
        self.chats = initialChats
        self.dataService = dataService
        self.errorMessage = initialErrorMessage
        self.navigationPath = NavigationPath()

        // Initialize other properties if necessary
        setupObservers()

        // Optionally load chats if not provided
        if initialChats.isEmpty {
            loadChats()
        }
    }

    // MARK: - Computed Properties

    /// Returns chats sorted by their last message time in descending order.
    var sortedChats: [Chat] {
        chats.sorted { $0.lastMessageTime > $1.lastMessageTime }
    }

    // MARK: - Public Methods

    /// Adds a new chat and navigates to it.
    func addNewChat() {
        let newChat = Chat(name: "")
        chats.append(newChat)
        selectedChat = newChat
        navigationPath.append(newChat)
        saveChats()
    }

    /// Deletes chats at specified offsets.
    /// - Parameter offsets: The index set containing the positions of chats to delete.
    func deleteChats(at offsets: IndexSet) {
        let chatsToDelete = offsets.map { chats[$0] }

        // Perform deletion on a background thread
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }
            do {
                for chat in chatsToDelete {
                    for message in chat.messages {
                        if let imagePath = message.imagePath {
                            do {
                                try self.dataService.deleteImage(at: imagePath)
                            } catch {
                                // Handle deletion error if necessary
                                print("Error deleting image at path: \(imagePath): \(error.localizedDescription)")
                            }
                        }
                    }
                }
                // Update the chats array by removing the deleted chats
                let updatedChats = self.chats.filter { !chatsToDelete.contains($0) }
                try self.dataService.saveChats(updatedChats)

                DispatchQueue.main.async {
                    self.chats = updatedChats
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to delete chats: \(error.localizedDescription)"
                }
            }
        }
    }

    /// Deletes a single chat.
    /// - Parameter chat: The chat to delete.
    func deleteChat(_ chat: Chat) {
        print("Deleting chat with ID: \(chat.id)")
        // Perform deletion on a background thread
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }
            do {
                for message in chat.messages {
                    if let imagePath = message.imagePath {
                        print("Attempting to delete image at path: \(imagePath)")
                        do {
                            try self.dataService.deleteImage(at: imagePath)
                        } catch {
                            // Handle deletion error if necessary
                            print("Error deleting image at path: \(imagePath): \(error.localizedDescription)")
                        }
                    }
                }
                // Update the chats array by removing the deleted chat
                let updatedChats = self.chats.filter { $0.id != chat.id }
                print("Chats before deletion: \(self.chats.map { $0.id })")
                print("Chats after filtering: \(updatedChats.map { $0.id })")
                try self.dataService.saveChats(updatedChats)
                print("Successfully saved chats after deletion.")

                DispatchQueue.main.async {
                    self.chats = updatedChats
                    print("Chats after deletion: \(self.chats.map { $0.id })")
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to delete chats: \(error.localizedDescription)"
                    print("Error deleting chat: \(error.localizedDescription)")
                }
            }
        }
    }

    // MARK: - Private Methods

    /// Loads chats from the data service.
    private func loadChats() {
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }
            do {
                let loadedChats = try self.dataService.loadChats()
                DispatchQueue.main.async {
                    self.chats = loadedChats
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to load chats: \(error.localizedDescription)"
                }
            }
        }
    }

    /// Saves all chats using the data service.
    private func saveChats() {
        let chatsToSave = self.chats
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }
            do {
                try self.dataService.saveChats(chatsToSave)
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to save chats: \(error.localizedDescription)"
                }
            }
        }
    }

    /// Sets up observers for chats and their changes.
    private func setupObservers() {
        // Observe changes to the chats array with debouncing to reduce save frequency
        $chats
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.saveChats()
                self?.setupChatObservers()
            }
            .store(in: &cancellables)
    }

    /// Sets up observers for each individual chat.
    private func setupChatObservers() {
        // Cancel previous chat subscriptions to prevent duplicates
        chatCancellables.removeAll()

        for chat in chats {
            observeSingleChat(chat)
        }
    }

    /// Observes changes to a single chat.
    /// - Parameter chat: The chat to observe.
    private func observeSingleChat(_ chat: Chat) {
        // Observe changes to the chat's properties
        chat.objectWillChange
            .sink { [weak self] in
                self?.saveChats()
            }
            .store(in: &chatCancellables)

        // Observe changes to the chat's messages array
        chat.$messages
            .sink { [weak self] _ in
                self?.saveChats()
            }
            .store(in: &chatCancellables)
    }
}
