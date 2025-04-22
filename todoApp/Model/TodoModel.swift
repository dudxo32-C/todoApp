//
//  TodoModel.swift
//  todoApp
//
//  Created by 조영태 on 3/5/25.
//

import Foundation

protocol TodoModelProtocol {
    var id: String { get }
    var title: String { get }
    var date: Date { get }
    var contents: String { get }
    var isDone: Bool { get }
}

extension TodoModelProtocol {
    func copyWith(
        title: String? = nil,
        date: Date? = nil,
        contents: String? = nil,
        isDone: Bool? = nil
    ) -> TodoModelProtocol{
        return TodoModel(
            id: self.id,
            title: title ?? self.title,
            date: date ?? self.date,
            contents: contents ?? self.contents,
            isDone: isDone ?? self.isDone
        )
    }
}

struct TodoModel: TodoModelProtocol {
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

    init(_ `protocol`: TodoModelProtocol) {
        self.id = `protocol`.id
        self.title = `protocol`.title
        self.date = `protocol`.date
        self.contents = `protocol`.contents
        self.isDone = `protocol`.isDone
    }
}
