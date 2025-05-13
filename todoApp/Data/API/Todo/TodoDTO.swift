//
//  File.swift
//  todoApp
//
//  Created by 조영태 on 3/5/25.
//

import Foundation

// MARK: - TODO List
struct TodoResponse: Codable {
    let id: String
    let title: String
    let date: Date
    let contents: String
    let isDone: Bool
    
    init (id: String, title: String, date: Date, contents: String, isDone: Bool) {
        self.id = id
        self.title = title
        self.date = date
        self.contents = contents
        self.isDone = isDone
    }
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.title = try container.decode(String.self, forKey: .title)
        
        let dateStr = try container.decode(String.self, forKey: .date)
        
        let formatter = ISO8601DateFormatter()
        let date = formatter.date(from: dateStr)
        self.date = date ?? Date()
        
        self.contents = try container.decode(String.self, forKey: .contents)
        self.isDone = try container.decode(Bool.self, forKey: .isDone)
    }
}

struct TodoDeleteResponse: Codable {
    let id: String
}
