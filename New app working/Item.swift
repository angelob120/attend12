//
//  Item.swift
//  New app working
//
//  Created by AB on 1/9/25.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date?
    
    init(timestamp: Date? = Date()) {
        self.timestamp = timestamp
    }
}
