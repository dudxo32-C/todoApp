//
//  DeleteTodoUC.swift
//  todoApp
//
//  Created by 조영태 on 5/11/25.
//

import Foundation
import RxSwift

protocol DeleteTodoUseCase {
    associatedtype Error: Swift.Error
    var repository: TodoRepository { get }

    /// 할일 삭제하기
    /// - Throws: ``DeleteTodoUseCaseBase.Error``
    func execute(_ target: Todo, list: [Todo]) async throws -> [Todo]
}

class DefaultDeleteTodoUseCase: DeleteTodoUseCase {
    enum Error: Swift.Error {
        case ServerError
    }

    var repository: TodoRepository
    let cache:TodoListCache
    
    init(_ repository: TodoRepository, cache:TodoListCache) {
        self.repository = repository
        self.cache = cache
        
    }

    func execute(_ target: Todo, list: [Todo]) async throws -> [Todo] {
        do {
            let removedID = try await repository.deleteTodo(target.id)

            return cache.deleteItemInList(removedID, list:list)

        } catch let error as NetworkError {
            switch error {
            case .DecodedFailed:
                throw error
            }
        } catch {
            throw Error.ServerError
        }
    }
}
