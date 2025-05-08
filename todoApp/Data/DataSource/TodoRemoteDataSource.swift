//
//  TodoRemoteDataSource.swift
//  todoApp
//
//  Created by 조영태 on 5/8/25.
//

import Foundation
import Moya

class TodoRemoteDataSource: TodoDataSourceProvider {
    fileprivate var provider: MoyaProvider<TodoAPI>

    init(_ provider: MoyaProvider<TodoAPI>) {
        self.provider = provider
    }

    func fetchTodoList() async throws -> [TodoResponseResponse] {
        let response = await provider.request(.fetchList)
        

        switch response {
        case .success(let success):
            do {
                let data = try success.toDecoded(type: [TodoResponseResponse].self)
                return data
            } catch {
                throw error
            }
        case .failure(let failure):
            throw failure
        }
    }

    func writeTodo(title: String, contents: String, date: Date) async throws
        -> TodoResponseResponse
    {
        let response = await provider.request(.write(title: title, contents: contents, date: date))
        
        switch response {
        case .success(let success):
            let data = try success.toDecoded(type: TodoResponseResponse.self)
            return data
        case .failure(let failure):
            throw failure
        }
    }

    func deleteTodo(id: String) async throws -> TodoDeleteResponse {
        let response = await provider.request(.delete(id: id))
        
        switch response {
        case .success(let success):
            let data = try success.toDecoded(type: TodoDeleteResponse.self)
            return data
            
        case .failure(let failure):
            throw failure
        }
    }

    func updateTodo(todo: TodoModelProtocol) async throws -> TodoResponseResponse {
        let response = await provider.request(
            .update(
                id: todo.id,
                title: todo.title,
                contents: todo.contents,
                isDone: todo.isDone,
                date: todo.date
            )
        )
        
        switch response {
        case .success(let success):
            let data = try success.toDecoded(type: TodoResponseResponse.self)
            return data
            
        case .failure(let failure):
            throw failure
        }
    }

}
