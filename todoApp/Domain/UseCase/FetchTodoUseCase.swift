//
//  FetchTodoUseCase.swift
//  todoApp
//
//  Created by 조영태 on 5/11/25.
//

import Foundation
import RxSwift

protocol FetchTodoUseCase {
    associatedtype Error: Swift.Error
    var repository: TodoRepository { get }

    /// 할일 목록 불러오기
    /// - Throws: ``FetchTodoUseCaseBase.Error``
    func execute() async throws -> [Todo]
}

final class DefaultFetchTodoUseCase: FetchTodoUseCase {
    enum Error: Swift.Error {
        case ServerError
    }

    var repository: TodoRepository

    init(_ repository: TodoRepository) {
        self.repository = repository
    }

    func execute() async throws -> [Todo] {
        do {
            return try await repository.fetchTodoList()
        } catch let error as NetworkError {
            switch error {
            case .DecodedFailed:
                throw error
            case .DictionaryFailed:
                throw error
            }
        } catch {
            throw Error.ServerError
        }
    }
}
