//
//  TodoDataSourceProvider.swift
//  todoApp
//
//  Created by 조영태 on 5/8/25.
//

import Foundation

enum TodoError: Error { case notFound }

protocol TodoDataSourceProtocol {
    func fetchTodoList() async throws -> [TodoResponse.Fetch]

    func writeTodo(_ param: TodoRequest.Write) async throws
        -> TodoResponse.Write

    func deleteTodo(_ param: TodoRequest.Delete) async throws
        -> TodoResponse.Delete

    func updateTodo(_ param: TodoRequest.Update) async throws -> TodoResponse.Update
}
