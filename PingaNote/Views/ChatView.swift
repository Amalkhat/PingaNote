//
//  ChatView.swift
//  PingaNote
//
//  Created by Malek Alkhatib on 2024-10-22.
//

import SwiftUI
import UIKit
import PhotosUI

struct ChatView: View {
    @ObservedObject var viewModel: ChatViewModel
    @Environment(\.presentationMode) var presentationMode
    @FocusState private var focusedField: FocusField?
    
    enum FocusField: Hashable {
        case name
        case message
    }
    
    // State variable to track the dynamic height of the TextEditor
    @State private var textEditorHeight: CGFloat = 40 // Initial height
    
    var body: some View {
        VStack {
            // Chat name input field
            TextField("Enter chat name", text: $viewModel.chat.name)
                .textFieldStyle(PlainTextFieldStyle())
                .padding(.horizontal)
                .padding(.vertical, 5)
                .focused($focusedField, equals: .name)
                .onAppear {
                    if viewModel.chat.name.isEmpty {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            focusedField = .name
                        }
                    }
                }
            
            Divider()
            
            // Messages list
            ScrollViewReader { proxy in
                List {
                    ForEach(viewModel.chat.messages) { message in
                        MessageBubble(
                            message: message,
                            onDelete: { messageToDelete in
                                viewModel.deleteMessage(messageToDelete)
                            },
                            onEdit: { messageToEdit in
                                viewModel.prepareEditMessage(messageToEdit)
                            }
                        )
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .id(message.id)
                    }
                }
                .listStyle(PlainListStyle())
                .onChange(of: viewModel.chat.messages.count) { oldCount, newCount in
                    if let lastMessage = viewModel.chat.messages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            Divider()
            
            // Message input field with dynamic height
            HStack(alignment: .bottom) {
                Button(action: {
                    // Dismiss the keyboard
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    viewModel.showingImagePicker = true
                }) {
                    Image(systemName: "photo")
                        .font(.system(size: 24))
                        .foregroundColor(.blue)
                }
                .padding(.horizontal, 5)
                .accessibilityLabel("Pick an image")
                
                // DynamicHeightTextEditor for multi-line input
                DynamicHeightTextEditor(
                    text: $viewModel.messageText,
                    calculatedHeight: $textEditorHeight,
                    placeholder: "Type a message",
                    maxHeight: 120 // Set the same maxHeight here
                )
                .frame(height: min(max(40, textEditorHeight), 120))
                .frame(maxWidth: .infinity)
                .padding(4)
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(8)
                .focused($focusedField, equals: .message)
                //.onSubmit { ... } // Removed as TextEditor doesn't support onSubmit
                
                Button(action: {
                    viewModel.sendMessage(isEditing: viewModel.editingMessage != nil)
                    // Reset editing state
                    if viewModel.editingMessage != nil {
                        viewModel.editingMessage = nil
                    }
                }) {
                    Image(systemName: viewModel.editingMessage != nil ? "pencil.circle.fill" : "arrow.up.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(viewModel.messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray : .blue)
                }
                .padding(.horizontal, 5)
                .disabled(viewModel.messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .accessibilityLabel(viewModel.editingMessage != nil ? "Update message" : "Send message")
            }
            .padding(.horizontal)
            .padding(.vertical, 5)
            .onChange(of: textEditorHeight) { oldHeight, newHeight in
                print("ChatView: TextEditor height updated from \(oldHeight) to \(newHeight)")
            }
        }
        .navigationTitle(viewModel.chat.name.isEmpty ? "" : viewModel.chat.name)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if viewModel.chat.name.isEmpty {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    focusedField = .name
                }
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    focusedField = .message
                }
            }
        }
        .sheet(isPresented: $viewModel.showingImagePicker) {
            ImagePicker(selectedImage: $viewModel.selectedImage)
        }
        // Populate the message input field when editing a message
        .onChange(of: viewModel.editingMessage) { oldValue, newValue in
            if let message = newValue {
                viewModel.messageText = message.text ?? ""
            } else {
                viewModel.messageText = ""
            }
        }
        // Error alert
        .alert(isPresented: Binding<Bool>(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Alert(
                title: Text("Error"),
                message: Text(viewModel.errorMessage ?? "An unknown error occurred."),
                dismissButton: .default(Text("OK")) {
                    viewModel.errorMessage = nil
                }
            )
        }
    }
}
