//
//  Item.swift
//  Grindr
//
//  Created by Mrdo1o Mac on 7/2/26.
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
