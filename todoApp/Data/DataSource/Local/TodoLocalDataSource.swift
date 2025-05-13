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

    func fetchTodoList() async throws -> [TodoResponse.Fetch] {

        try await _Concurrency.Task.delayTwoSecond()

        let todoList = try Array(realm.objects(TodoRealm.self))

        return todoList.map {
            TodoResponse.Fetch(
                id: $0._id,
                title: $0.title,
                date: $0.date,
                contents: $0.contents,
                isDone: $0.isDone
            )
        }
    }

    func writeTodo(_ param: TodoRequest.Write)
        async throws -> TodoResponse.Write
    {
        try await _Concurrency.Task.delayTwoSecond()

        let newTodo = TodoRealm(
            title: param.title,
            date: param.date,
            contents: param.contents
        )

        try realm.write {
            try realm.add(newTodo)
        }

        return TodoResponse.Write(
            id: newTodo._id,
            title: newTodo.title,
            date: newTodo.date,
            contents: newTodo.contents,
            isDone: newTodo.isDone
        )
    }

    func deleteTodo(_ param: TodoRequest.Delete) async throws
        -> TodoResponse.Delete
    {
        let target = try self.getData(id: param.id)

        try realm.write {
            try realm.delete(target)
        }

        return TodoResponse.Delete(id: param.id)
    }

    func updateTodo(_ param: TodoRequest.Update) async throws
        -> TodoResponse.Update
    {
        let target = try self.getData(id: param.id)

        try realm.write {
            target.title = param.title
            target.date = param.date
            target.contents = param.contents
            target.isDone = param.isDone
        }

        return TodoResponse.Update(
            id: param.id,
            title: param.title,
            date: param.date,
            contents: param.contents,
            isDone: param.isDone
        )

    }

}

class StubTodoLocalDataSource: TodoLocalDataSource {}
