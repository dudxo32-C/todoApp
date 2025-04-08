//
//  File.swift
//  todoApp
//
//  Created by 조영태 on 3/5/25.
//

import Foundation

// MARK: - TODO List
struct TodoResponseDTO: Codable {
    let id: String
    let title: String
    let date: Date
    let contents: String
}
