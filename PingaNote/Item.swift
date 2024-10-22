//
//  Item.swift
//  PingaNote
//
//  Created by Malek Alkhatib on 2024-10-22.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
