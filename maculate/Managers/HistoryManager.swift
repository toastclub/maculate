//
//  History.swift
//  maculate
//
//  Created by Evan Boehs on 11/27/24.
//

import Foundation
import SwiftData

enum MessageTypes: String, Codable, Hashable {
    case error = "Error"
    case warning = "Warning"
    case info = "Info"
}

struct Messages: Equatable,Codable,Hashable {
    let type: MessageTypes
    let message: String
}

enum SpecialStatuses: String, Codable, Hashable {
    case tutorial = "Tutorial"
}

@Model
class HistoryItem: Equatable,Hashable {
    var expression: String
    var result: String
    var messages: [Messages]
    var specialStatus: [SpecialStatuses]?
    var date: Date = Date()
    var starred: Bool = false
    var tape: String = ""
    
    init(expression: String, result: String, messages: [Messages], specialStatus: [SpecialStatuses]? = nil) {
        self.expression = expression
        self.result = result
        self.messages = messages
        self.specialStatus = specialStatus
        self.starred = false
    }
    
    static func == (lhs: HistoryItem, rhs: HistoryItem) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
