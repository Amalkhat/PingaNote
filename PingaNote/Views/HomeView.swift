//
//  HomeView.swift
//  PingaNote
//
//  Created by Malek Alkhatib on 2024-10-22.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var viewModel: HomeViewModel
    @State private var activeAlert: ActiveAlert? = nil

    enum ActiveAlert: Identifiable, Hashable {
        case delete(Chat)
        case error(String)
        
        // Unique identifier for each alert instance
        var id: UUID {
            UUID()
        }
    }

    var body: some View {
        NavigationStack(path: $viewModel.navigationPath) {
            List {
                ForEach(viewModel.sortedChats) { chat in
                    NavigationLink(value: chat) {
                        ChatRow(chat: chat)
                            .animation(.easeInOut, value: chat.id)
                    }
                    // Remove the role from the Button
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button {
                            // Trigger delete confirmation
                            activeAlert = .delete(chat)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        .tint(.red) // Optional: Set the tint color to red to indicate a destructive action
                    }
                }
                // Remove the onDelete modifier if it's still present
            }
            .listStyle(PlainListStyle())
            .navigationTitle("Chats")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        viewModel.addNewChat()
                    }) {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add New Chat")
                }
            }
            .navigationDestination(for: Chat.self) { chat in
                ChatView(viewModel: ChatViewModel(chat: chat))
            }
            // Single alert modifier handling multiple alert types
            .alert(item: $activeAlert) { alert in
                switch alert {
                case .delete(let chat):
                    return Alert(
                        title: Text("Delete Chat"),
                        message: Text("Are you sure you want to delete this chat?"),
                        primaryButton: .destructive(Text("Delete")) {
                            withAnimation {
                                viewModel.deleteChat(chat)
                            }
                        },
                        secondaryButton: .cancel()
                    )
                case .error(let message):
                    return Alert(
                        title: Text("Error"),
                        message: Text(message),
                        dismissButton: .default(Text("OK")) {
                            viewModel.errorMessage = nil
                        }
                    )
                }
            }
            // Observe errorMessage and trigger error alert
            .onReceive(viewModel.$errorMessage) { errorMessage in
                if let errorMessage = errorMessage {
                    activeAlert = .error(errorMessage)
                }
            }
        }
    }
}
