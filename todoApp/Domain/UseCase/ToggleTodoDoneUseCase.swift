//
//  ToggleTodoDoneUC.swift
//  todoApp
//
//  Created by 조영태 on 5/11/25.
//

import Foundation

protocol ToggleTodoDoneUseCase {
    associatedtype Error: Swift.Error
    var repository: TodoRepository { get }

    /// Todo 객체의 완료 여부 변경
    /// - Throws: ``ToggleTodoDoneUseCase.Error``
    func execute(_ target: Todo, list: [Todo]) async throws -> [Todo]
}

final class DefaultToggleTodoDoneUseCase: ToggleTodoDoneUseCase {
    enum Error: Swift.Error {
        case ServerError
    }

    var repository: any TodoRepository
    let cache: TodoListCache

    init(_ repository: any TodoRepository, cache: TodoListCache) {
        self.repository = repository
        self.cache = cache
    }

    func execute(_ target: Todo, list: [Todo]) async throws -> [Todo] {
        do {
            let newTodo = TodoImpl(
                id: target.id,
                title: target.title,
                date: target.date,
                contents: target.contents,
                isDone: !target.isDone
            )

            let new = try await repository.updateTodo(newTodo)

            return try cache.changeItemInList(new, list: list)

        } catch is NetworkError {
            throw NetworkError.DecodedFailed
        } catch is TodoListCache.Error {
            throw TodoListCache.Error.notFound
        } catch {
            throw Error.ServerError
        }
    }

}
