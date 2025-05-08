//
//  TodoRepo.swift
//  todoApp
//
//  Created by 조영태 on 5/8/25.
//

import Foundation


class TodoRepo {
    private let dataSource: TodoDataSourceProvider

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
                contents: res.contents,
                isDone: res.isDone
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
            contents: response.contents,
            isDone: response.isDone
        )
    }

    /// 할일 목록 삭제하기
    /// - Throws: ``NetworkError``, ``TodoError``
    /// - Returns: Todo 모델의 `id`
    func deleteTodo(_ id: String) async throws -> String {
        let response = try await dataSource.deleteTodo(id: id)

        return response.id
    }

    /// 할일 목록 수정하기
    /// - Throws: ``NetworkError``, ``TodoError``
    /// - Returns: `Todo` 데이터 모델
    func updateTodo(_ todo: TodoModelProtocol) async throws -> TodoModelProtocol
    {
        let response = try await dataSource.updateTodo(todo: todo)

        return TodoModel(
            id: response.id,
            title: response.title,
            date: response.date,
            contents: response.contents,
            isDone: response.isDone
        )
    }
}
