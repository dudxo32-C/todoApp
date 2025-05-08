//
//  TodoDataSourceProvider.swift
//  todoApp
//
//  Created by 조영태 on 5/8/25.
//

import Foundation

enum TodoError: Error { case notFound }

protocol TodoDataSourceProvider {
    func fetchTodoList() async throws -> [TodoResponseDTO]

    func writeTodo(title: String, contents: String, date: Date) async throws
        -> TodoResponseDTO

    func deleteTodo(id: String) async throws -> TodoModelProtocol

    func updateTodo(todo: TodoModelProtocol) async throws -> TodoResponseDTO
}
