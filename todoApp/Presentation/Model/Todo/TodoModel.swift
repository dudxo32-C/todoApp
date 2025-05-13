//
//  TodoState.swift
//  todoApp
//
//  Created by 조영태 on 5/11/25.
//

import Foundation
import Differentiator

typealias TodoGroup = [TodoFilterType: [TodoModel]]

enum TodoFilterType: Int {
    case past = 2
    case today = 0
    case future = 1

    static var values: [TodoFilterType] {
        return [.today, .future, .past]
    }
}

protocol TodoModelProtocol {
    var id: String { get }
    var title: String { get }
    var date: Date { get }
    var contents: String { get }
    var isDone: Bool { get }
}

extension TodoModelProtocol {
    var asTodoModel: TodoModel {
        return TodoModel(
            id: id,
            title: title,
            date: date,
            contents: contents,
            isDone: isDone
        )
    }
}

struct TodoModel: TodoModelProtocol {
    var id: String
    var title: String
    var date: Date
    var contents: String
    var isDone: Bool
    
    init(id: String, title: String, date: Date, contents: String, isDone: Bool) {
        self.id = id
        self.title = title
        self.date = date
        self.contents = contents
        self.isDone = isDone
    }
}

extension TodoModel: Equatable {
    static func == (lhs: TodoModel, rhs: TodoModel) -> Bool {
        let isSameDay = Calendar.current.isDate(lhs.date, inSameDayAs: rhs.date)

        return lhs.id == rhs.id
            && lhs.title == rhs.title
            && lhs.contents == rhs.contents
            && isSameDay
            && lhs.isDone == rhs.isDone
    }

    func copyWith(
        title: String? = nil,
        date: Date? = nil,
        contents: String? = nil,
        isDone: Bool? = nil
    ) -> TodoModel {
        return TodoModel(
            id: self.id,
            title: title ?? self.title,
            date: date ?? self.date,
            contents: contents ?? self.contents,
            isDone: isDone ?? self.isDone
        )
    }
}

extension TodoModel: IdentifiableType {
    var identity: String { self.id }
}
