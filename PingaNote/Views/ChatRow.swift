//
//  ChatRow.swift
//  PingaNote
//
//  Created by Malek Alkhatib on 2024-10-23.
//

import SwiftUI

struct ChatRow: View {
    @ObservedObject var chat: Chat

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Chat Name
            Text(chat.name.isEmpty ? "New Note" : chat.name)
                .font(.headline)
                .foregroundColor(.primary) // Adapts to light/dark mode

            // Last Message Preview and Timestamp
            if let lastMessage = chat.messages.last {
                HStack {
                    // Message Preview
                    if lastMessage.type == .text, let messageText = lastMessage.text {
                        Text(messageText)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    } else if lastMessage.type == .image {
                        Text("[Image]")
                            .font(.subheadline)
                            .italic()
                            .foregroundColor(.gray)
                    }

                    Spacer()

                    // Timestamp
                    Text(lastMessage.timestamp.formattedForChatList())
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle()) // Makes the entire row tappable
    }
}
