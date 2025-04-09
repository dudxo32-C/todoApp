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

enum TodoError: Error { case notFound }

protocol TodoDataSourceProvider {
    func fetchTodoList() async throws -> [TodoResponseDTO]

    func writeTodo(title: String, contents: String, date: Date) async throws
        -> TodoResponseDTO

    func deleteTodo(id: String) async throws -> String

    func updateTodo(todo: TodoModelProtocol) async throws -> TodoResponseDTO
}

class TodoRepo {
    private let dataSource: TodoDataSourceProvider
    private let cancelBag = Set<AnyCancellable>()

    init(_ dataSource: TodoDataSourceProvider) {
        self.dataSource = dataSource
    }

    /// 할일 목록 불러오기
    /// - Throws: ``NetworkError``
    /// - Returns: `Todo` 데이터 모델 배열
    func fetchTodoList() async throws -> [TodoModelProtocol] {
        let response = try await dataSource.fetchTodoList()

        return response.map { res in
            TodoModel(
                id: res.id,
                title: res.title,
                date: res.date,
                contents: res.contents
            )
        }
    }

    /// 할일 목록 작성하기
    /// - Throws: ``NetworkError``
    /// - Returns: `Todo` 데이터 모델
    func writeTodo(title: String, contents: String, date: Date) async throws
        -> TodoModelProtocol
    {
        let response = try await dataSource.writeTodo(
            title: title, contents: contents, date: date)

        return TodoModel(
            id: response.id,
            title: response.title,
            date: response.date,
            contents: response.contents
        )
    }

    /// 할일 목록 삭제하기
    /// - Throws: ``NetworkError``, ``TodoError``
    /// - Returns: Todo 모델의 `id`
    func deleteTodo(id: String) async throws -> String {
        let response = try await dataSource.deleteTodo(id: id)

        return response
    }

    /// 할일 목록 수정하기
    /// - Throws: ``NetworkError``, ``TodoError``
    /// - Returns: `Todo` 데이터 모델
    func updateTodo(todo: TodoModelProtocol) async throws -> TodoModelProtocol {
        let response = try await dataSource.updateTodo(todo: todo)
        
        return TodoModel(
            id: response.id,
            title: response.title,
            date: response.date,
            contents: response.contents
        )
    }

}

class TodoDS: TodoDataSourceProvider {
    fileprivate var networkManager: NetworkManager<TodoAPI>

    init(networkManager: NetworkManager<TodoAPI> = .init(environment: .mock)) {
        self.networkManager = networkManager
    }

    func fetchTodoList() async throws -> [TodoResponseDTO] {
        let response = await MoyaProvider<TodoAPI>().request(.fetchList)
        //        self.networkManager.request(.fetchList)

        switch response {
        case .success(let success):
            do {
                let data = try success.toDecoded(type: [TodoResponseDTO].self)
                return data
            } catch {
                throw error
            }
        case .failure(let failure):
            throw failure
        }
    }

    func writeTodo(title: String, contents: String, date: Date) async throws
        -> TodoResponseDTO
    {
        throw NSError(domain: "", code: 0, userInfo: nil)
    }

    func deleteTodo(id: String) async throws -> String {
        throw NSError(domain: "", code: 0, userInfo: nil)
    }

    func updateTodo(todo: TodoModelProtocol) async throws -> TodoResponseDTO {
        throw NSError(domain: "", code: 0, userInfo: nil)
    }

}

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
                contents: $0.contents
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
            contents: newTodo.contents
        )
    }

    override func deleteTodo(id: String) async throws -> String {
        let target = try self.getData(id: id)

        try realm.write {
            try realm.delete(target)
        }

        return target._id

    }

    override func updateTodo(todo: TodoModelProtocol) async throws
        -> TodoResponseDTO
    {

        let target = try self.getData(id: todo.id)

        try realm.write {
            target.title = todo.title
            target.date = todo.date
            target.contents = todo.contents
        }

        return TodoResponseDTO(
            id: todo.id,
            title: todo.title,
            date: todo.date,
            contents: todo.contents
        )

    }
}
