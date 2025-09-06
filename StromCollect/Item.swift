//
//  Item.swift
//  StromCollect
//
//  Created by Aaron Celestian on 9/5/25.
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
