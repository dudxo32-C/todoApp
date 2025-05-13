//
//  TodoRemoteDataSource.swift
//  todoApp
//
//  Created by 조영태 on 5/8/25.
//

import Foundation
import Moya

class TodoRemoteDataSource: TodoDataSourceProtocol {
    fileprivate var provider: MoyaProvider<TodoAPI>

    init(_ provider: MoyaProvider<TodoAPI>) {
        self.provider = provider
    }

    func fetchTodoList() async throws -> [TodoResponse.Fetch] {
        let response = await provider.request(.fetchList)
        

        switch response {
        case .success(let success):
            do {
                let data = try success.toDecoded(
                    type: [TodoResponse.Fetch].self
                )
                return data
            } catch {
                throw error
            }
        case .failure(let failure):
            throw failure
        }
    }

    func writeTodo(_ param:TodoRequest.Write) async throws
    -> TodoResponse.Write
    {
        let response = await provider.request(.write(param))
        
        switch response {
        case .success(let success):
            let data = try success.toDecoded(type: TodoResponse.Write.self)
            return data
        case .failure(let failure):
            throw failure
        }
    }

    func deleteTodo(_ param:TodoRequest.Delete) async throws -> TodoResponse.Delete {
        let response = await provider.request(.delete(param))
        
        switch response {
        case .success(let success):
            let data = try success.toDecoded(type: TodoResponse.Delete.self)
            return data
            
        case .failure(let failure):
            throw failure
        }
    }

    func updateTodo(_ param:TodoRequest.Update) async throws -> TodoResponse.Update {
        let response = await provider.request(.update(param))
        
        switch response {
        case .success(let success):
            let data = try success.toDecoded(type: TodoResponse.Update.self)
            return data
            
        case .failure(let failure):
            throw failure
        }
    }

}
