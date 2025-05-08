//
//  TodoRemoteDataSource.swift
//  todoApp
//
//  Created by 조영태 on 5/8/25.
//

import Foundation
import Moya

class TodoRemoteDataSource: TodoDataSourceProvider {
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
        preconditionFailure(
            "Subclasses must implement writeTodo(title:contents:date:)"
        )
    }

    func deleteTodo(id: String) async throws -> TodoModelProtocol {
        preconditionFailure(
            "Subclasses must implement deleteTodo(id:)"
        )
    }

    func updateTodo(todo: TodoModelProtocol) async throws -> TodoResponseDTO {
        preconditionFailure(
            "Subclasses must implement updateTodo(todo:)"
        )
    }

}
