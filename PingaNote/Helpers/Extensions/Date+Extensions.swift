//
//  Date+Extensions.swift
//  PingaNote
//
//  Created by Malek Alkhatib on 2024-10-22.
//

import Foundation

extension Date {
    /// Formats the date according to the following rules:
    /// - Today: Displays only the time.
    /// - Yesterday: Displays "Yesterday" (localized).
    /// - Within the last week: Displays the day of the week.
    /// - More than a week ago: Displays the date in a localized short format.
    func formattedForChatList() -> String {
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isDateInToday(self) {
            return Self.timeFormatter.string(from: self)
        } else if calendar.isDateInYesterday(self) {
            return NSLocalizedString("Yesterday", comment: "Label for yesterday's date")
        } else if let daysDifference = calendar.dateComponents([.day], from: self, to: now).day, daysDifference < 7 {
            return Self.weekdayFormatter.string(from: self)
        } else {
            return Self.shortDateFormatter.string(from: self)
        }
    }
    
    // MARK: - Static DateFormatters
    
    /// Static DateFormatter for time-only representation.
    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        formatter.locale = Locale.current
        return formatter
    }()
    
    /// Static DateFormatter for weekday representation.
    private static let weekdayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE" // Full day name, e.g., "Monday"
        formatter.locale = Locale.current
        return formatter
    }()
    
    /// Static DateFormatter for short date representation.
    private static let shortDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short // Automatically adapts to the user's locale
        formatter.timeStyle = .none
        formatter.locale = Locale.current
        return formatter
    }()
}
