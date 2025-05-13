//
//  TodoLocalDataSource.swift
//  todoApp
//
//  Created by 조영태 on 5/8/25.
//

import Foundation
import RealmSwift

class TodoLocalDataSource: TodoDataSourceProtocol {
    var realm: Realm { get throws { try Realm() } }

    fileprivate func getData(id: String) throws -> TodoRealm {
        guard
            let target = try realm.objects(TodoRealm.self).filter({
                $0._id == id
            }).first
        else { throw TodoError.notFound }

        return target
    }

    func fetchTodoList() async throws -> [Write] {

        try await _Concurrency.Task.delayTwoSecond()

        let todoList = try Array(realm.objects(TodoRealm.self))

        return todoList.map {
            Write(
                id: $0._id,
                title: $0.title,
                date: $0.date,
                contents: $0.contents,
                isDone: $0.isDone
            )
        }
    }

    func writeTodo(title: String, contents: String, date: Date)
        async throws -> Write
    {
        try await _Concurrency.Task.delayTwoSecond()

        let newTodo = TodoRealm(title: title, date: date, contents: contents)

        try realm.write {
            try realm.add(newTodo)
        }

        return Write(
            id: newTodo._id,
            title: newTodo.title,
            date: newTodo.date,
            contents: newTodo.contents,
            isDone: newTodo.isDone
        )
    }

    func deleteTodo(id: String) async throws -> Delete {
        let target = try self.getData(id: id)

        try realm.write {
            try realm.delete(target)
        }

        return Delete(id: id)
    }

    func updateTodo(id:String, title: String, contents: String, date: Date, isDone: Bool) async throws
        -> Write
    {

        let target = try self.getData(id: id)

        try realm.write {
            target.title = title
            target.date = date
            target.contents = contents
            target.isDone = isDone
        }

        return Write(
            id: id,
            title: title,
            date: date,
            contents: contents,
            isDone: isDone
        )

    }

}

class StubTodoLocalDataSource: TodoLocalDataSource {}
