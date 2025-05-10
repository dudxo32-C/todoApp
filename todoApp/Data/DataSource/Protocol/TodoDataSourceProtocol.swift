//
//  TodoDataSourceProvider.swift
//  todoApp
//
//  Created by 조영태 on 5/8/25.
//

import Foundation

enum TodoError: Error { case notFound }

protocol TodoDataSourceProtocol {
    func fetchTodoList() async throws -> [TodoResponseResponse]

    func writeTodo(title: String, contents: String, date: Date) async throws
        -> TodoResponseResponse

    func deleteTodo(id: String) async throws -> TodoDeleteResponse

    func updateTodo(todo: TodoModelProtocol) async throws -> TodoResponseResponse
}
