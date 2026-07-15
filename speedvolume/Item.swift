//
//  Item.swift
//  speedvolume
//
//  Created by Bruno Saad Marques on 15/07/26.
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
