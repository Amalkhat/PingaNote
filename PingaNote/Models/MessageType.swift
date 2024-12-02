//
//  MessageType.swift
//  PingaNote
//
//  Created by Malek Alkhatib on 2024-10-22.
//

import Foundation

/// Enum representing the type of a message.
enum MessageType: String, Codable, Equatable {
    case text
    case image
    case system // For system messages like "Chat created"
    // Add other types as needed
}
