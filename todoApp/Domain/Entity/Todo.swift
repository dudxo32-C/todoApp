//
//  TodoModel.swift
//  todoApp
//
//  Created by 조영태 on 3/5/25.
//

import Foundation

struct Todo {
    var id: String
    var title: String
    var date: Date
    var contents: String
    var isDone: Bool

    init(id: String, title: String, date: Date, contents: String, isDone: Bool)
    {
        self.id = id
        self.title = title
        self.date = date
        self.contents = contents
        self.isDone = isDone
    }
}
