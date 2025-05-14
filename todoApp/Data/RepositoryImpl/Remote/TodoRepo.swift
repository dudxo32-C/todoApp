//
//  TodoRepo.swift
//  todoApp
//
//  Created by 조영태 on 3/10/25.
//

import Combine
import Foundation
import Moya
import RealmSwift

//enum TodoError: Error { case notFound }

//protocol TodoDataSourceProvider {
//    func fetchTodoList() async throws -> [TodoResponseDTO]
//
//    func writeTodo(title: String, contents: String, date: Date) async throws
//        -> TodoResponseDTO
//
//    func deleteTodo(id: String) async throws -> TodoModelProtocol
//
//    func updateTodo(todo: TodoModelProtocol) async throws -> TodoResponseDTO
//}



class MockTodoDS: TodoDS {
    var realm: Realm { get throws { try Realm() } }

    fileprivate func getData(id: String) throws -> TodoRealm {
        guard
            let target = try realm.objects(TodoRealm.self).filter({
                $0._id == id
            }).first
        else { throw TodoError.notFound }

        return target
    }

    override func fetchTodoList() async throws -> [TodoResponseDTO] {

        try await _Concurrency.Task.delayTwoSecond()

        let todoList = try Array(realm.objects(TodoRealm.self))

        return todoList.map {
            TodoResponseDTO(
                id: $0._id,
                title: $0.title,
                date: $0.date,
                contents: $0.contents,
                isDone: $0.isDone
            )
        }
    }

    override func writeTodo(title: String, contents: String, date: Date)
        async throws -> TodoResponseDTO
    {
        try await _Concurrency.Task.delayTwoSecond()

        let newTodo = TodoRealm(title: title, date: date, contents: contents)

        try realm.write {
            try realm.add(newTodo)
        }

        return TodoResponseDTO(
            id: newTodo._id,
            title: newTodo.title,
            date: newTodo.date,
            contents: newTodo.contents,
            isDone: newTodo.isDone
        )
    }

    override func deleteTodo(id: String) async throws -> TodoModelProtocol {
        let target = try self.getData(id: id)

        let temp = TodoModel(
            id: target._id,
            title: target.title,
            date: target.date,
            contents: target.contents,
            isDone: target.isDone
        )
        
        try realm.write {
            try realm.delete(target)
        }

        return temp

    }

    override func updateTodo(todo: TodoModelProtocol) async throws
        -> TodoResponseDTO
    {

        let target = try self.getData(id: todo.id)

        try realm.write {
            target.title = todo.title
            target.date = todo.date
            target.contents = todo.contents
            target.isDone = todo.isDone
        }

        return TodoResponseDTO(
            id: todo.id,
            title: todo.title,
            date: todo.date,
            contents: todo.contents,
            isDone: todo.isDone
        )

    }
}
