//
//  TodoModel.swift
//  todoApp
//
//  Created by 조영태 on 3/5/25.
//

import Foundation

protocol CreatableTodo {
    var title: String { get }
    var date: Date { get }
    var contents: String { get }
}

struct CreatableToDoImpl: CreatableTodo {
    var title: String
    var date: Date
    var contents: String
}

protocol Todo : CreatableTodo {
    var id: String { get }
    var isDone: Bool { get }
}

struct TodoImpl: Todo {
    var id: String
    var title: String
    var date: Date
    var contents: String
    var isDone: Bool
}
