//
//  DataService.swift
//  PingaNote
//
//  Created by Malek Alkhatib on 2024-10-22.
//

import Foundation
import UIKit

/// Enum representing possible errors during data operations.
enum DataServiceError: Error {
    case fileNotFound
    case dataEncodingFailed
    case dataDecodingFailed
    case imageDeletionFailed
    case imageSavingFailed
}

/// Service responsible for handling data persistence and image management.
class DataService {
    // MARK: - Singleton Instance
    
    static let shared = DataService()
    
    // MARK: - Properties
    
    private let filename = "chats.json"
    
    // MARK: - Initialization
    
    private init() { }
    
    // MARK: - Public Methods
    
    /// Saves an array of chats to persistent storage.
    /// - Parameter chats: The array of `Chat` objects to save.
    /// - Throws: `DataServiceError` if saving fails.
    func saveChats(_ chats: [Chat]) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        do {
            let data = try encoder.encode(chats)
            let url = try getChatsFileURL()
            try data.write(to: url, options: [.atomicWrite, .completeFileProtection])
        } catch {
            throw DataServiceError.dataEncodingFailed
        }
    }
    
    /// Loads all chats from persistent storage.
    /// - Returns: An array of `Chat` objects.
    /// - Throws: `DataServiceError` if loading fails.
    func loadChats() throws -> [Chat] {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let url = try getChatsFileURL()
        
        do {
            let data = try Data(contentsOf: url)
            let chats = try decoder.decode([Chat].self, from: data)
            return chats
        } catch {
            throw DataServiceError.dataDecodingFailed
        }
    }
    
    /// Deletes an image at the specified path.
    /// - Parameter path: The relative path of the image to delete.
    /// - Returns: A Boolean indicating whether the deletion was successful.
    /// - Throws: `DataServiceError` if deletion fails due to reasons other than the file not existing.
    func deleteImage(at path: String) throws {
        let url = getDocumentsDirectory().appendingPathComponent(path)
        if FileManager.default.fileExists(atPath: url.path) {
            do {
                try FileManager.default.removeItem(at: url)
                print("Image deleted at path: \(path)")
                // No need to return true
            } catch {
                print("Error deleting image at path: \(path) - \(error.localizedDescription)")
                throw DataServiceError.imageDeletionFailed
            }
        } else {
            // Log the absence and continue
            print("Warning: Image file not found at path: \(path). Skipping deletion.")
            // No need to return false
        }
    }
    
    /// Saves an image to the documents directory.
    /// - Parameter image: The `UIImage` to save.
    /// - Returns: The relative path of the saved image.
    /// - Throws: `DataServiceError` if saving fails.
    func saveImage(_ image: UIImage) throws -> String {
        let uniqueID = UUID().uuidString
        let fileName = "\(uniqueID).jpg"
        let fileURL = getDocumentsDirectory().appendingPathComponent(fileName)
        
        // Optionally, resize or adjust image orientation here if needed.
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            throw DataServiceError.imageSavingFailed
        }
        
        do {
            try data.write(to: fileURL, options: [.atomicWrite, .completeFileProtection])
            print("Image saved at path: \(fileName)")
            return fileName // Return the relative path (fileName)
        } catch {
            throw DataServiceError.imageSavingFailed
        }
    }
    
    // MARK: - Private Methods
    
    /// Retrieves the file URL for the chats JSON file.
    /// - Returns: The `URL` of the chats JSON file.
    /// - Throws: `DataServiceError` if the file URL cannot be constructed.
    private func getChatsFileURL() throws -> URL {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        guard let directory = documentsDirectory else {
            throw DataServiceError.fileNotFound
        }
        return directory.appendingPathComponent(filename)
    }
    
    /// Retrieves the documents directory URL.
    /// - Returns: The `URL` of the documents directory.
    private func getDocumentsDirectory() -> URL {
        // Safe to force unwrap as documents directory always exists
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}
