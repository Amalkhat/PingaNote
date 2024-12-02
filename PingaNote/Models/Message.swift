//
//  Message.swift
//  PingaNote
//
//  Created by Malek Alkhatib on 2024-10-22.
//

import Foundation

struct Message: Identifiable, Codable, Equatable {
    // MARK: - Properties
    
    /// Unique identifier for the message.
    let id: UUID
    
    /// The textual content of the message. Nil if the message is an image.
    var text: String?
    
    /// The relative path to the image associated with the message. Nil if the message is text.
    let imagePath: String?
    
    /// The timestamp when the message was created or sent.
    var timestamp: Date
    
    /// The type of the message (e.g., text, image).
    var type: MessageType
    
    // MARK: - Initializers
    
    /// Initializes a new `Message`.
    /// - Parameters:
    ///   - id: The unique identifier. Defaults to a new UUID.
    ///   - text: The textual content. Defaults to `nil`.
    ///   - imagePath: The path to the associated image. Defaults to `nil`.
    ///   - type: The type of the message.
    ///   - timestamp: The timestamp of the message. Defaults to the current date and time.
    init(
        id: UUID = UUID(),
        text: String? = nil,
        imagePath: String? = nil,
        type: MessageType,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.text = text
        self.imagePath = imagePath
        self.type = type
        self.timestamp = timestamp
    }
    
    /// Convenience initializer for creating a text message.
    /// - Parameter text: The textual content of the message.
    init(text: String) {
        self.init(text: text, type: .text)
    }
    
    /// Convenience initializer for creating an image message.
    /// - Parameter imagePath: The path to the image associated with the message.
    init(imagePath: String) {
        self.init(imagePath: imagePath, type: .image)
    }
    
    // MARK: - Codable Conformance
    
    enum CodingKeys: String, CodingKey {
        case id, text, imagePath, timestamp, type
    }
}
