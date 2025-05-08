//
//  TodoLocalDataSource.swift
//  todoApp
//
//  Created by 조영태 on 5/8/25.
//

import Foundation
import RealmSwift

class TodoLocalDataSource: TodoDataSourceProvider {
    var realm: Realm { get throws { try Realm() } }

    fileprivate func getData(id: String) throws -> TodoRealm {
        guard
            let target = try realm.objects(TodoRealm.self).filter({
                $0._id == id
            }).first
        else { throw TodoError.notFound }

        return target
    }

    func fetchTodoList() async throws -> [TodoResponseResponse] {

        try await _Concurrency.Task.delayTwoSecond()

        let todoList = try Array(realm.objects(TodoRealm.self))

        return todoList.map {
            TodoResponseResponse(
                id: $0._id,
                title: $0.title,
                date: $0.date,
                contents: $0.contents,
                isDone: $0.isDone
            )
        }
    }

    func writeTodo(title: String, contents: String, date: Date)
        async throws -> TodoResponseResponse
    {
        try await _Concurrency.Task.delayTwoSecond()

        let newTodo = TodoRealm(title: title, date: date, contents: contents)

        try realm.write {
            try realm.add(newTodo)
        }

        return TodoResponseResponse(
            id: newTodo._id,
            title: newTodo.title,
            date: newTodo.date,
            contents: newTodo.contents,
            isDone: newTodo.isDone
        )
    }

    func deleteTodo(id: String) async throws -> TodoDeleteResponse {
        let target = try self.getData(id: id)

        try realm.write {
            try realm.delete(target)
        }

        return TodoDeleteResponse(id: id)
    }

    func updateTodo(todo: TodoModelProtocol) async throws
        -> TodoResponseResponse
    {

        let target = try self.getData(id: todo.id)

        try realm.write {
            target.title = todo.title
            target.date = todo.date
            target.contents = todo.contents
            target.isDone = todo.isDone
        }

        return TodoResponseResponse(
            id: todo.id,
            title: todo.title,
            date: todo.date,
            contents: todo.contents,
            isDone: todo.isDone
        )

    }

}

class StubTodoLocalDataSource: TodoLocalDataSource {}
