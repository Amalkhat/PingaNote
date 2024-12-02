//
//  Chat.swift
//  PingaNote
//
//  Created by Malek Alkhatib on 2024-10-22.
//

import Foundation
import Combine

/// Class representing a chat conversation.
final class Chat: Identifiable, ObservableObject, Equatable, Codable, Hashable {
    // MARK: - Properties
    
    /// Unique identifier for the chat.
    let id: UUID
    
    /// The name of the chat.
    @Published var name: String
    
    /// The list of messages in the chat.
    @Published var messages: [Message]
    
    /// The timestamp of the last message in the chat.
    var lastMessageTime: Date {
        messages.last?.timestamp ?? Date(timeIntervalSince1970: 0)
    }
    
    // MARK: - Initializers
    
    /// Initializes a new `Chat`.
    /// - Parameters:
    ///   - id: The unique identifier. Defaults to a new UUID.
    ///   - name: The name of the chat. Defaults to an empty string.
    ///   - messages: The initial list of messages. Defaults to an empty array.
    init(id: UUID = UUID(), name: String = "", messages: [Message] = []) {
        self.id = id
        self.name = name
        self.messages = messages
    }
    
    // MARK: - Equatable Conformance
    
    static func == (lhs: Chat, rhs: Chat) -> Bool {
        lhs.id == rhs.id
    }
    
    // MARK: - Codable Conformance
    
    enum CodingKeys: String, CodingKey {
        case id, name, messages
    }
    
    required convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try container.decode(UUID.self, forKey: .id)
        let name = try container.decode(String.self, forKey: .name)
        let messages = try container.decode([Message].self, forKey: .messages)
        self.init(id: id, name: name, messages: messages)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(messages, forKey: .messages)
    }
    
    // MARK: - Hashable Conformance
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    // MARK: - ObservableObject Publisher Overrides
    
    private var cancellables = Set<AnyCancellable>()
    
    /// Sets up publishers for `@Published` properties to notify observers on changes.
    func setupPublishers() {
        $name
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
        
        $messages
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
}
